`include "my_incl.vh"
module key_schedule_modified2_simon_parallel(clk,data_in,key_out,/*data_rdy,*/bit_counter,/*round_counter_out,round_counter,*/
s2,s1,s3,shifter_enable1,shifter_enable2,lut_ff_enable,fifo_ff_enable);

input clk;
input data_in;
//input [1:0] data_rdy;
input [`BIT_COUNTER-1:0] bit_counter;
output key_out;
//output round_counter_out;
//input [6:0] round_counter;
////////// Added stuff for are reduction
input s2;
input [1:0] s1,s3;
input shifter_enable1,shifter_enable2;
input lut_ff_enable,fifo_ff_enable;
//////////////////////////////////////

reg [(`KEY_SIZE/`KEY_BLK)-1-4:0] shifter1;
reg [(`KEY_SIZE/`KEY_BLK)-1:0] shifter2;
reg shift_in1,shift_in2;
wire shift_out1,shift_out2;
//reg shifter_enable1,shifter_enable2;

//reg lut_ff_enable,fifo_ff_enable;
wire lut_out;
reg lut_in3;
//reg s2;//,s3;
//reg [1:0] s1;
//reg [6:0] round_counter;
//reg z_value;
reg c;

reg fifo_ff0,fifo_ff1,fifo_ff2,fifo_ff3;

//(* shreg_extract = "no" *)
reg lut_ff0,lut_ff1,lut_ff2,lut_ff3;


/////////////////////////////////////////
//// BEGIN CODE ////////////////////////
///////////////////////////////////////

// Least bit of the round counter is sent to the datapath to check if it is even or odd
//assign round_counter_out = round_counter[0];

// Shift Register1 FIFO 60x1 Begin
// 60x1 shift register storing the 60 most significant bits of the upper word of the key
always @(posedge clk)
begin
	if(shifter_enable1)
	begin
		shifter1 <= {shift_in1, shifter1[(`KEY_SIZE/`KEY_BLK)-1-4:1]};
	end
end

assign shift_out1 = shifter1[0];
// Shift Register1 End

// Shift Register2 FIFO 64x1 Begin
// 64x1 shift register storing the lower word of the key
always @(posedge clk)
begin
	if(shifter_enable2)
	begin
		shifter2 <= {shift_in2, shifter2[(`KEY_SIZE/`KEY_BLK)-1:1]};
	end
end

assign shift_out2 = shifter2[0];
// Shift Register2 End

// 4 flip-flops storing the least significant 4 bits of the upper word in the first round
always @(posedge clk)
begin
	if(fifo_ff_enable)
	begin
		fifo_ff3 <= shift_out1;
		fifo_ff2 <= fifo_ff3;
		fifo_ff1 <= fifo_ff2;
		fifo_ff0 <= fifo_ff1;
	end
end

// 4 flip-flops storing the least significant 4 bits of the upper word after the first round
always@(posedge clk)
begin
	if(lut_ff_enable)
	begin
		lut_ff3 <= lut_out;
		lut_ff2 <= lut_ff3;
		lut_ff1 <= lut_ff2;
		lut_ff0 <= lut_ff1;
	end
end

//FIFO 64x1 Input MUX
always@(*)
begin
	if(s3==1/*data_rdy==2*/)
		shift_in2 = fifo_ff0;
	else if(s3==2/*data_rdy==3 && (round_counter<1 || bit_counter>3)*/)
		shift_in2 = fifo_ff0;
	else if(s3==3/*data_rdy==3 && bit_counter<4 && round_counter>0*/) 
		shift_in2 = lut_ff0; 
	else
		shift_in2 = 1'bx;
end

//LUT >>3 Input MUX
always@(*)
begin
	if(s2==0)
		lut_in3 = fifo_ff3;
	else
		lut_in3 = lut_ff3;
end

//FIFO 60x1 Input MUX
always@(*)
begin
	if(s1==0)
		shift_in1 = fifo_ff0;
	else if(s1==1)
		shift_in1 = data_in;
	else if(s1==2)
		shift_in1 = lut_out;
	else if(s1==3)
		shift_in1 = lut_ff0;
	else
		shift_in1 = 1'bx;
end

// The value of c is 1 at the first two cycles of each round only
always @(*)
begin
	if(bit_counter==0 || bit_counter==1)
		c = 0;
	else 
		c = 1;
end

// New computed key bit
assign lut_out = shift_out2 ^ lut_in3 ^ shift_out1 ^ c;

// Output key bit that is connected to the datapath	
assign key_out = shift_out2;
	
endmodule