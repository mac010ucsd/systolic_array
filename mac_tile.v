// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s0, out_s1, in_w0, in_w1, out_e0, out_e1, in_n0, in_n1, inst_w, inst_e, reset);

parameter bw = 2;
parameter psum_bw = 11;

// dual psum output, dual 2bit input moving act, etc.
input  [psum_bw-1:0] in_n0;
input  [psum_bw-1:0] in_n1;

output [psum_bw-1:0] out_s0;
output [psum_bw-1:0] out_s1;

input  [bw-1:0] in_w0; 
input  [bw-1:0] in_w1; 

output [bw-1:0] out_e0; 
output [bw-1:0] out_e1; 

// 2 bit kernel loading instruction, 1 bit execution, 1 bit mode?
input  [3:0] inst_w;
output [3:0] inst_e;
// mode will always propagate, execution will always propagate,
// kernel loading depends.

input  clk;
input  reset;

reg [bw-1:0] a_q0;
reg [bw-1:0] a_q1;
reg [bw-1:0] b_q0;
reg [bw-1:0] b_q1;
reg [psum_bw-1:0] c_q0;
reg [psum_bw-1:0] c_q1;
reg [2:0] inst_q;
reg [1:0] load_ready_q;

wire [psum_bw-1:0] mac_output0;
wire [psum_bw-1:0] mac_output1;

assign out_e0[bw-1:0] = a_q0[bw-1:0];
assign out_e1[bw-1:0] = a_q1[bw-1:0];

assign inst_e[2:0] = inst_q[2:0];


// inst_e[0] = left or right reg

// inst_e[2] = mode
// inst_e[1] = exec
// inst_e[0] = weightload

/*
todo
assign out_s[psum_bw-1:0] = mac_output[psum_bw-1:0];
assign out_s[psum_bw-1:0] = mac_output[psum_bw-1:0];
*/

wire [10:0] big_psum;
assign big_psum = mac_output0 + (mac_output1 << 2);

// assign from big psum if STORED mode is 1 else just pull from mac output
assign out_s0 = inst_q[2] ? {1'b0, big_psum[7:0]} : mac_output0[psum_bw-1:0];
assign out_s1 = inst_q[2] ? {big_psum[10:8], 6'b0} : mac_output1[psum_bw-1:0];


mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance0 (
        .a(a_q0), 
        .b(b_q0),
        .c(c_q0),
	.out(mac_output0)
); 

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance1 (
        .a(a_q1), 
        .b(b_q1),
        .c(c_q1),
	.out(mac_output1)
); 

always@(posedge clk) begin
	
	if(reset==1'b1)	begin
		inst_q <= 0;
		load_ready_q <= 2'b11; //weight not loaded yet
	end

	else begin

		// weight loading portion

		inst_q[2:1] <= inst_w[2:1];	// each cycle forward the MODE bit and EXECUTE bit.

		c_q0[psum_bw-1:0] <= in_n0[psum_bw-1:0]; // psum from previous mac used as c in a*b +c
		c_q1[psum_bw-1:0] <= in_n1[psum_bw-1:0]; // psum from previous mac used as c in a*b +c

		if (inst_w[1:0] != 2'b00) // if we are executing or loading weights, move the data in
			a_q0<=in_w0;
			a_q1<=in_w1;
		if ((inst_w[2] == 1'b0) && (inst_w[0] == 1'b1)) begin // 0 mode = 2-bit mode, 
			if (load_ready_q[0]) begin
				b_q0 <= {in_w1, in_w0};
				load_ready_q[0] <= 1'b0;
			end
			else if (load_ready_q[1]) begin
				b_q1 <= {in_w1, in_w0};
				load_ready_q[1] <= 1'b0;
			end
		end
	 	if ((inst_w[2] == 1'b1) && (inst_w[0] == 1'b1) && (load_ready_q == 2'b11)) begin // 1 mode = 4bit mode, load weights into both simultaneously.
			b_q0<={in_w1, in_w0};
			b_q1<={in_w1, in_w0};
			load_ready_q <= 2'b00;
		end
		
		if(load_ready_q == 2'b00) begin //weight loaded then move kernel instruction
			inst_q[0] <= inst_w[0];
		end
	end
end

endmodule

