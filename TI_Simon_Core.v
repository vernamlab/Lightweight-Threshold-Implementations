`timescale 1ns / 1ps

module TI_Simon_Core(
       clk, data_ina, data_inb, data_rdy, cipher_outa, cipher_outb, round_counter, Done, Trig);
		 
	//------------------------------------------------ Interfaces
	input clk;
	input data_ina, data_inb;
	input [1:0] data_rdy;
	output cipher_outa, cipher_outb;
	output reg [6:0] round_counter;
	output reg Done, Trig;

	//------------------------------------------------
	reg [5:0] bit_counter;
	reg flag;
	
	wire shifter_enable1,shifter_enable2;
	wire lut_ff_enable,fifo_ff_enable;
	
	wire [1:0] s1,s3;
	wire s2;
	wire keya, keyb;

	// bit_counter logic
	always@(posedge clk)
	begin
		if(data_rdy==0)
			bit_counter <= 0;
		else if(flag) 
			bit_counter <= bit_counter + 1;		
		else
			bit_counter <= bit_counter;
	end
	
	always@(posedge clk) 
	begin
		if(data_rdy==0)
			flag <= 0;
		else if(data_rdy == 3)
		begin
			if(bit_counter == 63)
				flag <= ~flag;
			else
				flag <= 1;
		end
		else
			flag <= flag;
	end
	
	// round_counter logic
	always@(posedge clk)
	begin
		if(data_rdy==0)
			round_counter <= 0;
		else if(data_rdy == 3 && bit_counter == 63)
			round_counter <= round_counter + 1;
		else
			round_counter <= round_counter;
	end

	always @(posedge clk) begin
		if (round_counter == 0 && bit_counter == 1) //So it means first 4 rounds
			Trig = 1;
		else
			Trig = 0;

		if(data_rdy == 3 && round_counter == 67 && bit_counter == 62)
			Done = 1;			
		else
			Done = 0;
	end
	//------------------------------------------------
	/*
		data_rdy=0 -> Reset, Idle
		data_rdy=1 -> Load Plaintext
		data_rdy=2 -> Load Key
		data_rdy=3 -> Run (keep at 3 while the block cipher is running)
	*/

	datapath_simon2share SIMON_DATAPATH
					(.clk(clk), 
					 .data_ina(data_ina), .data_inb(data_inb), 
					 .data_rdy(data_rdy), 
					 .key_ina(keya), .key_inb(keyb),
					 .cipher_outa(cipher_outa), .cipher_outb(cipher_outb), 
					 .round_counter_0(round_counter[0]), .bit_counter(bit_counter), .flag(flag));
											
	key_schedule_1 SIMON_KEY_EXP_1
					(.clk(clk), 
					 .data_in(data_ina), .data_rdy(data_rdy), 
					 .key_out(keya), 
					 .bit_counter(bit_counter), .round_counter(round_counter),
					 .s2(s2), .s1(s1), .s3(s3), .flag(flag),
					 .shifter_enable1(shifter_enable1), .shifter_enable2(shifter_enable2),
					 .lut_ff_enable(lut_ff_enable), .fifo_ff_enable(fifo_ff_enable));

	key_schedule_2 SIMON_KEY_EXP_2
					(.clk(clk), .data_in(data_inb), .key_out(keyb), 
					 .bit_counter(bit_counter), 
					 .s2(s2), .s1(s1), .s3(s3), .flag(flag),
					 .shifter_enable1(shifter_enable1), .shifter_enable2(shifter_enable2),
					 .lut_ff_enable(lut_ff_enable), .fifo_ff_enable(fifo_ff_enable));

endmodule

// 
module datapath_simon2share(clk, data_ina, data_inb, data_rdy, key_ina, key_inb, 
							cipher_outa, cipher_outb, round_counter_0, flag, bit_counter);
	input clk, data_ina, data_inb;
	input key_ina, key_inb;
	input [1:0] data_rdy;
	input round_counter_0;
	input [5:0] bit_counter;
	input flag;
	output cipher_outa, cipher_outb;

	reg s1, s2;
	reg [1:0] s3;

	wire lut_rol8_shifted_out_a, lut_rol8_shifted_out_b;
	reg shifter_enable1, shifter_enable2;
	//Selection MUX
	always@(*)
	begin
		// For the first 8 bits of each even round OR for all the bits after the first 8 bits in odd rounds OR loading the plaintext  
		if((round_counter_0==0 && (bit_counter<8 || flag==0))||(round_counter_0==1 && (bit_counter>7 && flag))||(data_rdy==1))
			s1 = 1;
		else 
			s1 = 0;
		
		if(round_counter_0==0) // Even rounds
			s2 = 0;
		else
			s2 = 1;

		if(data_rdy==1) // Loading plaintext
			s3 = 0;
		else if(bit_counter==63) // Even rounds
			s3 = 2;
		else  begin
			if(flag == 0) // Odd rounds
				s3 = 1;
			else
				s3 = s3;
		end
	end

	// SHIFTER ENABLES
	// Two shift registers are enabled when the plaintext is being loaded (1) or when the block cipher is running (3)
	always@(*)
	begin
		if(data_rdy == 1 || (data_rdy == 3 && bit_counter != 63))
		begin
			shifter_enable1 = 1;
			shifter_enable2 = 1;
		end
		else
		begin
			shifter_enable1 = 0;
			shifter_enable2 = 0;
		end
	end

	datapath_share dp_a(clk, data_ina, key_ina, shifter_enable1, shifter_enable2, cipher_outa,
						lut_rol8_shifted_out_b, lut_rol8_shifted_out_a, s1, s2, s3);

	datapath_share dp_b(clk, data_inb, key_inb, shifter_enable1, shifter_enable2, cipher_outb,
						lut_rol8_shifted_out_a, lut_rol8_shifted_out_b, s1, s2, s3);

endmodule

module datapath_share(clk, data_in, key_in, shifter_enable1, shifter_enable2, cipher_out, 
		 			  lut_rol8_shifted_ext, lut_rol8_shifted_out, s1, s2, s3);

	// interfaces
	input clk;
	input data_in, key_in;
	input s1, s2;
	input [1:0] s3;
	input shifter_enable1, shifter_enable2;
	input lut_rol8_shifted_ext;
	output cipher_out;
	output reg lut_rol8_shifted_out;
	
	// shift register 
	reg [54:0] shifter1;
	reg [63:0] shifter2;
	reg shift_in1,shift_in2;
	wire shift_out1,shift_out2;
	
	// FIFO
	reg fifo_ff62,fifo_ff61,fifo_ff60,fifo_ff59,fifo_ff58,fifo_ff57,fifo_ff56, fifo_ff55;
	reg lut_ff62,lut_ff61,lut_ff60,lut_ff59,lut_ff58,lut_ff57,lut_ff56, lut_ff55;
	reg ff63;
	
	reg lut_ff_input,fifo_ff_input, ff_input;
	reg lut_rol1,lut_rol2,lut_rol8;
	reg lut_rol1_shifted;
	wire lut_out;
	// Loading data in
	always @(posedge clk)
	begin
		if(shifter_enable1)
			shifter1 <= {shift_in1, shifter1[54:1]};
	end
	
	assign shift_out1 = shifter1[0];
	
	always @(posedge clk)
	begin
		if(shifter_enable2)
			shifter2 <= {shift_in2, shifter2[63:1]};
	end
	
	assign shift_out2 = shifter2[0];
	
	always@(posedge clk)
	begin
		ff63 <= ff_input;
		if(shifter_enable1)
		begin	
			fifo_ff62 <= fifo_ff_input;
			fifo_ff61 <= fifo_ff62;
			fifo_ff60 <= fifo_ff61;
			fifo_ff59 <= fifo_ff60;
			fifo_ff58 <= fifo_ff59;
			fifo_ff57 <= fifo_ff58;
			fifo_ff56 <= fifo_ff57;
			fifo_ff55 <= fifo_ff56;
		end
	end

	always@(posedge clk)
	begin
		if(shifter_enable1)
		begin
			lut_ff62 <= lut_ff_input;
			lut_ff61 <= lut_ff62;
			lut_ff60 <= lut_ff61;
			lut_ff59 <= lut_ff60;
			lut_ff58 <= lut_ff59;
			lut_ff57 <= lut_ff58;
			lut_ff56 <= lut_ff57;
			lut_ff55 <= lut_ff56;
		end
	end
	
	always@(*)
	begin
			shift_in2 = shift_out1;
	end
	
	always@(*)
	begin
		if(s1 == 0)
			shift_in1 = lut_ff55;
		else
			shift_in1 = fifo_ff55;
	end
	
	always@(*)
	begin
		if(s3 == 0)
			ff_input = data_in;
		else if(s3 == 1) begin
			ff_input = shift_out1;
		end
		else if(s3 == 2) begin
			ff_input = lut_out;
		end
		else
			ff_input = ff_input; 
	end
	
	always@(*)
	begin
		if(s2 == 0) 
			fifo_ff_input = ff63;
		else
			fifo_ff_input = lut_out;
	end
	
	always@(*)
	begin
		if(s2 == 1)
			lut_ff_input = ff63;
		else
			lut_ff_input = lut_out;
	end
	
	always@(*)
	begin
		lut_rol1 = ff63;
		
		if(s2 == 0) 
			lut_rol1_shifted = fifo_ff62;
		else
			lut_rol1_shifted = lut_ff62;
		
		if(s2 == 0)
			lut_rol8_shifted_out = fifo_ff55;
		else
			lut_rol8_shifted_out = lut_ff55;
		
		if(s2 == 0)
			lut_rol2 = fifo_ff62;
		else
			lut_rol2 = lut_ff62;
			
		if(s2 == 0)
			lut_rol8 = fifo_ff56;
		else
			lut_rol8 = lut_ff56;
	end

	lut_datapath LUT_A_DATAPATH 
	(.clk(clk), .out(lut_out), .shift_out2(shift_out2), .key_in(key_in), .lut_rol2(lut_rol2), 
	 .lut_rol1(lut_rol1), .lut_rol8(lut_rol8), 
	 .lut_rol1_shifted(lut_rol1_shifted), .lut_rol8_ext(lut_rol8_shifted_ext));
	 
	assign cipher_out = lut_out; 
endmodule

//================================================ lut_datapath
module lut_datapath
	(clk, out, shift_out2, key_in, lut_rol2, lut_rol1, lut_rol8, lut_rol1_shifted, lut_rol8_ext);
	
	//------------------------------------------------
	input clk, shift_out2, key_in, lut_rol2, lut_rol1, lut_rol8, lut_rol1_shifted, lut_rol8_ext;
	output out;
	reg intreg;
	//------------------------------------------------
	//assign lut_outa = shift_out2a ^ key_ina ^ lut_rol2a ^ (lut_rol1a & lut_rol8a) ^ (lut_rol1a & lut_rol8b);
	always @(posedge clk)
	begin
		intreg <= shift_out2 ^ lut_rol2 ^ (lut_rol1 & lut_rol8);
	end
	assign out = key_in ^ (lut_rol1_shifted & lut_rol8_ext) ^ intreg;

endmodule //lut_datapath

//================================================ key_schedule_modified1_simon_parallel
module key_schedule_1
	(clk,data_in,key_out,data_rdy,round_counter,bit_counter,flag,
	s2,s1,s3,shifter_enable1,shifter_enable2,lut_ff_enable,fifo_ff_enable);

	//------------------------------------------------
	input clk;
	input data_in;
	input [1:0] data_rdy;
	input [5:0] bit_counter;
	input [6:0] round_counter;
	input flag;
	output key_out;
	//output [6:0]round_counter;
	output s2;
	output [1:0] s1,s3;
	output shifter_enable1,shifter_enable2;
	output lut_ff_enable,fifo_ff_enable;
	//------------------------------------------------
	reg [59:0] shifter1;
	reg [63:0] shifter2;
	reg shift_in1,shift_in2;
	wire shift_out1,shift_out2;
	reg shifter_enable1,shifter_enable2;
	reg lut_ff_enable,fifo_ff_enable;
	wire lut_out;
	reg lut_in3;
	reg s2;
	reg [1:0] s1,s3;
	reg z_value;
	reg fifo_ff0,fifo_ff1,fifo_ff2,fifo_ff3;
	//(* shreg_extract = "no" *)
	reg lut_ff0,lut_ff1,lut_ff2,lut_ff3;
	//Constant value Z ROM
	wire [0:67] Z = 68'b10101111011100000011010010011000101000010001111110010110110011101011;
	//------------------------------------------------
	// Least bit of the round counter is sent to the datapath to check if it is even or odd

	// Shift Register1 FIFO 60x1 Begin
	// 60x1 shift register storing the 60 most significant bits of the upper word of the key
	always @(posedge clk)
	begin
		if(shifter_enable1)
		begin
			shifter1 <= {shift_in1, shifter1[59:1]};
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
			shifter2 <= {shift_in2, shifter2[63:1]};
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

	always@(*)
	begin
		if(data_rdy==2)
			s3 = 1;//shift_in2 = fifo_ff0;
		else if(data_rdy==3 && (round_counter<1 || (bit_counter>3 && bit_counter != 127)))
			s3 = 2;//shift_in2 = fifo_ff0;
		else if(data_rdy==3 && bit_counter<4 && round_counter>0) 
			s3 = 3;//shift_in2 = lut_ff0; 
		else
			s3 = 0;//shift_in2 = 1'bx;
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

	//S2 MUX
	always@(*)
	begin
		if((flag && bit_counter==0) && round_counter!=0)
			s2 = 1;
		else
			s2 = 0;
	end

	//S1 MUX
	always@(*)
	begin
		if(data_rdy==2)
			s1 = 1;
		else if(data_rdy==3 && (flag && bit_counter<4) && round_counter==0)
			s1 = 0;
		else if(data_rdy==3 && (flag && bit_counter<4) && round_counter>0)
			s1 = 3;
		else
			s1 = 2;
	end

	// LUT FF ENABLE MUX
	// LUT FFs are used only at the first four clock cycles of each round
	always@(*)
	begin
		if(data_rdy==3 && (flag && bit_counter<4))
			lut_ff_enable = 1;
		else
			lut_ff_enable = 0;
	end

	//FIFO FF ENABLE MUX
	always@(*)
	begin
		if(data_rdy==2 || flag)
			fifo_ff_enable = 1;
		else
			fifo_ff_enable = 0;
	end

	//SHIFTER ENABLES
	// Shifters are enabled when the key is loaded or block cipher is running
	always@(*)
	begin
		if(data_rdy==2 || flag)
			shifter_enable1 = 1;
		else
			shifter_enable1 = 0;
		
		if(data_rdy==2 || flag)
			shifter_enable2 = 1;
		else
			shifter_enable2 = 0;
			
	end


	// The necessary bit of the constant Z is selected by the round counter
	always @(*)
	begin
		if(bit_counter==0)
			z_value = Z[round_counter];
		else
			z_value = 0;
	end

	// New computed key bit
	assign lut_out = shift_out2 ^ lut_in3 ^ shift_out1 ^ z_value;// ^ c;

	// Output key bit that is connected to the datapath	
	assign key_out = shift_out2;
	
endmodule

//================================================ key_schedule_modified2_simon_parallel
module key_schedule_2
	(clk,data_in,key_out, bit_counter, flag,s2,s1,s3,shifter_enable1,shifter_enable2,lut_ff_enable,fifo_ff_enable);

	//------------------------------------------------
	input clk;
	input data_in;
	//input [1:0] data_rdy;
	input [5:0] bit_counter;
	input flag;
	output key_out;
	input s2;
	input [1:0] s1,s3;
	input shifter_enable1,shifter_enable2;
	input lut_ff_enable,fifo_ff_enable;
	//------------------------------------------------
	reg [59:0] shifter1;
	reg [63:0] shifter2;
	reg shift_in1,shift_in2;
	wire shift_out1,shift_out2;
	wire lut_out;
	reg lut_in3;
	reg c;
	reg fifo_ff0,fifo_ff1,fifo_ff2,fifo_ff3;
	//(* shreg_extract = "no" *)
	reg lut_ff0,lut_ff1,lut_ff2,lut_ff3;
	//------------------------------------------------
	// Shift Register1 FIFO 60x1 Begin
	// 60x1 shift register storing the 60 most significant bits of the upper word of the key
	always @(posedge clk)
	begin
		if(shifter_enable1)
		begin
			shifter1 <= {shift_in1, shifter1[59:1]};
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
			shifter2 <= {shift_in2, shifter2[63:1]};
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
		if((flag && bit_counter==0) || bit_counter==1)
			c = 0;
		else 
			c = 1;
	end

	// New computed key bit
	assign lut_out = shift_out2 ^ lut_in3 ^ shift_out1 ^ c;

	// Output key bit that is connected to the datapath	
	assign key_out = shift_out2;
		
endmodule //key_schedule_modified2_simon_parallel