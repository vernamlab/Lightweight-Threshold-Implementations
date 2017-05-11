`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:40:17 12/03/2015
// Design Name:   parallel_simon
// Module Name:   C:/Users/Cong/Dropbox/PhDWork/Courses/Spring 2015/Applied Crypto and Physical Attacks/Project/Speck/Control Core/SimonCrypto/src/par_simon_tb.v
// Project Name:  SimonCrypto
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: parallel_simon
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module speck_tb;

	// Inputs
	reg clk;
	reg data_ina, data_inb, data_inc;
	reg k_data_ina, k_data_inb, k_data_inc;
	reg carry_init_a,carry_init_b,carry_init_c;
	reg we, Start;

	// Outputs
	//wire [47:0] cipher_out;
	wire [1:0] cipher_out1, cipher_out2, cipher_out3;

	wire rndlessthan32;
	
	/*reg [143:0] pkb = 144'h6d20_7369_6874_1a19_1812_1110_0a09_0802_0100;
	reg [143:0] pka = 144'd0;
	reg [143:0] pkc = 144'd0;*/
	/*reg [191:0] pkb = 192'h3b72_6574_7475_432d_1b1a_1918_1312_1110_0b0a_0908_0302_0100;
	reg [191:0] pka = 192'd0;
	reg [191:0] pkc = 192'd0;*/
	/*reg [383:0] pkb = 384'h65736f6874206e49202e72656e6f6f701f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100;
	reg [383:0] pka = 384'd0;
	reg [383:0] pkc = 384'd0;*/
	reg [255:0] pka = 256'h6c617669757165207469206564616d200f0e0d0c0b0a09080706050403020100;
	reg [255:0] pkb = 256'd0;
	reg [255:0] pkc = 256'd0;
	//reg [255:0] pkc = 256'd655465465465 ^ 256'd54561156465;
	integer i;
	// Instantiate the Unit Under Test (UUT)
	bitSpeck128_128_hierarchy_carry_sharing uut (
		.clk(clk), 
		.data_ina(data_ina), 
		.data_inb(data_inb), 
		.data_inc(data_inc), 
		.k_data_ina(k_data_ina), 
		.k_data_inb(k_data_inb), 
		.k_data_inc(k_data_inc), 
		.carry_init_a(carry_init_a),.carry_init_b(carry_init_b),.carry_init_c(carry_init_c),
		.we(we), .Start(Start),
		.cipher_out1(cipher_out1), 
		.cipher_out2(cipher_out2), 
		.cipher_out3(cipher_out3), 
		.rndlessthan32(rndlessthan32)
	);
	
	always #5 clk = ~clk;
	initial begin
		// Initialize Inputs
		clk = 0;
		data_ina = 0;data_inb = 0;data_inc = 0;
		we = 0; Start = 0;
		carry_init_a = 1; carry_init_b = 0; carry_init_c = 1;
		#20;
		// Wait 100 ns for global reset to finish
		for( i = 0; i <= 127; i= i+1 ) begin	
			if(i < 128) begin
				we = 1;
				data_ina = pka[i +128];
				data_inb = pkb[i +128];
				data_inc = pkc[i +128];
				k_data_ina = pka[i ];
				k_data_inb = pkb[i ];
				k_data_inc = pkc[i ];
			end
	
			#10;
		end
		we = 0;
		Start = 1;
		#30000;
		Start = 0;
		
		// Add stimulus here

	end
      
endmodule

