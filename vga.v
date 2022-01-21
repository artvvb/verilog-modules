`timescale 1ns/1ps
`default_nettype none

// vga #(
//     .RED_BITS         (),
//     .GREEN_BITS       (),
//     .BLUE_BITS        (),
//     .X_DISPLAY        (),
//     .X_FRONT_PORCH    (),
//     .X_SYNC           (),
//     .X_BACK_PORCH     (),
//     .Y_DISPLAY        (),
//     .Y_FRONT_PORCH    (),
//     .Y_SYNC           (),
//     .Y_BACK_PORCH     ()
// ) vga_inst (
//     .clock            (),
//     .reset            (),
//     .enable           (),
//     .rgb_ready_o      (),
//     .rgb_valid_i      (),
//     .rgb_data_red_i   (),
//     .rgb_data_green_i (),
//     .rgb_data_blue_i  (),
//     .rgb_last_i       (),
//     .vga_red_o        (),
//     .vga_green_o      (),
//     .vga_blue_o       (),
//     .vga_hsync_o      (),
//     .vga_vsync_o      (),
//     .sync_error       (),
//     .in_display_area  ()
// );

module vga #(
    parameter integer RED_BITS      = 4,
    parameter integer GREEN_BITS    = 4,
    parameter integer BLUE_BITS     = 4,
    parameter integer X_DISPLAY     = 10,
    parameter integer X_FRONT_PORCH = 2,
    parameter integer X_SYNC        = 2,
    parameter integer X_BACK_PORCH  = 2,
    parameter integer Y_DISPLAY     = 10,
    parameter integer Y_FRONT_PORCH = 2,
    parameter integer Y_SYNC        = 2,
    parameter integer Y_BACK_PORCH  = 2
) (
    input  wire                  clock,
    input  wire                  reset,
    input  wire                  enable, // ~programming_done
    
    output wire                  rgb_ready_o,
    input  wire                  rgb_valid_i,
    input  wire [RED_BITS-1:0]   rgb_data_red_i,
    input  wire [GREEN_BITS-1:0] rgb_data_green_i,
    input  wire [BLUE_BITS-1:0]  rgb_data_blue_i,
    input  wire                  rgb_last_i,

    output wire [RED_BITS-1:0]   vga_red_o,
    output wire [GREEN_BITS-1:0] vga_green_o,
    output wire [BLUE_BITS-1:0]  vga_blue_o,
    output wire                  vga_hsync_o,
    output wire                  vga_vsync_o,

    // debug signals
    output wire                  sync_error_o,
    output wire                  in_display_area_o,
    output wire                  end_of_frame_o
);

    localparam integer X_DISPLAY_HIGH     = X_DISPLAY - 1;
    localparam integer X_FRONT_PORCH_HIGH = X_DISPLAY_HIGH + X_FRONT_PORCH;
    localparam integer X_SYNC_HIGH        = X_FRONT_PORCH_HIGH + X_SYNC;
    localparam integer X_BACK_PORCH_HIGH  = X_SYNC_HIGH + X_BACK_PORCH;
    localparam integer X_COUNT_HIGH       = X_BACK_PORCH_HIGH;

    localparam integer Y_DISPLAY_HIGH     = Y_DISPLAY - 1;
    localparam integer Y_FRONT_PORCH_HIGH = Y_DISPLAY_HIGH + Y_FRONT_PORCH;
    localparam integer Y_SYNC_HIGH        = Y_FRONT_PORCH_HIGH + Y_SYNC;
    localparam integer Y_BACK_PORCH_HIGH  = Y_SYNC_HIGH + Y_BACK_PORCH;
    localparam integer Y_COUNT_HIGH       = Y_BACK_PORCH_HIGH;
    // instantiate my own X/Y counter synced to rgb_last to generate rgb_ready and the sync pulses

    wire [$clog2(X_COUNT_HIGH)-1:0] x_count;
    wire [$clog2(Y_COUNT_HIGH)-1:0] y_count;
    wire rollover;
    reg hsync;
    reg vsync;
    reg in_display_area;
    reg end_of_frame;

    register #(
        .RESET_VALUE  (0),
        .WIDTH        (RED_BITS)
    ) red_register_inst (
        .clk          (clock),
        .reset        (reset),
        .write_enable (rgb_ready_o && rgb_valid_i),
        .data_i       (rgb_data_red_i),
        .data_o       (vga_red_o)
    );

    register #(
        .RESET_VALUE  (0),
        .WIDTH        (GREEN_BITS)
    ) green_register_inst (
        .clk          (clock),
        .reset        (reset),
        .write_enable (rgb_ready_o && rgb_valid_i),
        .data_i       (rgb_data_green_i),
        .data_o       (vga_green_o)
    );

    register #(
        .RESET_VALUE  (0),
        .WIDTH        (BLUE_BITS)
    ) blue_register_inst (
        .clk          (clock),
        .reset        (reset),
        .write_enable (rgb_ready_o && rgb_valid_i),
        .data_i       (rgb_data_blue_i),
        .data_o       (vga_blue_o)
    );

    double_counter #(
        .X_HIGH         (X_COUNT_HIGH),
        .Y_HIGH         (Y_COUNT_HIGH)
    ) xy_counter_inst (
        .clk            (clock),
        .clock_enable_i (enable),
        .sync_reset_i   (reset),
        .enable_i       (rgb_valid_i),
        .x_o            (x_count),
        .y_o            (y_count),
        .tc_o           (rollover)
    );

    always @(*) begin : hsync_generation_proc
        if (x_count > X_FRONT_PORCH_HIGH && x_count <= X_SYNC_HIGH) begin
            hsync = 1'b0;
        end else begin
            hsync = 1'b1;
        end
    end

    always @(*) begin : vsync_generation_proc
        if (y_count > Y_FRONT_PORCH_HIGH && y_count <= Y_SYNC_HIGH) begin
            vsync = 1'b0;
        end else begin
            vsync = 1'b1;
        end
    end

    register #(
        .RESET_VALUE  (1),
        .WIDTH        (1)
    ) hsync_register_inst (
        .clk          (clock),
        .reset        (reset),
        .write_enable (enable),
        .data_i       (hsync),
        .data_o       (vga_hsync_o)
    );

    register #(
        .RESET_VALUE  (1),
        .WIDTH        (1)
    ) vsync_register_inst (
        .clk          (clock),
        .reset        (reset),
        .write_enable (enable),
        .data_i       (vsync),
        .data_o       (vga_vsync_o)
    );

    register #(
        .RESET_VALUE  (0),
        .WIDTH        (1)
    ) in_display_area_register_inst (
        .clk          (clock),
        .reset        (reset),
        .write_enable (enable),
        .data_i       (in_display_area),
        .data_o       (in_display_area_o)
    );
    

    always @(*) begin : in_display_area_proc
        if (x_count <= X_DISPLAY_HIGH && y_count <= Y_DISPLAY_HIGH) begin
            in_display_area = 1'b1;
        end else begin
            in_display_area = 1'b0;
        end
    end

    always @(*) begin : end_of_frame_proc
        if (rollover) begin
            end_of_frame = 1'b1;
        end else begin
            end_of_frame = 1'b0;
        end
    end

    assign rgb_ready_o = in_display_area & enable; // consider registering this?
    assign end_of_frame_o = end_of_frame;

    wire last_beat_was_last;
    wire first_rgb_beat; // sync reset for counter?
    
    register #(
        .RESET_VALUE  (0),
        .WIDTH        (1)
    ) last_register_inst (
        .clk          (clock),
        .reset        (reset),
        .write_enable (rgb_ready_o && rgb_valid_i),
        .data_i       (rgb_last_i),
        .data_o       (last_beat_was_last)
    );
    
    // register #(
    //     .RESET_VALUE  (0),
    //     .WIDTH        (1)
    // ) end_of_frame_register_inst (
    //     .clk          (clock),
    //     .reset        (reset),
    //     .write_enable (rgb_ready_o && rgb_valid_i),
    //     .data_i       (end_of_frame),
    //     .data_o       (end_of_frame_o)
    // );

    assign first_rgb_beat = rgb_ready_o && rgb_valid_i && ~last_beat_was_last;

    assign sync_error_o = (rgb_ready_o && rgb_valid_i && last_beat_was_last) ? (x_count != X_DISPLAY_HIGH || y_count != Y_DISPLAY_HIGH) : (1'b0);
endmodule