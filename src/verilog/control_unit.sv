module control_unit (
    input logic clk,
    input logic reset,
    input logic debug_inner,
    input logic [7:0] IR,
    input logic [7:0] from_memory,
    input logic [3:0] CCR_Result,
    output logic IR_Load,
    output logic MAR_Load,
    output logic PC_Load,
    output logic PC_Inc,
    output logic [3:0] reg_read_addr_A,
    output logic [3:0] reg_read_addr_B,
    output logic [3:0] reg_write_addr,
    output logic reg_write_enable,
    output logic [3:0] ALU_Sel,
    output logic CCR_Load,
    output logic [2:0] Bus2_Sel,
    output logic [1:0] Bus1_Sel,
    output logic ALU_B_Sel,
    output logic write,
    output logic [7:0] immediate_out,
    output logic [7:0] address_out,
    output logic addr_sel
);

    typedef enum logic [2:0] {
        FETCH, DECODE, EXECUTE, LOADSTORE, DATA, BRANCH
    } state_t;

    state_t state, next;
    logic [3:0] cycle_count;

    logic [7:0] reg_operand_1, reg_operand_2;
    logic LoadStoreOP, DataOP, BranchOP;

    // Capture operands at the right time
    always_ff @(posedge clk) begin
        if (state==FETCH && cycle_count==3) reg_operand_1 <= from_memory; // byte‑1 (register or first operand)
        if (state==FETCH && cycle_count==5) reg_operand_2 <= from_memory; // byte‑2 (immediate or second operand)
    end

    assign immediate_out = (IR[7:4]==4'h2) ? reg_operand_1 : reg_operand_2;
    assign address_out   = reg_operand_2;

    // State register with cycle counter
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= FETCH;
            cycle_count <= 4'd0;
        end else if (state != next) begin
				 state <= next;
				 cycle_count <= 4'd0;
			end else
				 cycle_count <= cycle_count + 4'd1;
	 end

    // Next state logic
    always_comb begin
        next = state;

        unique case (state)
            FETCH: if (cycle_count==4'd5)
                        next = DECODE;

            DECODE: next = EXECUTE;

            EXECUTE: case(IR[7:4])
                          4'h8 : next = LOADSTORE;
                          4'h9 : next = DATA;
                          4'hA : next = LOADSTORE;
                          4'h2 : next = BRANCH;
                          default : next = FETCH;
                       endcase

            LOADSTORE: if ( (IR==8'h80) || cycle_count==3'd2)
							next = FETCH;

            DATA:      if (cycle_count==3'd0)
                            next = FETCH;

            BRANCH:    if (cycle_count==3'd1)
                            next = FETCH;
            default:   next = FETCH;
        endcase
    end

    typedef logic [24:0] ctrl_t;  // new type
	 ctrl_t ctrl;

    function automatic ctrl_t CTL (
        input logic         a_sel, b_sel, wr, ccr_load, reg_we,
        input logic [3:0]   alu, reg_wa,
        input logic [1:0]   b1,
        input logic [2:0]   b2,
        input logic         pc_inc, pc_load, mar_load, ir_load
    );
        return {a_sel, b_sel, wr, ccr_load, reg_we,
                alu, reg_wa, b1, b2, pc_inc, pc_load,
                mar_load, ir_load};
    endfunction

    localparam ctrl_t
        C_NOP  = CTL(1'b0,1'b0,1'b0,1'b0,1'b0, 4'd0,4'd0, 2'd0,3'd0, 1'b0,1'b0,1'b0,1'b0),
        CF0    = CTL(1'b0,1'b0,1'b0,1'b0,1'b0, 4'd0,4'd0, 2'd0,3'b001, 1'b0,1'b0,1'b1,1'b0),
        CF1    = CTL(1'b0,1'b0,1'b0,1'b0,1'b0, 4'd0,4'd0, 2'd0,3'b010, 1'b1,1'b0,1'b0,1'b1),
        CF2    = CF0,
        CF3    = CTL(1'b0,1'b0,1'b0,1'b0,1'b0, 4'd0,4'd0, 2'd0,3'b010, 1'b1,1'b0,1'b0,1'b0),
        CF4    = CF0,
        CF5    = CF3;

    function automatic ctrl_t INC_and_DEC (input logic inc, input logic [3:0] r);
        return CTL(1'b1, 1'b0,          // addr_sel=1, ALU_B_Sel=0
                   1'b1, 1'b1, 1'b1,        // write=0, CCR_Load=1, reg_we=1
                   inc ? 4'd7 : 4'd8,  // ALU opcode
                   r,
                   2'd1, 3'd0,     // Bus1=reg, Bus2=ALU
                   1'b0,1'b0,1'b0,1'b0);
    endfunction

    function automatic ctrl_t decode(
        input state_t       state,
        input logic [2:0]   cycle_count,
        input logic [7:0]   ir
    );
        ctrl_t c = C_NOP;
        
         unique case (state)
            FETCH: case (cycle_count)
                    4'd0: c = CF0;
                    4'd1: c = CF1;
                    4'd2: c = CF2;
                    4'd3: c = CF3;
                    4'd4: c = CF4;
                    4'd5: c = CF5;
                endcase

            LOADSTORE: begin
                if ((ir==8'h80) && (cycle_count==3'b0)) begin              // LD rX, #imm
                    c = CTL(1'b0,1'b0,1'b0,1'b0,1'b1, 4'd0, reg_operand_1[3:0], 2'd0,3'b011,1'b0,1'b0,1'b0,1'b0);
                end
                else if ((ir[7:4]==4'hA) && (cycle_count==3'b0)) begin     // prepare INC/DEC
                    c = CTL(1'b0,1'b0,1'b0,1'b0,1'b0, 4'd0,4'd0, 2'd0,3'b001, 1'b0,1'b0,1'b1,1'b0);
                end
                else if ((ir[7:4]==4'hA) && (cycle_count==3'd2)) begin                 // execute INC/DEC
                    c = INC_and_DEC(ir==8'hA0, reg_operand_1[3:0]);
                end
            end

            DATA: if (cycle_count==4'd0) begin
                logic [3:0] alu;
                case (ir[2:0])
                    3'b000: alu = 4'd0;   // ADD
                    3'b001: alu = 4'd1;   // SUB
                    3'b010: alu = 4'd4;   // AND
                    3'b011: alu = 4'd5;   // OR
                    3'b100: alu = 4'd6;   // XOR
                    default: alu = 4'd0;
                endcase
                c = CTL(1'b0,1'b0,1'b0,1'b1,1'b1, alu, reg_operand_1[3:0], 2'd1, 3'd0, 1'b0,1'b0,1'b0,1'b0);
            end

            BRANCH: begin
                if (cycle_count==4'd0)
                    // Set up ALU to calculate PC + branch offset  
                    c = CTL(1'b1,1'b1,1'b0,1'b0,1'b0, 4'd0,4'd0, 2'd0,3'd0, 1'b0,1'b0,1'b0,1'b0);
                if (cycle_count==4'd1) begin
                    // Load ALU result (PC + offset) into PC if branch condition is met
                    logic pc_load;
                    logic pc_ld;
                    case (ir[2:0])
                        3'b000: pc_load = 1'b1;              // BRA
                        3'b011: pc_load = ~CCR_Result[2];    // BNE
                        3'b100: pc_load =  CCR_Result[2];    // BEQ
                        default: pc_load = 1'b0;
                    endcase
                    c = CTL(1'b0,1'b0,1'b0,1'b0,1'b0, 4'd0,4'd0, 2'd0,3'd0, 1'b0, pc_load, 1'b0,1'b0);
                end
            end
        endcase
        return c;
    endfunction

    always_comb ctrl = decode(state, cycle_count, IR);

    // Unpack once
    assign { addr_sel, ALU_B_Sel, write, CCR_Load, reg_write_enable,
             ALU_Sel,
             reg_write_addr,
             Bus1_Sel, Bus2_Sel,
             PC_Inc, PC_Load, MAR_Load, IR_Load } = ctrl;

    // Read-address buses (only DATA & INC/DEC need them)
    assign reg_read_addr_A = (state==DATA || (state==LOADSTORE && IR[7:4]==4'hA)) ? reg_operand_1[3:0] : 4'd0;
    assign reg_read_addr_B = (state==DATA) ? reg_operand_2[3:0] : 4'd0;

    always_ff @(posedge clk)
        if (debug_inner && write)
            $display("[%0t] CU-write  R%0d <= %02h", $time, reg_write_addr, IR);

endmodule
