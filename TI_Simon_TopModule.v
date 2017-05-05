`timescale 1ns / 1ps

module TI_Simon_TopModule(Din, Dout, Drdy, Dvld, EN, BSY, CLK, RSTn, Trig);

//------------------------------------------------
input [(128*6)-1:0]  Din;  // Data input
output [127:0] Dout; // Data output
input          Drdy; // Data input ready
output         Dvld; // Data output valid

input          EN;   // circuit enable
output         BSY;  // Busy signal
input          CLK;  // System clock
input          RSTn; // Reset (Low active)
output         Trig; //	Based on The number of desired rounds can be adjusted

reg            Dvld;
wire           rst;
wire           BSY;

//for simon
reg [127:0]count;
wire [6:0] round_counter;
reg [1:0] state;
reg [255:0] share_a, share_b,share_c;

wire Done;
reg [127:0]Ser_2_Par;
wire cipher_outa, cipher_outb;
reg [63:0] cout_La, cout_Lb, cout_Ra, cout_Rb;
//------------------------------------------------
assign rst = ~RSTn;

always @(posedge CLK or posedge rst) begin
	if (rst)     Dvld <= 0;
	else if (EN) Dvld <= Done;
end

always @(posedge CLK or posedge rst) begin
	if (rst) begin
		share_a <= {256{1'h0}};
		share_b <= {256{1'h0}};
		share_c <= {256{1'h0}};
	end
	else if (EN) begin
		if (Drdy) begin            
			share_a <= Din[767:512];
			share_b <= Din[511:256];
			share_c <= Din[255:0];
		end
		else begin
			share_a <= {1'd0,share_a[255:1]};
			share_b <= {1'd0,share_b[255:1]};
			share_c <= {1'd0,share_c[255:1]};
		end
	end
end

always @(posedge CLK or posedge rst) begin
	if (rst)	state <= 2'b00;
	else if (EN) begin
		if (Drdy)	
			state <= 2'b10;
		else if (count[127]==1 && state == 2'b10)  	
			state <= 2'b01;
		else if (count[127]==1 && state == 2'b01)  	
			state <= 2'b11;
		if(Done)
			state <= 2'b00;
	end
end	  

always @(posedge CLK or posedge rst) begin
	if (rst)
		count = 128'b0;
	else if (EN) begin
		if (Drdy)
			count = 1;
		else
			count = {count[126:0],count[127]};
		if (state==3)
			count = 0;
		if (Done)
			count = 0;
	end
end		

always@(posedge CLK) begin
	if (round_counter ==  66) begin
		cout_Ra <= {cipher_outa, cout_Ra[63:1]};
		cout_Rb <= {cipher_outb, cout_Rb[63:1]};
	end
	else if (round_counter ==  67) begin
		cout_La <= {cipher_outa, cout_La[63:1]};
		cout_Lb <= {cipher_outb, cout_Lb[63:1]};
	end
	else begin
		cout_Ra <= 0;
		cout_Rb <= 0;
		cout_La <= 0;
		cout_Lb <= 0;
	end
end

always@(posedge CLK) begin
	if(Dvld) begin
		Ser_2_Par <= {cout_La, cout_Ra}^{cout_Lb, cout_Rb};
	end		
end	

assign Dout = Ser_2_Par;
assign BSY = &state;

TI_Simon_Core my_simon_core
	(.clk(CLK), .data_rdy(state), .data_ina(share_a[0]), .data_inb(share_b[0]^share_c[0]),
	.cipher_outa(cipher_outa), .cipher_outb(cipher_outb), .round_counter(round_counter),
	.Done(Done), .Trig(Trig));

endmodule 
