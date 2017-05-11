`include "my_incl.vh"
module datapath_simon_parallel(clk,data_ina,data_inb,data_inc,data_rdy,key_ina, key_inb, key_inc,cipher_outa, cipher_outb, cipher_outc,round_counter,round_num,bit_counter);

input clk,data_ina,data_inb,data_inc;
input key_ina,key_inb,key_inc;
input [1:0] data_rdy;
input round_counter;
input [`ROUND_COUNTER-1:0] round_num;
output cipher_outa, cipher_outb, cipher_outc;
output [`BIT_COUNTER-1:0] bit_counter;

////////////////////////////////////////////////////////
reg [(`P_SIZE/2)-1-8:0] shifter1a;
reg [(`P_SIZE/2)-1:0] shifter2a;
reg shift_in1a,shift_in2a;
wire shift_out1a,shift_out2a;
reg shifter_enable1a,shifter_enable2a;

reg [(`P_SIZE/2)-1-8:0] shifter1b;
reg [(`P_SIZE/2)-1:0] shifter2b;
reg shift_in1b,shift_in2b;
wire shift_out1b,shift_out2b;
reg shifter_enable1b,shifter_enable2b;

reg [(`P_SIZE/2)-1-8:0] shifter1c;
reg [(`P_SIZE/2)-1:0] shifter2c;
reg shift_in1c,shift_in2c;
wire shift_out1c,shift_out2c;
reg shifter_enable1c,shifter_enable2c;
////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
reg fifo_ff63a,fifo_ff62a,fifo_ff61a,fifo_ff60a,fifo_ff59a,fifo_ff58a,fifo_ff57a,fifo_ff56a;
reg lut_ff63a,lut_ff62a,lut_ff61a,lut_ff60a,lut_ff59a,lut_ff58a,lut_ff57a,lut_ff56a;

reg fifo_ff63b,fifo_ff62b,fifo_ff61b,fifo_ff60b,fifo_ff59b,fifo_ff58b,fifo_ff57b,fifo_ff56b;
reg lut_ff63b,lut_ff62b,lut_ff61b,lut_ff60b,lut_ff59b,lut_ff58b,lut_ff57b,lut_ff56b;

reg fifo_ff63c,fifo_ff62c,fifo_ff61c,fifo_ff60c,fifo_ff59c,fifo_ff58c,fifo_ff57c,fifo_ff56c;
reg lut_ff63c,lut_ff62c,lut_ff61c,lut_ff60c,lut_ff59c,lut_ff58c,lut_ff57c,lut_ff56c;
////////////////////////////////////////////////////////

reg lut_ff_inputa,fifo_ff_inputa;
reg lut_rol1a,lut_rol2a,lut_rol8a;

reg lut_ff_inputb,fifo_ff_inputb;
reg lut_rol1b,lut_rol2b,lut_rol8b;

reg lut_ff_inputc,fifo_ff_inputc;
reg lut_rol1c,lut_rol2c,lut_rol8c;

reg s1,s4,s5,s6,s7;
reg [1:0] s3;
reg [`BIT_COUNTER-1:0] bit_counter;
wire lut_outa,lut_outb,lut_outc;



// Shift Register1 FIFO 56x1 Begin
// 56x1 Shift register to store the upper word
always @(posedge clk)
begin
	if(shifter_enable1a)
	begin
		shifter1a <= {shift_in1a, shifter1a[(`P_SIZE/2)-1-8:1]};
	end
	if(shifter_enable1b)
	begin
		shifter1b <= {shift_in1b, shifter1b[(`P_SIZE/2)-1-8:1]};
	end
	if(shifter_enable1c)
	begin
		shifter1c <= {shift_in1c, shifter1c[(`P_SIZE/2)-1-8:1]};
	end
end

assign shift_out1a = shifter1a[0];
assign shift_out1b = shifter1b[0];
assign shift_out1c = shifter1c[0];
// Shift Register1 End

// Shift Register2 FIFO 64x1 Begin
// 64x1 Shift register to store the lower word
always @(posedge clk)
begin
	if(shifter_enable2a)
	begin
		shifter2a <= {shift_in2a, shifter2a[(`P_SIZE/2)-1:1]};
	end
	if(shifter_enable2b)
	begin
		shifter2b <= {shift_in2b, shifter2b[(`P_SIZE/2)-1:1]};
	end
	if(shifter_enable2c)
	begin
		shifter2c <= {shift_in2c, shifter2c[(`P_SIZE/2)-1:1]};
	end
end

assign shift_out2a = shifter2a[0];
assign shift_out2b = shifter2b[0];
assign shift_out2c = shifter2c[0];
// Shift Register2 End


// 8 Flip-Flops to store the most significant 8 bits of the upper word at even rounds
// Denoted as Shift Register Up (SRU) in Figure 5
always@(posedge clk)
begin
	if(shifter_enable1a)
	begin
		fifo_ff63a <= fifo_ff_inputa;
		fifo_ff62a <= fifo_ff63a;
		fifo_ff61a <= fifo_ff62a;
		fifo_ff60a <= fifo_ff61a;
		fifo_ff59a <= fifo_ff60a;
		fifo_ff58a <= fifo_ff59a;
		fifo_ff57a <= fifo_ff58a;
		fifo_ff56a <= fifo_ff57a;
	end
	if(shifter_enable1b)
	begin
		fifo_ff63b <= fifo_ff_inputb;
		fifo_ff62b <= fifo_ff63b;
		fifo_ff61b <= fifo_ff62b;
		fifo_ff60b <= fifo_ff61b;
		fifo_ff59b <= fifo_ff60b;
		fifo_ff58b <= fifo_ff59b;
		fifo_ff57b <= fifo_ff58b;
		fifo_ff56b <= fifo_ff57b;
	end
	if(shifter_enable1c)
	begin
		fifo_ff63c <= fifo_ff_inputc;
		fifo_ff62c <= fifo_ff63c;
		fifo_ff61c <= fifo_ff62c;
		fifo_ff60c <= fifo_ff61c;
		fifo_ff59c <= fifo_ff60c;
		fifo_ff58c <= fifo_ff59c;
		fifo_ff57c <= fifo_ff58c;
		fifo_ff56c <= fifo_ff57c;
	end
end

// 8 Flip-Flops to store the most significant 8 bits of the upper word at odd rounds
// Denoted as Shift Register Down (SRD) in Figure 5
always@(posedge clk)
begin
	lut_ff63a <= lut_ff_inputa;
	lut_ff62a <= lut_ff63a;
	lut_ff61a <= lut_ff62a;
	lut_ff60a <= lut_ff61a;
	lut_ff59a <= lut_ff60a;
	lut_ff58a <= lut_ff59a;
	lut_ff57a <= lut_ff58a;
	lut_ff56a <= lut_ff57a;
	
	lut_ff63b <= lut_ff_inputb;
	lut_ff62b <= lut_ff63b;
	lut_ff61b <= lut_ff62b;
	lut_ff60b <= lut_ff61b;
	lut_ff59b <= lut_ff60b;
	lut_ff58b <= lut_ff59b;
	lut_ff57b <= lut_ff58b;
	lut_ff56b <= lut_ff57b;
	
	lut_ff63c <= lut_ff_inputc;
	lut_ff62c <= lut_ff63c;
	lut_ff61c <= lut_ff62c;
	lut_ff60c <= lut_ff61c;
	lut_ff59c <= lut_ff60c;
	lut_ff58c <= lut_ff59c;
	lut_ff57c <= lut_ff58c;
	lut_ff56c <= lut_ff57c;
end

// FIFO 64x1 Input MUX
// Input of the lower FIFO is always the output of the upper FIFO
always@(*)
begin
		shift_in2a = shift_out1a;
		shift_in2b = shift_out1b;
		shift_in2c = shift_out1c;
end

// FIFO 56x1 Input MUX
// Input of the upper FIFO depends on the select line S1
always@(*)
begin
	if(s1==0) begin
		shift_in1a = lut_ff56a;
		shift_in1b = lut_ff56b;
		shift_in1c = lut_ff56c;
	end
	else begin
		shift_in1a = fifo_ff56a;
		shift_in1b = fifo_ff56b;
		shift_in1c = fifo_ff56c;
	end
end

// FIFO FF Input MUX
// The input of FIFO_FF can be the input plaintext, output of 56x1 FIFO or the output of LUT
always@(*)
begin
	if(s3==0) begin
		fifo_ff_inputa = data_ina;
		fifo_ff_inputb = data_inb;
		fifo_ff_inputc = data_inc;
	end
	else if(s3==1) begin
		fifo_ff_inputa = shift_out1a;
		fifo_ff_inputb = shift_out1b;
		fifo_ff_inputc = shift_out1c;
	end
	else if(s3==2) begin
		fifo_ff_inputa = lut_outa;
		fifo_ff_inputb = lut_outb;
		fifo_ff_inputc = lut_outc;
	end
	else begin
		fifo_ff_inputa = 1'bx; // Debugging
		fifo_ff_inputb = 1'bx; // Debugging
		fifo_ff_inputc = 1'bx; // Debugging
	end
end

// LUT FF Input MUX
// The input of the LUT_FF is either the output of 56x1 FIFO or the output of LUT
always@(*)
begin
	if(s5==0) begin
		lut_ff_inputa = shift_out1a;
		lut_ff_inputb = shift_out1b;
		lut_ff_inputc = shift_out1c;
	end
	else begin
		lut_ff_inputa = lut_outa;
		lut_ff_inputb = lut_outb;
		lut_ff_inputc = lut_outc;
	end
end

// LUT Input MUX
always@(*)
begin
	if(s7==0) begin
		lut_rol1a = fifo_ff63a;
		lut_rol1b = fifo_ff63b;
		lut_rol1c = fifo_ff63c;
	end
	else begin
		lut_rol1a = lut_ff63a;
		lut_rol1b = lut_ff63b;
		lut_rol1c = lut_ff63c;
	end	
	
	if(s4==0) begin
		lut_rol2a = fifo_ff62a;
		lut_rol2b = fifo_ff62b;
		lut_rol2c = fifo_ff62c;
	end
	else begin
		lut_rol2a = lut_ff62a;
		lut_rol2b = lut_ff62b;
		lut_rol2c = lut_ff62c;
	end
		
	if(s6==0) begin
		lut_rol8a = fifo_ff56a;
		lut_rol8b = fifo_ff56b;
		lut_rol8c = fifo_ff56c;
	end
	else begin
		lut_rol8a = lut_ff56a;
		lut_rol8b = lut_ff56b;
		lut_rol8c = lut_ff56c;
	end
end

//Selection MUX
always@(*)
begin
	// For the first 8 bits of each even round OR for all the bits after the first 8 bits in odd rounds OR loading the plaintext  
	if((round_counter==0 && bit_counter<8)||(round_counter==1 && bit_counter>7)||(data_rdy==1))
		s1 = 1;
	else 
		s1 = 0;
		
	if(data_rdy==1) // Loading plaintext
		s3 = 0;
	else if(round_counter==0) // Even rounds
		s3 = 1;
	else if(round_counter==1) // Odd rounds
		s3 = 2;
	else 
		s3 = 1'bx; // For debugging
		
	if(round_counter==0) // Even rounds
		s6 = 0;
	else
		s6 = 1;
	
	s4 = s6;
	s7 = s6;
	s5 = ~s6;
end

// SHIFTER ENABLES
// Two shift registers are enabled when the plaintext is being loaded (1) or when the block cipher is running (3)
always@(*)
begin
	if(data_rdy==1 || data_rdy==3)
	begin
		shifter_enable1a = 1;
		shifter_enable2a = 1;
		
		shifter_enable1b = 1;
		shifter_enable2b = 1;
		
		shifter_enable1c = 1;
		shifter_enable2c = 1;
	end
	else
	begin
		shifter_enable1a = 0;
		shifter_enable2a = 0;

		shifter_enable1b = 0;
		shifter_enable2b = 0;

		shifter_enable1c = 0;
		shifter_enable2c = 0;
	end
end

// The bit_counter value is incremented in each clock cycle when the block cipher is running
always@(posedge clk)
begin
	if(data_rdy==0)
		bit_counter <= 0;
	else if(data_rdy==3)
		if(bit_counter == (`P_SIZE/2)-1)
			bit_counter <= 0;
		else
			bit_counter <= bit_counter + 1;
	else 
		bit_counter <= bit_counter;
end


lut_datapath LUT_A_DATAPATH 
	(.out(lut_outa), .in1(shift_out2b), .in2(key_inb), .in3(lut_rol2b), 
	 .in_4(lut_rol1b), .in_5(lut_rol8b), 
	 .in_6_(lut_rol1b), .in_7_(lut_rol8c), 
	 .in_8(lut_rol1c), .in_9(lut_rol8b));

lut_datapath LUT_B_DATAPATH 
	(.out(lut_outb), .in1(shift_out2c), .in2(key_inc), .in3(lut_rol2c), 
	 .in_4(lut_rol1c), .in_5(lut_rol8c), 
	 .in_6_(lut_rol1a), .in_7_(lut_rol8c), 
	 .in_8(lut_rol1c), .in_9(lut_rol8a));

lut_datapath LUT_C_DATAPATH 
	(.out(lut_outc), .in1(shift_out2a), .in2(key_ina), .in3(lut_rol2a), 
	 .in_4(lut_rol1a), .in_5(lut_rol8a), 
	 .in_6_(lut_rol1a), .in_7_(lut_rol8b), 
	 .in_8(lut_rol1b), .in_9(lut_rol8a));

// The global output that gives the ciphertext value
// Can be modified in future since right now it does not mean anything
reg out_res_1, out_res_2, out_res_3;
always @(*) begin
	if (round_num >= `ROUNDS - 2) begin
		out_res_1 <= lut_outa;
		out_res_2 <= lut_outb;
		out_res_3 <= lut_outc;
	end
	else begin
		out_res_1 <= 0;
		out_res_2 <= 0;
		out_res_3 <= 0;
	end
end
//assign cipher_out = out_res_1 ^ out_res_2 ^ out_res_3;
assign cipher_outa = out_res_1;
assign cipher_outb = out_res_2;
assign cipher_outc = out_res_3;

endmodule
