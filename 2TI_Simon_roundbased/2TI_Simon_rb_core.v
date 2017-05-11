`timescale 1ns / 1ps

module simon2share(clk, data_ina, data_inb, data_rdy, cipher_out, Done, Trig);

input clk;
input data_ina, data_inb;
input [1:0] data_rdy;
output [127:0] cipher_out;
output reg Done, Trig;

reg [7:0] counter;
wire [63:0] keya, keyb;

always@(posedge clk)
begin
	if(data_rdy==0) begin
		counter <= 0;
	end
	else if(data_rdy ==3) begin			
		counter <= counter + 1;
	end
end

always @(posedge clk) begin
	if (counter == 1) //So it means first 1 rounds
		Trig <= 1;
	else
		Trig <= 0;
	if(data_rdy == 3 && (counter == 134))
		Done <= 1;			
	else
		Done <= 0;
end

p_datapath mydatapath(.clk(clk), .counter(counter), 
							 .data_ina(data_ina), .data_inb(data_inb),
							 .data_rdy(data_rdy), 
							 .key_ina(keya), .key_inb(keyb), 
							 .cipher_out(cipher_out));
					 
p_keysch10 mykeysch_a(.clk(clk), .counter(counter), 
							 .data_in(data_ina), .data_rdy(data_rdy), .key_out(keya));
							 
p_keysch11 mykeysch_b(.clk(clk), .counter(counter), 
							 .data_in(data_inb), .data_rdy(data_rdy), .key_out(keyb));						 
endmodule

module p_datapath
	(clk, counter, data_ina, data_inb, data_rdy,key_ina, key_inb, cipher_out);
	
input clk, data_ina, data_inb;
input [1:0] data_rdy;
input [7:0] counter;
input [63:0] key_ina, key_inb;	
output [127:0] cipher_out;

wire [63:0] Xout_a, Xout_b, Yout_a, Yout_b;

data_share2 share_a(.clk(clk), .data_rdy(data_rdy), .counter(counter[0]), .data_in(data_ina), 
						 .key_in(key_ina), .X_out(Xout_a), .Y_out(Yout_a), .Y_in(Yout_b));				 
data_share2 share_b(.clk(clk), .data_rdy(data_rdy), .counter(counter[0]), .data_in(data_inb), 
						 .key_in(key_inb), .X_out(Xout_b), .Y_out(Yout_b), .Y_in(Yout_a));


wire [127:0] res1, res2;
reg sel1, sel2;
always @(*) begin
	if (134 <= counter) begin
		sel1 <= 1;
		sel2 <= 1;
		//sel3 <= 1;
	end
	else begin		
		sel1 <= 0;
		sel2 <= 0;
		//sel3 <= 0;
	end
end
quick_mux_128 SHARE_A_OUT_MUX_128( .in1({Xout_a, Yout_a}), .in2(128'd0), .out(res1), .sel(sel1) );
quick_mux_128 SHARE_B_OUT_MUX_128( .in1({Xout_b, Yout_b}), .in2(128'd0), .out(res2), .sel(sel2) );
//quick_mux_128 SHARE_C_OUT_MUX_128( .in1({Xc, Yc}), .in2(128'd0), .out(res3), .sel(sel3) );
assign cipher_out = res1 ^ res2;

endmodule //simon_datapath


module data_share2(clk, data_rdy, counter, data_in,key_in, X_out, Y_out, Y_in);

input clk, counter, data_in;
input [63:0] key_in;
input [1:0] data_rdy;	
input [63:0] Y_in;
output [63:0] X_out, Y_out;

reg [63:0] X, Y;
wire [63:0] XL1_1, XL2_1, XL8_1;
assign XL1_1 = {X[62:0], X[63]}; 
assign XL2_1 = {X[61:0], X[63:62]}; 
assign XL8_1 = {X[55:0], X[63:56]}; 

wire [63:0] YL1_1, YL8_2;
assign YL1_1 = {Y[62:0], Y[63]}; 
assign YL8_2 = {Y_in[55:0], Y_in[63:56]}; 

wire [63:0] sout1, sout2;
sub1 s1(Y, XL2_1, XL8_1, XL1_1, sout1);
sub1 s2(X, key_in, YL1_1, YL8_2, sout2);
always@(posedge clk)
begin
   if(data_rdy ==1) begin
		{X, Y} <= {data_in, X, Y[63:1]};
	end
	else if(data_rdy ==3) begin			
		if (counter == 1'b0) begin							
			X <= sout1 ;
			Y <= X;
		end
		else begin
			X <= sout2;
		end
	end
end
	
assign X_out = X;
assign Y_out = Y;

endmodule


module quick_mux_128(in1, in2, out, sel);
input [127:0] in1,in2;
input sel;
output [127:0] out;
assign out = sel?(in1):in2;

endmodule	

module p_keysch10(clk, counter, data_in, data_rdy, key_out);
input clk, data_in;
input [1:0] data_rdy;
input [7:0] counter;
output [63:0] key_out;

reg [63:0] KX, KY;
reg [0:67] Z = 68'b10101111011100000011010010011000101000010001111110010110110011101011;
reg [63:0] c = 64'hfffffffffffffffc;


always@(posedge clk)
begin
	if(data_rdy == 2) begin
		{KX, KY} <= {data_in, KX, KY[63:1]};
	end
	else if(data_rdy == 3) begin
		if(counter[0] == 1'b1) begin
			KX <= c ^ Z[counter[7:1]] ^ KY ^ {KX[2:0],KX[63:3]} ^ {KX[3:0],KX[63:4]};
			KY <= KX;
		end
	end
end
assign key_out = KY ;

endmodule

module p_keysch11(clk, counter, data_in, data_rdy, key_out);
input clk, data_in;
input [1:0] data_rdy;
input [7:0] counter;
output [63:0] key_out;

reg [63:0] KX, KY;

always@(posedge clk)
begin
	if(data_rdy ==2) begin
		{KX, KY} <= {data_in, KX, KY[63:1]};
	end
	else if(data_rdy ==3) begin
		if(counter[0] == 1'b1) begin
			KX <= KY ^ {KX[2:0],KX[63:3]} ^ {KX[3:0],KX[63:4]};
			KY <= KX;
		end
	end
end
assign key_out = KY ;

endmodule

module sub1(i1, i2, i3, i4, o1);
input [63:0] i1, i2, i3, i4;
output [63:0] o1;
wire [63:0] andout;
and4 a1(i3[3:0], i4[3:0], andout[3:0]);
and4 a2(i3[7:4], i4[7:4], andout[7:4]);
and4 a3(i3[11:8], i4[11:8], andout[11:8]);
and4 a4(i3[15:12], i4[15:12], andout[15:12]);
and4 a5(i3[19:16], i4[19:16], andout[19:16]);
and4 a6(i3[23:20], i4[23:20], andout[23:20]);
and4 a7(i3[27:24], i4[27:24], andout[27:24]);
and4 a8(i3[31:28], i4[31:28], andout[31:28]);

and4 a9(i3[35:32], i4[35:32], andout[35:32]);
and4 a10(i3[39:36], i4[39:36], andout[39:36]);
and4 a11(i3[43:40], i4[43:40], andout[43:40]);
and4 a12(i3[47:44], i4[47:44], andout[47:44]);
and4 a13(i3[51:48], i4[51:48], andout[51:48]);
and4 a14(i3[55:52], i4[55:52], andout[55:52]);
and4 a15(i3[59:56], i4[59:56], andout[59:56]);
and4 a16(i3[63:60], i4[63:60], andout[63:60]);

assign o1 = i1 ^ i2 ^ andout;
endmodule

module and4(a1, a2, andout);
input [3:0] a1,a2;
output [3:0] andout;
assign andout = a1 & a2;
endmodule

