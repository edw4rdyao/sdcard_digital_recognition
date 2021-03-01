`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 15:28:09
// Design Name: 
// Module Name: dig_regnize
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


module dig_regnize(
    input   w_en,         // 写使能

    input   clk_w,        // 写时钟
    input   clk_r,        // 读时钟

    input   [18:0]  addr_w, // 写地址
    input   [18:0]  addr_r, // 读地址
    
    input   [15:0]  dat_w   ,  // 16位像素传入
    output  [11:0]  dat_r   ,  // 12位像素读出

    output  [1:0]   n_node  ,       // 竖直交点个数
    output  [1:0]   m1_node_l,      // 横左交点个数
    output  [1:0]   m1_node_r,      // 横右交点个数
    output  [1:0]   m2_node_l,      // 横左交点个数
    output  [1:0]   m2_node_r,      // 横右交点个数
    output  [3:0]   iden_num
    );

/**************************************************************   
线网、寄存器定义与连接
*************************************************************/ 
wire         [11:0] dat_w_pix;

wire         [10:0] left_x  ;   // 数字的左边界
wire         [10:0] right_x ;   // 数字的右边界
wire         [10:0] up_y    ;   // 数字的上边界
wire         [10:0] down_y  ;   // 数字的下边界
wire         [10:0] xpos     ;  // 当前读取地址对应的横坐标
wire         [10:0] ypos     ;  // 当前读取地址对应的纵坐标

wire         [11:0] dat_r_pre;  // ram中原像素数据

// 计算当前横纵坐标
assign xpos = addr_r  % 11'd640;
assign ypos = addr_r  / 11'd640;
// 显示数字边框
assign      dat_r = (            
            ((xpos >= left_x-2 - 3) && (xpos <= right_x+2 + 3) && (ypos >= up_y-2 - 3) && (ypos <= up_y-2))||
            ((xpos >= left_x-2 - 3) && (xpos <= right_x+2 + 3) && (ypos >= down_y+2) && (ypos <= down_y+2 + 3))||
            ((ypos >= up_y-2 - 3) && (ypos <= down_y+2 + 3) && (xpos >= left_x-2 - 3) && (xpos <= left_x-2))||
            ((ypos >= up_y-2 - 3) && (ypos <= down_y+2 + 3) && (xpos >= right_x+2) && (xpos <= right_x+2 + 3))
            )? 12'b0000_0000_0000 : dat_r_pre;
// 适应VGA的12位像素数据            
assign dat_w_pix = { dat_w[15:12], dat_w[10:7], dat_w[4:1] };   

/**************************************************************   
实例化双端口ram模块
*************************************************************/ 
ram ram_ins(
    .clka (clk_w)    ,      // 写时钟
    .wea  (w_en)     ,      // 使能
    .addra(addr_w)   ,      // 写地址  
    .dina (dat_w_pix),      // 写数据  
    .clkb (clk_r)    ,      // 读时钟 
    .addrb(addr_r)   ,      // 读地址
    .doutb(dat_r_pre)       // 读数据
);

/**************************************************************   
实例化图像处理模块
*************************************************************/ 
img_deal img_deal_ins(
    .w_en(w_en),
    .clk_w(clk_w),
    .addr_w(addr_w),
    .dat_w(dat_w_pix),

    .left_x(left_x),
    .right_x(right_x),
    .up_y(up_y),
    .down_y(down_y),

    .n_node(n_node),            // 竖直交点个数
    .m1_node_l(m1_node_l),      // 横左交点个数
    .m1_node_r(m1_node_r),      // 横右交点个数
    .m2_node_l(m2_node_l),      // 横左交点个数
    .m2_node_r(m2_node_r),       // 横右交点个数
    
    .iden_num(iden_num)
);

endmodule
