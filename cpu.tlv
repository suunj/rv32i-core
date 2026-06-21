\m4_TLV_version 1d: tl-x.org
\SV
   m4_include_lib(['https://raw.githubusercontent.com/BalaDhinesh/RISC-V_MYTH_Workshop/master/tlv_lib/risc-v_shell_lib.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV

   // ===== INIT =====
   m4_asm(ADD, r10, r0, r0)             // r10 = 0 (결과 저장용)
   m4_asm(ADD, r14, r10, r0)            // r14 = 0 (누적 합계)
   m4_asm(ADDI, r12, r10, 1010)         // r12 = 10 (루프 한계값)
   m4_asm(ADD, r13, r10, r0)            // r13 = 0 (카운터)
   // ===== LOOP =====
   m4_asm(ADD, r14, r13, r14)           // r14 += r13
   m4_asm(ADDI, r13, r13, 1)            // r13++
   m4_asm(BLT, r13, r12, 1111111111000) // r13 < r12이면 루프로 점프 (오프셋 -8)
   // ===== RESULT =====
   m4_asm(ADD, r10, r14, r0)            // r10 = r14 (최종 합 45)
   m4_asm(SW, r0, r10, 10000)
   m4_asm(LW, r17, r0, 10000)
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)

   |cpu
      @0
         $reset = *reset;
         $pc[31:0] = >>1$reset ? 32'b0 :
                     >>3$valid_taken_branch ? >>3$br_target_pc :
                     >>3$valid_jump && >>3$is_jal  ? >>3$br_target_pc :
                     >>3$valid_jump && >>3$is_jalr ? >>3$jalr_target_pc :
                                                     >>1$pc + 32'd4;
      @1
         $imem_rd_addr[M4_IMEM_INDEX_CNT-1:0] = $pc[M4_IMEM_INDEX_CNT+1:2];
         $imem_rd_en = !$reset;

         $instr[31:0] = $imem_rd_data[31:0];
         $is_u_instr = $instr[6:2] ==? 5'b0x101;      // U-type (LUI, AUIPC)
         
         $is_s_instr = $instr[6:2] ==? 5'b0100x;      // S-type (SW, SB, SH)
         
         $is_r_instr = $instr[6:2] ==? 5'b01011 ||    // R-type (ADD, SUB, AND, OR...)
                       $instr[6:2] ==? 5'b011x0 ||
                       $instr[6:2] ==? 5'b10100;
         
         $is_j_instr = $instr[6:2] ==? 5'b11011;      // J-type (JAL)
         
         $is_i_instr = $instr[6:2] ==? 5'b0000x ||    // I-type (ADDI, LW, JALR...)
                       $instr[6:2] ==? 5'b001x0 ||
                       $instr[6:2] ==? 5'b11001;
         
         $is_b_instr = $instr[6:2] ==? 5'b11000;      // B-type (BEQ, BNE, BLT...)

         $imm[31:0] = $is_i_instr ? {{21{$instr[31]}}, $instr[30:20]} :
                      $is_s_instr ? {{21{$instr[31]}}, $instr[30:25], $instr[11:7]} :
                      $is_b_instr ? {{20{$instr[31]}}, $instr[7], $instr[30:25],
                                     $instr[11:8], 1'b0} :
                      $is_u_instr ? {$instr[31:12], 12'b0} :
                      $is_j_instr ? {{12{$instr[31]}}, $instr[19:12], $instr[20],
                                     $instr[30:21], 1'b0} :
                      32'b0;

         $opcode[6:0] = $instr[6:0];
         $funct3[2:0] = $instr[14:12];
         $funct7[6:0] = $instr[31:25];
         $rs1[4:0]    = $instr[19:15];   // 소스 레지스터 1
         $rs2[4:0]    = $instr[24:20];   // 소스 레지스터 2
         $rd[4:0]     = $instr[11:7];    // 목적지 레지스터
         
         $rs1_valid    = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
         $rs2_valid    = $is_r_instr || $is_s_instr || $is_b_instr;
         $rd_valid     = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
      @2
         // funct7[5] + funct3 + opcode = 1+3+7 = 11비트 디코드 벡터
         $dec_bits[10:0] = {$funct7[5], $funct3, $opcode};
         
         $is_beq  = $dec_bits ==? 11'bx_000_1100011;  // Branch if Equal
         $is_bne  = $dec_bits ==? 11'bx_001_1100011;  // Branch if Not Equal
         $is_blt  = $dec_bits ==? 11'bx_100_1100011;  // Branch if Less Than (signed)
         $is_bge  = $dec_bits ==? 11'bx_101_1100011;  // Branch if Greater/Equal (signed)
         $is_bltu = $dec_bits ==? 11'bx_110_1100011;  // Branch if Less Than (unsigned)
         $is_bgeu = $dec_bits ==? 11'bx_111_1100011;  // Branch if Greater/Equal (unsigned)
         $is_addi = $dec_bits ==? 11'bx_000_0010011;  // Add Immediate
         $is_add  = $dec_bits ==? 11'b0_000_0110011;  // Add Register
         $is_load = $opcode ==? 7'b0000011;
         $is_jal  = $opcode ==? 7'b1101111;
         $is_jalr = $dec_bits ==? 11'bx_000_1100111;
         $is_jump = $is_jal || $is_jalr;

         // Port 1: rs1 읽기
         $rf_rd_en1 = $rs1_valid;            // rs1이 유효할 때만 읽기 활성화
         $rf_rd_index1[4:0] = $rs1;          // 읽을 레지스터 번호
         
         // Port 2: rs2 읽기
         $rf_rd_en2 = $rs2_valid;
         $rf_rd_index2[4:0] = $rs2;
         
         // 읽은 값을 소스 값으로 캡처 (ALU 입력이 됨)
         $src1_value[31:0] = $rf_rd_data1;   // rs1 값
         $src2_value[31:0] = $rf_rd_data2;   // rs2 값
         
         $br_target_pc[31:0] = $pc + $imm;
         $inc_pc[31:0] = $pc + 32'd4;
         $jalr_target_pc[31:0] = $src1_value + $imm;
      @3
         $result[31:0] = $is_addi ? $src1_value + $imm :        // ADDI: rs1 + imm
                         $is_add  ? $src1_value + $src2_value : // ADD:  rs1 + rs2
                         ($is_load || $is_s_instr) ? $src1_value + $imm :
                         ($is_jal || $is_jalr) ? $inc_pc :
                         32'bx;
         $taken_branch = $is_beq  ? ($src1_value == $src2_value) :
                         $is_bne  ? ($src1_value != $src2_value) :
                         $is_blt  ? (($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
                         $is_bge  ? (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
                         $is_bltu ? ($src1_value < $src2_value) :
                         $is_bgeu ? ($src1_value >= $src2_value) :
                                    1'b0;
         $valid_taken_branch = $taken_branch;
         $valid_jump = $is_jump;
         $rf_wr_en = $rd_valid && $rd != 5'b0;   // rd 유효하고 x0이 아닐 때만 쓰기
         $rf_wr_index[4:0] = $rd;                 // 레지스터 번호
         $rf_wr_data[31:0] = $is_load ? >>2$ld_data : $result;
      @4
         $dmem_rd_en = $is_load;
         $dmem_wr_en = $is_s_instr;
         $dmem_addr[3:0] = $result[5:2];
         $dmem_wr_data[31:0] = $src2_value;
      @5
         $ld_data[31:0] = $dmem_rd_data;

   *passed = |cpu/xreg[17]>>5$value == (1+2+3+4+5+6+7+8+9);
   *failed = 1'b0;

   |cpu
      m4+imem(@1)    // Args: (read stage)
      m4+rf(@2, @3)  // Args: (read stage, write stage)
      m4+dmem(@4)

    m4+cpu_viz(@4)
\SV
   endmodule
