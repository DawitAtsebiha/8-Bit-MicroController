import os, glob, sys
from pathlib import Path
from PyQt6.QtWidgets import *
from PyQt6.QtCore import Qt, QProcess
from PyQt6.QtGui import QTextCursor


class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("8-But MightyController - Assembly & Simulation Tool")
        self.resize(1400, 900)  # Increased default size
        self.setMinimumSize(1200, 700)  # Set minimum size to prevent crushing
        self.setStyleSheet(self._get_styles())
        
        # Main layout
        main_layout = QHBoxLayout(self)
        main_layout.setContentsMargins(10, 10, 10, 10)  # Reduced margins
        main_layout.setSpacing(10)
        
        splitter = QSplitter(Qt.Orientation.Horizontal)
        main_layout.addWidget(splitter)
        
        splitter.addWidget(self._create_left_panel())
        splitter.addWidget(self._create_right_panel())
        splitter.setSizes([500, 900])  # Better proportions
        splitter.setStretchFactor(0, 0)  # Left panel doesn't stretch
        splitter.setStretchFactor(1, 1)  # Right panel stretches
        
        # Initialize
        self.has_file = False
        self.selected_file = None
        self.file_name = None
        self._setup_processes()
        self._connect_signals()
        self._populate_existing_programs()
        self._set_status("Ready", "success")

    def _get_styles(self):
        return """
            QMainWindow, QWidget { 
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #f8f9fa, stop:1 #e9ecef);
                color: #2c3e50; 
                font-family: 'Segoe UI', 'SF Pro Display', system-ui, sans-serif; 
                font-size: 14px;
            }
            QGroupBox { 
                border: 2px solid #3498db; 
                border-radius: 12px; 
                margin-top: 20px; 
                padding-top: 20px; 
                font-weight: 600;
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #ffffff, stop:1 #f8f9fa);
            }
            QGroupBox::title { 
                subcontrol-origin: margin; 
                left: 20px; 
                padding: 0 12px;
                color: #3498db;
                font-size: 15px;
                font-weight: 700;
            }
            QPushButton { 
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #3498db, stop:1 #2980b9);
                border: none;
                color: white;
                padding: 12px 24px; 
                border-radius: 8px; 
                font-weight: 600;
                font-size: 14px;
                min-height: 20px;
            }
            QPushButton:hover { 
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #5dade2, stop:1 #3498db);
            }
            QPushButton:pressed { 
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #2980b9, stop:1 #1f618d);
            }
            QPushButton:disabled {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #ecf0f1, stop:1 #d5dbdb);
                color: #95a5a6;
                border: 1px solid #bdc3c7;
            }
            QTextEdit { 
                background: #1e1e1e; 
                color: #d4d4d4;
                border: 2px solid #333333;
                border-radius: 8px;
                font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
                font-size: 12px;
                padding: 12px;
                selection-background-color: #264f78;
            }
            QComboBox { 
                padding: 10px 16px; 
                border: 2px solid #3498db; 
                border-radius: 8px; 
                background: white;
                font-size: 14px;
                min-height: 20px;
            }
            QComboBox:hover {
                border-color: #5dade2;
            }
            QComboBox::drop-down {
                border: none;
                width: 30px;
            }
            QComboBox::down-arrow {
                image: none;
                border: 2px solid #3498db;
                width: 8px;
                height: 8px;
                border-radius: 2px;
            }
            QLabel {
                color: #2c3e50;
                font-weight: 500;
                background: transparent;
            }
            #fileStatus {
                color: #7f8c8d;
                font-style: italic;
                background: transparent;
            }
            #orSeparator {
                color: #7f8c8d;
                font-style: italic;
                margin: 5px;
                background: transparent;
            }
            #fileSelected {
                color: #27ae60;
                font-weight: bold;
                background: transparent;
            }
            #status { 
                font-weight: 700; 
                padding: 12px 20px; 
                border-radius: 8px;
                font-size: 14px;
                border: none;
                background: rgba(236, 240, 241, 0.3);  /* Light transparent gray */
                color: #2c3e50;
            }
            #status[class="success"] {
                background: rgba(213, 244, 230, 0.4);  /* Light transparent green */
                color: #1e8449;  /* Darker green for better contrast */
                border: 1px solid rgba(39, 174, 96, 0.3);
            }
            #status[class="error"] {
                background: rgba(248, 215, 218, 0.4);  /* Light transparent red */
                color: #c0392b;  /* Darker red for better contrast */
                border: 1px solid rgba(231, 76, 60, 0.3);
            }
            #status[class="working"] {
                background: rgba(255, 243, 205, 0.4);  /* Light transparent orange */
                color: #d68910;  /* Darker orange for better contrast */
                border: 1px solid rgba(243, 156, 18, 0.3);
            }
            #title { 
                color: #2c3e50; 
                font-size: 28px; 
                font-weight: 700;
                margin-bottom: 8px;
            }
            #subtitle {
                color: #7f8c8d;
                font-size: 16px;
                font-weight: 400;
                margin-bottom: 20px;
            }
            #consoleHeader {
                color: #2c3e50;
                font-size: 18px;
                font-weight: 600;
                margin-bottom: 10px;
            }
            QSplitter::handle {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, 
                    stop:0 #e0e0e0, stop:0.5 #3498db, stop:1 #e0e0e0);
                width: 4px;
                border-radius: 2px;
            }
            QSplitter::handle:hover {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, 
                    stop:0 #3498db, stop:0.5 #2980b9, stop:1 #3498db);
            }
            QSplitter::handle:pressed {
                background: #2980b9;
            }
            QSpinBox {
                padding: 5px 8px;
                border: 2px solid #3498db;
                border-radius: 4px;
                background: white;
                font-size: 12px;
                min-height: 20px;
            }
            QSpinBox:focus {
                border-color: #5dade2;
            }
            QCheckBox {
                color: #2c3e50;
                font-size: 13px;  /* Slightly larger font */
                spacing: 6px;     /* More spacing */
                min-height: 22px; /* Bigger minimum height */
                padding: 2px;     /* Add some padding */
            }
            QCheckBox::indicator {
                width: 18px;      /* Bigger checkbox */
                height: 18px;
                border: 2px solid #3498db;
                border-radius: 3px;
                background: white;
            }
            QCheckBox::indicator:checked {
                background: #3498db;
                image: none;
                border: 2px solid #2980b9;
            }
            QScrollArea {
                border: none;
                background: transparent;
            }
        """

    def _create_left_panel(self):
        panel = QFrame()
        panel.setMinimumWidth(450)  
        panel.setMaximumWidth(600)  # Maximum width to prevent over-expansion
        layout = QVBoxLayout(panel)
        layout.setSpacing(12)  # Reduced spacing

        # Header
        title = QLabel("8-But MightyController")
        title.setObjectName("title")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        subtitle = QLabel("Assembly & Simulation Tool")
        subtitle.setObjectName("subtitle")
        subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        layout.addWidget(title)
        layout.addWidget(subtitle)

        # File Selection
        file_group = QGroupBox("File Selection")
        file_layout = QVBoxLayout(file_group)
        file_layout.setSpacing(8)  
        
        # New file selection
        new_file_row = QHBoxLayout()
        self.file_btn = QPushButton("Select ASM File")
        self.file_btn.setFixedHeight(35) 
        self.file_label = QLabel("No file selected")
        self.file_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.file_label.setObjectName("fileStatus")
        new_file_row.addWidget(self.file_btn)
        new_file_row.addWidget(self.file_label, 1)
        file_layout.addLayout(new_file_row)

        # OR separator
        or_label = QLabel("— OR —")
        or_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        or_label.setObjectName("orSeparator")
        file_layout.addWidget(or_label)

        # Existing programs dropdown
        existing_row = QHBoxLayout()
        existing_row.addWidget(QLabel("Quick Run:"))
        self.existing_combo = QComboBox()
        self.existing_combo.setFixedHeight(30)  
        self.quick_run_btn = QPushButton("Run")
        self.quick_run_btn.setFixedSize(80, 30) 
        self.quick_run_btn.setEnabled(True)
        existing_row.addWidget(self.existing_combo, 1)
        existing_row.addWidget(self.quick_run_btn)
        file_layout.addLayout(existing_row)

        layout.addWidget(file_group)

        # Actions
        actions_group = QGroupBox("Actions")
        actions_layout = QVBoxLayout(actions_group)
        actions_layout.setSpacing(8) 
        
        self.assemble_btn = QPushButton("Assemble Code")
        self.assemble_btn.setFixedHeight(35) 
        self.assemble_btn.setEnabled(False)
        
        self.simulate_btn = QPushButton("Compile & Simulate")
        self.simulate_btn.setFixedHeight(35)
        self.simulate_btn.setEnabled(False)
        
        self.wave_btn = QPushButton("Show Waveforms")
        self.wave_btn.setFixedHeight(35)
        self.wave_btn.setEnabled(False)

        actions_layout.addWidget(self.assemble_btn)
        actions_layout.addWidget(self.simulate_btn)
        actions_layout.addWidget(self.wave_btn)
        layout.addWidget(actions_group)

        # Debug Options
        debug_group = QGroupBox("Debug Options")
        debug_layout = QVBoxLayout(debug_group)
        debug_layout.setSpacing(8)  
        
        # Top row: Max Cycles and Presets
        top_row = QHBoxLayout()
        
        # Max Cycles section (left side)
        cycles_section = QHBoxLayout()
        cycles_section.addWidget(QLabel("Max Cycles:"))
        self.cycle_spin = QSpinBox()
        self.cycle_spin.setRange(100, 50000)
        self.cycle_spin.setValue(1000)
        self.cycle_spin.setSingleStep(100)
        self.cycle_spin.setFixedHeight(28) 
        self.cycle_spin.setMinimumWidth(100)
        cycles_section.addWidget(self.cycle_spin)
        cycles_section.addStretch()
        
        # Presets section (right side)
        presets_section = QHBoxLayout()
        presets_section.addWidget(QLabel("Presets:"))
        
        self.preset_none_btn = QPushButton("None")
        self.preset_full_btn = QPushButton("Full")
        
        # Smaller preset buttons
        for btn in [self.preset_none_btn, self.preset_full_btn]:
            btn.setFixedHeight(28)
            btn.setMinimumWidth(90)
            btn.setMaximumWidth(90)
        
        presets_section.addWidget(self.preset_none_btn)
        presets_section.addWidget(self.preset_full_btn)
        
        # Add both sections to top row
        top_row.addLayout(cycles_section)
        top_row.addSpacing(20)  # Add some space between sections
        top_row.addLayout(presets_section)
        
        debug_layout.addLayout(top_row)
        
        # Debug checkboxes in a grid (now with more space)
        debug_checks_layout = QGridLayout()
        debug_checks_layout.setSpacing(6)  # Increased spacing for bigger checkboxes
        
        self.debug_enable = QCheckBox("Enable Debug")
        self.debug_pc = QCheckBox("Show PC")
        self.debug_ir = QCheckBox("Show IR")
        self.debug_regs = QCheckBox("Show Register Values")
        self.debug_mem = QCheckBox("Show Memory")
        self.debug_inner_workings = QCheckBox("See Inner Workings")
        self.debug_state = QCheckBox("Show State")
        self.debug_verbose = QCheckBox("Verbose Mode")
        
        # Set defaults
        self.debug_inner_workings.setChecked(False)  # Default to off since it shows detailed internal operations
        
        # Arrange in 2 columns with better sizing
        debug_checks_layout.addWidget(self.debug_enable, 0, 0)
        debug_checks_layout.addWidget(self.debug_pc, 0, 1)
        debug_checks_layout.addWidget(self.debug_ir, 1, 0)
        debug_checks_layout.addWidget(self.debug_regs, 1, 1)
        debug_checks_layout.addWidget(self.debug_mem, 2, 0)
        debug_checks_layout.addWidget(self.debug_inner_workings, 2, 1)
        debug_checks_layout.addWidget(self.debug_state, 3, 0)
        debug_checks_layout.addWidget(self.debug_verbose, 3, 1)
        
        # Set column stretch to distribute evenly
        debug_checks_layout.setColumnStretch(0, 1)
        debug_checks_layout.setColumnStretch(1, 1)
        
        debug_layout.addLayout(debug_checks_layout)
        
        layout.addWidget(debug_group)

        # Status
        self.status_label = QLabel()
        self.status_label.setObjectName("status")
        self.status_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.status_label.setMaximumHeight(40) 
        layout.addWidget(self.status_label)

        layout.addStretch()  # Add stretch at the bottom
        return panel

    def _create_right_panel(self):
        panel = QFrame()
        layout = QVBoxLayout(panel)
        layout.setSpacing(10)

        # Console header with clear button
        header_row = QHBoxLayout()
        console_title = QLabel("Simulation Console")
        console_title.setObjectName("consoleHeader")
        header_row.addWidget(console_title)
        
        clear_btn = QPushButton("Clear")
        clear_btn.setMaximumWidth(120)
        clear_btn.setFixedHeight(35)
        clear_btn.clicked.connect(lambda: self.console.clear())
        header_row.addStretch()
        header_row.addWidget(clear_btn)
        layout.addLayout(header_row)

        # Console
        self.console = QTextEdit()
        self.console.setReadOnly(True)
        layout.addWidget(self.console)

        return panel

    def _setup_processes(self):
        self.proc_asm = QProcess(self)
        self.proc_sim = QProcess(self)
        self.proc_wave = QProcess(self)
        for p in [self.proc_asm, self.proc_sim]:
            p.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)

    def _connect_signals(self):
        self.file_btn.clicked.connect(self._select_file)
        self.assemble_btn.clicked.connect(self._assemble)
        self.simulate_btn.clicked.connect(self._simulate)
        self.wave_btn.clicked.connect(self._show_waves)
        self.quick_run_btn.clicked.connect(self._quick_run)
        self.existing_combo.currentTextChanged.connect(self._on_existing_changed)
        
        # Debug preset connections
        self.preset_none_btn.clicked.connect(self._preset_none)
        self.preset_full_btn.clicked.connect(self._preset_full)
        
        # Verbose mode auto-enables all debug options
        self.debug_verbose.toggled.connect(self._on_verbose_changed)

    def _populate_existing_programs(self):
        """Find existing binary files and populate dropdown"""
        build_dir = Path("Programs/build")
        if not build_dir.exists():
            build_dir.mkdir(parents=True, exist_ok=True)
            
        bin_files = list(build_dir.glob("*.bin"))
        
        self.existing_combo.clear()
        if bin_files:
            self.existing_combo.addItem("Select program...")
            for bin_file in sorted(bin_files):
                self.existing_combo.addItem(bin_file.stem)
        else:
            self.existing_combo.addItem("No programs available")

    def _on_existing_changed(self):
        """Enable quick run button when program selected"""
        current = self.existing_combo.currentText()
        self.quick_run_btn.setEnabled(
            current not in ["Select program...", "No programs available", ""]
        )

    def _preset_none(self):
        """Disable all debug options"""
        self.debug_enable.setChecked(False)
        self.debug_pc.setChecked(False)
        self.debug_ir.setChecked(False)
        self.debug_regs.setChecked(False)
        self.debug_mem.setChecked(False)
        self.debug_inner_workings.setChecked(False)
        self.debug_state.setChecked(False)
        self.debug_verbose.setChecked(False)

    def _preset_full(self):
        """Enable all debug options"""
        self.debug_enable.setChecked(True)
        self.debug_pc.setChecked(True)
        self.debug_ir.setChecked(True)
        self.debug_regs.setChecked(True)
        self.debug_mem.setChecked(True)
        self.debug_inner_workings.setChecked(True)
        self.debug_state.setChecked(True)
        self.debug_verbose.setChecked(False)  # Don't auto-enable verbose

    def _on_verbose_changed(self, checked):
        """When verbose mode is enabled, enable all debug options"""
        if checked:
            self.debug_enable.setChecked(True)
            self.debug_pc.setChecked(True)
            self.debug_ir.setChecked(True)
            self.debug_regs.setChecked(True)
            self.debug_mem.setChecked(True)
            self.debug_inner_workings.setChecked(True)
            self.debug_state.setChecked(True)

    def _set_status(self, msg: str, status_type: str = "normal"):
        """Update status with enhanced styling based on type"""
        self.status_label.setText(msg)
        
        # Map old color-based calls to new types
        color_map = {
            "#e74c3c": "error",
            "#27ae60": "success", 
            "#f39c12": "working",
            "#3498db": "working"
        }
        
        if status_type in color_map.values():
            # New type-based call
            self.status_label.setProperty("class", status_type)
        elif status_type in color_map:
            # Legacy color-based call - convert to type
            self.status_label.setProperty("class", color_map[status_type])
        else:
            # Default
            self.status_label.setProperty("class", "normal")
            
        # Force style refresh
        self.status_label.style().unpolish(self.status_label)
        self.status_label.style().polish(self.status_label)

    def _log(self, msg: str):
        self.console.moveCursor(QTextCursor.MoveOperation.End)
        self.console.insertPlainText(msg + "\n")
        self.console.moveCursor(QTextCursor.MoveOperation.End)

    def _select_file(self):
        file, _ = QFileDialog.getOpenFileName(
            self, "Select Assembly File", "Programs/asm", "Assembly Files (*.asm);;Text Files (*.txt);;All Files (*)"
        )
        if file:
            self.has_file = True
            self.selected_file = file
            self.file_name = Path(file).stem
            self.file_label.setText(f"✅ {self.file_name}.asm")
            self.file_label.setObjectName("fileSelected")
            # Force style refresh
            self.file_label.style().unpolish(self.file_label)
            self.file_label.style().polish(self.file_label)
            self.assemble_btn.setEnabled(True)
            self._set_status("File selected", "#27ae60")

    def _assemble(self):
        """Assemble the selected ASM file"""
        if not self.has_file:
            return
            
        self.console.clear()
        self._log("Assembling...")
        self._set_status("Assembling...", "working")
        
        out_bin = f"Programs/build/{self.file_name}.bin"
        
        self.proc_asm.readyReadStandardOutput.connect(
            lambda: self._log(bytes(self.proc_asm.readAllStandardOutput()).decode(errors="ignore").strip())
        )
        self.proc_asm.finished.connect(self._on_assemble_done)
        self.proc_asm.start("python", ["src/software/assembler.py", "assemble", self.selected_file, "-o", out_bin])

    def _on_assemble_done(self):
        """Handle assembly completion"""
        ok = self.proc_asm.exitCode() == 0
        self._set_status("Assembly Complete ✅" if ok else "Assembly Failed ❌", 
                        "success" if ok else "error")
        if ok:
            self._log("Assembly successful!")
            self.simulate_btn.setEnabled(True)
            self._populate_existing_programs()  # Refresh dropdown
        else:
            self._log("Assembly failed!")
        self._disconnect_process_signals(self.proc_asm)

    def _disconnect_process_signals(self, process):
        """Helper to safely disconnect process signals"""
        try:
            process.readyReadStandardOutput.disconnect()
            process.finished.disconnect()
        except TypeError:
            pass  # Signals already disconnected

    def _simulate(self):
        self._run_simulation(self.file_name)

    def _quick_run(self):
        """Run simulation for selected existing program"""
        program = self.existing_combo.currentText()
        if program not in ["Select program...", "No programs available", ""]:
            self._run_simulation(program)

    def _compile_testbench(self) -> bool:
        tb_dir = Path("src/testbench")
        tb_dir.mkdir(parents=True, exist_ok=True)     
        out_path = tb_dir / "tb_new.out"

        verilog_files       = glob.glob("src/verilog/*.v")
        systemverilog_files = glob.glob("src/verilog/*.sv")
        all_sources = verilog_files + systemverilog_files + ["src/testbench/computer_TB.v"]

        cmd = ["iverilog", "-g2012", "-o", str(out_path), "-I", "src/verilog"] + all_sources

        self._log("Compiling …")

        proc = QProcess(self)
        proc.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        proc.start(cmd[0], cmd[1:])

        while proc.waitForFinished(30):
            chunk = proc.readAllStandardOutput()
            if chunk:
                self._log(bytes(chunk).decode().rstrip())

        leftover = proc.readAllStandardOutput()
        if leftover:
            self._log(bytes(leftover).decode().rstrip())

        ok = proc.exitStatus() == QProcess.ExitStatus.NormalExit and proc.exitCode() == 0
        self._set_status("Compilation OK ✅" if ok else "Compilation Failed ❌",
                        "ok" if ok else "error")

        if ok:
            self.last_build = out_path.resolve()          # store for run step

        return ok


    
    def _build_simulation_args(self, program_name: str, testbench_file: Path) -> list:
        """Build simulation arguments with debug options"""
        bin_file = f"Programs/build/{program_name}.bin"
        cycle_value = self.cycle_spin.value()
        
        sim_args = [
            str(testbench_file),
            f"+ROMFILE={bin_file}",
            f"+TESTNAME={program_name} Test",
            f"+CYCLES={cycle_value}"
        ]
        
        # Add debug flags based on checkboxes
        debug_flags = [
            (self.debug_pc,              "+DEBUG_PC",      "PC"),
            (self.debug_ir,              "+DEBUG_IR",      "IR"),
            (self.debug_regs,            "+DEBUG_REGS",    "Registers"),
            (self.debug_mem,             "+DEBUG_MEM",     "Memory"),
            (self.debug_inner_workings,  "+DEBUG_INNER",   "Inner Workings"),
            (self.debug_state,           "+DEBUG_STATE",   "State"),
        ]

        if self.debug_enable.isChecked():
            sim_args.append("+DEBUG")
            enabled_flags = [flag for cb, flag, _ in debug_flags if cb.isChecked()]
            sim_args.extend(enabled_flags)
            self._log(f"Debug flags added: {enabled_flags}")

        if self.debug_verbose.isChecked():
            sim_args.append("+DEBUG_VERBOSE")
            self._log("Verbose debugging enabled")

        if self.debug_enable.isChecked():
            active = [label for cb, _, label in debug_flags if cb.isChecked()]
            if self.debug_verbose.isChecked():
                active.append("Verbose")
            self._log(f"Debug enabled: {', '.join(active)}")
            
        return sim_args

    def _run_simulation(self, program_name: str):
        """Run simulation for given program name with debug options"""
        bin_file = f"Programs/build/{program_name}.bin"
        if not os.path.exists(bin_file):
            self._log(f"Binary file not found: {bin_file}")
            self._set_status("Binary File Not Found ❌", "error")
            return
            
        self.console.clear()
        self._log("Starting enhanced simulation...")
        self._set_status("Simulating...", "working")
        
        # Compile testbench
        if not self._compile_testbench():
            return
        
        self.console.clear()
        # Build and run simulation
        testbench_file = Path("src/testbench") / "tb_new.out"
        sim_args = self._build_simulation_args(program_name, testbench_file)
        
        self.proc_sim.readyReadStandardOutput.connect(
            lambda: self._log(bytes(self.proc_sim.readAllStandardOutput()).decode(errors="ignore").strip())
        )
        self.proc_sim.finished.connect(self._on_sim_done)
        self.proc_sim.start("vvp", sim_args)

    def _on_sim_done(self):
        """Handle simulation completion"""
        ok = self.proc_sim.exitCode() == 0
        self._set_status("Simulation Complete ✅" if ok else "Simulation Failed ❌", 
                        "success" if ok else "error")
        if ok:
            self._log("Simulation completed!")
            self.wave_btn.setEnabled(True)
        else:
            self._log("Simulation failed!")
        self._disconnect_process_signals(self.proc_sim)

    def _show_waves(self):
        """Open GTKWave to show simulation waveforms"""
        if os.path.exists("waves.vcd"):
            self._log("Opening GTKWave...")
            self.proc_wave.start("gtkwave", ["waves.vcd"])
        else:
            self._log("Wave file not found!")
            self._set_status("Wave File Not Found ❌", "error")

    def closeEvent(self, e):
        for p in [self.proc_asm, self.proc_sim, self.proc_wave]:
            if p.state() != QProcess.ProcessState.NotRunning:
                p.kill()
        e.accept()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())