`timescale 1ns / 1ps

module serial_simon(clk,data_in,data_rdy,cipher_out, Done, Trig);

input clk,data_in;
input [1:0] data_rdy;
output cipher_out;
output reg Trig, Done;

wire key;
wire [5:0] bit_counter;
wire round_counter_out;
wire [6:0] round_counter_full;

/*
	data_rdy=0 -> Reset, Idle
	data_rdy=1 -> Load Plaintext
	data_rdy=2 -> Load Key
	data_rdy=3 -> Run (keep at 3 while the block cipher is running)
*/
always @(posedge clk) begin
	if (round_counter_full==0 && bit_counter == 1) //So it means first 4 rounds
		Trig = 1;
	else
		Trig = 0;
	if(data_rdy == 3 && round_counter_full == 67 && bit_counter == 62)
		Done = 1;			
	else
		Done = 0;
end

simon_datapath_shiftreg datapath(.clk(clk), .data_in(data_in), .data_rdy(data_rdy), .key_in(key), 
								 . cipher_out(cipher_out), .round_counter(round_counter_out), .bit_counter(bit_counter));
											
simon_key_expansion_shiftreg key_exp(.clk(clk), .data_in(data_in), .data_rdy(data_rdy), .key_out(key), .bit_counter(bit_counter), 
									 .round_counter_full(round_counter_full), .round_counter_out(round_counter_out));


endmodule
