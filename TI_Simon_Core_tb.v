`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:52:48 07/11/2016
// Design Name:   SimonSerial
// Module Name:   C:/Users/Cong/Dropbox/PhDWork/Research/Projects/2ShareTI/BitSerialSimon2Share/BitSerialSimon2Share/SimonSerial_tb.v
// Project Name:  BitSerialSimon2Share
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: SimonSerial
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module TI_Simon_Core_tb;

	// Inputs
	reg clk;
	reg data_ina;
	reg data_inb;
	reg [1:0] data_rdy;

	// Outputs
	wire cipher_outa,cipher_outb;
	wire [6:0] round_counter;
	wire Done;
	wire Trig;
	integer i;
	reg [255:0] pka = 256'h63736564207372656c6c6576617274200f0e0d0c0b0a09080706050403020100 ;
	reg [255:0] pkb = 256'd0;
	// Instantiate the Unit Under Test (UUT)
	TI_Simon_Core uut (
		.clk(clk), 
		.data_ina(data_ina), 
		.data_inb(data_inb), 
		.data_rdy(data_rdy), 
		.cipher_outa(cipher_outa),
		.cipher_outb(cipher_outb),	
		.round_counter(round_counter),
		.Done(Done), 
		.Trig(Trig)
	);
	
	always #5 clk = ~clk;
	initial begin
		// Initialize Inputs
		clk = 0;
		data_ina = 0;
		data_inb = 0;
		data_rdy = 0;

		// Wait 100 ns for global reset to finish
		#20;
		// Wait 100 ns for global reset to finish
		for( i = 0; i <= 255; i= i+1 ) begin	
			if(i < 128) begin
				data_rdy = 2'b10;
				data_ina = pka[i];
				data_inb = pkb[i];
			end
			else begin
				data_rdy = 2'b01;
				data_ina = pka[i];
				data_inb = pkb[i];
			end
			#10;
		end
		data_rdy = 2'b11;
        
	end
      
endmodule

