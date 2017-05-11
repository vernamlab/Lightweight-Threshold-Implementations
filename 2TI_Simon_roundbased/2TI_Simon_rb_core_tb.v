`timescale 1ns / 1ps


module par_simon_tb;

	// Inputs
	reg clk;
	reg data_ina, data_inb;
	reg [1:0] data_rdy;

	// Outputs
	wire [127:0] cipher_out;
	wire Done;
	wire Trig;
	
	reg [255:0] pkb = 256'h4984135146514455468484448764456412346845131555465757486435446838;
	reg [255:0] pka = 256'h63736564207372656c6c6576617274200f0e0d0c0b0a09080706050403020100 ^ 256'h4984135146514455468484448764456412346845131555465757486435446838;
	//reg [255:0] pkb = 256'd0;
	//reg [255:0] pka = 256'h63736564207372656c6c6576617274200f0e0d0c0b0a09080706050403020100;
	
	//reg [255:0] pkc = 256'd655465465465 ^ 256'd54561156465;
	integer i;
	// Instantiate the Unit Under Test (UUT)
	simon2share uut (
		.clk(clk), 
		.data_ina(data_ina), 
		.data_inb(data_inb), 
		//.data_in(data_ina ^ data_inb), 
		.data_rdy(data_rdy), 
		.cipher_out(cipher_out), 
		.Done(Done), 
		.Trig(Trig)
	);
	
	always #5 clk = ~clk;
	initial begin
		// Initialize Inputs
		clk = 0;
		data_ina = 0;data_inb = 0;
		data_rdy = 0;
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
		// Add stimulus here

	end
      
endmodule

