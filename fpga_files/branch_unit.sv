module branch_unit (
    input  logic [31:0] src1_i,
    input  logic [31:0] src2_i,

    input  logic is_beq_i,
    input  logic is_bne_i,
    input  logic is_blt_i,
    input  logic is_bge_i,
    input  logic is_bltu_i,
    input  logic is_bgeu_i,

    output logic taken_o
);

    // Preserve the original CPU's comparison semantics.
    always_comb begin
        if (is_beq_i)
            taken_o = (src1_i == src2_i);
        else if (is_bne_i)
            taken_o = (src1_i != src2_i);
        else if (is_blt_i)
            taken_o = ((src1_i < src2_i) ^
                       (src1_i[31] != src2_i[31]));
        else if (is_bge_i)
            taken_o = ((src1_i >= src2_i) ^
                       (src1_i[31] != src2_i[31]));
        else if (is_bltu_i)
            taken_o = (src1_i < src2_i);
        else if (is_bgeu_i)
            taken_o = (src1_i >= src2_i);
        else
            taken_o = 1'b0;
    end

endmodule

