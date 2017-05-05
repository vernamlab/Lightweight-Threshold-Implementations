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
module bitSpeck128_128_hierarchy_carry_sharing(		
		input clk,
		input data_ina, data_inb, data_inc,
		input k_data_ina, k_data_inb, k_data_inc,
		input carry_init_a,carry_init_b,carry_init_c,
		input we, Start,
		output [1:0] cipher_out1, cipher_out2, cipher_out3,
		output rndlessthan32);

// Global
reg [5:0] roundcnt;
reg [5:0] shiftcnt;
wire shiftlessthan8, shiftlessthan3, rnd0;
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

wire X_m1, X_m2, X_m3, Y_m1, Y_m2, Y_m3, C_m1, C_m2, C_m3;
wire K_X_m1, K_X_m2, K_X_m3, K_Y_m1, K_Y_m2, K_Y_m3, K_C_m1, K_C_m2, K_C_m3;
wire share_out1, share_out2, share_out3; 
wire share_out11, share_out22, share_out33; 
share datapath1(clk, we, Start, EN,data_ina,  shiftlessthan8, shiftlessthan3, rndlessthan32, 
						rnd0, K_Y_m1, X_m2, Y_m2, C_m2, carry_init_a, X_m1, Y_m1, C_m1, share_out1, share_out11);
share datapath2(clk, we, Start, EN,data_inb,  shiftlessthan8, shiftlessthan3, rndlessthan32, 
						rnd0, K_Y_m2, X_m3, Y_m3, C_m3, carry_init_b, X_m2, Y_m2, C_m2, share_out2, share_out22);
share datapath3(clk, we, Start, EN,data_inc,  shiftlessthan8, shiftlessthan3, rndlessthan32, 
						rnd0, K_Y_m3, X_m1, Y_m1, C_m1, carry_init_c, X_m3, Y_m3, C_m3, share_out3, share_out33);

key_share keysch1(clk, we, Start, EN,k_data_ina, shiftlessthan8, shiftlessthan3, 
						rndlessthan32, rnd0, rc, K_X_m2, K_Y_m2, K_C_m2, K_X_m1, K_Y_m1, K_C_m1);
key_share keysch2(clk, we, Start, EN,k_data_inb,  shiftlessthan8, shiftlessthan3, 
						rndlessthan32, rnd0, 1'b0, K_X_m3, K_Y_m3, K_C_m3, K_X_m2, K_Y_m2, K_C_m2);
key_share keysch3(clk, we, Start, EN,k_data_inc,  shiftlessthan8, shiftlessthan3, 
						rndlessthan32, rnd0, 1'b0, K_X_m1, K_Y_m1, K_C_m1, K_X_m3, K_Y_m3, K_C_m3);
						
assign cipher_out1 = {share_out1, share_out11};
assign cipher_out2 = {share_out2, share_out22};
assign cipher_out3 = {share_out3, share_out33};
//assign Done = roundcnt[5];

endmodule

////////////////////////////////////////////////////////////////////////
module share(
       input clk, we, Start, EN,
		 input share_in,
		 input shiftlessthan8, shiftlessthan3, rndlessthan32,rnd0,
		 input keybit,
		 input Xbit_else, Ybit_else, carry_else, carry_init,
		 output wire Xbit_mine, Ybit_mine, carry_mine, 
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
		else begin
			{X_63_8, X_7_0} <= {1'b0, X_63_8, X_7_0[7:1]}; 
			{Y_63_61_even, Y_60_0} <= {1'b0, Y_63_61_even, Y_60_0[60:1]}; 
		end
	end
end

assign share_out_x = X_7_0[0];
assign share_out_y = Y_60_0[0];
			  
share_roundTI myRound(clk, EN, keybit, Xbit_mine, Ybit_mine, Y_carry, Xbit_else, Ybit_else, carry_else, carry_init, X_out, Y_out, carry_mine);
endmodule

////////////////////////////////////////////////////////////////////////////
module share_roundTI(
		input clk, EN,
		input keybit, Xbit, Ybit1, Ybit2,
		input Xbit_else, Ybit_else, carry_else, carry_init,
		output X_out, Y_out,
		output reg carry);

assign X_out = carry ^ Xbit ^ Ybit1 ^ keybit;
assign Y_out = X_out ^ Ybit2;

always @(posedge clk) begin
	if(~EN) begin
		//carry <= 1'b0;
		carry <= carry_init;
	end
	// This is a TI representation of a nonlinear operation
	// but the three shares of the outputs are uniform
	else begin
		carry <= (Xbit && carry) ^ (Xbit && carry_else) ^ (Xbit_else && carry) 
				  ^ (Xbit && Ybit1) ^ (Xbit && Ybit_else) ^ (Xbit_else && Ybit1)  
				  ^ (Ybit1 && carry) ^ (Ybit1 && carry_else) ^ (Ybit_else && carry);
	end
end
endmodule

////////////////////////////////////////////////////////////////////////////
module key_share(
       input clk, we, Start, EN,
		 input share_in,
		 input shiftlessthan8, shiftlessthan3, rndlessthan32,rnd0,
		 input keybit,
		 input Xbit_else, Ybit_else, carry_else,
		 output wire Xbit_mine, Ybit_mine, carry_mine);	 
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
	  
key_share_roundTI myRound(clk, EN, keybit, Xbit_mine, Ybit_mine, Y_carry, Xbit_else, Ybit_else, carry_else, X_out, Y_out, carry_mine);
endmodule

/////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
module key_share_roundTI(
		input clk, EN,
		input keybit, Xbit, Ybit1, Ybit2,
		input Xbit_else, Ybit_else, carry_else,
		output X_out, Y_out,
		output reg carry);

assign X_out = carry ^ Xbit ^ Ybit1 ^ keybit;
assign Y_out = X_out ^ Ybit2;

always @(posedge clk) begin
	if(~EN) begin
		carry <= 1'b0;
	end
	// This is a TI representation of a nonlinear operation
	// but the three shares of the outputs are uniform
	else begin
		carry <= (Xbit && carry) ^ (Xbit && carry_else) ^ (Xbit_else && carry) 
				  ^ (Xbit && Ybit1) ^ (Xbit && Ybit_else) ^ (Xbit_else && Ybit1)  
				  ^ (Ybit1 && carry) ^ (Ybit1 && carry_else) ^ (Ybit_else && carry);
	end
end
endmodule
