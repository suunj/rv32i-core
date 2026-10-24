`timescale 1ns/1ps

module branch_unit_tb;

    logic [31:0] src1;
    logic [31:0] src2;

    logic is_beq;
    logic is_bne;
    logic is_blt;
    logic is_bge;
    logic is_bltu;
    logic is_bgeu;

    logic taken;

    int tests = 0;

    branch_unit dut (
        .src1_i(src1),
        .src2_i(src2),

        .is_beq_i(is_beq),
        .is_bne_i(is_bne),
        .is_blt_i(is_blt),
        .is_bge_i(is_bge),
        .is_bltu_i(is_bltu),
        .is_bgeu_i(is_bgeu),

        .taken_o(taken)
    );

    task automatic check_branch(
        input string name,
        input logic [5:0] select_branch,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic expected
    );
        {is_beq, is_bne, is_blt,
         is_bge, is_bltu, is_bgeu} = select_branch;

        src1 = a;
        src2 = b;

        #1;

        if (taken !== expected) begin
            $fatal(1,
                "FAIL %s: a=%h b=%h expected=%b actual=%b",
                name, a, b, expected, taken);
        end

        tests++;
        $display("PASS %-14s a=%h b=%h taken=%b",
                 name, a, b, taken);
    endtask

    initial begin
        // BEQ
        check_branch("BEQ equal",
                     6'b100000, 10, 10, 1);
        check_branch("BEQ unequal",
                     6'b100000, 10, 20, 0);

        // BNE
        check_branch("BNE unequal",
                     6'b010000, 10, 20, 1);
        check_branch("BNE equal",
                     6'b010000, 10, 10, 0);

        // BLT: signed comparison
        check_branch("BLT negative",
                     6'b001000, 32'hFFFFFFFF, 1, 1);
        check_branch("BLT equal",
                     6'b001000, 5, 5, 0);

        // BGE: signed comparison
        check_branch("BGE equal",
                     6'b000100, 5, 5, 1);
        check_branch("BGE negative",
                     6'b000100, 32'hFFFFFFFF, 1, 0);

        // BLTU: unsigned comparison
        check_branch("BLTU smaller",
                     6'b000010, 1, 2, 1);
        check_branch("BLTU negative bits",
                     6'b000010, 32'hFFFFFFFF, 1, 0);

        // BGEU: unsigned comparison
        check_branch("BGEU greater",
                     6'b000001, 10, 5, 1);
        check_branch("BGEU negative bits",
                     6'b000001, 32'hFFFFFFFF, 1, 1);

        // No branch selected
        check_branch("No branch",
                     6'b000000, 10, 10, 0);

        $display("ALL BRANCH TESTS PASSED (%0d tests)", tests);
        $finish;
    end

endmodule
