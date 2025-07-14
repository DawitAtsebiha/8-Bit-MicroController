# app.py – 8-Bit MightyController GUI (black text, white background)

import os, glob, sys
from pathlib import Path
from PyQt6.QtWidgets import (
    QApplication, QWidget, QLabel, QTextEdit, QFileDialog, QMessageBox,
    QPushButton, QVBoxLayout, QHBoxLayout, QGroupBox
)
from PyQt6.QtCore import Qt, QProcess
from PyQt6.QtGui import QTextCursor


class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("8-Bit MightyController")
        self.resize(600, 700)

        # global stylesheet: white everywhere, black text
        self.setStyleSheet("""
            QWidget        { background:#ffffff; color:#000000;
                             font-family:'Segoe UI',Arial,sans-serif; }
            QGroupBox      { border:2px solid #bdc3c7; border-radius:10px;
                             margin-top:15px; padding-top:15px; }
            QGroupBox::title { subcontrol-origin:margin; left:15px; padding:0 10px; }
            QPushButton    { background:#f0f0f0; border:1px solid #a0a0a0;
                             padding:10px 20px; border-radius:8px; font-weight:bold; }
            QPushButton:hover   { background:#e0e0e0; }
            QPushButton:pressed { background:#d0d0d0; }
            QTextEdit      { background:#ffffff; color:#000000;
                             border:1px solid #bdc3c7; }
        """)

        root = QVBoxLayout(self)
        root.setContentsMargins(40, 40, 40, 40)
        root.setSpacing(25)

        # Title
        title    = QLabel("8-Bit MightyController", alignment=Qt.AlignmentFlag.AlignCenter)
        subtitle = QLabel("Assembly & Simulation Tool", alignment=Qt.AlignmentFlag.AlignCenter)
        title.setStyleSheet("font-size:28px; font-weight:bold;")
        subtitle.setStyleSheet("font-size:16px; margin-bottom:20px;")
        root.addWidget(title); root.addWidget(subtitle)

        # File Selection
        gb_file = QGroupBox("File Selection"); vf = QVBoxLayout(gb_file); vf.setSpacing(20)
        self.file_btn      = self._mk_button("Select ASM File", 45)
        self.assemble_btn  = self._mk_button("Assemble Code",   45)
        self.file_label    = QLabel("Please select your ASM (Assembly) file."); self.file_label.setWordWrap(True)
        row = QHBoxLayout(); row.setSpacing(20); row.addWidget(self.file_btn); row.addWidget(self.file_label, 1)
        vf.addLayout(row); vf.addWidget(self.assemble_btn)
        root.addWidget(gb_file)

        # Simulation
        gb_sim = QGroupBox("Simulation & Analysis"); vs = QVBoxLayout(gb_sim); vs.setSpacing(20)
        self.compile_btn  = self._mk_button("Compile & Simulate",   50)
        self.wave_btn     = self._mk_button("Show Wave Simulation", 50)
        vs.addWidget(self.compile_btn); vs.addWidget(self.wave_btn)
        root.addWidget(gb_sim)

        # Status + Console
        self.status_label = QLabel(alignment=Qt.AlignmentFlag.AlignCenter); root.addWidget(self.status_label)
        self.console = QTextEdit(readOnly=True); self.console.setMinimumHeight(180); root.addWidget(self.console)
        self._set_status("Ready", "#27ae60")

        # Processes
        self.proc_asm  = QProcess(self)
        self.proc_cc   = QProcess(self)
        self.proc_sim  = QProcess(self)
        for p in (self.proc_asm, self.proc_cc, self.proc_sim):
            p.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)

        # Signal wiring
        self.file_btn.clicked.connect(self._select_file)
        self.assemble_btn.clicked.connect(self._run_assemble)
        self.compile_btn.clicked.connect(self._run_compile)
        self.wave_btn.clicked.connect(self._run_wave)

        # keep last output path for message box
        self._pending_bin = ""

    # UI HELPERS 
    def _mk_button(self, text: str, height: int) -> QPushButton:
        b = QPushButton(text); b.setFixedHeight(height); return b

    def _set_status(self, msg: str, border: str):
        self.status_label.setText(msg)
        self.status_label.setStyleSheet(f"background:#ffffff; border:2px solid {border}; "
                                        f"border-radius:6px; padding:8px 15px; font-weight:bold;")

    def _append_output(self, proc: QProcess):
        data = bytes(proc.readAllStandardOutput()).decode(errors="ignore")
        self.console.moveCursor(QTextCursor.MoveOperation.End)
        self.console.insertPlainText(data)
        self.console.moveCursor(QTextCursor.MoveOperation.End)

    def _info(self, title: str, text: str): QMessageBox.information(self, title, text)

    # Assembly File Selection
    def _select_file(self):
        fn, _ = QFileDialog.getOpenFileName(self, "Select Assembly File", "", "Assembly Files (*.asm);;All Files (*)")
        if fn:
            self.selected_file = fn
            self.file_name = Path(fn).stem
            self.file_label.setText(f"Selected: {self.file_name}.asm")
            self._set_status("File selected", "#27ae60")
        else:
            self.selected_file = self.file_name = None
            self.file_label.setText("Please select your ASM (Assembly) file.")
            self._set_status("No file selected", "#e74c3c")

    # Assembling into Binary
    def _run_assemble(self):
        if not self.selected_file:
            self._info("Warning", "Please select an ASM file first."); return
        self.console.clear()
        out_bin = os.path.join("build", f"{self.file_name}.bin"); self._pending_bin = out_bin
        self._set_status("Assembling…", "#f39c12")
        self.proc_asm.readyReadStandardOutput.connect(lambda: self._append_output(self.proc_asm),
                                                      Qt.ConnectionType.UniqueConnection)
        self.proc_asm.finished.connect(self._on_assemble_done, Qt.ConnectionType.UniqueConnection)
        self.proc_asm.start("python", ["software/assembler.py", "assemble",
                                       self.selected_file, "-o", out_bin])

    def _on_assemble_done(self):
        ok = self.proc_asm.exitCode() == 0
        self._set_status("Assembly OK" if ok else "Assembly failed", "#27ae60" if ok else "#e74c3c")
        if ok: self._info("Assembly Complete", f"Output: {self._pending_bin}")
        self.proc_asm.readyReadStandardOutput.disconnect()
        self.proc_asm.finished.disconnect()

    # Compiling + Simulation
    def _run_compile(self):
        self.console.clear()
        self._set_status("Compiling…", "#f39c12")
        build_dir = Path("build"); build_dir.mkdir(exist_ok=True)
        src = glob.glob("verilog/*.sv") + ["testbench/computer_TB.sv"]
        args = ["-g2012", "-o", str(build_dir / "tb.out"), "-s", "computer_TB", *src]

        self.proc_cc.readyReadStandardOutput.connect(lambda: self._append_output(self.proc_cc),
                                                     Qt.ConnectionType.UniqueConnection)
        self.proc_cc.finished.connect(self._on_compile_done, Qt.ConnectionType.UniqueConnection)
        self.proc_cc.start("iverilog", args)

    def _on_compile_done(self):
        if self.proc_cc.exitCode() != 0:
            self._set_status("Compilation failed", "#e74c3c")
            self._info("Compilation Error", "Compilation failed — see console.")
            self.proc_cc.readyReadStandardOutput.disconnect(); self.proc_cc.finished.disconnect(); return

        self._set_status("Running simulation…", "#f39c12")
        self.proc_sim.readyReadStandardOutput.connect(lambda: self._append_output(self.proc_sim),
                                                      Qt.ConnectionType.UniqueConnection)
        self.proc_sim.finished.connect(self._on_sim_done, Qt.ConnectionType.UniqueConnection)
        self.proc_sim.start("vvp", ["-n", "build/tb.out"])

    def _on_sim_done(self):
        ok = self.proc_sim.exitCode() == 0
        self._set_status("Simulation OK" if ok else "Simulation failed", "#27ae60" if ok else "#e74c3c")
        if ok:
            self._info("Simulation Complete", "Simulation finished. Use 'Show Wave Simulation' if desired.")
        self.proc_sim.readyReadStandardOutput.disconnect(); self.proc_sim.finished.disconnect()

    # Producing waves simulation
    def _run_wave(self):
        self._set_status("Opening GTKWave…", "#8e44ad")
        self.proc_asm.start("gtkwave", ["waves.vcd"])   # reuse proc_asm as a simple worker

    # Exiting
    def closeEvent(self, e):
        for p in (self.proc_asm, self.proc_cc, self.proc_sim):
            if p.state() != QProcess.ProcessState.NotRunning: p.kill()
        e.accept()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")

    window = MainWindow()    # keep in a variable
    window.show()

    sys.exit(app.exec())
