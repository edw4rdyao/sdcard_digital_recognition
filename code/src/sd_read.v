`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 15:00:35
// Design Name: 
// Module Name: sd_read
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

module sd_read(
    input                clk_ref        ,  // 时钟信号
    input                rst            ,  // 复位信号

    input                sd_miso        ,  // SD卡SPI串行输入数据信号
    output  reg          sd_cs          ,  // SD卡SPI片选信号
    output  reg          sd_mosi        ,  // SD卡SPI串行输出数据信号

    input                rd_start_en    ,  // 开始读SD卡数据信号
    input        [31:0]  rd_sec_addr    ,  // 读数据扇区地址                        
    output  reg          rd_busy        ,  // 读数据忙信号
    output  reg          rd_val_en      ,  // 读数据有效信号
    output  reg  [15:0]  rd_val_data    ,  // 读数据

    output  reg  [18:0]  ram_wr_addr       // 读ram地址
    );

/**************************************************************   
参数、线网、寄存器定义
*************************************************************/
parameter      MAX_ADDR =  19'd307200;      // ram最大地址
reg            rd_start_en_bat0      ;      // 延时打拍
reg            rd_start_en_bat1      ;      // 延时打拍

reg            res_en        ;            // 接收SD卡返回数据有效信号      
reg    [7:0]   res_data      ;            // 接收SD卡返回数据                  
reg            res_flag      ;            // 开始接收返回数据的标志            
reg    [5:0]   res_bit_cnt   ;            // 接收位数据计数器                  
                              
reg            rx_en_t       ;            // 接收SD卡数据使能信号
reg    [15:0]  rx_data_t     ;            // 接收SD卡的数据
reg            rx_flag       ;            // 开始接收的标志
reg    [3:0]   rx_bit_cnt    ;            // 接收数据位计数器
reg    [8:0]   rx_data_cnt   ;            // 接收的数据个数计数器
reg            rx_finish_en  ;            // 接收完成使能信号
                              
reg    [3:0]   rd_ctrl_cnt   ;            // 读控制计数器
reg    [47:0]  cmd_rd        ;            // 读命令
reg    [5:0]   cmd_bit_cnt   ;            // 读命令位计数器
reg            rd_data_flag  ;            // 准备读取数据的标志

wire           pos_rd_start_en      ;     // 开始读SD卡数据信号的上升沿

/**************************************************************   
采用延时打拍的方法采集rd_start_en的上升沿
*************************************************************/
assign pos_rd_start_en = rd_start_en_bat0 & (~rd_start_en_bat1);
always @(posedge clk_ref or negedge rst) begin
    if(!rst) begin
        rd_start_en_bat0 <= 1'b0;
        rd_start_en_bat1 <= 1'b0;
    end    
    else begin
        rd_start_en_bat0 <= rd_start_en;
        rd_start_en_bat1 <= rd_start_en_bat0;
    end        
end

/**************************************************************   
接受SD卡返回的响应数据
*************************************************************/
always @(negedge clk_ref or negedge rst) begin
    if(!rst) begin
        res_en <= 1'b0;
        res_data <= 8'd0;
        res_flag <= 1'b0;
        res_bit_cnt <= 6'd0;
    end    
    else begin
        
        if(sd_miso == 1'b0 && res_flag == 1'b0) begin
            res_flag <= 1'b1;
            res_data <= {res_data[6:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            res_en <= 1'b0;
        end    
        else if(res_flag) begin
            res_data <= {res_data[6:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            if(res_bit_cnt == 6'd7) begin
                res_flag <= 1'b0;
                res_bit_cnt <= 6'd0;
                res_en <= 1'b1; 
            end                
        end 

        else
            res_en <= 1'b0;        
    end
end 

/**************************************************************   
接受SD卡返回的有效数据
*************************************************************/
always @(negedge clk_ref or negedge rst) begin
    if(!rst) begin
        rx_en_t <= 1'b0;
        rx_data_t <= 16'd0;
        rx_flag <= 1'b0;
        rx_bit_cnt <= 4'd0;
        rx_data_cnt <= 9'd0;
        rx_finish_en <= 1'b0;
    end    
    else begin
        rx_en_t <= 1'b0; 
        rx_finish_en <= 1'b0;
        // SD卡返回的数据头0xfe 8'b1111_1110
        if(rd_data_flag && sd_miso == 1'b0 && rx_flag == 1'b0)    
            rx_flag <= 1'b1;   
        else if(rx_flag) begin
            rx_bit_cnt <= rx_bit_cnt + 4'd1;
            rx_data_t <= {rx_data_t[14:0],sd_miso};
            if(rx_bit_cnt == 4'd15) begin 
                rx_data_cnt <= rx_data_cnt + 9'd1;
                // 接收单个BLOCK共512个字节 = 256 * 16bit
                if(rx_data_cnt <= 9'd255)
                    rx_en_t <= 1'b1;  
                else if(rx_data_cnt == 9'd257) begin   // 接收CRC校验值
                    rx_flag <= 1'b0;
                    rx_finish_en <= 1'b1;
                    rx_data_cnt <= 9'd0;               
                    rx_bit_cnt <= 4'd0;
                end    
            end
        end       
        else
            rx_data_t <= 16'd0;
    end    
end    

/**************************************************************   
向SD卡发送读命令
*************************************************************/
always @(posedge clk_ref or negedge rst) begin
    if(!rst) begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1;        
        rd_ctrl_cnt <= 4'd0;
        cmd_rd <= 48'd0;
        cmd_bit_cnt <= 6'd0;
        rd_busy <= 1'b0;
        rd_data_flag <= 1'b0;
    end   
    else begin
        case(rd_ctrl_cnt)
            4'd0 : begin
                rd_busy <= 1'b0;
                sd_cs <= 1'b1;
                sd_mosi <= 1'b1;
                if(pos_rd_start_en) begin
                    cmd_rd <= {8'h51,rd_sec_addr,8'hff};    // 写入单个命令块CMD17
                    rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;      // 控制计数器加1
                    // 开始执行读取数据,拉高读忙信号
                    rd_busy <= 1'b1;                      
                end    
            end
            4'd1 : begin
                if(cmd_bit_cnt <= 6'd47) begin              // 开始按位发送读命令
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= cmd_rd[6'd47 - cmd_bit_cnt]; // 先发送高字节
                end    
                else begin                                  
                    sd_mosi <= 1'b1;
                    if(res_en) begin                        // SD卡响应
                        rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;  // 控制计数器加1 
                        cmd_bit_cnt <= 6'd0;
                    end    
                end    
            end    
            4'd2 : begin
                // 拉高rd_data_flag信号,准备接收数据
                rd_data_flag <= 1'b1;                       
                if(rx_finish_en) begin                      // 数据接收完成
                    rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1; 
                    rd_data_flag <= 1'b0;
                    sd_cs <= 1'b1;
                end
            end        
            default : begin
                // 进入空闲状态后,拉高片选信号,等待8个时钟周期以上
                sd_cs <= 1'b1;   
                rd_ctrl_cnt <= rd_ctrl_cnt + 4'd1;
            end    
        endcase
    end         
end

/**************************************************************   
输出数据和数据有效信号
*************************************************************/
always @(posedge clk_ref or negedge rst) begin
    if(!rst) begin
        rd_val_en <= 1'b0;
        rd_val_data <= 16'd0;
        ram_wr_addr <= 19'd0;
    end
    else begin
        if(rx_en_t) begin
            rd_val_en <= 1'b1;
            rd_val_data <= rx_data_t;
            if(ram_wr_addr < MAX_ADDR - 1) begin
                ram_wr_addr <= ram_wr_addr +19'd1;
            end
            else begin
                ram_wr_addr <= 19'd0;
            end
        end    
        else
            rd_val_en <= 1'b0;
    end
end      

endmodule