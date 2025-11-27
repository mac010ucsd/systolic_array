module mac_array_tb;

parameter bw = 2;
parameter b_bw = 4;
parameter psum_bw = 32;
parameter col = 2;
parameter row = 2;


reg clk;
reg reset;

// (clk, reset, out_s, in_w, in_n, inst_w, valid);
// inputs
reg [row*bw*2-1:0] in_w;
reg [psum_bw*col-1:0] in_n;
reg [2:0] inst_w;

// outputs
wire [psum_bw*col-1:0] out_s;
wire [col-1:0] valid;

mac_array #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw), .col(col), .row(row)) uut (
    .clk(clk),
    .out_s(out_s),
    .in_w(in_w),
    .in_n(in_n),
    .inst_w(inst_w),
    .valid(valid),
    .reset(reset)
);

reg [col-1:0] valid_reg;
reg [col-1:0][psum_bw-1:0] out_display;

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 time units clock period
end

integer j;

always @(negedge clk) begin
    out_display <= out_s;
    valid_reg <= valid;
end

always @(posedge clk) begin
    $display("psum outputs:");
    for (j = 0; j < col; j = j + 1) begin
        $display("out_s[%0d]: %b %0d", j, valid_reg[j], $signed(out_display[j]));
    end
    $display("-----------------------");
end;

integer i;

// Testbench procedure
initial begin

    $dumpfile("mac_array_tb.vcd");
    $dumpvars(0, mac_array_tb);
    // Initialize inputs

    reset = 1;
    in_n = 0;
    in_w = 0;
    inst_w = 0;
    #10;
    reset = 0;

    // CASE 1 : 2-bit mode operation
    // Load weight for 2-bit mode. Repeat 4 times (two for each column) for 4 columns
    // start weight loading for next row after one cycle?
    // or can't we load weight for both rows at the same time?

    inst_w = 3'b001; // mode=0, exec=0, weight

    #10

    in_w = {4'b0, 4'b0111}; // weights for row0 top half, row1 top half
    #10;

    in_w = {4'b0101, 4'b0110}; // weights for row0 low half, row1 low half
    #10;

    in_w = {4'b0100, 4'b1011}; 
    #10;

    in_w = {4'b1001, 4'b1010}; 
    #10;

    in_w = {4'b1000, 4'b0}; 
    #10;


    /* weights should look like:
    7           -5
        6           -6

    5           -7  
        4           -8
    */

    // test unit for 1 input timestep
    
    // should take 1 extra cycle to load in
    #10;

    // all weights are loaded, begin mac operations
    inst_w = 3'b010; // mode=0, exec=1, weightload=0

    #10;
    // want to leave inst_w for the length of NIJ cycles. in this case NIJ=1
    inst_w = 3'b000;

    in_w = {4'b0, 4'b1111};
    #10;

    in_w = {4'b1111, 4'b0000};
    #10;

    // works fine in 2-bit mode.

    // 4-bit mode test

    #20;

    reset = 1;
    #10
    reset = 0;
    inst_w = 3'b101; // mode=1, exec=0, weightload=1
    #10;

    in_w = {4'b0, 4'b0111};
    #10;
    in_w = {4'b0101, 4'b1011};
    #10;
    in_w = {4'b1001, 4'b0};
    inst_w = 3'b110;

    #10;

    inst_w = 3'b100;
    in_w = {4'b0, 4'b1111};
    #10;

    in_w = {4'b1111, 4'b0000};
    #10;

    #20;
    // expected psum = (5+7)*(15) = 180, -180
    // works!!!

    $finish;
end

endmodule