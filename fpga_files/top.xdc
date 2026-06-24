#=====================================================================
# top.xdc  -  PA35T-StarLite (XC7A35T) 핀 제약
#   기존 LED 데모 XDC 기반. 핀 번호는 동일, 포트 이름만 top.v에 맞춤.
#=====================================================================

# --- 설정 (LED 데모에서 그대로) ---
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]

# --- 차동 클럭 (핀 R4) ---
set_property -dict {PACKAGE_PIN R4 IOSTANDARD DIFF_SSTL15} [get_ports sys_clk_p]

# 클럭 주파수 제약: 보드 클럭이 100MHz 라고 가정 (주기 10ns)
# 보드가 200MHz 이면 아래 10.000 을 5.000 으로 바꿀 것.
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]

# --- 리셋 버튼 (핀 R14) ---
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports sys_rstn]

# --- LED 2개 (핀 W22, Y22) ---
set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN Y22 IOSTANDARD LVCMOS33} [get_ports {led[1]}]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {pc_dbg[0]} {pc_dbg[1]} {pc_dbg[2]} {pc_dbg[3]} {pc_dbg[4]} {pc_dbg[5]} {pc_dbg[6]} {pc_dbg[7]} {pc_dbg[8]} {pc_dbg[9]} {pc_dbg[10]} {pc_dbg[11]} {pc_dbg[12]} {pc_dbg[13]} {pc_dbg[14]} {pc_dbg[15]} {pc_dbg[16]} {pc_dbg[17]} {pc_dbg[18]} {pc_dbg[19]} {pc_dbg[20]} {pc_dbg[21]} {pc_dbg[22]} {pc_dbg[23]} {pc_dbg[24]} {pc_dbg[25]} {pc_dbg[26]} {pc_dbg[27]} {pc_dbg[28]} {pc_dbg[29]} {pc_dbg[30]} {pc_dbg[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list taken_branch_dbg]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list valid_dbg]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_BUFG]
