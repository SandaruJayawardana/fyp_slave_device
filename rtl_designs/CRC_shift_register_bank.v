module CRC_shift_register_bank(
	output [31:0] crc_out,
	input in_data,
	input clk_in,
	input en,
	input reset_n
	);
	
		DFFE reg_0 (
				.d(in_data^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[31])
				);
		DFFE reg_1 (
				.d(crc_out[31]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[30])
				);
		DFFE reg_2 (
				.d(crc_out[30]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[29])
				);
		DFFE reg_3 (
				.d(crc_out[29]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[28])
				);
		DFFE reg_4 (
				.d(crc_out[28]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[27])
				);
		DFFE reg_5 (
				.d(crc_out[27]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[26])
				);
		DFFE reg_6 (
				.d(crc_out[26]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[25])
				);
		DFFE reg_7 (
				.d(crc_out[25]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[24])
				);
		DFFE reg_8 (
				.d(crc_out[24]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[23])
				);
		DFFE reg_9 (
				.d(crc_out[23]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[22])
				);
		DFFE reg_10 (
				.d(crc_out[22]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[21])
				);
		DFFE reg_11 (
				.d(crc_out[21]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[20])
				);

		DFFE reg_12 (
				.d(crc_out[20]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[19])
				);
		DFFE reg_13 (
				.d(crc_out[19]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[18])
				);
		DFFE reg_14 (
				.d(crc_out[18]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[17])
				);
		DFFE reg_15 (
				.d(crc_out[17]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[16])
				);
		DFFE reg_16 (
				.d(crc_out[16]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[15])
				);
		DFFE reg_17 (
				.d(crc_out[15]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[14])
				);
		DFFE reg_18 (
				.d(crc_out[14]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[13])
				);
		DFFE reg_19 (
				.d(crc_out[13]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[12])
				);
		DFFE reg_20 (
				.d(crc_out[12]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[11])
				);
		DFFE reg_21 (
				.d(crc_out[11]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[10])
				);
		DFFE reg_22 (
				.d(crc_out[10]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[9])
				);
		DFFE reg_23 (
				.d(crc_out[9]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[8])
				);
		DFFE reg_24 (
				.d(crc_out[8]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[7])
				);
		DFFE reg_25 (
				.d(crc_out[7]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[6])
				);
		DFFE reg_26 (
				.d(crc_out[6]^crc_out[0]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[5])
				);
		DFFE reg_27 (
				.d(crc_out[5]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[4])
				);
		DFFE reg_28 (
				.d(crc_out[4]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[3])
				);
		DFFE reg_29 (
				.d(crc_out[3]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[2])
				);
		DFFE reg_30 (
				.d(crc_out[2]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[1])
				);
		DFFE reg_31 (
				.d(crc_out[1]), 
				.clk(clk_in), 
				.clrn(reset_n), 
				//.prn(<active_low_preset>), 
				.ena(en), 
				.q(crc_out[0])
				);
endmodule 