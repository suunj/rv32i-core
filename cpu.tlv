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
   
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)

   |cpu
      @0
         $reset = *reset;
         $pc[31:0] = >>1$reset ? 32'b0 : >>1$pc + 32'd4;
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
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
   
\SV
   endmodule
