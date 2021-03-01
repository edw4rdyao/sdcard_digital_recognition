`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 14:12:05
// Design Name: 
// Module Name: SD_VGA_DIG_TOP
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

module SD_VGA_DIG_TOP(
    // 系统接口
    input       SYS_CLK ,           // 系统时钟
    input       SYS_RST ,           // 系统复位

    // SD卡外部接口
    input       SD_CD       ,
    output      SD_RESET    ,
    output      SD_SCK      ,
    output      SD_CMD      ,
    inout   [3:0]   SD_DATA ,

    // VGA外部接口                          
    output          VGA_HS  ,        // 行同步信号
    output          VGA_VS  ,        // 场同步信号
    output  [11:0]  VGA_RGB,        // 红绿蓝颜色输出

    // Debug接口
    output  init_done_out,           // SD卡初始化完成信号
    output  [1:0]   n_node,         // 竖直交点个数
    output  [1:0]   m1_node_l,      // 横左交点个数
    output  [1:0]   m1_node_r,      // 横右交点个数
    output  [1:0]   m2_node_l,      // 横左交点个数
    output  [1:0]   m2_node_r,      // 横右交点个数

    output  [7:0]   DIG,            // 数码管信号(识别出来的数字)
    output  [7:0]   BIT_CTRL        // 数码管位控信号(只显示一位)

    );

/**************************************************************   
参数定义
*************************************************************/ 
parameter COL_MAX = 11'd640;        // 横坐标最大边界640  

/**************************************************************   
线网定义与连接
*************************************************************/ 
wire                    clk_25mhz       ;   // 25.175mhz时钟
wire                    clk_50mhz       ;   // 50.000mhz时钟
wire                    locked          ;   // 锁
wire                    rst             ;   // 内部复位信号

wire                    sd_init_done    ;   // SD卡初始化完成信号
wire                    sd_rd_start_en  ;   // 读SD卡数据开始信号
wire        [31:0]      sd_rd_addr      ;   // 读数据扇区地址    
wire                    sd_rd_busy      ;   // 读忙信号
wire                    sd_rd_val_en    ;   // 数据读取使能信号
wire        [15:0]      sd_rd_val_data  ;   // 从SD卡读的数据
wire        [18:0]      sd_ram_wr_addr  ;   // SD卡控制ram的写入地址

wire                    ram_wr_en       ;   // ram写使能
wire        [15:0]      ram_wr_data     ;   // ram写数据
wire        [18:0]      ram_wr_addr     ;   // ram写地址
wire                    ram_rd_en       ;   // ram读使能
wire        [11:0]      ram_rd_data     ;   // ram读数据
wire        [18:0]      ram_rd_addr     ;   // ram读地址 

wire        [10:0]      pix_xpos        ;   // VGA请求的像素横坐标 
wire        [10:0]      pix_ypos        ;   // VGA请求的像素纵坐标

wire        [3:0]       iden_num        ;   // 识别出来的数字

assign  rst     =   SYS_RST & locked    ;   // 内部复位信号

assign  ram_wr_en       =   sd_rd_val_en    ;
assign  ram_wr_data     =   sd_rd_val_data  ;
assign  ram_wr_addr     =   sd_ram_wr_addr  ;
assign  ram_rd_addr     =   pix_ypos * COL_MAX + pix_xpos;  // 通过VGA的请求横纵坐标计算出读ram地址

assign  init_done_out   =   sd_init_done    ;               // Debug接口

/**************************************************************   
实例化时钟分频模块
*************************************************************/ 
clk_div clk_div_ins(
    .sys_clk(SYS_CLK),
    .clk_50mhz(clk_50mhz),
    .clk_25mhz(clk_25mhz),
    .reset(0),
    .locked(locked)
);

/**************************************************************   
实例化数码管显示模块
*************************************************************/ 
display_seg seg_ins(
    .num(iden_num),
    .dig(DIG),
    .bit_ctrl(BIT_CTRL)
);

/**************************************************************   
实例化VGA模块
*************************************************************/ 
vga_driver vga_ins(
    .vga_clk(clk_25mhz),    // VGA驱动时钟
    .rst(rst),              // 复位信号
    
    .vga_hs(VGA_HS),
    .vga_vs(VGA_VS),
    .vga_rgb(VGA_RGB),

    .pix_data(ram_rd_data), // 像素点数据
    .pix_xpos(pix_xpos),    // 像素点横坐标
    .pix_ypos(pix_ypos)     // 像素点纵坐标
);

/**************************************************************   
实例化数字识别模块
*************************************************************/ 
dig_regnize regnize_ins(
    .w_en(ram_wr_en),             // 写使能

    .clk_w(clk_50mhz),        // 写时钟
    .clk_r(clk_25mhz),        // 读时钟

    .addr_w(ram_wr_addr),         // 写地址
    .addr_r(ram_rd_addr),         // 读地址
    .dat_w(ram_wr_data),          // 16位像素传入
    .dat_r(ram_rd_data),          // 12位像素读出

    .iden_num(iden_num),      // 识别出的数字
    .n_node(n_node),          // 竖直交点个数
    .m1_node_l(m1_node_l),    // 横左交点个数
    .m1_node_r(m1_node_r),    // 横右交点个数
    .m2_node_l(m2_node_l),    // 横左交点个数
    .m2_node_r(m2_node_r)     // 横右交点个数
);

/**************************************************************   
实例化读取图片控制模块
*************************************************************/ 
img_read_ctrl img_read_ins(
    .clk             (clk_50mhz),
    .rst             (rst & sd_init_done), 

    .rd_busy         (sd_rd_busy),
    .rd_start_en     (sd_rd_start_en),
    .rd_sec_addr     (sd_rd_addr)
);

/**************************************************************   
实例化SD卡控制模块
*************************************************************/ 
sd_ctrl sd_ins(
    .clk_ref           (clk_50mhz),
    .rst                (rst),
    // SD卡接口
    .SD_CD      (SD_CD),
    .SD_RESET   (SD_RESET),
    .SD_SCK     (SD_SCK),
    .SD_CMD     (SD_CMD),
    .SD_DATA    (SD_DATA),
    // 读SD卡数据接口
    .rd_start_en       (sd_rd_start_en),
    .rd_sec_addr       (sd_rd_addr),
    .rd_busy           (sd_rd_busy),
    .rd_val_en         (sd_rd_val_en),
    .rd_val_data       (sd_rd_val_data),

    .ram_wr_addr        (sd_ram_wr_addr),
    .sd_init_done      (sd_init_done)
);

endmodule
