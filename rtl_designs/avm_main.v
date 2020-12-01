module avm_main(
	input reset_n,
	input clk_50,//50 MHz
	
	//main controller
	input [31:0] data_write_main,
	input [1:0] mode_main, //00- Normal operation, 01-EEPROM read full, 10-singlewrite, 11-single read
	output [31:0] e_ram_data_read_main,
	input [15:0] r_w_addr_main,
	output [7:0] e_ram_addr_read_main,//EEPROM_addr
	output reg e_ram_write_en_main,
	output reg EEPROM_error_main,
	output wait_request_main,
	input new_main,//00-boot 01-write 10-read
	
	//avs
	input [1:0] avs_response,
	input avs_waitrequest,
	output [15:0] avm_addr,
	output reg [31:0] avm_data_write_reg,
	input [31:0] avm_data_read_receive,
	output reg avm_datawrite_en_reg,
	output reg avm__dataread_en_reg
	
	
	);
	
	reg [31:0] avm_data_read_receive_reg;
	reg [15:0] avm_r_w_addr_reg;
	reg [7:0] counter_reg;
	reg avm_mode_reg;
	reg avm_boot_reg;
	reg [3:0] avm_state;
	
	
	assign e_ram_addr_read_main=counter_reg;
	and new_requet_and(wait_request_main,new_main,~avm_mode_reg);
	assign avm_addr=(avm_boot_reg)? {8'b0,counter_reg}:avm_r_w_addr_reg;
	assign e_ram_data_read_main=avm_data_read_receive_reg;
	
	parameter avm_ideal=4'd0,avm_boot_init=4'd1,avm_boot_wait=4'd2,avm_boot_next_addr=4'd3,avm_wait_low_new_main=4'd4,avm_write_init=4'd5,avm_write_wait=4'd6,avm_read_init=4'd7,avm_read_wait=4'd8;
	
	always @(posedge clk_50 or negedge reset_n)
		begin	
			if(~reset_n)
				begin	
					counter_reg<=8'b0;
					avm_mode_reg<=1'b0;// 0-ideal/processing 1-ready
					avm_datawrite_en_reg<=1'b0;
					avm__dataread_en_reg<=1'b0;
					avm_state<=4'b0;
					e_ram_write_en_main<=1'b0;
					avm_data_read_receive_reg<=32'b0;
					avm_data_write_reg<=32'b0;
					avm_boot_reg<=1'b0;
					avm_r_w_addr_reg<=16'b0;
					EEPROM_error_main<=1'b0;
				end
			else	
				begin	
					case(avm_state)
						avm_ideal:
							begin	
								counter_reg<=8'b0;
								avm_mode_reg<=1'b0;
								e_ram_write_en_main<=1'b0;
								avm_data_read_receive_reg<=avm_data_read_receive_reg;
								EEPROM_error_main<=1'b0;
								casex({new_main,mode_main})
									3'b0xx:
										begin
											avm_state<=avm_state;
											avm_datawrite_en_reg<=1'b0;
											avm__dataread_en_reg<=1'b0;
											avm_boot_reg<=1'b0;
											avm_data_write_reg<=32'bx;
											avm_r_w_addr_reg<=16'bx;
										end
									3'b100:
										begin
											avm_state<=avm_boot_init;
											avm_datawrite_en_reg<=1'b0;
											avm__dataread_en_reg<=1'b1;
											avm_boot_reg<=1'b1;
											avm_data_write_reg<=32'bx;
											avm_r_w_addr_reg<=16'bx;
										end
									3'b101:
										begin
											avm_state<=avm_write_init;
											avm_datawrite_en_reg<=1'b1;
											avm__dataread_en_reg<=1'b0;
											avm_boot_reg<=1'b0;
											avm_data_write_reg<=data_write_main;
											avm_r_w_addr_reg<=r_w_addr_main;
										end
									3'b100:
										begin
											avm_state<=avm_read_init;
											avm_datawrite_en_reg<=1'b0;
											avm__dataread_en_reg<=1'b1;
											avm_boot_reg<=1'b0;
											avm_data_write_reg<=32'bx;
											avm_r_w_addr_reg<=r_w_addr_main;
										end
									default:
										begin
											avm_state<=avm_state;
											avm_datawrite_en_reg<=1'b0;
											avm__dataread_en_reg<=1'b0;
											avm_boot_reg<=1'b0;
											avm_data_write_reg<=32'bx;
											avm_r_w_addr_reg<=16'bx;
										end
								endcase
							end
						avm_boot_init:
							begin
								counter_reg<=counter_reg;
								avm_mode_reg<=1'b0;
								avm_datawrite_en_reg<=1'b0;
								avm__dataread_en_reg<=1'b1;
								avm_boot_reg<=1'b1;
								e_ram_write_en_main<=1'b0;
								avm_state<=avm_boot_wait;
								avm_data_read_receive_reg<=avm_data_read_receive_reg;
								avm_data_write_reg<=32'bx;
								avm_r_w_addr_reg<=16'bx;
								EEPROM_error_main<=EEPROM_error_main;
							end
						avm_boot_wait:
							begin
								counter_reg<=counter_reg;
								avm_datawrite_en_reg<=1'b0;
								avm_boot_reg<=1'b1;
								avm_mode_reg<=1'b0;
								avm_data_write_reg<=32'bx;
								avm_r_w_addr_reg<=16'bx;
								if(avs_waitrequest)
									begin	
										avm_state<=avm_state;
										avm_data_read_receive_reg<=avm_data_read_receive_reg;
										e_ram_write_en_main<=1'b0;
										avm__dataread_en_reg<=1'b1;
										EEPROM_error_main<=EEPROM_error_main;
									end
								else	
									begin
										avm_state<=avm_boot_next_addr;
										avm_data_read_receive_reg<=avm_data_read_receive;
										e_ram_write_en_main<=1'b1;
										avm__dataread_en_reg<=1'b0;
										EEPROM_error_main<=(avs_response!=2'b00);//00-okay
									end	
							end
						avm_boot_next_addr:
							begin
								avm_mode_reg<=1'b0;
								avm_boot_reg<=1'b1;
								avm_datawrite_en_reg<=1'b0;
								e_ram_write_en_main<=1'b0;
								avm_data_read_receive_reg<=avm_data_read_receive_reg;
								avm_data_write_reg<=32'bx;
								avm_r_w_addr_reg<=16'bx;
								EEPROM_error_main<=EEPROM_error_main;
								if(counter_reg==8'b11111111)
									begin
										avm_state<=avm_wait_low_new_main;
										counter_reg<=8'b0;
										avm__dataread_en_reg<=1'b0;
									end
								else
									begin
										avm_state<=avm_boot_init;
										counter_reg<=counter_reg+8'b1;
										avm__dataread_en_reg<=1'b1;
									end
							end
						avm_wait_low_new_main:
							begin
								counter_reg<=8'b0;
								avm_boot_reg<=1'b0;
								e_ram_write_en_main<=1'b0;
								avm__dataread_en_reg<=1'b0;
								avm_datawrite_en_reg<=1'b0;
								avm_data_read_receive_reg<=avm_data_read_receive_reg;
								avm_data_write_reg<=32'bx;
								avm_r_w_addr_reg<=16'bx;
								EEPROM_error_main<=EEPROM_error_main;
								if(new_main)
									begin
										avm_state<=avm_state;
										avm_mode_reg<=avm_mode_reg;
									end
								else
									begin
										avm_state<=avm_ideal;
										avm_mode_reg<=1'b0;
									end
							
							end
						avm_write_init:
							begin
								counter_reg<=8'b0;
								avm_mode_reg<=1'b0;
								avm_datawrite_en_reg<=1'b1;
								avm__dataread_en_reg<=1'b0;
								avm_boot_reg<=1'b0;
								e_ram_write_en_main<=1'b0;
								avm_state<=avm_write_wait;
								avm_data_read_receive_reg<=avm_data_read_receive_reg;
								avm_data_write_reg<=avm_data_write_reg;
								avm_r_w_addr_reg<=avm_r_w_addr_reg;
								EEPROM_error_main<=1'b0;
							end
						avm_write_wait:
							begin
								counter_reg<=8'b0;
								avm__dataread_en_reg<=1'b0;
								avm_boot_reg<=1'b0;
								avm_data_read_receive_reg<=avm_data_read_receive_reg;
								avm_data_write_reg<=avm_data_write_reg;
								avm_r_w_addr_reg<=avm_r_w_addr_reg;
								e_ram_write_en_main<=1'b0;
								if(avs_waitrequest)
									begin	
										avm_state<=avm_state;
										avm_mode_reg<=1'b0;
										EEPROM_error_main<=1'b0;
										avm_datawrite_en_reg<=1'b1;
									end
								else	
									begin
										avm_state<=avm_wait_low_new_main;
										avm_mode_reg<=1'b1;
										avm_datawrite_en_reg<=1'b0;
										EEPROM_error_main<=(avs_response!=2'b00);//00-okay
									end	
							end
						avm_read_init:
							begin
								counter_reg<=8'b0;
								avm_mode_reg<=1'b0;
								avm_datawrite_en_reg<=1'b0;
								avm__dataread_en_reg<=1'b1;
								avm_boot_reg<=1'b0;
								e_ram_write_en_main<=1'b0;
								avm_state<=avm_read_wait;
								avm_data_read_receive_reg<=avm_data_read_receive_reg;
								avm_data_write_reg<=32'bx;
								avm_r_w_addr_reg<=avm_r_w_addr_reg;
								EEPROM_error_main<=1'b0;
							end
						avm_read_wait:
							begin
								counter_reg<=8'b0;
								avm_datawrite_en_reg<=1'b0;
								avm_boot_reg<=1'b0;
								e_ram_write_en_main<=1'b0;
								avm_data_write_reg<=32'bx;
								avm_r_w_addr_reg<=avm_r_w_addr_reg;
								if(avs_waitrequest)
									begin	
										avm_state<=avm_state;
										avm_data_read_receive_reg<=avm_data_read_receive_reg;
										avm__dataread_en_reg<=1'b1;
										avm_mode_reg<=1'b0;
										EEPROM_error_main<=1'b0;
									end
								else	
									begin
										avm_state<=avm_wait_low_new_main;
										avm_data_read_receive_reg<=avm_data_read_receive;
										avm__dataread_en_reg<=1'b0;
										avm_mode_reg<=1'b1;
										EEPROM_error_main<=(avs_response!=2'b00);//00-okay
									end	
							end
						default:
							begin
								counter_reg<=8'b0;
								avm_mode_reg<=1'b0;// 0-ideal/processing 1-ready
								avm_datawrite_en_reg<=1'b0;
								avm__dataread_en_reg<=1'b0;
								avm_state<=4'b0;
								e_ram_write_en_main<=1'b0;
								avm_data_read_receive_reg<=32'b0;
								avm_boot_reg<=1'b0;
								avm_data_write_reg<=32'bx;
								avm_r_w_addr_reg<=16'bx;
								EEPROM_error_main<=1'b0;
							end
					endcase
				end
		end



	endmodule
								
								
								
								
								
								
								
								
								
								
								
								
								
								