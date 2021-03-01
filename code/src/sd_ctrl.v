`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 14:48:12
// Design Name: 
// Module Name: sd_ctrl
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


module sd_ctrl(
    input               clk_ref     ,  // 时钟信号
    input               rst         ,  // 复位信号,低电平有效

    // SD卡接口
    input               SD_CD       ,
    output              SD_RESET    ,
    output              SD_SCK      ,
    output              SD_CMD      ,
    inout   [3:0]       SD_DATA     ,

    // 读SD卡接口
    input               rd_start_en    ,    // 开始读SD卡数据信号
    input   [31:0]      rd_sec_addr    ,    // 读数据扇区地址
    output              rd_busy        ,    // 读数据忙信号
    output              rd_val_en      ,    // 读数据有效信号
    output  [15:0]      rd_val_data    ,    // 读数据
    output  [18:0]      ram_wr_addr    ,    // 写入ran的地址

    output              sd_init_done        // SD卡初始化完成信号
    );

/**************************************************************   
参数、寄存器、线网定义y与连接
*************************************************************/ 
wire    init_clk    ;       // 初始化SD卡时的低速时钟
wire    init_cs     ;       // 初始化模块SD片选信号
wire    init_mosi   ;       // 初始化模块SD数据输出信号

wire    rd_cs       ;       // 读数据模块SD片选信号     
wire    rd_mosi     ;       // 读数据模块SD数据输出信号 

wire    spi_miso    ;       // MISO接口
wire    spi_clk     ;       // CLK接口
reg     spi_cs      ;       // CS接口
reg     spi_mosi    ;       // MOSI接口

wire    clk_ref_neg ;       // 反相位时钟

// SPI模式接口
assign      SD_RESET        =   0;
assign      SD_DATA[1]      =   1;
assign      SD_DATA[2]      =   1;
assign      SD_DATA[3]      =   spi_cs    ;
assign      SD_CMD          =   spi_mosi  ;
assign      SD_SCK          =   spi_clk   ;
assign      spi_miso        =   SD_DATA[0];

// SD卡的SPI_CLK
assign  clk_ref_neg = ~clk_ref;
assign  spi_clk = (sd_init_done == 1'b0)  ?  init_clk  :  clk_ref_neg;

/**************************************************************   
SD卡接口的信号选择
*************************************************************/ 
always @(*) begin
    if(sd_init_done == 1'b0) begin     
        spi_cs = init_cs;
        spi_mosi = init_mosi;
    end
    else if(rd_busy) begin
        spi_cs = rd_cs;
        spi_mosi = rd_mosi;       
    end
    else begin
        spi_cs = 1'b1;
        spi_mosi = 1'b1;
    end    
end    

/**************************************************************   
实例化SD卡初始化模块
*************************************************************/ 
sd_init sd_init_ins(
    .clk_ref            (clk_ref),
    .rst                (rst),

    .sd_miso            (spi_miso),
    .sd_clk             (init_clk),
    .sd_cs              (init_cs),
    .sd_mosi            (init_mosi),

    .sd_init_done       (sd_init_done)
    );

/**************************************************************   
实例化SD卡读模块
*************************************************************/
sd_read sd_read_ins(
    .clk_ref            (clk_ref),
    .rst                (rst),
    
    .sd_miso            (spi_miso),
    .sd_cs              (rd_cs),
    .sd_mosi            (rd_mosi),

    .rd_start_en        (rd_start_en & sd_init_done),  
    .rd_sec_addr        (rd_sec_addr),
    .rd_busy            (rd_busy),
    .rd_val_en          (rd_val_en),
    .rd_val_data        (rd_val_data),

    .ram_wr_addr        (ram_wr_addr)
    );

endmodule
