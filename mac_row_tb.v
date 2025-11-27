module mac_tile_tb;

parameter bw = 2;
parameter psum_bw = 9;

// send reset signal to mac_tile

reg clk;
reg reset;
reg [psum_bw-1:0] in_n0;
reg [psum_bw-1:0] in_n1;
reg [bw-1:0] in_w0;
reg [bw-1:0] in_w1;
reg [2:0] inst_w;
wire [psum_bw-1:0] out_s0;
wire [psum_bw-1:0] out_s1;
wire [bw-1:0] out_e0;
wire [bw-1:0] out_e1;
wire [2:0] inst_e;
mac_tile #(bw, psum_bw) uut (
    .clk(clk),
    .out_s0(out_s0),
    .out_s1(out_s1),
    .in_w0(in_w0),
    .in_w1(in_w1),
    .out_e0(out_e0),
    .out_e1(out_e1),
    .in_n0(in_n0),
    .in_n1(in_n1),
    .inst_w(inst_w),
    .inst_e(inst_e),
    .reset(reset)
);
// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 time units clock period
end

// Testbench procedure
initial begin

    $dumpfile("mac_tile_tb.vcd");
    $dumpvars(0, mac_tile_tb);
    // Initialize inputs
    reset = 1;
    in_n0 = 0;
    in_n1 = 0;
    in_w0 = 0;
    in_w1 = 0;
    inst_w = 0;

    #10;
    reset = 0;

    // CASE 1 : 2-bit mode operation
    // Load weight for 2-bit mode
    inst_w = 3'b001; // mode=0, exec=0, weightload=1
    
    // weight 0 value: 1001 = -7
    in_w0 = 2'b01; // weight 0, 0
    in_w1 = 2'b10; // weight 0, 1
    
    #10; // Wait for one clock cycle

    inst_w = 3'b001; // mode=0, exec=0, weightload=1
    
    // weight 1 value: 0111 = 7
    in_w0 = 2'b11; // weight 1, 0
    in_w1 = 2'b01; // weight 1, 1

    #10; // Wait for one clock cycle

    // Execute MAC operation
    inst_w = 3'b010; // mode=0, exec=1, weightload=0
    in_w0 = 2'b10; 
    in_w1 = 2'b10;

    in_n0 = 9'b0; // psum input
    in_n1 = 9'b0; // psum input
    // expected output: -7*2+0=-14 , 7*2+0=14

    #10; // Wait for one clock cycle
    inst_w = 3'b010; // mode=0, exec=1, weightload=0
    in_w0 = 2'b11; 
    in_w1 = 2'b00;

    in_n0 = 9'd21; // psum input
    in_n1 = 9'd50; // psum input
    // expected output: -7*3+21=0 , 7*0+50=50

    #10; // Wait for one clock cycle
    inst_w = 3'b010; // mode=0, exec=1, weightload=0
    in_w0 = 2'b01; 
    in_w1 = 2'b11;

    in_n0 = 9'b0; // psum input
    in_n1 = 9'b100111111; // psum input
    // expected output: -7*1+0=-7 , 7*3+(-193)=-172

    #10; // Wait for one clock cycle
    inst_w = 3'b000; // dummy cycle
    in_w0 = 2'b01; 
    in_w1 = 2'b11;

    in_n0 = 9'b0; // psum input
    in_n1 = 9'b100111111; // psum input
    // expect no output change

    #10; 
    reset = 1; // reset before next test case

    // CASE 2 : 4-bit mode operation

    #10;
    reset = 0;

    // Load weight for 4-bit mode
    inst_w = 3'b101; // mode=1, exec=0, weightload=1
    // weight value: 1110 = -2
    in_w0 = 2'b10; // weight 0
    in_w1 = 2'b11; // weight 1

    #10; // Wait for one clock cycle
    // mac operation
    inst_w = 3'b110; // mode=1, exec=1, weightload=0
    // act value: 0111 = 7
    in_w0 = 2'b11;
    in_w1 = 2'b01;
    in_n0 = 9'b0; // psum input
    in_n1 = 9'b0; // psum input
    // mac_output0 = -2*3=-6 = 9'b111111010 
    // mac_output1 = -2*1=-2 = 9'b111111110 
    /*
      11111111010
    + 11111111000

    */
    // expected output: out_s0 = -2*7+0=-14, out_s1 = 0

    #10; // Wait for one clock cycle
    inst_w = 3'b110; // mode=1, exec=1, weightload=0
    // act_value = 1001 = 9 (unsigned)
    in_w0 = 2'b01;
    in_w1 = 2'b10;
    // in_psum = {513=11'b01000000001}
    // split into two parts for the inputs

    in_n0 = {1'b0, 8'b00000001}; // psum input = 243, 243+(1*-7) = 236
    in_n1 = {3'b010, 6'b0}; // psum input = 16 << 2 = 64
    // expected output: 495 = 00111101111

    #20;
    
    $finish;
end

endmodule