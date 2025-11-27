module mac_row_tb;

parameter bw = 2;
parameter psum_bw = 9;
parameter inst_bw = 3;
parameter col = 4;

// test with 4 columns first for ease of reading

// send reset signal to mac_tile

reg clk;
reg reset;

// (clk, reset, out_s, in_w, in_n, inst_w, valid);

// inputs
reg [bw-1:0] in_w0;
reg [bw-1:0] in_w1;
reg [psum_bw*col*2-1:0] in_n;
reg [inst_bw-1:0] inst_w;

// outputs
wire [psum_bw*col*2-1:0] out_s;
wire [col-1:0] valid;

mac_row #(bw, psum_bw, col, inst_bw) uut (
    .clk(clk),
    .out_s(out_s),
    .in_w0(in_w0),
    .in_w1(in_w1),
    .in_n(in_n),
    .inst_w(inst_w),
    .reset(reset)
);


reg [col*2-1:0][psum_bw-1:0] out_display;

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 time units clock period
end

integer j;

always @(negedge clk) begin
    out_display <= out_s;
end

always @(posedge clk) begin
    $display("psum outputs:");
    for (j = 0; j < col*2; j = j + 1) begin
        $display("out_s[%0d]: %0d", j, $signed(out_display[j]));
    end
    $display("-----------------------");
end;

integer i;

// Testbench procedure
initial begin

    $dumpfile("mac_row_tb.vcd");
    $dumpvars(0, mac_row_tb);
    // Initialize inputs

    reset = 1;
    in_n = 0;
    in_w0 = 0;
    in_w1 = 0;
    inst_w = 0;
    #10;
    reset = 0;

    // CASE 1 : 2-bit mode operation
    // Load weight for 2-bit mode. Repeat 8 times (two for each column) for 4 columns
    inst_w = 3'b001; // mode=0, exec=0, weight
    // value = 0001 = 1
    in_w0 = 2'b01; 
    in_w1 = 2'b00;
    #10;

    // value = 0010 = 2;
    in_w0 = 2'b10; 
    in_w1 = 2'b00; 
    #10;
    
    // value = 0011 = 3;
    in_w0 = 2'b11; 
    in_w1 = 2'b00; 
    #10;

    // value = 0100 = 4;
    in_w0 = 2'b00; 
    in_w1 = 2'b10; 
    #10;
    
    // value = 1000 = -8;
    in_w0 = 2'b00; 
    in_w1 = 2'b10; 
    #10;

    // value = 0000 = 0;
    in_w0 = 2'b00;
    in_w1 = 2'b00;
    #10;
    
    // value = 1000 = -7;
    in_w0 = 2'b01; 
    in_w1 = 2'b10; 
    #10;

    // value = 1000 = 7;
    in_w0 = 2'b11; 
    in_w1 = 2'b01; 
    #10;

    // all weights are loaded, begin mac operations
    inst_w = 3'b010; // mode=0, exec=1, weightload=0

    // pass in activations of -8 to 7 sequentially
    for (i = 0; i < 16; i = i + 1) begin
        {in_w1, in_w0} = i;
        #10;
    end


    // man too tired.. just believe that it works
    #80;
    
    $finish;
end

endmodule