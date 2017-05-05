`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   09:37:51 07/21/2016
// Design Name:   sasebo_simon
// Module Name:   C:/Users/Cong/Dropbox/PhDWork/Research/Projects/2ShareTI/SerialSimon2Share_wholeProj/BitSerialSimon2Share_crypto/TopModule_tb.v
// Project Name:  BitSerialSimon2Share
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: sasebo_simon
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module TI_Simon_TopModule_tb;

	// Inputs
	reg [767:0] Din;
	reg Drdy;
	reg EN;
	reg CLK;
	reg RSTn;

	// Outputs
	wire [127:0] Dout;
	wire Dvld;
	wire BSY;
	wire Trig;

	// Instantiate the Unit Under Test (UUT)
	TI_Simon_TopModule uut (
		.Din(Din), 
		.Dout(Dout), 
		.Drdy(Drdy), 
		.Dvld(Dvld), 
		.EN(EN), 
		.BSY(BSY), 
		.CLK(CLK), 
		.RSTn(RSTn), 
		.Trig(Trig)
	);
	always #5 CLK = ~CLK;
	initial begin
		// Initialize Inputs
		Din = 0;
		Drdy = 0;
		EN = 0;
		CLK = 0;
		RSTn = 1;

		// Wait 100 ns for global reset to finish
		#20;
      RSTn = 0;
		#40;
		RSTn = 1;
		EN = 1;
		#20;
		Din = 768'h63736564207372656c6c6576617211110f0e0d0c0b0a0908070605040302010063736564207372656c6c6576617211110f0e0d0c0b0a0908070605040302010063736564207372656c6c6576617274200f0e0d0c0b0a09080706050403020100;
		#10;
		Drdy = 1;
		#10;
		Drdy = 0;
		
		// Add stimulus here

	end
      
endmodule

