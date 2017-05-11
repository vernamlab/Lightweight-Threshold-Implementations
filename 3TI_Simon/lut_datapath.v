module lut_datapath
	(out, in1, in2, in3, in_4, in_5, in_6_, in_7_, in_8, in_9);
	
	//------------------------------------------------
	input in1, in2, in3, in_4, in_5, in_6_, in_7_, in_8, in_9;
	output out;

	//------------------------------------------------
	//assign lut_outa = shift_out2a ^ key_ina ^ lut_rol2a ^ (lut_rol1a & lut_rol8a) ^ (lut_rol1a & lut_rol8b) ^ (lut_rol1b & lut_rol8a);
	assign out = in1 ^ in2 ^ in3 ^ (in_4 & in_5) ^ (in_6_ & in_7_) ^ (in_8 & in_9);

endmodule //lut_datapath