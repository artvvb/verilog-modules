`timescale 1ns / 1ps

module bram #(parameter integer WIDTH=8, parameter integer DEPTH=256) (
    input wire clk,
    input wire areset,
    input wire wen,
    input wire [$clog2(DEPTH)-1:0] waddr,
    input wire [WIDTH-1:0] wdata,
    input wire [$clog2(DEPTH)-1:0] raddr,
    output reg [WIDTH-1:0] rdata
);
    reg [WIDTH-1:0] mem [DEPTH-1:0];
    always@(posedge clk, posedge areset) begin
        if (areset) begin
            rdata <= 0;
        end else begin
            rdata <= mem[raddr];
            if (wen) begin
                mem[waddr] <= wdata;
            end
        end
    end
endmodule
