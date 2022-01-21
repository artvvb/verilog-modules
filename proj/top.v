`timescale 1ns / 1ps
module top (
    input wire clock,
    output wire led
);
    wire carry;

    counter #(
        .HIGH         (50_000_000 - 1)
    ) counter_inst (
        .clock        (clock),
        .clock_enable (1'b1),
        .sync_reset   (1'b0),
        .enable       (1'b1),
        .count        (),
        .tc           (carry)
    );

    register #(
        .RESET_VALUE  (0),
        .WIDTH        (1)
    ) register_inst (
        .clock        (clock),
        .reset        (1'b0),
        .write_enable (carry),
        .data_i       (~led),
        .data_o       (led)
    );
endmodule