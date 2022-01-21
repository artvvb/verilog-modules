`timescale 1ns/1ps
`default_nettype none

module uart_rx #(
    parameter integer clocks_per_bit = 100_000_000 / 9_600
) (
    input wire clk,
    input wire reset_i,
    input wire clock_enable_i,
    input wire rx_i,
    input wire m_ready_i,
    output wire m_valid_o,
    output wire [7:0] m_data_o
);
    wire bit_clock;
    wire [9:0] data;
    wire [9:0] next_data;
    wire start_bit_detect;
    wire stall;
    wire data_dropped; // debug signal

    counter #(
        .HIGH         (clocks_per_bit - 1)
    ) counter_inst (
        .clk          (clk),
        .sync_reset   (reset_i),
        .clock_enable (clock_enable_i),
        .enable       (1'b1),
        .count        (),
        .tc           (bit_clock)
        // assert tc once per bit
    );

    assign next_data = {data[8:0], rx_i};
    register #(
        .RESET_VALUE  (10'h3ff),
        .WIDTH        (10)
    ) shift_register_inst (
        .clk          (clk),
        .reset        (reset_i || start_bit_detect),
        .write_enable (bit_clock),
        .data_i       (next_data),
        .data_o       (data)
    );

    assign start_bit_detect = (data[9] == 0);
    assign stall = m_valid_o && ~m_ready_i;
    assign data_dropped = start_bit_detect && stall;

    register #(
        .WIDTH       (8),
        .RESET_VALUE (8'd0)
    ) output_data_register_inst (
        .clk          (clk),
        .reset        (reset_i),
        .write_enable (start_bit_detect && ~stall),
        .data_i       (data[1+:8]),
        .data_o       (m_data_o)
    );

    register #(
        .WIDTH       (1),
        .RESET_VALUE (1'd0)
    ) output_valid_register_inst (
        .clk          (clk),
        .reset        (reset_i),
        .write_enable (~stall),
        .data_i       (start_bit_detect),
        .data_o       (m_valid_o)
    );
endmodule