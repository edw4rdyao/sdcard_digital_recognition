`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 15:47:05
// Design Name: 
// Module Name: img_deal
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


module img_deal(
    input       w_en,                // 写使能，高电平有效
    input       clk_w,               // 写时钟50mhz
    input       [18:0] addr_w,       // 写地址
    input       [11:0] dat_w,        // 12位像素传入
    
    output reg  [10:0] left_x,       // 数字的左边界
    output reg  [10:0] right_x,      // 数字的左边界
    output reg  [10:0] up_y,         // 数字的左边界
    output reg  [10:0] down_y,       // 数字的左边界

    output reg  [1:0] n_node,        // 竖直交点个数
    output reg  [1:0] m1_node_l,     // 横左交点个数
    output reg  [1:0] m1_node_r,     // 横右交点个数
    output reg  [1:0] m2_node_l,     // 横左交点个数
    output reg  [1:0] m2_node_r,     // 横右交点个数
    
    output reg [3:0] iden_num       // 识别的数字
);

/**************************************************************   
参数、寄存器、线网定义与连接
*************************************************************/ 
reg     bin_pix [0:307199]  ;   // 储存二值化后的图像数据

wire    [10:0]  n;              // 左右边界1/2处
wire    [10:0]  m1;             // 上下边界2/5处
wire    [10:0]  m2;             // 上下边界2/3处
assign n = (left_x + right_x) >> 1;
assign m1 = up_y + 2 * (down_y - up_y) / 5;
assign m2 = up_y + 2 * (down_y - up_y) / 3;

// 二值化处理
wire    [3:0]   red;        // 红颜色分量
wire    [3:0]   green;      // 绿颜色分量
wire    [3:0]   blue;       // 蓝颜色分量
wire    [3:0]   grey;       // 灰度数据
wire            bin_dat;    // 二值化数据
assign  red     =   dat_w[11:8];
assign  green   =   dat_w[7:4];
assign  blue    =   dat_w[3:0];
assign  grey    =   (red * 4 + green * 10 + blue * 2) >> 4;
assign  bin_dat =   (grey > 4'd8) ? 1'b1 : 1'b0;

// 用于获得交点个数的打拍信号
reg     n_pix_pre;
reg     n_pix_post;
reg     m1_pix_pre;
reg     m1_pix_post;
reg     m2_pix_pre;
reg     m2_pix_post;
reg     [18:0] scan_cnt; // 扫描计数器

// 获得扫描的横纵坐标
wire    [11:0] scan_x;
wire    [11:0] scan_y;
assign  scan_x = scan_cnt % 11'd640;
assign  scan_y = scan_cnt / 11'd640;

/**************************************************************   
利用投影分割获取数字边界
*************************************************************/ 
always@(posedge clk_w) begin
    if(w_en) begin
        bin_pix[addr_w] <= bin_dat;
        if(addr_w == 19'd1) begin
            left_x <= 11'd639;
            right_x <= 11'd0;
            up_y <= 11'd479;
            down_y <= 11'd0;
        end else if( !bin_dat ) begin
            if(addr_w % 11'd640 > right_x) right_x <= addr_w % 11'd640;
            else right_x <= right_x;
            if(addr_w % 11'd640 < left_x) left_x <= addr_w % 11'd640;
            else left_x <= left_x;
            if(addr_w / 11'd640 > down_y) down_y <= addr_w / 11'd640;
            else down_y <= down_y;
            if(addr_w / 11'd640 < up_y) up_y <= addr_w / 11'd640;
            else up_y <= up_y;
        end
    end else begin
        bin_pix[addr_w] <= bin_pix[addr_w];
    end
end

/**************************************************************   
利用打拍获得与各线交点个数
*************************************************************/ 
always@(posedge clk_w) begin
    if(w_en) begin
        n_pix_pre  <= 1'b1;
        n_pix_post  <= 1'b1;
        m1_pix_pre  <= 1'b1;
        m1_pix_post  <= 1'b1;
        m2_pix_pre  <= 1'b1;
        m2_pix_post  <= 1'b1;
        scan_cnt <= 19'd0;
        
        n_node    <= 2'd0;  
        m1_node_l <= 2'd0; 
        m1_node_r <= 2'd0; 
        m2_node_l <= 2'd0; 
        m2_node_r <= 2'd0; 
    end
    else begin
        if(scan_cnt < 19'd307200) begin
            scan_cnt <= scan_cnt +19'd1;

            if(n_pix_pre && (~n_pix_post) && (scan_x == n)) n_node <= n_node + 2'd1; 
            else n_node <= n_node;

            if(scan_x == n) begin
                n_pix_pre <= n_pix_post;
                n_pix_post <= bin_pix[scan_cnt];
            end
            else begin
                n_pix_pre <= n_pix_pre;
                n_pix_post <= n_pix_post;
            end

            if(m1_pix_pre && (~m1_pix_post) && (scan_x < n)) begin
                m1_node_l <= m1_node_l + 2'd1;
            end else if( m1_pix_pre && (~m1_pix_post)) begin
                m1_node_r <= m1_node_r + 2'd1;
            end else begin
                m1_node_l <= m1_node_l;
                m1_node_r <= m1_node_r;
            end

            if(scan_y == m1) begin
                m1_pix_pre <= m1_pix_post;
                m1_pix_post <= bin_pix[scan_cnt];
            end else begin
                m1_pix_post <= m1_pix_post;
                m1_pix_pre <= m1_pix_pre;
            end

            if(m2_pix_pre && (~m2_pix_post) && (scan_x < n)) begin
                m2_node_l <= m2_node_l + 2'd1;
            end else if(m2_pix_pre && (~m2_pix_post)) begin
                m2_node_r <= m2_node_r + 2'd1;
            end else begin
                m2_node_l <= m2_node_l;
                m2_node_r <= m2_node_r;
            end

            if(scan_y == m2) begin
                m2_pix_pre <= m2_pix_post;
                m2_pix_post <= bin_pix[scan_cnt];
            end else begin
                m2_pix_post <= m2_pix_post;
                m2_pix_pre <= m2_pix_pre;
            end

        end
    end
end

/**************************************************************   
通过交点得到识别的数字
*************************************************************/ 
always @(*) begin
    case({n_node, m1_node_l, m1_node_r, m2_node_l, m2_node_r})
        10'b10_01_01_01_01: iden_num = 4'd0;
        10'b01_01_00_01_00: iden_num = 4'd1;
        10'b11_00_01_01_00: iden_num = 4'd2;
        10'b11_00_01_00_01: iden_num = 4'd3;
        10'b10_01_01_01_00: iden_num = 4'd4;
        10'b11_01_00_00_01: iden_num = 4'd5;
        10'b11_01_00_01_01: iden_num = 4'd6;
        10'b11_10_00_01_01: iden_num = 4'd6;
        10'b10_00_01_01_00: iden_num = 4'd7;
        10'b10_00_01_00_01: iden_num = 4'd7;
        10'b11_01_01_01_01: iden_num = 4'd8;
        10'b11_01_01_00_01: iden_num = 4'd9;
        default: iden_num = 4'd10;
    endcase
end

endmodule
