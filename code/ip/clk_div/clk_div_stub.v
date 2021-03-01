// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.2 (win64) Build 1577090 Thu Jun  2 16:32:40 MDT 2016
// Date        : Sat Dec 26 14:31:11 2020
// Host        : LAPTOP-TD3KU3GO running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/vivado_project/SDCRAD_DIG_REGNIZE/SDCRAD_DIG_REGNIZE.srcs/sources_1/ip/clk_div/clk_div_stub.v
// Design      : clk_div
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_div(sys_clk, clk_50mhz, clk_25mhz, reset, locked)
/* synthesis syn_black_box black_box_pad_pin="sys_clk,clk_50mhz,clk_25mhz,reset,locked" */;
  input sys_clk;
  output clk_50mhz;
  output clk_25mhz;
  input reset;
  output locked;
endmodule
