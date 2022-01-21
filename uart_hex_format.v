`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2017 01:09:09 PM
// Design Name: 
// Module Name: uart_hex_format
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


module uart_hex_format(clk, start, din, tx);
    parameter CLOCK_FREQUENCY = 200000000;
    parameter BAUD_RATE = 9600;
    parameter FORMAT_SLOTS = 2;
    parameter FORMAT_STR_LEN = 22;
    parameter FORMAT_STR_LEN_LOG2 = 5;
    parameter FORMAT_STRING = "Button R\1C\2 Pressed!\r\n";
    input wire clk;
    input wire start;
    input wire [4*FORMAT_SLOTS-1:0] din;
    output wire tx;
    
    reg tx_start = 0;
    reg [7:0] tx_din;
    wire tx_busy, tx_ready_flag;
    uart_tx #(
        .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE)
    ) m_uart_tx (
        .clk(clk),
        .start(tx_start),
        .din(tx_din),
        .tx(tx),
        .busy(tx_busy),
        .ready_flag(tx_ready_flag)
    );
    
    localparam S_IDLE = 0, S_TX_BUSY = 1, S_BUSY = 2;
    reg [1:0] state = S_IDLE;
    
//    reg [FORMAT_STR_LEN*8-1:0] str;
    reg [3:0] format [FORMAT_SLOTS-1:0];
    reg [FORMAT_STR_LEN_LOG2+3-1:0] idx = 0;
    
    genvar i;
    generate for (i=0; i<FORMAT_SLOTS; i=i+1) begin : FORMAT_IDX
    always@(posedge clk)
        if (state == S_IDLE && start == 1)
            format[i] <= din[4*i+3:4*i];
    end endgenerate
    
    always@(posedge clk)
        if (state == S_IDLE) begin
            if (start == 1) begin
                state <= S_TX_BUSY;
                idx <= {FORMAT_STR_LEN-1, 3'b0};
                //set format
            end
        end else if (state == S_TX_BUSY) begin
            if (tx_busy == 0) begin
                //assert tx_start
                state <= S_BUSY;
            end
        end else if (state == S_BUSY) begin
            if (tx_ready_flag == 1) begin
                if (idx == 0) begin
                    state <= S_IDLE;
                end else begin
                    //assert tx_start
                    idx <= idx - 8;
                end
            end
        end else
            state <= S_IDLE;
        
    always@(posedge clk)
        if (state == S_TX_BUSY && tx_busy == 0)
            tx_start <= 1;
        else if (state == S_BUSY && tx_ready_flag == 1 && idx > 0)
            tx_start <= 1;
        else
            tx_start <= 0;

    reg [7:0] ch_tmp;                
    always@* begin
        ch_tmp = 8'hFF & (FORMAT_STRING >> idx);
        if (ch_tmp <= FORMAT_SLOTS)
            tx_din = (format[ch_tmp-1] < 10) ? "0" + format[ch_tmp-1] : "A" + format[ch_tmp-1] - 10; // hex2ascii
        else
            tx_din = 8'hFF & (FORMAT_STRING >> idx);
    end
endmodule
