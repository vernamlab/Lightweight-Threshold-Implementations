`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:21:18 09/10/2015 
// Design Name: 
// Module Name:    bitSpeck128_hierarchy 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// This module put each share into isolated modules 
// such that no two shares are mixed into the same slice 
// to cause leakage.
//////////////////////////////////////////////////////////////////////////////////
module bitSpeck128_128_unpro(		
		input clk,
		input data_in,
		input k_data_in,
		input we, Start,
		output [1:0] cipher_out,
		output Done);

// Global
reg [5:0] roundcnt;
reg [5:0] shiftcnt;
wire shiftlessthan8, shiftlessthan3, rndlessthan32, rnd0;
assign shiftlessthan8 = (shiftcnt < 8);
assign shiftlessthan3 = (shiftcnt < 3);
assign rndlessthan32 = (roundcnt < 32);
assign rnd0 =roundcnt[0];
//one bit input for key schedule								
wire rc;
assign rc = (shiftcnt == 6'd0) ? roundcnt[0]: 
					((shiftcnt == 6'd1) ? roundcnt[1]: 
					 ((shiftcnt == 6'd2) ? roundcnt[2]:
						((shiftcnt == 6'd3) ? roundcnt[3]:
						 ((shiftcnt == 6'd4) ? roundcnt[4]:
						  ((shiftcnt == 6'd5) ? roundcnt[5] : 1'b0)))));
wire EN;
assign EN = (rndlessthan32) && (shiftcnt != 6'd63)  && (Start);

always @(posedge clk) begin // this is the reset part
   if (~Start) begin		//	RESET BLOCK
		roundcnt <= 6'd0;
		shiftcnt <= 6'd0;
	end
	else begin //	MAIN BLOCK
		if (rndlessthan32) begin
			shiftcnt <= shiftcnt + 1;
			if(~EN) begin
				roundcnt <= roundcnt + 1;
			end	
		end
	end	 
end

wire K_Y_m;
wire share_out1, share_out11;
share datapath1(clk, we, Start, EN,data_in,  shiftlessthan8, shiftlessthan3, rndlessthan32, 
						rnd0, K_Y_m, share_out1, share_out11);

key_share keysch1(clk, we, Start, EN,k_data_in, shiftlessthan8, shiftlessthan3, 
						rndlessthan32, rnd0, rc, K_Y_m);
						
assign cipher_out = {share_out1, share_out11};
assign Done = ~rndlessthan32;

endmodule

////////////////////////////////////////////////////////////////////////
module share(
       input clk, we, Start, EN,
		 input share_in,
		 input shiftlessthan8, shiftlessthan3, rndlessthan32,rnd0,
		 input keybit,
		 output wire share_out_x, share_out_y);
		 
wire X_out, Y_out;
wire X_carry;
reg [55:0] X_63_8;
reg [7:0] X_7_0;
assign X_carry = (shiftlessthan8) ? X_7_0[0] : X_out;

wire Y_carry_even, Y_carry_odd, Y_carry_60_0, Y_carry;
reg [60:0] Y_60_0;
reg [2:0]  Y_63_61_even, Y_63_61_odd;
assign Y_carry_even = rnd0 ? Y_out : Y_60_0[0];  
assign Y_carry_odd  = rnd0 ? Y_60_0[0] : Y_out;
assign Y_carry      = rnd0 ? Y_63_61_odd[0]: Y_63_61_even[0];
assign Y_carry_60_0 = rnd0 ? ((shiftlessthan3) ? Y_63_61_odd[0]  : Y_63_61_even[0]): 
												 ((shiftlessthan3) ? Y_63_61_even[0] :  Y_63_61_odd[0]);

//wire Xbit_mine, Ybit_mine, carry_mine;
assign Xbit_mine = X_63_8[0];
assign Ybit_mine = Y_60_0[0];

always @ (posedge clk) begin
	if (we) begin
		{X_63_8, X_7_0, Y_63_61_even, Y_60_0} <= {share_in, X_63_8, X_7_0, Y_63_61_even, Y_60_0[60:1]}; 
	end
	else if (Start) begin
		if (rndlessthan32) begin
			if (shiftlessthan8) begin
				X_7_0 <= {X_out, X_7_0[7:1]};
			end
			X_63_8 <= {X_carry, X_63_8[55:1]};
			
			// Processing the right block in 64 clock cycles
			Y_60_0       <= {Y_carry_60_0, Y_60_0[60:1]};
			Y_63_61_even <= {Y_carry_even, Y_63_61_even[2:1]};
			Y_63_61_odd  <= {Y_carry_odd,  Y_63_61_odd[2:1]};
		end
	end
	else begin
		{X_63_8, X_7_0} <= {1'b0, X_63_8, X_7_0[7:1]}; 
	   {Y_63_61_even, Y_60_0} <= {1'b0, Y_63_61_even, Y_60_0[60:1]}; 
	end
	
end
assign share_out_x = X_7_0[0];
assign share_out_y = Y_60_0[0];
//safe_mux myMUX({X_63_8, X_7_0, Y_63_61_even, Y_60_0}, roundcnt, share_out);
			  
round myRound(clk, EN, keybit, Xbit_mine, Ybit_mine, Y_carry, X_out, Y_out);
endmodule

module key_share(
       input clk, we, Start, EN,
		 input share_in,
		 input shiftlessthan8, shiftlessthan3, rndlessthan32,rnd0,
		 input keybit,
		 output Ybit_mine);	 
wire X_out, Y_out;
wire X_carry;
reg [55:0] X_63_8;
reg [7:0] X_7_0;
assign X_carry = (shiftlessthan8) ? X_7_0[0] : X_out;

wire Y_carry_even, Y_carry_odd, Y_carry_60_0, Y_carry;
reg [60:0] Y_60_0;
reg [2:0]  Y_63_61_even, Y_63_61_odd;
assign Y_carry_even = rnd0 ? Y_out : Y_60_0[0];  
assign Y_carry_odd  = rnd0 ? Y_60_0[0] : Y_out;
assign Y_carry      = rnd0 ? Y_63_61_odd[0]: Y_63_61_even[0];
assign Y_carry_60_0 = rnd0 ? ((shiftlessthan3) ? Y_63_61_odd[0]  : Y_63_61_even[0]): 
												 ((shiftlessthan3) ? Y_63_61_even[0] :  Y_63_61_odd[0]);

assign Xbit_mine = X_63_8[0];
assign Ybit_mine = Y_60_0[0];

always @ (posedge clk) begin
	if (we) begin
		{X_63_8, X_7_0, Y_63_61_even, Y_60_0} <= {share_in, X_63_8, X_7_0, Y_63_61_even, Y_60_0[60:1]}; 
	end
	else if (Start) begin
		if (rndlessthan32) begin
			if (shiftlessthan8) begin
				X_7_0 <= {X_out, X_7_0[7:1]};
			end
			X_63_8 <= {X_carry, X_63_8[55:1]};
			
			// Processing the right block in 64 clock cycles
			Y_60_0       <= {Y_carry_60_0, Y_60_0[60:1]};
			Y_63_61_even <= {Y_carry_even, Y_63_61_even[2:1]};
			Y_63_61_odd  <= {Y_carry_odd,  Y_63_61_odd[2:1]};
		end
	end
end
	  
round myRound(clk, EN, keybit, Xbit_mine, Ybit_mine, Y_carry, X_out, Y_out);
endmodule

/////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
module round(
		input CLK,
		input EN,
		input K,
		input X, //One bit of left block for addition
		input Y1,//one bit of right block for addition
		input Y2,//one bit of right block for xor
		output wire X_out,
		output wire Y_out
    );

reg carry;
assign X_out = carry ^ X ^ Y1 ^ K;
assign Y_out = X_out ^ Y2;

always @(posedge CLK) begin
	if(~EN) begin
		carry <= 1'b0;
	end
	else begin
		carry <= (X && carry) ^ (Y1 && carry) ^ (X && Y1);
	end
end
endmodule
