`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 14:35:24
// Design Name: 
// Module Name: display_seg
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


module display_seg(
    input       [3:0]   num     ,   // 需要显示的数字
    output reg  [7:0]   dig     ,   // 输出的数码管信号
    output      [7:0]   bit_ctrl    // 输出的数码管位控
    );

/**************************************************************   
参数定义
*************************************************************/ 
parameter D0 = 8'b1100_0000;
parameter D1 = 8'b1111_1001;
parameter D2 = 8'b1010_0100;
parameter D3 = 8'b1011_0000;
parameter D4 = 8'b1001_1001;
parameter D5 = 8'b1001_0010;
parameter D6 = 8'b1000_0010;
parameter D7 = 8'b1111_1000;
parameter D8 = 8'b1000_0000;
parameter D9 = 8'b1001_0000;
parameter DN = 8'b1111_1111;

// 位控(只显示一位)
assign bit_ctrl = 8'b1111_1110;

// 选择数码管信号
always @(num) begin
    case (num)
        4'd0:
            dig <= D0;
        4'd1:
            dig <= D1;
        4'd2:
            dig <= D2;
        4'd3:
            dig <= D3;
        4'd4:
            dig <= D4;
        4'd5:
            dig <= D5;
        4'd6:
            dig <= D6;
        4'd7:
            dig <= D7;
        4'd8:
            dig <= D8;
        4'd9:
            dig <= D9;
        default:
            dig <= DN;
    endcase
end

endmodule
