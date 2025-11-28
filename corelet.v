/*
corelet.v is just a wrapper that includes all blocks you designed so far (L0/Input
FIFO, OFIFO, MAC Array, SFP?).    
*/

module corelet (clk, reset, in, out, inst, valid);
parameter bw = 2;
parameter b_bw = 4;
parameter psum_bw = 32;
parameter col = 8;
parameter row = 8;

input  clk, reset;
input [4:0] inst; // [wr][mode][exec][weightload]
input [row*bw*2-1:0] in; // from input sram
output [psum_bw*col-1:0] out; // to output sram
output valid;

wire l0_wr;
wire l0_rd;
wire exec;
wire weightload;
wire mode;

// wire ofifo_valid;

assign valid = ofifo_ready_delay_2;
reg ofifo_ready_delay_2;
always @(posedge clk) begin
    if (reset)
        ofifo_ready_delay_2 <= 0;
    else
        ofifo_ready_delay_2 <= ofifo_ready_delay;
end

assign l0_rd = inst[4];
assign l0_wr = inst[3];
assign mode = inst[2];
assign exec = inst[1];
assign weightload = inst[0];

/*
    input (from sram) -> input fifo -> mac array -> output fifo -> output
*/

reg [psum_bw*col-1:0] in_n;

wire [psum_bw*col-1:0] mac_out;
wire [bw*row*2-1:0] wire_a; // input fifo to mac array
wire [col-1:0] mac_valid; // mac array to output fifo

wire ofifo_rd;

always @(posedge clk) begin
    if (reset)
        in_n <= 0;
end

// l0 fifo l0 (clk, in, out, rd, wr, o_full, reset, o_ready);
// wr = write into l0 (from sram)
// rd = read from l0 (into mac)
// o_ready = l0 is ready to accept new data from sram
// why is there no o_valid??? it makes life easier
l0 #(.row(row), .bw(bw*2)) l0_instance (
    .clk(clk),
    .reset(reset),
    .in(in),            // connect to input sram
    .out(wire_a),       // connect to mac array
    .rd(l0_rd),          // 
    .wr(l0_wr),          // connect to input sram
    .o_full(),          // not needed
    .o_ready());        // not needed

// mode must be externally given
// RD from input fifo when exec|weightload|other??
// inst_w[2:0] : [mode][exec][weightload]
mac_array #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_instance (
    .clk(clk),
    .reset(reset),
    .out_s(mac_out),// connect to ofifo
    .in_w(wire_a),  // connect to input fifo
    .in_n(in_n),        // connect to persistent 0?
    .inst_w({mode, exec, weightload}),      // connect to input fifo
    .valid(mac_valid));

// delay mac_out by 1 cycle
/*
reg [psum_bw*col-1:0] mac_out_delay;
always @(posedge clk) begin
    if (reset)
        mac_out_delay <= 0;
    else
        mac_out_delay <= mac_out;
end
*/

// wr = write into ofifo (from mac array)
// rd = read from ofifo (into sram)
// ofifo (clk, in, out, rd, wr, o_full, reset, o_ready, o_valid);


reg [col-1:0] mac_out_ready;
always @(posedge clk) begin
    if (reset)
        mac_out_ready <= 0;
    else
        mac_out_ready <= mac_valid;
end


reg ofifo_ready_delay;
always @(posedge clk) begin
    if (reset)
        ofifo_ready_delay <= 0;
    else
        ofifo_ready_delay <= ofifo_rd;
end

ofifo #(.col(col), .bw(psum_bw)) ofifo_instance (
    .clk(clk),
    .reset(reset),
    .in(mac_out),      // connect to mac array
    .out(out), // connect to sram
    .rd(ofifo_ready_delay),   // ofifo_rd       // can start reading the moment o_valid is high
    .wr(mac_out_ready),      // connect to mac array
    .o_full(),      // not needed
    .o_ready(),     // not needed
    .o_valid(ofifo_rd));    // valid if ALL col have output (1 whole row). but this is already checked in ofifo?

// ignore sfu for now.
// ofifo ready needs to be delayed...

endmodule