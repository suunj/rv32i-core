// Extracted without changing decode expressions from fpga_files/core.sv.
module instruction_decoder (
    input logic [31:0] instr_i,
    output logic is_u_instr_o,
    output logic is_s_instr_o,
    output logic is_r_instr_o,
    output logic is_j_instr_o,
    output logic is_i_instr_o,
    output logic is_b_instr_o,
    output logic [31:0] imm_o,
    output logic [6:0] opcode_o,
    output logic [2:0] funct3_o,
    output logic [6:0] funct7_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [4:0] rd_o,
    output logic rs1_valid_o,
    output logic rs2_valid_o,
    output logic rd_valid_o
);

         assign is_u_instr_o = instr_i[6:2] ==? 5'b0x101;      // U-type (LUI, AUIPC)
         
         assign is_s_instr_o = instr_i[6:2] ==? 5'b0100x;      // S-type (SW, SB, SH)
         
         assign is_r_instr_o = instr_i[6:2] ==? 5'b01011 ||    // R-type (ADD, SUB, AND, OR...)
                       instr_i[6:2] ==? 5'b011x0 ||
                       instr_i[6:2] ==? 5'b10100;
         
         assign is_j_instr_o = instr_i[6:2] ==? 5'b11011;      // J-type (JAL)
         
         assign is_i_instr_o = instr_i[6:2] ==? 5'b0000x ||    // I-type (ADDI, LW, JALR...)
                       instr_i[6:2] ==? 5'b001x0 ||
                       instr_i[6:2] ==? 5'b11001;
         
         assign is_b_instr_o = instr_i[6:2] ==? 5'b11000;      // B-type (BEQ, BNE, BLT...)

         assign imm_o[31:0] = is_i_instr_o ? {{21{instr_i[31]}}, instr_i[30:20]} :
                      is_s_instr_o ? {{21{instr_i[31]}}, instr_i[30:25], instr_i[11:7]} :
                      is_b_instr_o ? {{20{instr_i[31]}}, instr_i[7], instr_i[30:25],
                                     instr_i[11:8], 1'b0} :
                      is_u_instr_o ? {instr_i[31:12], 12'b0} :
                      is_j_instr_o ? {{12{instr_i[31]}}, instr_i[19:12], instr_i[20],
                                     instr_i[30:21], 1'b0} :
                      32'b0;

         assign opcode_o[6:0] = instr_i[6:0];
         assign funct3_o[2:0] = instr_i[14:12];
         assign funct7_o[6:0] = instr_i[31:25];
         assign rs1_o[4:0]    = instr_i[19:15];   // 소스 레지스터 1
         assign rs2_o[4:0]    = instr_i[24:20];   // 소스 레지스터 2
         assign rd_o[4:0]     = instr_i[11:7];    // 목적지 레지스터
         
         assign rs1_valid_o    = is_r_instr_o || is_i_instr_o || is_s_instr_o || is_b_instr_o;
         assign rs2_valid_o    = is_r_instr_o || is_s_instr_o || is_b_instr_o;
         assign rd_valid_o     = is_r_instr_o || is_i_instr_o || is_u_instr_o || is_j_instr_o;

endmodule
