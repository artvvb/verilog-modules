`timescale 1ns/1ps
`default_nettype none

// axi_stream_width_converter #(
//     .INPUT_WIDTH  (),
//     .OUTPUT_WIDTH ()
// ) eight_to_one_bit_converter_inst (
//     .clk          (),
//     .reset        (),
//     .s_valid_i    (),
//     .s_data_i     (),
//     .s_ready_o    (),
//     .m_ready_i    (),
//     .m_valid_o    (),
//     .m_data_o     ()
// );

module axi_stream_width_converter #(
    parameter INPUT_WIDTH = 8,
    parameter OUTPUT_WIDTH = 1,
    parameter MSB_FIRST = 1 // endianness, which direction to shift out the data
) (
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    s_valid_i,
    input  wire [INPUT_WIDTH-1:0]  s_data_i,
    output wire                    s_ready_o,
    input  wire                    m_ready_i,
    output wire                    m_valid_o,
    output wire [OUTPUT_WIDTH-1:0] m_data_o
);
    // only supports the following case:
    //      INPUT_WIDTH > OUTPUT_WIDTH and INPUT_WIDTH % OUTPUT_WIDTH == 0

    localparam COUNT_HIGH = INPUT_WIDTH / OUTPUT_WIDTH - 1;

    wire [$clog2(COUNT_HIGH)-1:0] count;
    wire rollover;

    counter #(
        .HIGH         (COUNT_HIGH)
    ) counter_inst (
        .clk          (clk),
        .clock_enable (1'b1),
        .sync_reset   (1'b0),
        .enable       (m_valid_o && m_ready_i),
        .count        (count),
        .tc           (rollover)
    );

    reg valid_next;

    always @(*) begin : valid_next_proc
        if (m_valid_o) begin
            if (rollover && m_ready_i) begin
                // last beat of the packet is being sent
                valid_next = 0;
            end else begin
                // either a beat is not being sent or there is another beat to follow it
                valid_next = 1;
            end
        end else begin
            if (s_valid_i && s_ready_o) begin
                // loading some new data
                valid_next = 1;
            end else begin
                // ready for new data but there isn't any
                valid_next = 0;
            end
        end
    end

    wire shift_register_loaded;
    register #(
        .RESET_VALUE  (1'b0),
        .WIDTH        (1)
    ) load_register_inst (
        .clk          (clk),
        .reset        (reset),
        .write_enable (1'b1),
        .data_i       (valid_next),
        .data_o       (shift_register_loaded)
    );

    assign s_ready_o = ~shift_register_loaded;
    assign m_valid_o = shift_register_loaded;

    wire [INPUT_WIDTH-1:0] data;
    wire [INPUT_WIDTH-1:0] next_data;
    wire [INPUT_WIDTH-1:0] shifted_data;

    assign next_data = (s_valid_i && s_ready_o) ? s_data_i : shifted_data;

    register #(
        .RESET_VALUE  ('b0),
        .WIDTH        (INPUT_WIDTH)
    ) shift_register_inst (
        .clk          (clk),
        .reset        (reset),
        .write_enable ((s_valid_i && s_ready_o) || (m_valid_o && m_ready_i)),
        .data_i       (next_data),
        .data_o       (data)
    );
    generate
        if (MSB_FIRST) begin
            // not tested
            assign shifted_data = { data[INPUT_WIDTH-OUTPUT_WIDTH-1:0], {OUTPUT_WIDTH{1'bz}} };
            assign m_data_o = data[INPUT_WIDTH-1:INPUT_WIDTH-OUTPUT_WIDTH];
        end else begin
            assign shifted_data = { {OUTPUT_WIDTH{1'bz}}, data[INPUT_WIDTH-1:OUTPUT_WIDTH] };
            assign m_data_o = data[0+:OUTPUT_WIDTH];
        end
    endgenerate
endmodule