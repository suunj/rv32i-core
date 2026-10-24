`timescale 1ns/1ps

module core_tb;

    logic clk = 0;
    logic reset = 1;

    logic [31:0] result_out;
    logic done;
    logic [31:0] pc_out;
    logic taken_branch_out;
    logic valid_out;

    bit passed = 0;

    always #5 clk = ~clk;

    core dut (
        .clk(clk),
        .reset(reset),
        .result_out(result_out),
        .done(done),
        .pc_out(pc_out),
        .taken_branch_out(taken_branch_out),
        .valid_out(valid_out)
    );

    initial begin
        repeat (10) @(negedge clk);
        reset = 0;

        for (int cycle = 0; cycle < 1000; cycle++) begin
            @(negedge clk);

            if (done === 1'b1) begin
                if (result_out !== 32'd45)
                    $fatal(1, "FAIL: result=%0d", result_out);

                $display(
                    "PASS: cycle=%0d result=%0d pc=0x%08h",
                    cycle, result_out, pc_out
                );

                passed = 1;
                break;
            end
        end

        if (!passed)
            $fatal(1, "TIMEOUT: CPU did not produce 45");

        $finish;
    end

endmodule
