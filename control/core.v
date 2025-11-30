module core (
	clk, reset, inst, ofifo_valid, D_xmem, sfp_out, mode, sel
);

// core holds 1 sram per act file (nij x rows), 1 (input) sram per weights file (rows x cols), 
// 1 corelet (rows x cols), 2 output sram (cols x nij?)

/*
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
	.D_xmem(D_xmem_q), 
	.sfp_out(sfp_out), 
	.reset(reset)); 
*/

input clk, reset;
input [33:0] inst;
output ofifo_valid;
input [b_bw*row-1:0] D_xmem;
output [psum_bw*col-1:0] sfp_out;
input mode; // 0: 2-bit mode, 1: 4-bit mode
input sel; // output sram selector.

parameter bw = 2;
parameter b_bw = 4;
parameter psum_bw = 16;
parameter col = 2;
parameter row = 2;

/*
assign inst_q[33] = acc_q;              accumulate mode, unimplemented so far.
assign inst_q[32] = CEN_pmem_q;         pmem cen (low active, will not read/write when high)
assign inst_q[31] = WEN_pmem_q;         pmem wen (low active)
assign inst_q[30:20] = A_pmem_q;        pmem address
assign inst_q[19]   = CEN_xmem_q;       xmem cen (low active, will not read/write when high)
assign inst_q[18]   = WEN_xmem_q;       xmem wen (low active)
assign inst_q[17:7] = A_xmem_q;         xmem address
assign inst_q[6]   = ofifo_rd_q;        ofifo read enable (ofifo -> sram)
assign inst_q[5]   = ififo_wr_q;        ififo write enable? ignore
assign inst_q[4]   = ififo_rd_q;        ififo rd enable? ignore
	CHANGE inst_q[4] = SEL (SELECT SRAM OUTPUT BANK)
assign inst_q[3]   = l0_rd_q;           l0 read enable
assign inst_q[2]   = l0_wr_q;           l0 write enable
assign inst_q[1]   = execute_q;         load and execute activations
assign inst_q[0]   = load_q;            load weights
*/
reg acc_q;
reg cen_pmem_q;
reg wen_pmem_q;
reg [10:0] a_pmem_q;
reg cen_xmem_q;
reg wen_xmem_q;
reg [10:0] a_xmem_q;
reg ofifo_rd_q;
reg [4:0] inst_corelet_q;
reg sel_q;

reg [31:0] D_xmem_q;
// no ififo

always @(posedge clk) begin
	if (reset) begin
		acc_q        <= 0;
		cen_pmem_q   <= 1;
		wen_pmem_q   <= 1;
		a_pmem_q     <= 0;
		cen_xmem_q   <= 1;
		wen_xmem_q   <= 1;
		a_xmem_q     <= 0;
		ofifo_rd_q   <= 0;
		inst_corelet_q <= 0;
		D_xmem_q    <= 0;
		sel_q <= 0;
	end
	else begin
		acc_q        <= inst[33];
		cen_pmem_q   <= inst[32];
		wen_pmem_q   <= inst[31];
		a_pmem_q     <= inst[30:20];
		cen_xmem_q   <= inst[19];
		wen_xmem_q   <= inst[18];
		a_xmem_q     <= inst[17:7];
		ofifo_rd_q   <= inst[6];
		inst_corelet_q <= {inst[3:2], mode, inst[1:0]};
		inst_corelet_qq <= inst_corelet_q;
		D_xmem_q    <= D_xmem;
		sel_q <= sel;
	end
end

wire [psum_bw*col-1:0] sfp_out;
// wire ofifo_valid;
// assign ofifo_valid = ofifo_ready;
reg [4:0] inst_corelet_qq;

corelet #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw), .col(col), .row(row)) corelet_instance (
	.clk(clk),
	.reset(reset),
	.in(o_xmem),            
	.out(o_corelet),      
	.inst(inst_corelet_qq),
	.ofifo_rd(ofifo_rd_q),
	.valid(ofifo_valid),
	.o_sram_in(o_sram_corelet), // fill later
	.sfu_en(acc_q)
);

wire [psum_bw*col-1:0] o_corelet;
// wire ofifo_ready;


// nij guaranteed to be larger than # of cols
// DIN = input data, Q = output data

// xmem: activation memory
// write to xmem when wen_xmem_q = 0 and cen_xmem_q = 0
sram_32b_w2048 sram_x (
	.CLK(clk),
	.WEN(wen_xmem_q),
	.CEN(cen_xmem_q),
	.D(D_xmem_q),
	.A(a_xmem_q),
	.Q(o_xmem)
);

wire [31:0] o_xmem;
wire [psum_bw*col-1:0] o_pmem_even;
wire [psum_bw*col-1:0] o_pmem_odd;

wire wen_pmem_even_q;
wire wen_pmem_odd_q;

// need to delay 2 cycles,

assign wen_pmem_even_q = !(!sel_q & !wen_pmem_q);
assign wen_pmem_odd_q = !(sel_q & !wen_pmem_q);
assign sfp_out = sel_q ? o_pmem_odd : o_pmem_even;

// acc_q, cen, wen, sel
// SEL = bank to write to (delay 2 cycles?)
// !SEL = bank to read from

sram_bank_32b_w2048 #(.col(col), .psum_bw(psum_bw)) sram_o_even (
	.CLK(clk),
	.WEN(wen_pmem_even_q),
	.CEN(cen_pmem_q),
	.D(o_corelet),
	.A(a_pmem_q),
	.Q(o_pmem_even)
);

wire [psum_bw*col-1:0] o_sram_corelet;
// the "other" bank goes to corelet
assign o_sram_corelet = sel ? o_pmem_even : o_pmem_even;

/*
reg [10:0] a_pmem_qq;
reg [10:0] a_pmem_qqq;
reg wen_pmem_q;
reg wen_pmem_qq;
*/

sram_bank_32b_w2048 #(.col(col), .psum_bw(psum_bw)) sram_o_odd (
	.CLK(clk),
	.WEN(wen_pmem_odd_q),
	.CEN(cen_pmem_q),
	.D(o_corelet),
	.A(a_pmem_q),
	.Q(o_pmem_odd)
);




endmodule