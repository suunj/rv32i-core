//_\SV
   // Included URL: "https://raw.githubusercontent.com/BalaDhinesh/RISC-V_MYTH_Workshop/master/tlv_lib/risc-v_shell_lib.tlv"// Included URL: "https://raw.githubusercontent.com/stevehoover/warp-v_includes/2d6d36baa4d2bc62321f982f78c8fe1456641a43/risc-v_defs.tlv"
//_\SV
   module core (
      input  logic clk,
      input  logic reset,
      output logic [31:0] result_out,   // 코어 결과를 밖으로
      output logic        done,          // 계산 완료 신호
      output logic [31:0] pc_out,            // ILA용 PC
      output logic        taken_branch_out,  // ILA용 분기 점프
      output logic        valid_out          // ILA용 유효신호
   );
`include "core_gen.sv" //_\TLV
   // Inst #0: ADD,r10,r0,r0
   // Inst #1: ADD,r14,r10,r0
   // Inst #2: ADDI,r12,r10,1010
   // Inst #3: ADD,r13,r10,r0
   // Inst #4: ADD,r14,r13,r14
   // Inst #5: ADDI,r13,r13,1
   // Inst #6: BLT,r13,r12,1111111111000
   // Inst #7: ADD,r10,r14,r0
   // Inst #8: SW,r0,r10,10000
   // Inst #9: LW,r17,r0,10000
   
   //_|cpu
      //_@0
         assign CPU_reset_a0 = reset;
         assign CPU_pc_a0[31:0] = CPU_reset_a1 ? 32'b0 :
                     CPU_valid_taken_branch_a3 ? CPU_br_target_pc_a3 :
                     CPU_valid_jump_a3 && CPU_is_jal_a3  ? CPU_br_target_pc_a3 :
                     CPU_valid_jump_a3 && CPU_is_jalr_a3 ? CPU_jalr_target_pc_a3 :
                                                     CPU_pc_a1 + 32'd4;
      //_@1
         assign CPU_imem_rd_addr_a1[4-1:0] = CPU_pc_a1[4+1:2];
         assign CPU_imem_rd_en_a1 = !CPU_reset_a1;

         assign CPU_instr_a1[31:0] = CPU_imem_rd_data_a1[31:0];
         assign CPU_is_u_instr_a1 = CPU_instr_a1[6:2] ==? 5'b0x101;      // U-type (LUI, AUIPC)
         
         assign CPU_is_s_instr_a1 = CPU_instr_a1[6:2] ==? 5'b0100x;      // S-type (SW, SB, SH)
         
         assign CPU_is_r_instr_a1 = CPU_instr_a1[6:2] ==? 5'b01011 ||    // R-type (ADD, SUB, AND, OR...)
                       CPU_instr_a1[6:2] ==? 5'b011x0 ||
                       CPU_instr_a1[6:2] ==? 5'b10100;
         
         assign CPU_is_j_instr_a1 = CPU_instr_a1[6:2] ==? 5'b11011;      // J-type (JAL)
         
         assign CPU_is_i_instr_a1 = CPU_instr_a1[6:2] ==? 5'b0000x ||    // I-type (ADDI, LW, JALR...)
                       CPU_instr_a1[6:2] ==? 5'b001x0 ||
                       CPU_instr_a1[6:2] ==? 5'b11001;
         
         assign CPU_is_b_instr_a1 = CPU_instr_a1[6:2] ==? 5'b11000;      // B-type (BEQ, BNE, BLT...)

         assign CPU_imm_a1[31:0] = CPU_is_i_instr_a1 ? {{21{CPU_instr_a1[31]}}, CPU_instr_a1[30:20]} :
                      CPU_is_s_instr_a1 ? {{21{CPU_instr_a1[31]}}, CPU_instr_a1[30:25], CPU_instr_a1[11:7]} :
                      CPU_is_b_instr_a1 ? {{20{CPU_instr_a1[31]}}, CPU_instr_a1[7], CPU_instr_a1[30:25],
                                     CPU_instr_a1[11:8], 1'b0} :
                      CPU_is_u_instr_a1 ? {CPU_instr_a1[31:12], 12'b0} :
                      CPU_is_j_instr_a1 ? {{12{CPU_instr_a1[31]}}, CPU_instr_a1[19:12], CPU_instr_a1[20],
                                     CPU_instr_a1[30:21], 1'b0} :
                      32'b0;

         assign CPU_opcode_a1[6:0] = CPU_instr_a1[6:0];
         assign CPU_funct3_a1[2:0] = CPU_instr_a1[14:12];
         assign CPU_funct7_a1[6:0] = CPU_instr_a1[31:25];
         assign CPU_rs1_a1[4:0]    = CPU_instr_a1[19:15];   // 소스 레지스터 1
         assign CPU_rs2_a1[4:0]    = CPU_instr_a1[24:20];   // 소스 레지스터 2
         assign CPU_rd_a1[4:0]     = CPU_instr_a1[11:7];    // 목적지 레지스터
         
         assign CPU_rs1_valid_a1    = CPU_is_r_instr_a1 || CPU_is_i_instr_a1 || CPU_is_s_instr_a1 || CPU_is_b_instr_a1;
         assign CPU_rs2_valid_a1    = CPU_is_r_instr_a1 || CPU_is_s_instr_a1 || CPU_is_b_instr_a1;
         assign CPU_rd_valid_a1     = CPU_is_r_instr_a1 || CPU_is_i_instr_a1 || CPU_is_u_instr_a1 || CPU_is_j_instr_a1;
      //_@2
         // funct7[5] + funct3 + opcode = 1+3+7 = 11비트 디코드 벡터
         assign CPU_dec_bits_a2[10:0] = {CPU_funct7_a2[5], CPU_funct3_a2, CPU_opcode_a2};
         
         assign CPU_is_beq_a2  = CPU_dec_bits_a2 ==? 11'bx_000_1100011;  // Branch if Equal
         assign CPU_is_bne_a2  = CPU_dec_bits_a2 ==? 11'bx_001_1100011;  // Branch if Not Equal
         assign CPU_is_blt_a2  = CPU_dec_bits_a2 ==? 11'bx_100_1100011;  // Branch if Less Than (signed)
         assign CPU_is_bge_a2  = CPU_dec_bits_a2 ==? 11'bx_101_1100011;  // Branch if Greater/Equal (signed)
         assign CPU_is_bltu_a2 = CPU_dec_bits_a2 ==? 11'bx_110_1100011;  // Branch if Less Than (unsigned)
         assign CPU_is_bgeu_a2 = CPU_dec_bits_a2 ==? 11'bx_111_1100011;  // Branch if Greater/Equal (unsigned)
         assign CPU_is_addi_a2 = CPU_dec_bits_a2 ==? 11'bx_000_0010011;  // Add Immediate
         assign CPU_is_add_a2  = CPU_dec_bits_a2 ==? 11'b0_000_0110011;  // Add Register
         assign CPU_is_load_a2 = CPU_opcode_a2 ==? 7'b0000011;
         assign CPU_is_jal_a2  = CPU_opcode_a2 ==? 7'b1101111;
         assign CPU_is_jalr_a2 = CPU_dec_bits_a2 ==? 11'bx_000_1100111;
         assign CPU_is_jump_a2 = CPU_is_jal_a2 || CPU_is_jalr_a2;

         // Port 1: rs1 읽기
         assign CPU_rf_rd_en1_a2 = CPU_rs1_valid_a2;            // rs1이 유효할 때만 읽기 활성화
         assign CPU_rf_rd_index1_a2[4:0] = CPU_rs1_a2;          // 읽을 레지스터 번호
         
         // Port 2: rs2 읽기
         assign CPU_rf_rd_en2_a2 = CPU_rs2_valid_a2;
         assign CPU_rf_rd_index2_a2[4:0] = CPU_rs2_a2;
         
         // 읽은 값을 소스 값으로 캡처 (ALU 입력이 됨)
         assign CPU_src1_value_a2[31:0] =
              (CPU_rf_wr_en_a3 && (CPU_rf_wr_index_a3 == CPU_rf_rd_index1_a2)) ? CPU_result_a3 :
              CPU_rf_rd_data1_a2;
         assign CPU_src2_value_a2[31:0] =
              (CPU_rf_wr_en_a3 && (CPU_rf_wr_index_a3 == CPU_rf_rd_index2_a2)) ? CPU_result_a3 :
              CPU_rf_rd_data2_a2;
         
         assign CPU_br_target_pc_a2[31:0] = CPU_pc_a2 + CPU_imm_a2;
         assign CPU_inc_pc_a2[31:0] = CPU_pc_a2 + 32'd4;
         assign CPU_jalr_target_pc_a2[31:0] = CPU_src1_value_a2 + CPU_imm_a2;
      //_@3
         assign CPU_result_a3[31:0] = CPU_is_addi_a3 ? CPU_src1_value_a3 + CPU_imm_a3 :        // ADDI: rs1 + imm
                         CPU_is_add_a3  ? CPU_src1_value_a3 + CPU_src2_value_a3 : // ADD:  rs1 + rs2
                         (CPU_is_load_a3 || CPU_is_s_instr_a3) ? CPU_src1_value_a3 + CPU_imm_a3 :
                         (CPU_is_jal_a3 || CPU_is_jalr_a3) ? CPU_inc_pc_a3 :
                         32'bx;
         assign CPU_taken_branch_a3 = CPU_is_beq_a3  ? (CPU_src1_value_a3 == CPU_src2_value_a3) :
                         CPU_is_bne_a3  ? (CPU_src1_value_a3 != CPU_src2_value_a3) :
                         CPU_is_blt_a3  ? ((CPU_src1_value_a3 < CPU_src2_value_a3) ^ (CPU_src1_value_a3[31] != CPU_src2_value_a3[31])) :
                         CPU_is_bge_a3  ? ((CPU_src1_value_a3 >= CPU_src2_value_a3) ^ (CPU_src1_value_a3[31] != CPU_src2_value_a3[31])) :
                         CPU_is_bltu_a3 ? (CPU_src1_value_a3 < CPU_src2_value_a3) :
                         CPU_is_bgeu_a3 ? (CPU_src1_value_a3 >= CPU_src2_value_a3) :
                                    1'b0;
         assign CPU_valid_a3 = !(CPU_valid_taken_branch_a4 || CPU_valid_taken_branch_a5 ||
                    CPU_valid_jump_a4 || CPU_valid_jump_a5);
         assign CPU_valid_taken_branch_a3 = CPU_valid_a3 && CPU_taken_branch_a3;
         assign CPU_valid_jump_a3 = CPU_valid_a3 && CPU_is_jump_a3;
         assign CPU_rf_wr_en_a3 = CPU_valid_a3 && CPU_rd_valid_a3 && CPU_rd_a3 != 5'b0;
         assign CPU_rf_wr_index_a3[4:0] = CPU_rd_a3;                 // 레지스터 번호
         assign CPU_rf_wr_data_a3[31:0] = CPU_is_load_a3 ? CPU_ld_data_a5 : CPU_result_a3;
      //_@4
         assign CPU_dmem_rd_en_a4 = CPU_is_load_a4;
         assign CPU_dmem_wr_en_a4 = CPU_valid_a4 && CPU_is_s_instr_a4;
         assign CPU_dmem_addr_a4[3:0] = CPU_result_a4[5:2];
         assign CPU_dmem_wr_data_a4[31:0] = CPU_src2_value_a4;
      //_@5
         assign CPU_ld_data_a5[31:0] = CPU_dmem_rd_data_a5;

//_\TLV
   // x14에 저장된 합계를 출력으로 노출
   assign result_out = CPU_Xreg_value_a5[14];
   
   // 계산 완료 감지: 합이 45가 되면 done=1
   assign done = (CPU_Xreg_value_a5[14] == 32'd45);
   assign pc_out           = CPU_pc_a1;
   assign taken_branch_out = CPU_valid_taken_branch_a3;
   assign valid_out        = CPU_valid_a3;

   //_|cpu
         // Instruction Memory containing program defined by m4_asm(...) instantiations.
         //_@1
            
            /*SV_plus*/
               // The program in an instruction memory.
               logic [31:0] instrs [0:10-1];
               assign instrs = '{
                  {7'b0000000, 5'd0, 5'd0, 3'b000, 5'd10, 7'b0110011}, {7'b0000000, 5'd0, 5'd10, 3'b000, 5'd14, 7'b0110011}, {12'b1010, 5'd10, 3'b000, 5'd12, 7'b0010011}, {7'b0000000, 5'd0, 5'd10, 3'b000, 5'd13, 7'b0110011}, {7'b0000000, 5'd14, 5'd13, 3'b000, 5'd14, 7'b0110011}, {12'b1, 5'd13, 3'b000, 5'd13, 7'b0010011}, {1'b1, 6'b111111, 5'd12, 5'd13, 3'b100, 4'b1100, 1'b1, 7'b1100011}, {7'b0000000, 5'd0, 5'd14, 3'b000, 5'd10, 7'b0110011}, {7'b0000000, 5'd10, 5'd0, 3'b010, 5'b10000, 7'b0100011}, {12'b10000, 5'd0, 3'b010, 5'd17, 7'b0000011}
               };
            for (imem = 0; imem <= 9; imem++) begin : L1_CPU_Imem //_/imem
               assign CPU_Imem_instr_a1[imem][31:0] = instrs[imem]; end
            //_?$imem_rd_en
               assign CPU_imem_rd_data_a1[31:0] = CPU_Imem_instr_a1[CPU_imem_rd_addr_a1];
            
            
            
               
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
              
          
      //_\end_source    // Args: (read stage)
         // Reg File
         //_@3
            for (xreg = 0; xreg <= 31; xreg++) begin : L1_CPU_Xreg logic L1_wr_a3; //_/xreg
               assign L1_wr_a3 = CPU_rf_wr_en_a3 && (CPU_rf_wr_index_a3 != 5'b0) && (CPU_rf_wr_index_a3 == xreg);
               assign CPU_Xreg_value_a3[xreg][31:0] = CPU_reset_a3 ?   xreg           :
                              L1_wr_a3        ?   CPU_rf_wr_data_a3 :
                                             CPU_Xreg_value_a4[xreg][31:0]; end
         //_@2
            //_?$rf_rd_en1
               assign CPU_rf_rd_data1_a2[31:0] = CPU_Xreg_value_a4[CPU_rf_rd_index1_a2];
            //_?$rf_rd_en2
               assign CPU_rf_rd_data2_a2[31:0] = CPU_Xreg_value_a4[CPU_rf_rd_index2_a2];
            `BOGUS_USE(CPU_rf_rd_data1_a2 CPU_rf_rd_data2_a2) 
      //_\end_source  // Args: (read stage, write stage)
         // Data Memory
         //_@4
            for (dmem = 0; dmem <= 15; dmem++) begin : L1_CPU_Dmem logic L1_wr_a4; //_/dmem
               assign L1_wr_a4 = CPU_dmem_wr_en_a4 && (CPU_dmem_addr_a4 == dmem);
               assign CPU_Dmem_value_a4[dmem][31:0] = CPU_reset_a4 ?   dmem :
                              L1_wr_a4        ?   CPU_dmem_wr_data_a4 :
                                             CPU_Dmem_value_a5[dmem][31:0]; end
                                        
            //_?$dmem_rd_en
               assign CPU_dmem_rd_data_a4[31:0] = CPU_Dmem_value_a5[CPU_dmem_addr_a4];
            `BOGUS_USE(CPU_dmem_rd_data_a4)
      //_\end_source

//_\SV
   endmodule


// Undefine macros defined by SandPiper (in "core_gen.sv").
`undef BOGUS_USE
