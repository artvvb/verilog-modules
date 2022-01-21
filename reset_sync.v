`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/24/2020 12:07:01 PM
// Design Name: 
// Module Name: reset_sync
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


module sync (
    input wire clk,
    input wire din,
    output reg dout
);
    reg ff;
    always@(posedge clk) begin
        ff <= din;
        dout <= ff;
    end
endmodule
