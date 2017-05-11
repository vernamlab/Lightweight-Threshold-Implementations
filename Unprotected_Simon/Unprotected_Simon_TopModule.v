`timescale 1ns / 1ps

module sasebo_simon
  (Din, Dout, Drdy, Dvld, EN, BSY, CLK, RSTn, Trig);

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
   //------------------------------------------------
   reg [(128*6)-1:0]    dat;
   wire [127:0]   dat_next;
	reg [68:0]     rnd;
   reg            sel;  // Indicate final round
   reg            Dvld;//, BSY;
   wire           rst;
   wire           BSY;
	
	//for simon
	reg data_rdy;
	reg [127:0]count;
	reg [1:0] state;
	reg [255:0] share_a, share_b,share_c;
	wire res;
	wire Done;
	reg [127:0]Ser_2_Par;
   //------------------------------------------------
   assign rst = ~RSTn;
     
   always @(posedge CLK or posedge rst) begin
      if (rst)     Dvld <= 0;
      else if (EN) Dvld <= Done;
   end
  
   always @(posedge CLK or posedge rst) begin
      if (rst) begin
			dat <= {256{1'h0}};
			share_a <= {256{1'h0}};
			share_b <= {256{1'h0}};
			share_c <= {256{1'h0}};
		end
      else if (EN) begin
         if (Drdy) begin            
				// dat <= Din;
				share_a <= Din[767:512];
				share_b <= Din[511:256];
				share_c <= Din[255:0];
			end
			else begin
				share_a <= {1'd0,share_a[255:1]};
				share_b <= {1'd0,share_b[255:1]};
				share_c <= {1'd0,share_c[255:1]};
			end
        // else if (~rnd[0]|sel) dat <= dat_next;
      end
   end
   assign Dout = Ser_2_Par;//dat;
	
	assign BSY = &state;
	  
   always @(posedge CLK or posedge rst) begin
      if (rst)                 state <= 2'b00;
      else if (EN) begin
         if (Drdy)             							state <= 2'b10;
         else if (count[127]==1 && state == 2'b10)  	state <= 2'b01;
			else if (count[127]==1 && state == 2'b01)  	state <= 2'b00;
			else if (count[5] && state == 2'b00)  		state <= 2'b11;
			if(Done)												state <= 2'b00;
      end
   end	  
	  
   always @(posedge CLK or posedge rst) begin
      if (rst)                count = 128'b0;
      else if (EN) begin
         if (Drdy)            count = 1;
         else 						count = {count[126:0],count[127]};
			if (state==3)        count = 0;
			if (Done)				count = 0;
      end
   end		
////////////////////////////////
serial_simon my_simon_core
       (.clk(CLK),.data_in(share_a[0] ^ share_b[0] ^ share_c[0]),.data_rdy(state),.cipher_out(res),
		 .Done(Done),.Trig(Trig));

reg [127:0] cout;
always@(posedge CLK)
begin
	cout <= {res, cout[127:1]};
end

always@(posedge CLK)
begin
	if(Drdy) begin
		Ser_2_Par <= 0;
	end
	if(Dvld) begin
		Ser_2_Par <= cout;
	end		
end	

endmodule 
