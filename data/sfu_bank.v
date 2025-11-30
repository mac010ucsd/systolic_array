// sfu bank for col size
module sfu_bank (clk, psum_in, psum_mem, valid, psum_out);

parameter psum_bw = 32;
parameter col = 8;

input clk;
input [(col*psum_bw)-1:0] psum_in; 
input [(col*psum_bw)-1:0] psum_mem;
input valid;
output [(col*psum_bw)-1:0] psum_out;

// module sfu (clk, psum_in, psum_mem, valid, psum_out);
genvar i;
for (i=0; i < col; i=i+1) begin : col_num
	sfu #(.psum_bw(psum_bw)) sfu_instance (
		.clk(clk),
		.psum_in(psum_in[(i+1)*psum_bw-1:i*psum_bw]),
		.psum_mem(psum_mem[(i+1)*psum_bw-1:i*psum_bw]),
		.valid(valid),
		.psum_out(psum_out[(i+1)*psum_bw-1:i*psum_bw])
    );
end

endmodule