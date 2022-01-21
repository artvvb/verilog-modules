`default_nettype none
`timescale 1ns/1ps

// debouncer #(
//     NOISE_PERIOD (),
//     RESET_VALUE  ()
// ) (
//     .clock       (),
//     .reset       (),
//     .enable      (),
//     .data_i      (),
//     .data_o      ()
// );

module debouncer #(
    parameter integer NOISE_PERIOD = 256,
    parameter RESET_VALUE = 0
) (
    input wire clock,
    input wire reset,
    input wire enable,
    input wire data_i,
    output wire data_o
);
    localparam C_STATE_BITS = 1;
    localparam STATE_IDLE = 0;
    localparam STATE_CHANGING = 1;

    wire state;
    wire data;
    wire rollover;
    reg next_state;

    always @(*) begin
        if (state == STATE_CHANGING) begin
            if (rollover || data == data_i) begin
                next_state = STATE_IDLE;
            end else begin
                next_state = state;
            end
        end else begin
            if (data != data_i) begin
                next_state = STATE_CHANGING;
            end else begin
                next_state = state;
            end
        end
    end

    wire counter_reset = (state == STATE_IDLE);
    wire counter_enable = (state == STATE_CHANGING);
    wire data_write_enable = (state == STATE_CHANGING && next_state == STATE_IDLE);
    register #(
        .RESET_VALUE  (STATE_IDLE),
        .WIDTH        (C_STATE_BITS)
    ) state_register_inst (
        .clock        (clock),
        .reset        (reset),
        .write_enable (enable),
        .data_i       (),
        .data_o       (state)
    );

    counter #(
        .HIGH         (NOISE_PERIOD-1)
    ) counter_inst (
        .clock        (clock),
        .clock_enable (enable),
        .sync_reset   (reset || counter_reset),
        .enable       (counter_enable),
        .count        (),
        .tc           (rollover)
    );

    register #(
        .RESET_VALUE  (RESET_VALUE),
        .WIDTH        (1)
    ) data_register_inst (
        .clock        (clock),
        .reset        (reset),
        .write_enable (enable && data_write_enable),
        .data_i       (data_i),
        .data_o       (data)
    );
endmodule