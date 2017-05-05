`timescale 1ns / 1ps

`include "my_incl.vh"

module simon_parallel(clk,data_ina,data_inb,data_inc,data_rdy,cipher_outa,cipher_outb,cipher_outc, Trig, Done);

input clk,data_ina,data_inb,data_inc;
input [1:0] data_rdy;
output cipher_outa,cipher_outb,cipher_outc;
output reg Trig, Done;

wire keya, keyb, keyc;
wire [`BIT_COUNTER-1:0] bit_counter;
wire round_counter_out;
wire [`ROUND_COUNTER-1:0]round_counter;

wire s2;
wire [1:0] s1,s3;
wire shifter_enable1,shifter_enable2;
wire lut_ff_enable,fifo_ff_enable;

always @(posedge clk) begin
	if (round_counter==0 && bit_counter == 1) //So it means first 4 rounds
		Trig = 1;
	else
		Trig = 0;
	if(data_rdy == 3 && round_counter == 67 && bit_counter == 62)
		Done = 1;			
	else
		Done = 0;
end

datapath_simon_parallel DATAPATH
					(.clk(clk), .data_ina(data_ina), .data_inb(data_inb), .data_inc(data_inc), 
					 .data_rdy(data_rdy), 
					 .key_ina(keya), .key_inb(keyb), .key_inc(keyc),
					 .cipher_outa(cipher_outa), .cipher_outb(cipher_outb),.cipher_outc(cipher_outc),
					 .round_counter(round_counter_out), .round_num(round_counter),
					 .bit_counter(bit_counter));
											
key_schedule_modified1_simon_parallel KEY_SCH_1
					(.clk(clk), .data_in(data_ina), .data_rdy(data_rdy), .key_out(keya), 
					 .bit_counter(bit_counter), .round_counter_out(round_counter_out), .round_counter(round_counter),
					 .s2(s2), .s1(s1), .s3(s3), .shifter_enable1(shifter_enable1), .shifter_enable2(shifter_enable2),
					 .lut_ff_enable(lut_ff_enable), .fifo_ff_enable(fifo_ff_enable));

key_schedule_modified2_simon_parallel KEY_SCH_2
					(.clk(clk), .data_in(data_inb), .key_out(keyb), .bit_counter(bit_counter), 
					 .s2(s2), .s1(s1), .s3(s3), .shifter_enable1(shifter_enable1), .shifter_enable2(shifter_enable2),
					 .lut_ff_enable(lut_ff_enable), .fifo_ff_enable(fifo_ff_enable));

key_schedule_modified3_simon_parallel KEY_SCH_3
					(.clk(clk), .data_in(data_inc), .key_out(keyc), 
					 .s2(s2), .s1(s1), .s3(s3), .shifter_enable1(shifter_enable1), .shifter_enable2(shifter_enable2),
					 .lut_ff_enable(lut_ff_enable), .fifo_ff_enable(fifo_ff_enable));

endmodule
