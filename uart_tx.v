`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/08/2017 02:26:43 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx (clk, start, din, tx, busy, ready_flag);
    input wire clk;
    input wire start;
    input wire [7:0] din;
    output wire tx;
    output reg busy = 0;
    output reg ready_flag = 1; // ready_flag pulses high for one cycle, the cycles before busy goes low
    
    reg [9:0] data = 10'h3FF;
    reg [31:0] count;
    reg [3:0] bit_idx = 0;
    parameter CLOCK_FREQUENCY = 200000000;
    parameter BAUD_RATE = 9600;
    localparam TIMER_MAX = CLOCK_FREQUENCY/BAUD_RATE-1;//ceil(200MHz/9600baud)-1
    always@(posedge clk)
        if (busy == 0) begin
            if (start == 1) begin
                busy <= 1;
                data <= {1'b1, din, 1'b0};
                count <= 0;
                bit_idx <= 0;
            end
        end else begin
            if (count >= TIMER_MAX) begin
                count <= 0;
                if (bit_idx >= 9)
                    if (start == 1) begin
                        data <= {1'b1, din, 1'b0};
                        bit_idx <= 0;
                    end else
                        busy <= 0;
                else
                    bit_idx <= bit_idx + 1;
            end else
                count <= count + 1;
        end
        
    assign tx = data[bit_idx];
    always@*
        if (count >= TIMER_MAX && bit_idx == 9)
            ready_flag = 1;
        else
            ready_flag = 0;
endmodule
