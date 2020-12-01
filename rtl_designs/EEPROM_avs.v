module EEPROM_avs(
	
	input clk_50,
	input reset_n,
	
	
		//avs
	output reg [1:0] avs_response_reg=2'b00,
	output reg avs_waitrequest_reg,
	input [7:0] avm_addr,
	input [31:0] avm_data_write,
	output [31:0] avm_data_read_receive,
	input avm_datawrite_en,
	input avm__dataread_en
	
	
	
	);
	
	
	
	EEPROM_I2C_RAM eeprom_i2c_ram(.data(avm_data_write),.addr(avm_addr),.we(avm_datawrite_en), .clk(clk_50),.q(avm_data_read_receive));
	
	reg [2:0] count_avs;
	reg [2:0] state_avs;
	parameter ideal=3'b0,wait_count=3'b1;
	always @(posedge clk_50 or negedge reset_n)
		begin
			if (~reset_n)
				begin
					count_avs<=3'b0;
					state_avs<=3'b0;
					avs_waitrequest_reg<=1'b0;
				end
			else
				begin
					case(state_avs)
						ideal:
							begin
								count_avs<=3'b0;
								case({avm_datawrite_en,avm__dataread_en})
									
									2'b00:
										begin
											avs_waitrequest_reg<=1'b0;
											state_avs<=state_avs;
										end
									2'b10:
										begin
											avs_waitrequest_reg<=1'b1;
											state_avs<=wait_count;
										end
									2'b01:
										begin
											avs_waitrequest_reg<=1'b1;
											state_avs<=wait_count;
										end
									default:
										begin
											avs_waitrequest_reg<=1'b0;
											state_avs<=state_avs;
										end
								endcase
							end	
						wait_count:
							begin	
								if(count_avs== 3'b111)
									begin
										count_avs<=3'b0;
										avs_waitrequest_reg<=1'b0;
										state_avs<=ideal;
									end
								else	
									begin
										count_avs<=count_avs+3'b1;
										avs_waitrequest_reg<=1'b0;
										state_avs<=state_avs;
									end
							end
						default:
							begin
								count_avs<=3'b0;
								state_avs<=3'b0;
								avs_waitrequest_reg<=1'b0;
							end
					endcase
			end
	end
	
endmodule
