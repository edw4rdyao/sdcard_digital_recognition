`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 15:00:23
// Design Name: 
// Module Name: sd_init
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


module sd_init(
    input          clk_ref       ,  // 参考时钟
    input          rst           ,  // 复位信号,低电平有效
    
    input          sd_miso       ,  // SD卡SPI串行输入数据信号
    output         sd_clk        ,  // SD卡SPI时钟信号
    output  reg    sd_cs         ,  // SD卡SPI片选信号
    output  reg    sd_mosi       ,  // SD卡SPI串行输出数据信号
    
    output  reg    sd_init_done     // SD卡初始化完成信号
    );

/**************************************************************   
参数定义
*************************************************************/    
// SD卡命令定义
parameter  CMD0  = {8'h40,8'h00,8'h00,8'h00,8'h00,8'h95};
parameter  CMD8  = {8'h48,8'h00,8'h00,8'h01,8'haa,8'h87};
parameter  CMD55 = {8'h77,8'h00,8'h00,8'h00,8'h00,8'hff};
parameter  ACMD41 = {8'h69,8'h40,8'h00,8'h00,8'h00,8'hff};

// 状态编码
parameter  sta_idle        = 7'b000_0001;  // 上电等待SD卡稳定
parameter  sta_send_cmd0   = 7'b000_0010;  // 发送软复位命令
parameter  sta_wait_cmd0   = 7'b000_0100;  // 等待SD卡响应
parameter  sta_send_cmd8   = 7'b000_1000;  // 检测SD卡是否满足电压范围
parameter  sta_send_cmd55  = 7'b001_0000;  // 告诉SD卡接下来的命令是应用相关命令
parameter  sta_send_acmd41 = 7'b010_0000;  // 发送操作寄存器(OCR)内容
parameter  sta_init_done   = 7'b100_0000;  // SD卡初始化完成

// 时钟分频系数,初始化SD卡时需要降低SD卡的时钟频率,50M/250K = 200 
parameter  DIV_NUM = 200;

// 上电至少等待74个同步时钟周期,在等待上电稳定期间,sd_cs = 1,sd_mosi = 1
parameter  POWER_ON_NUM = 5000;

// 发送软件复位命令时等待SD卡返回的最大时间,T = 100ms; 100_000us/4us = 25000
parameter  OVER_TIME = 25000;

/**************************************************************   
寄存器定义
*************************************************************/    
reg    [7:0]   cur_sta      ;    // 现态
reg    [7:0]   nex_sta      ;    // 次态
                              
reg    [7:0]   div_cnt        ;    // 分频计数器
reg            clk_250khz     ;    // 分频后的250khz时钟         
reg    [12:0]  poweron_cnt    ;    // 等待稳定计数器
reg            res_en         ;    // 接收SD卡返回数据有效信号
reg    [47:0]  res_data       ;    // 接收SD卡返回数据
reg            res_flag       ;    // 开始接收返回数据的标志
reg    [5:0]   res_bit_cnt    ;    // 接收位数据计数器
                                   
reg    [5:0]   cmd_bit_cnt    ;    // 发送指令位计数器
reg    [15:0]  over_time_cnt  ;    // 超时计数器
reg            over_time_en   ;    // 超时使能信号

/**************************************************************   
时钟分频
*************************************************************/ 
assign  sd_clk = ~clk_250khz;         // 输出sd_clk
always @(posedge clk_ref or negedge rst) begin
    if(!rst) begin
        clk_250khz <= 1'b0;
        div_cnt <= 8'd0;
    end
    else begin
        if(div_cnt == DIV_NUM/2 - 1'b1) begin
            clk_250khz <= ~clk_250khz;
            div_cnt <= 8'd0;
        end
        else    
            div_cnt <= div_cnt + 1'b1;
    end        
end   

/**************************************************************   
等待SD卡稳定
*************************************************************/ 
always @(posedge clk_250khz or negedge rst) begin
    if(!rst) 
        poweron_cnt <= 13'd0;
    else if(cur_sta == sta_idle) begin
        if(poweron_cnt < POWER_ON_NUM)
            poweron_cnt <= poweron_cnt + 1'b1;
    end
    else
        poweron_cnt <= 13'd0;    
end

/**************************************************************   
接受SD卡返回的数据
*************************************************************/ 
always @(negedge clk_250khz or negedge rst) begin
    if(!rst) begin
        res_en <= 1'b0;
        res_data <= 48'd0;
        res_flag <= 1'b0;
        res_bit_cnt <= 6'd0;
    end    
    else begin
        // 开始接收响应数据
        if(sd_miso == 1'b0 && res_flag == 1'b0) begin 
            res_flag <= 1'b1;
            res_data <= {res_data[46:0],sd_miso};
            res_bit_cnt <= res_bit_cnt + 6'd1;
            res_en <= 1'b0;
        end
        else if(res_flag) begin
            // 接收6个字节,多出的1个字节为8个时钟周期的延时
            res_data <= {res_data[46:0],sd_miso};     
            res_bit_cnt <= res_bit_cnt + 6'd1;
            if(res_bit_cnt == 6'd47) begin
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
三段式状态机
*************************************************************/ 
always @(posedge clk_250khz or negedge rst) begin
    if(!rst)
        cur_sta <= sta_idle;
    else
        cur_sta <= nex_sta;
end

always @(*) begin
    nex_sta = sta_idle;
    case(cur_sta)
        // 上电等待SD卡稳定
        sta_idle : begin
            // 上电至少等待74个同步时钟周期
            if(poweron_cnt == POWER_ON_NUM)          
                nex_sta = sta_send_cmd0;
            else
                nex_sta = sta_idle;
        end
        // 发送软复位命令 
        sta_send_cmd0 : begin                         
            if(cmd_bit_cnt == 6'd47)
                nex_sta = sta_wait_cmd0;
            else
                nex_sta = sta_send_cmd0;    
        end
        // 等待SD卡响应               
        sta_wait_cmd0 : begin                         
            if(res_en) begin                         // SD卡返回响应信号
                if(res_data[47:40] == 8'h01)         // SD卡返回复位成功
                    nex_sta = sta_send_cmd8;
                else
                    nex_sta = sta_idle;
            end
            else if(over_time_en)                    // SD卡响应超时
                nex_sta = sta_idle;
            else
                nex_sta = sta_wait_cmd0;                                    
        end    
        // 检测SD卡是否满足电压范围
        sta_send_cmd8 : begin 
            if(res_en) begin                         // SD卡返回响应信号  
                // 返回SD卡的操作电压,[19:16] = 4'b0001(2.7V~3.6V)
                if(res_data[19:16] == 4'b0001)       
                    nex_sta = sta_send_cmd55;
                else
                    nex_sta = sta_idle;
            end
            else
                nex_sta = sta_send_cmd8;            
        end
        // 告诉SD卡接下来的命令是应用相关命令
        sta_send_cmd55 : begin     
            if(res_en) begin                         // SD卡返回响应信号  
                if(res_data[47:40] == 8'h01)         // SD卡返回空闲状态
                    nex_sta = sta_send_acmd41;
                else
                    nex_sta = sta_send_cmd55;    
            end        
            else
                nex_sta = sta_send_cmd55;     
        end
        // 发送操作寄存器(OCR)内容  
        sta_send_acmd41 : begin                       
            if(res_en) begin                         // SD卡返回响应信号  
                if(res_data[47:40] == 8'h00)         // 初始化完成信号
                    nex_sta = sta_init_done;
                else
                    nex_sta = sta_send_cmd55;      // 初始化未完成,重新发起 
            end
            else
                nex_sta = sta_send_acmd41;     
        end
        // 初始化完成              
        sta_init_done : nex_sta = sta_init_done;    

        default : nex_sta = sta_idle;
    endcase
end

always @(posedge clk_250khz or negedge rst) begin
    if(!rst) begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1;
        sd_init_done <= 1'b0;
        cmd_bit_cnt <= 6'd0;
        over_time_cnt <= 16'd0;
        over_time_en <= 1'b0;
    end
    else begin
        over_time_en <= 1'b0;
        case(cur_sta)
            // 上电等待SD卡稳定
            sta_idle : begin                               
                sd_cs <= 1'b1;                            // 在等待上电稳定期间,sd_cs=1
                sd_mosi <= 1'b1;                          // sd_mosi=1
            end
            // 发送CMD0软件复位命令     
            sta_send_cmd0 : begin                          
                cmd_bit_cnt <= cmd_bit_cnt + 6'd1;        
                sd_cs <= 1'b0;                            
                sd_mosi <= CMD0[6'd47 - cmd_bit_cnt];     // 先发送CMD0命令高位
                if(cmd_bit_cnt == 6'd47)                  
                    cmd_bit_cnt <= 6'd0;                  
            end      
            //在接收CMD0响应返回期间,片选CS拉低,进入SPI模式                                     
            sta_wait_cmd0 : begin                          
                sd_mosi <= 1'b1;
                // SD卡返回响应信号             
                if(res_en)                                
                    sd_cs <= 1'b1;                          // 接收完成之后再拉高,进入SPI模式                                              
                over_time_cnt <= over_time_cnt + 1'b1;    // 超时计数器开始计数
                // SD卡响应超时,重新发送软件复位命令
                if(over_time_cnt == OVER_TIME - 1'b1)
                    over_time_en <= 1'b1; 
                if(over_time_en)
                    over_time_cnt <= 16'd0;                                        
            end
            sta_send_cmd8 : begin                          // 发送CMD8
                if(cmd_bit_cnt<=6'd47) begin
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= CMD8[6'd47 - cmd_bit_cnt]; // 先发送CMD8命令高位       
                end
                else begin
                    sd_mosi <= 1'b1;
                    // SD卡返回响应信号
                    if(res_en) begin                      
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0; 
                    end
                end                                                                   
            end 
            sta_send_cmd55 : begin                         // 发送CMD55
                if(cmd_bit_cnt<=6'd47) begin
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= CMD55[6'd47 - cmd_bit_cnt];       
                end
                else begin
                    sd_mosi <= 1'b1;
                    if(res_en) begin                      // SD卡返回响应信号
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0;     
                    end        
                end                                                                                    
            end
            sta_send_acmd41 : begin                        // 发送ACMD41
                if(cmd_bit_cnt <= 6'd47) begin
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= ACMD41[6'd47 - cmd_bit_cnt];      
                end
                else begin
                    sd_mosi <= 1'b1;
                    if(res_en) begin                       // SD卡返回响应信号
                        sd_cs <= 1'b1;
                        cmd_bit_cnt <= 6'd0;  
                    end        
                end     
            end
            sta_init_done : begin                          // 初始化完成
                sd_init_done <= 1'b1;
                sd_cs <= 1'b1;
                sd_mosi <= 1'b1;
            end
            default : begin
                sd_cs <= 1'b1;
                sd_mosi <= 1'b1;                
            end    
        endcase
    end
end

endmodule