`timescale 1ns / 1ps
//=====================================================================
// top.v  -  MYTH RISC-V 코어를 PA35T-StarLite 보드에 연결하는 래퍼
//
//   보드 핀 (XDC):
//     sys_clk_p / sys_clk_n : 차동 클럭 (핀 R4)
//     sys_rstn              : 리셋 버튼, active-low (핀 R14)
//     led[1:0]              : LED 2개 (핀 W22, Y22)
//
//   동작:
//     1. 차동 클럭을 IBUFDS로 일반 클럭(clk)으로 변환
//     2. 전원 켜진 직후 잠깐 코어에 reset을 주고 풀어줌
//     3. 코어가 1~9 합(45)을 계산
//     4. done=1 이 되면 LED 2개 모두 켜짐
//=====================================================================
module top (
    input  sys_clk_p,
    input  sys_clk_n,
    input  sys_rstn,        // 버튼: 누르면 0 (active-low)
    output [1:0] led
);

    //------------------------------------------------------------
    // 1) 차동 클럭 → 일반 클럭  (LED.v에서 그대로 가져온 부분)
    //------------------------------------------------------------
    wire clk;
    IBUFDS #(
        .DIFF_TERM("FALSE"),
        .IBUF_LOW_PWR("TRUE"),
        .IOSTANDARD("DEFAULT")
    ) IBUFDS_inst (
        .O (clk),
        .I (sys_clk_p),
        .IB(sys_clk_n)
    );

    //------------------------------------------------------------
    // 2) 리셋 생성
    //    코어의 reset은 active-high (1일 때 리셋).
    //    보드 버튼 sys_rstn은 active-low (0일 때 눌림).
    //
    //    전원 켜진 직후 자동으로 잠깐 리셋을 주기 위해
    //    작은 카운터로 시작 후 일정 사이클 동안 reset=1 유지.
    //------------------------------------------------------------
    reg [7:0] rst_cnt = 8'd0;
    reg       core_reset = 1'b1;

    always @(posedge clk) begin
        if (!sys_rstn) begin
            // 버튼 누르면 강제 리셋 + 카운터 초기화
            rst_cnt    <= 8'd0;
            core_reset <= 1'b1;
        end else if (rst_cnt < 8'd200) begin
            // 전원 직후 200사이클 동안 리셋 유지
            rst_cnt    <= rst_cnt + 1'b1;
            core_reset <= 1'b1;
        end else begin
            // 그 후 리셋 해제 → 코어 동작 시작
            core_reset <= 1'b0;
        end
    end

    //------------------------------------------------------------
    // 3) RISC-V 코어 인스턴스
    //------------------------------------------------------------
    wire [31:0] result_out;
    wire        done;

    // ILA로 관찰할 신호 (mark_debug = 합성 후에도 보존)
    (* mark_debug = "true" *) wire [31:0] pc_dbg;
    (* mark_debug = "true" *) wire        taken_branch_dbg;
    (* mark_debug = "true" *) wire        valid_dbg;

    core u_core (
        .clk        (clk),
        .reset      (core_reset),
        .result_out (result_out),
        .done       (done),
        .pc_out           (pc_dbg),
        .taken_branch_out (taken_branch_dbg),
        .valid_out        (valid_dbg)
    );

    //------------------------------------------------------------
    // 4) 결과를 LED로
    //    계산이 끝나(done=1) 합이 45가 되면 LED 2개 모두 켜짐.
    //
    //    한 번 done이 뜨면 계속 켜져 있도록 래치.
    //    (보드 LED는 1일 때 켜진다고 가정 — 안 켜지면 ~done_latched 로 반전)
    //------------------------------------------------------------
    reg done_latched = 1'b0;
    always @(posedge clk) begin
        if (core_reset)
            done_latched <= 1'b0;
        else if (done)
            done_latched <= 1'b1;
    end

    assign led = done_latched ? 2'b11 : 2'b00;

endmodule
