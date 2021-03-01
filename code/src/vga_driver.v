`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 14:41:03
// Design Name: 
// Module Name: vga_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vga_driver(
    input           vga_clk,            // VGA驱动时钟
    input           rst,                // 复位信号

    output          vga_hs,             // 行同步信号
    output          vga_vs,             // 场同步信号
    output  [11:0]  vga_rgb,            // 红绿蓝输出

    input   [11:0]  pix_data,           // 像素点数据
    output  [10:0]  pix_xpos,           // 像素点横坐标
    output  [10:0]  pix_ypos            // 像素点纵坐标
    );

/**************************************************************   
参数、寄存器、线网定义(分辨率: 640*480 时钟频率: 25.175mhz 位宽:10位)
*************************************************************/ 
parameter  H_SYNC   =  10'd96;    // 行同步
parameter  H_BACK   =  10'd48;    // 行显示后沿
parameter  H_DISP   =  10'd640;   // 行有效数据
parameter  H_FRONT  =  10'd16;    // 行显示前沿
parameter  H_TOTAL  =  10'd800;   // 行扫描周期

parameter  V_SYNC   =  10'd2;     // 场同步
parameter  V_BACK   =  10'd33;    // 场显示后沿
parameter  V_DISP   =  10'd480;   // 场有效数据
parameter  V_FRONT  =  10'd10;    // 场显示前沿
parameter  V_TOTAL  =  10'd525;   // 场扫描周期
                         
reg     [10:0]      cnt_h;      // 行时序计数器           
reg     [10:0]      cnt_v;      // 场时序计数器    

wire                vga_en;     // RGB显示的使能信号

/**************************************************************   
VGA显示
*************************************************************/
// VGA请求数据标志      
assign pix_data_req_flag = (((cnt_h >= H_SYNC+H_BACK-1'b1) && (cnt_h < H_SYNC+H_BACK+H_DISP-1'b1))
                  && ((cnt_v >= V_SYNC+V_BACK) && (cnt_v < V_SYNC+V_BACK+V_DISP)))
                  ?  1'b1 : 1'b0;

// 输出的像素点坐标
assign pix_xpos = pix_data_req_flag ? (cnt_h - (H_SYNC + H_BACK - 1'b1)) : 10'd0;
assign pix_ypos = pix_data_req_flag ? (cnt_v - (V_SYNC + V_BACK - 1'b1)) : 10'd0;

// VGA行场同步信号
assign vga_hs  = (cnt_h <= H_SYNC - 1'b1) ? 1'b0 : 1'b1;
assign vga_vs  = (cnt_v <= V_SYNC - 1'b1) ? 1'b0 : 1'b1;

// 行计数器计数
always @(posedge vga_clk or negedge rst) begin         
    if (!rst)
        cnt_h <= 10'd0;                                  
    else begin
        if(cnt_h < H_TOTAL - 1'b1)                                               
            cnt_h <= cnt_h + 1'b1;                               
        else 
            cnt_h <= 10'd0;  
    end
end

// 场计数计数
always @(posedge vga_clk or negedge rst) begin         
    if (!rst)
        cnt_v <= 10'd0;                                  
    else if(cnt_h == H_TOTAL - 1'b1) begin
        if(cnt_v < V_TOTAL - 1'b1)                                               
            cnt_v <= cnt_v + 1'b1;                               
        else 
            cnt_v <= 10'd0;  
    end
end

// RGB显示的使能信号
assign vga_en  = (((cnt_h >= H_SYNC+H_BACK) && (cnt_h < H_SYNC+H_BACK+H_DISP))
                 &&((cnt_v >= V_SYNC+V_BACK) && (cnt_v < V_SYNC+V_BACK+V_DISP)))
                 ?  1'b1 : 1'b0;

// VGA显示像素数据
assign vga_rgb = vga_en ? pix_data : 12'd0;

endmodule
