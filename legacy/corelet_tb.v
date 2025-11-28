module corelet_tb;

parameter bw = 2;
parameter b_bw = 4;
parameter psum_bw = 32;
parameter col = 2;
parameter row = 2;

reg clk, reset;
reg [4:0] inst;             // [l0rd][wr][mode][exec][weightload]
reg [row*bw*2-1:0] in; 
wire [psum_bw*col-1:0] out;
wire valid;

corelet #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw), .col(col), .row(row)) corelet_instance (
    .clk(clk),
    .reset(reset),
    .in(in),            
    .out(out),      
    .inst(inst),
    .valid(valid)
);

initial begin
    clk = 0;
    forever #1 clk = ~clk;
end

integer i;

integer j;

reg valid_reg;
reg [col-1:0][psum_bw-1:0] out_display;
always @(negedge clk) begin
    out_display <= out;
    valid_reg <= valid;
end

always @(posedge clk) begin
    $display("psum outputs:");
    for (j = 0; j < col; j = j + 1) begin
        $display("out_s[%0d]: %b, %0d", j, valid_reg, $signed(out_display[j]));
    end
    $display("-----------------------");
end;

initial begin 
    $dumpfile("corelet_tb.vcd");
    $dumpvars(0, corelet_tb);
    // Initialize inputs
    reset = 1;
    in = 0;
    inst = 5'b0000;
    #4;
    reset = 0;
    // Load weights
    // testing in 4-bit mode first
    /*
        want to load in weights (in mac) :
        [ 1 -1 ]
        [ 1 -1 ]

        then in sram:
        [ 1  1 ]
        [-1 -1 ]
    */
    in = {4'b10,  4'b1};

    inst = 5'b01100; // must write 1 entry first [rd bit may be 1 or 0], CANNOT load weight or execute yet.
    #2
    inst = 5'b11101; // start reading and writing and executing at same time
    in = {4'b100, 4'b11}; // -1
    #2
    #2
    #8
    // at this point, weights should be fully loaded.


    in = {4'b0001, 4'b0001};
    #2;
    // load acts and execute
    inst = 5'b01100; // write one entry first 
    in = {4'b0011, 4'b0011};
    #2;

    // pass in activations of 0 to 15 sequentially
    inst = 5'b11110; // read, write, execut
    for (i = 1; i < 16; i = i + 1) begin
        in = {i | (i << 4)};
        #2;
    end

    inst = 5'b00100; // read, write, execut

    // check if weights are loaded properly before continue
    #24;
    $finish;

end


endmodule