`timescale 1ns / 1ps

module sasebo_crypto_tb;

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

	
	integer i, fp, fp_hw_a, fp_hw_b, fp_hw_c, fp_hw_a_hex, fp_hw_b_hex, fp_hw_c_hex, fp_k;
	reg [8*10:1] str;
	reg [127:0] mem_plaintext [0:9999];
	reg [127:0] mem_ciphertext [0:9999];

	reg [127:0] random_p1 = 128'h0;//00112233445566778899aabbccddeeff;
	reg [127:0] random_p2 = 128'h0;//0123456789abcdeffedcba9876543210;
	reg [127:0] random_k1 = 128'h0;//102132435465768798a9bacbdcedfe03;
	reg [127:0] random_k2 = 128'h0;//abcdeffedcba98765432101234567890;

	reg [127:0] plaintext1 = 	128'h63736564207372656c6c657661727420;
	reg [127:0] plaintext2 = 	128'h63736564207372656c6c657661727421;
	reg [127:0] randomdata1 = 	128'hFF00EE11DD22CC33BB44AA5599668877;
	reg [127:0] randomdata2 = 	128'h000102030405060708090A0B0C0D0E0F;
	
	//The KEY changed so that DPA will results in different key for different attack points.
	//reg [127:0] key = 			128'h0f0e0d0c0b0a09080706050403020100;
	reg [127:0] key = 			128'h0f0e0d0c0b0a09080706050403020100;
	reg [127:0] randomkey1 = 	128'h00112233445566778899AABBCCDDEEFF;
	reg [127:0] randomkey2 = 	128'hAABBCCDDEEFF00112233445566778899;

	reg [127:0] ciphertext = 	128'h0;
	reg [127:0] plaintext = 	128'h0;
	
	reg [127:0] ZERO = 128'b0;
	reg [127:0] test1,test2;

	wire Trig;
	// Instantiate the Unit Under Test (UUT)
	sasebo_simon uut (
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

	initial begin
	CLK = 0;
		for (i=0;i<10000;i=i+1) begin	

			// Initialize Inputs
    		//Din = {plaintext^randomdata1^randomdata2,key^randomkey1^randomkey2,randomdata1,randomkey1,randomdata2,randomkey2};
			//Din = {};
			Din = {plaintext1,key, 512'd0};
			Drdy = 0;
			EN = 1;
			
			RSTn = 0;

			// Wait 100 ns for global reset to finish
			#100
			RSTn = 0;
			
			#400
			RSTn = 1;
			
			#100;	
			Drdy = 1;
			
			#15;
			Drdy = 0;
			
			#20;
			Drdy = 0;
		// Add stimulus here
			#95000;
			test2 = Dout;	

		end

	end

always #10 CLK = ~CLK;

 
endmodule

