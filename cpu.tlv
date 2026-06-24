\m4_TLV_version 1d: tl-x.org
\SV
   m4_include_lib(['https://raw.githubusercontent.com/BalaDhinesh/RISC-V_MYTH_Workshop/master/tlv_lib/risc-v_shell_lib.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   m4_asm(ADDI, r1, r0, 101)
   m4_asm(ADDI, r2, r0, 11)
   m4_asm(SUB,  r3, r1, r2)
   m4_asm(AND,  r4, r1, r2)
   m4_asm(OR,   r5, r1, r2)
   m4_asm(XOR,  r6, r1, r2)
   m4_asm(SLT,  r7, r2, r1)
   m4_asm(SLL,  r8, r1, r2)
   m4_asm(SRL,  r9, r1, r2)
   m4_asm(ANDI, r21, r1, 110)
   m4_asm(ORI,  r22, r1, 1000)
   m4_asm(XORI, r23, r1, 11)
   m4_asm(SLTI, r24, r1, 1010)
   m4_asm(ADD,  r20, r3, r4)
   m4_asm(ADD,  r20, r20, r5)
   m4_asm(ADD,  r20, r20, r6)
   m4_asm(ADD,  r20, r20, r7)
   m4_asm(ADD,  r20, r20, r8)
   m4_asm(ADD,  r20, r20, r9)
   m4_asm(ADD,  r20, r20, r21)
   m4_asm(ADD,  r20, r20, r22)
   m4_asm(ADD,  r20, r20, r23)
   m4_asm(ADD,  r20, r20, r24)
   m4_asm(SW, r0, r20, 10000)
   m4_asm(LUI,   r25, 00000000000000000001)
   m4_asm(ADD,   r20, r20, r25)
   m4_asm(AUIPC, r26, 00000000000000000000)
   m4_asm(SUB,   r26, r26, r26)
   m4_asm(ADD,   r20, r20, r26)
   m4_asm(SW, r0, r20, 10000)
   m4_asm(LW, r17, r0, 10000)
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
         $is_u_instr = $instr[6:2] ==? 5'b0x101;
         
         $is_s_instr = $instr[6:2] ==? 5'b0100x;
         
         $is_r_instr = $instr[6:2] ==? 5'b01011 ||
                       $instr[6:2] ==? 5'b011x0 ||
                       $instr[6:2] ==? 5'b10100;
         
         $is_j_instr = $instr[6:2] ==? 5'b11011;
         
         $is_i_instr = $instr[6:2] ==? 5'b0000x ||
                       $instr[6:2] ==? 5'b001x0 ||
                       $instr[6:2] ==? 5'b11001;
         
         $is_b_instr = $instr[6:2] ==? 5'b11000;

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
         $rs1[4:0]    = $instr[19:15];
         $rs2[4:0]    = $instr[24:20];
         $rd[4:0]     = $instr[11:7];
         
         $rs1_valid    = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
         $rs2_valid    = $is_r_instr || $is_s_instr || $is_b_instr;
         $rd_valid     = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
      @2
         $dec_bits[10:0] = {$funct7[5], $funct3, $opcode};
         
         $is_beq  = $dec_bits ==? 11'bx_000_1100011;
         $is_bne  = $dec_bits ==? 11'bx_001_1100011;
         $is_blt  = $dec_bits ==? 11'bx_100_1100011;
         $is_bge  = $dec_bits ==? 11'bx_101_1100011;
         $is_bltu = $dec_bits ==? 11'bx_110_1100011;
         $is_bgeu = $dec_bits ==? 11'bx_111_1100011;
         $is_addi = $dec_bits ==? 11'bx_000_0010011;
         $is_add  = $dec_bits ==? 11'b0_000_0110011;
         $is_load = $opcode ==? 7'b0000011;
         $is_jal  = $opcode ==? 7'b1101111;
         $is_jalr = $dec_bits ==? 11'bx_000_1100111;
         $is_jump = $is_jal || $is_jalr;
         
         $is_sub  = $dec_bits ==? 11'b1_000_0110011;
         $is_sll  = $dec_bits ==? 11'b0_001_0110011;
         $is_slt  = $dec_bits ==? 11'b0_010_0110011;
         $is_sltu = $dec_bits ==? 11'b0_011_0110011;
         $is_xor  = $dec_bits ==? 11'b0_100_0110011;
         $is_srl  = $dec_bits ==? 11'b0_101_0110011;
         $is_sra  = $dec_bits ==? 11'b1_101_0110011;
         $is_or   = $dec_bits ==? 11'b0_110_0110011;
         $is_and  = $dec_bits ==? 11'b0_111_0110011;

         $is_slli  = $dec_bits ==? 11'b0_001_0010011;
         $is_slti  = $dec_bits ==? 11'bx_010_0010011;
         $is_sltiu = $dec_bits ==? 11'bx_011_0010011;
         $is_xori  = $dec_bits ==? 11'bx_100_0010011;
         $is_srli  = $dec_bits ==? 11'b0_101_0010011;
         $is_srai  = $dec_bits ==? 11'b1_101_0010011;
         $is_ori   = $dec_bits ==? 11'bx_110_0010011;
         $is_andi  = $dec_bits ==? 11'bx_111_0010011;
         $is_lui   = $opcode ==? 7'b0110111;
         $is_auipc = $opcode ==? 7'b0010111;

         $rf_rd_en1 = $rs1_valid;
         $rf_rd_index1[4:0] = $rs1;
         
         $rf_rd_en2 = $rs2_valid;
         $rf_rd_index2[4:0] = $rs2;
         
         $src1_value[31:0] =
              (>>1$rf_wr_en && (>>1$rf_wr_index == $rf_rd_index1)) ? >>1$result :
              $rf_rd_data1;
         $src2_value[31:0] =
              (>>1$rf_wr_en && (>>1$rf_wr_index == $rf_rd_index2)) ? >>1$result :
              $rf_rd_data2;
         
         $br_target_pc[31:0] = $pc + $imm;
         $inc_pc[31:0] = $pc + 32'd4;
         $jalr_target_pc[31:0] = $src1_value + $imm;
      @3
         $sltu_rslt[31:0]  = {31'b0, $src1_value < $src2_value};
         $slt_rslt[31:0]   = {31'b0, (($src1_value < $src2_value) ^
                                      ($src1_value[31] != $src2_value[31]))};
         $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
         $slti_rslt[31:0]  = {31'b0, (($src1_value < $imm) ^
                                      ($src1_value[31] != $imm[31]))};
         $result[31:0] =
              $is_addi  ? $src1_value + $imm :
              $is_andi  ? $src1_value & $imm :
              $is_ori   ? $src1_value | $imm :
              $is_xori  ? $src1_value ^ $imm :
              $is_slti  ? $slti_rslt :
              $is_sltiu ? $sltiu_rslt :
              $is_slli  ? $src1_value << $imm[4:0] :
              $is_srli  ? $src1_value >> $imm[4:0] :
              $is_srai  ? ({{32{$src1_value[31]}}, $src1_value} >> $imm[4:0]) :
              $is_add   ? $src1_value + $src2_value :
              $is_sub   ? $src1_value - $src2_value :
              $is_and   ? $src1_value & $src2_value :
              $is_or    ? $src1_value | $src2_value :
              $is_xor   ? $src1_value ^ $src2_value :
              $is_slt   ? $slt_rslt :
              $is_sltu  ? $sltu_rslt :
              $is_sll   ? $src1_value << $src2_value[4:0] :
              $is_srl   ? $src1_value >> $src2_value[4:0] :
              $is_sra   ? ({{32{$src1_value[31]}}, $src1_value} >> $src2_value[4:0]) :
              $is_lui   ? {$imm[31:12], 12'b0} :
              $is_auipc ? $pc + $imm :
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
         $valid = !(>>1$valid_taken_branch || >>2$valid_taken_branch ||
                    >>1$valid_jump || >>2$valid_jump);
         $valid_taken_branch = $valid && $taken_branch;
         $valid_jump = $valid && $is_jump;
         $rf_wr_en = $valid && $rd_valid && $rd != 5'b0;
         $rf_wr_index[4:0] = $rd;
         $rf_wr_data[31:0] = $is_load ? >>2$ld_data : $result;
      @4
         $dmem_rd_en = $is_load;
         $dmem_wr_en = $valid && $is_s_instr;
         $dmem_addr[3:0] = $result[5:2];
         $dmem_wr_data[31:0] = $src2_value;
      @5
         $ld_data[31:0] = $dmem_rd_data;

   *passed = |cpu/xreg[17]>>5$value == 4177;
   *failed = 1'b0;

   |cpu
      m4+imem(@1)    // Args: (read stage)
      m4+rf(@2, @3)  // Args: (read stage, write stage)
      m4+dmem(@4)

\SV
   endmodule
