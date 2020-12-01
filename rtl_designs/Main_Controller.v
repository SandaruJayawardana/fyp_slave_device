//module Main_Controller(
//	input clk_in,
//	input reset_n,
//	
//	//Avalon Master
//	output [31:0] data_write,
//	output [1:0] mode, //00- Normal operation, 01-EEPROM read full, 10-singlewrite, 11-single read
//	input [31:0] data_read,
//	output [15:0] addr_write;
//	input [7:0] addr_read;//EEPROM_addr
//	input write_En,
//	input EEPROM_error,
//	input wait_request,
//	output new_operaton,
//	output write_en,
//	
//	
//	//Port 0 
//	
//	//RX_MAC
//	input reg count_addr_0,
//	input reg receive_mac_0,
//	input [7:0] data_0,
//	
//	//TX_MAC
//	output count_addr_tx_0,
//	output receive_mac_tx_0,
//	output [7:0] data_tx_0,
//	output [1:0] mode_0,
//	output [4:0] packet_no_0,
//	input [7:0] packet_data_0,
//	
//	//Port 1
//	
//	//RX_MAC
//	input reg count_addr_1,
//	input reg receive_mac_1,
//	input [7:0] data_1,
//	
//	//TX_MAC
//	output count_addr_tx_1,
//	output receive_mac_tx_1,
//	output [7:0] data_tx_1,
//	output [1:0] mode_1,
//	output [4:0] packet_no_1,
//	input [7:0] packet_data_1
//	
//	);
//	//EEPROM RAM
//	EEPROM_RAM eeprom_ram(.data(e_ram_data_in),.read_addr(e_ram_read_addr), .write_addr(e_ram_write_addr),.we(e_ram_we), .clk(clk_in),.q(e_ram_data_out));
//	
//	
//	
//	//	Slave addr register
//	reg [7:0] slave_addr;
//	wire [7:0] in_slave_addr;
//	wire en_slave_addr;
//	reg main_slave_addr_en;
//	reg back_slave_addr_en;
//	
//	assign in_slave_addr=(wait_reg)? back_reg_0:pipeline_reg_0;
//	assign en_slave_addr=(wait_reg)? back_slave_addr_en:main_slave_addr_en;
//	
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					slave_addr<=8'b0;
//				end
//			else
//				begin
//					if(en_slave_addr)
//						begin
//							slave_addr<=in_slave_addr;
//						end
//					else
//						begin
//							slave_addr<=slave_addr;
//						end
//				end
//		end
//	
//	//Sync 0 register
//	reg [31:0] sync_reg_0;
//	reg [3:0] back_sync_0_en;
//	reg [3:0] main_sync_0_en;
//	wire [3:0] en_sync_0;
//	wire [7:0] in_sync_0;
//	
//	assign in_sync_0=(wait_reg)? back_reg_0:pipeline_reg_0;
//	assign en_sync_0=(wait_reg)? back_sync_0_en:main_sync_0_en;
//	
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_0[7:0]<=8'b0;
//				end
//			else
//				begin
//					if(en_sync_0[0])
//						begin
//							sync_reg_0[7:0]<=in_sync_0;
//						end
//					else
//						begin
//							sync_reg_0[7:0]<=sync_reg_0[7:0];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_0[15:8]<=8'b0;
//				end
//			else
//				begin
//					if(en_sync_0[1])
//						begin
//							sync_reg_0[15:8]<=in_sync_0;
//						end
//					else
//						begin
//							sync_reg_0[15:8]<=sync_reg_0[15:8];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_0[23:16]<=8'b0;
//				end
//			else
//				begin
//					if(en_sync_0[2])
//						begin
//							sync_reg_0[23:16]<=in_sync_0;
//						end
//					else
//						begin
//							sync_reg_0[23:16]<=sync_reg_0[23:16];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_0[31:24]<=8'b0;
//				end
//			else
//				begin
//					if(en_sync_0[3])
//						begin
//							sync_reg_0[31:24]<=in_sync_0;
//						end
//					else
//						begin
//							sync_reg_0[31:24]<=sync_reg_0[31:24];
//						end
//				end
//		end
//	
//	// Sync 1 register
//	
//	reg [31:0] sync_reg_1;
//	reg [3:0] back_sync_1_en;
//	reg [3:0] main_sync_1_en;
//	wire [3:0] en_sync_1;
//	wire [7:0] in_sync_1;
//	
//	assign in_sync_1=(wait_reg)? back_reg_0:pipeline_reg_0;
//	assign en_sync_1=(wait_reg)? back_sync_1_en:main_sync_1_en;
//	
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_1[7:0]<=8'b0;
//				end
//			else
//				begin
//					if(en_sync_1[0])
//						begin
//							sync_reg_1[7:0]<=in_sync_1;
//						end
//					else
//						begin
//							sync_reg_1[7:0]<=sync_reg_1[7:0];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_1[15:8]<=8'b0;
//				end
//			else
//				begin
//					if(en_sync_1[1])
//						begin
//							sync_reg_1[15:8]<=in_sync_1;
//						end
//					else
//						begin
//							sync_reg_1[15:8]<=sync_reg_1[15:8];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_1[23:16]<=8'b0;
//				end
//			else
//				begin
//					if(en_sync_1[2])
//						begin
//							sync_reg_1[23:16]<=in_sync_1;
//						end
//					else
//						begin
//							sync_reg_1[23:16]<=sync_reg_1[23:16];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_1[31:24]<=8'b0;
//				end
//			else
//				begin
//					if(en_sync_1[3])
//						begin
//							sync_reg_1[31:24]<=in_sync_1;
//						end
//					else
//						begin
//							sync_reg_1[31:24]<=sync_reg_1[31:24];
//						end
//				end
//		end
//	
//	//i_o register
//	reg [7:0] cmd_i_o_reg;
//	reg [7:0] device_addr_i_o_reg;
//	reg [15:0] reg_addr_i_o_reg;
//	reg [31:0] data_i_o_reg;
//	reg main_wait_request_i_o;
//	reg back_wait_request_i_o;
//	reg main_new_i_o;
//	reg back_new_i_o;
//	wire new_i_o;
//	wire wait_request_i_o
//	reg wait_request_main;
//	reg new_secondary;
//	
//	//i_o register wait_request and new
//	assign new_i_o=(wait_reg)? back_new_i_o:main_new_i_o;
//	assign wait_request_i_o=(wait_reg)? back_wait_request_i_o:main_wait_request_i_o;
//	
//	//i_o register cmd
//	reg back_cmd_i_o_en;
//	reg main_cmd_i_o_en;
//	wire en_cmd_i_o;
//	wire [7:0] in_cmd_i_o;
//	
//	assign in_cmd_i_o=(wait_reg)? back_reg_0:pipeline_reg_0;
//	assign en_cmd_i_o=(wait_reg)? back_cmd_i_o_en:main_cmd_i_o_en;
//	
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					cmd_i_o_reg[7:0]<=8'b0;
//				end
//			else
//				begin
//					if(en_cmd_i_o)
//						begin
//							cmd_i_o_reg[7:0]<=in_cmd_i_o;
//						end
//					else
//						begin
//							cmd_i_o_reg[7:0]<=cmd_i_o_reg[7:0];
//						end
//				end
//		end
//	
//	//i_o register device addr
//	reg back_device_addr_i_o;
//	reg main_device_addr_i_o_en;
//	wire en_device_addr_i_o;
//	wire [7:0] in_device_addr_i_o;
//	
//	assign in_device_addr_i_o=(wait_reg)? back_reg_0:pipeline_reg_0;
//	assign en_device_addr_i_o=(wait_reg)? back_device_addr_i_o:main_device_addr_i_o;
//	
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					device_addr_i_o_reg[7:0]<=8'b0;
//				end
//			else
//				begin
//					if(en_device_addr_i_o)
//						begin
//							device_addr_i_o_reg[7:0]<=in_device_addr_i_o;
//						end
//					else
//						begin
//							device_addr_i_o_reg[7:0]<=device_addr_i_o_reg[7:0];
//						end
//				end
//		end
//	
//	//i_o register reg addr
//	reg [1:0] back_reg_addr_i_o_en;
//	reg [1:0] main_reg_addr_i_o_en;
//	wire [1:0] en_reg_addr_i_o;
//	wire [7:0] in_reg_addr_i_o;
//	
//	assign in_reg_addr_i_o=(wait_reg)? back_reg_0:pipeline_reg_0;
//	assign en_reg_addr_i_o=(wait_reg)? back_reg_addr_i_o_en:main_reg_addr_i_o_en;
//	
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					reg_addr_i_o_reg[7:0]<=8'b0;
//				end
//			else
//				begin
//					if(en_reg_addr_i_o[0])
//						begin
//							reg_addr_i_o_reg[7:0]<=in_reg_addr_i_o;
//						end
//					else
//						begin
//							reg_addr_i_o_reg[7:0]<=reg_addr_i_o_reg[7:0];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					reg_addr_i_o_reg[15:8]<=8'b0;
//				end
//			else
//				begin
//					if(en_reg_addr_i_o[1])
//						begin
//							reg_addr_i_o_reg[15:8]<=in_reg_addr_i_o;
//						end
//					else
//						begin
//							reg_addr_i_o_reg[15:8]<=reg_addr_i_o_reg[15:8];
//						end
//				end
//		end
//	
//	//i_o register data
//	reg [3:0] back_data_i_o_en;
//	reg [3:0] main_data_i_o_en;
//	wire [3:0] en_data_i_o;
//	wire [7:0] in_data_i_o;
//	
//	assign in_data_i_o=(wait_reg)? back_reg_0:pipeline_reg_0;
//	assign en_data_i_o=(wait_reg)? back_data_i_o_en:main_data_i_o_en;
//	
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					data_i_o_reg[7:0]<=8'b0;
//				end
//			else
//				begin
//					if(en_data_i_o[0])
//						begin
//							data_i_o_reg[7:0]<=in_data_i_o;
//						end
//					else
//						begin
//							data_i_o_reg[7:0]<=data_i_o_reg[7:0];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					sync_reg_1[15:8]<=8'b0;
//				end
//			else
//				begin
//					if(en_data_i_o[1])
//						begin
//							data_i_o_reg[15:8]<=in_data_i_o;
//						end
//					else
//						begin
//							data_i_o_reg[15:8]<=data_i_o_reg[15:8];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					data_i_o_reg[23:16]<=8'b0;
//				end
//			else
//				begin
//					if(en_data_i_o[2])
//						begin
//							data_i_o_reg[23:16]<=in_data_i_o;
//						end
//					else
//						begin
//							data_i_o_reg[23:16]<=data_i_o_reg[23:16];
//						end
//				end
//		end
//	
//	always @(posedge clk_in or negedge reset_n)
//		begin	
//			if(~reset_n)
//				begin
//					data_i_o_reg[31:24]<=8'b0;
//				end
//			else
//				begin
//					if(en_data_i_o[3])
//						begin
//							data_i_o_reg[31:24]<=in_data_i_o;
//						end
//					else
//						begin
//							data_i_o_reg[31:24]<=data_i_o_reg[31:24];
//						end
//				end
//		end
//	
//	// trig module
//	reg [1:0] trig_count;
//	wire stay_trig;
//	wire trig_en;
//	
//	always @(posedge clk_in)
//		begin
//			casex({receive_mac_0,available_reg_4})
//				2'b1x:
//					begin
//						trig_count<=2'b0;
//					end
//				2'b01:
//					begin
//						trig_count<=trig_count+2'b1;
//					end
//				default:
//					begin
//						trig_count<=2'b0;
//					end
//			endcase			
//		end
//	assign stay_trig=available_reg_4;
//	assign trig_en=(trig_count==2'b11);
//	
//	//Main State Machine
//	reg [7:0] back_reg_0;
//	reg [7:0] pipeline_reg_0;
//	reg [7:0] pipeline_reg_1;
//	reg [7:0] pipeline_reg_2;
//	reg [7:0] pipeline_reg_3;
//	reg [7:0] pipeline_reg_4;
//	reg available_reg_0;
//	reg available_reg_1;
//	reg available_reg_2;
//	reg available_reg_3;
//	reg available_reg_4;
//	reg running_mode_reg;//1-normal 0-booting
//	reg wait_reg;
//	reg [1:0] main_avm_mode_reg;// 00-eeprom load 01-eeprom single read 10-eeprom single write 11-normal avm
//	reg [7:0] main_avm_read_addr;
//	reg main_avm_new_operation;
//	reg [7:0] main_e_ram_addr;
//	reg [11:0] main_len_count_0;
//	reg [11:0] main_len_count_1;
//	reg [7:0] main_len_count_2;
//	reg [11:0] main_len_0;
//	reg [11:0] main_len_1;
//	reg [7:0] main_len_2;
//	reg main_count_addr;
//
//	reg [7:0] back_e_ram_addr;
//	reg [65:0] main_i_o_reg;
//	
//	reg main_e_ram_ram_addr_sel;
//	wire [7:0] main_e_ram_addr_wire;
//	assign main_e_ram_addr_wire=(main_e_ram_ram_addr_sel)? {5'b000001,main_e_ram_addr[7:6]}:main_e_ram_addr;
//	assign e_ram_read_addr=(wait_reg)? back_e_ram_addr:main_e_ram_addr_wire;
//	
//	always @(posedge clk_in)
//		begin
//			available_reg_0<=receive_mac_0;
//			available_reg_1<=available_reg_0;
//			available_reg_2<=available_reg_1;
//			available_reg_3<=available_reg_2;
//			available_reg_4<=available_reg_3;
//		end
//		
//	always @(posedge clk_in or negedge rest_n)
//		begin
//		
//			if (~reset_n)
//				begin
//					state_main<= 5'b0;
//					running_mode_reg<=1'b0;
//					wait_reg<=1'b0;
//					main_avm_new_operation<=1'b0;
//					main_avm_read_addr<=8'b0;
//					main_avm_mode_reg<==2'b0;
//					main_len_count_0 <= 12'b0;
//					main_len_count_1<= 12'b0;
//					main_len_count_2<= 8'b0;
//					main_len_0<= 12'b0;
//					main_len_1<= 12'b0;
//					main_len_2<= 8'b0;
//					main_e_ram_ram_addr_sel<=1'b0;
//					main_slave_addr_en<=1'b0;
//					main_count_addr<=1'b0;
//				end
//			else
//				begin
//					case(state_main)
//						boot_init:
//							begin
//								main_avm_new_operation<=1'b1;
//								main_avm_mode_reg<=2'b00;
//								main_e_ram_addr <= 8'b0;
//							end
//						boot_local_space:
//							begin
//								casex({(addr_read!=main_e_ram_addr), main_e_ram_addr[1:0]})
//									3'b0xx:
//										begin
//											state_main<=state_main;
//										end
//									3'b101://slave addr
//										begin
//											pipeline_reg_0<=e_ram_data_out[7:0];
//											main_slave_addr_en<=1'b1;
//											state_main<=boot_local_space_slave_addr_0;
//										end
//									3'b110://sync 0
//										begin
//											pipeline_reg_0<=e_ram_data_out[7:0];
//											en_sync_0[0]<=1'b1;
//											state_main<=boot_local_space_sync0_0;
//										end
//									3'b111://sync 1
//										begin
//											pipeline_reg_0<=e_ram_data_out[7:0];
//											en_sync_0[0]<=1'b1;
//											state_main<=boot_local_space_sync0_0;
//										end
//									
//									default:
//										begin
//											state_main<=state_main;
//											main_e_ram_addr <= main_e_ram_addr + 8'b1;
//										end
//								endcase
//							end
//						boot_local_space_slave_addr_0:
//							begin
//								main_slave_addr_en<=1'b0;
//								state_main<=boot_local_space;
//								main_e_ram_addr <= main_e_ram_addr + 8'b1;
//							end
//						boot_local_space_sync0_0:
//							begin
//								pipeline_reg_0<=e_ram_data_out[15:8];
//								en_sync_0[0]<=1'b0;
//								en_sync_0[1]<=1'b1;
//								state_main<=boot_local_space_sync0_1;
//							end
//						boot_local_space_sync0_1:
//							begin
//								pipeline_reg_0<=e_ram_data_out[23:16];
//								en_sync_0[1]<=1'b0;
//								en_sync_0[2]<=1'b1;
//								state_main<=boot_local_space_sync0_2;
//							end
//						boot_local_space_sync0_2:
//							begin
//								pipeline_reg_0<=e_ram_data_out[31:24];
//								en_sync_0[2]<=1'b0;
//								en_sync_0[3]<=1'b1;
//								state_main<=boot_local_space_sync0_3;
//							end
//						boot_local_space_sync0_3:
//							begin
//								pipeline_reg_0<=e_ram_data_out[23:16];
//								en_sync_0[1]<=1'b0;
//								en_sync_0[3]<=1'b0;
//								state_main<=boot_local_space;
//								main_e_ram_addr <= main_e_ram_addr + 8'b1;
//							end
//						boot_local_space_sync1_0:
//							begin
//								pipeline_reg_1<=e_ram_data_out[15:8];
//								en_sync_1[0]<=1'b0;
//								en_sync_1[1]<=1'b1;
//								state_main<=boot_local_space_sync1_1;
//							end
//						boot_local_space_sync1_1:
//							begin
//								pipeline_reg_1<=e_ram_data_out[23:16];
//								en_sync_1[1]<=1'b0;
//								en_sync_1[2]<=1'b1;
//								state_main<=boot_local_space_sync1_2;
//							end
//						boot_local_space_sync1_2:
//							begin
//								pipeline_reg_1<=e_ram_data_out[31:24];
//								en_sync_1[2]<=1'b0;
//								en_sync_1[3]<=1'b1;
//								state_main<=boot_local_space_sync1_3;
//							end
//						boot_local_space_sync1_3:
//							begin
//								pipeline_reg_1<=e_ram_data_out[23:16];
//								en_sync_1[1]<=1'b0;
//								en_sync_1[3]<=1'b0;
//								state_main<=boot_local_space;
//								main_e_ram_addr <= main_e_ram_addr + 8'b1;
//							end
//						user_space_init:
//							begin
//								casex({(addr_read!=main_e_ram_addr), main_e_ram_addr[4]})
//									2'b1x:
//										begin
//											state_main<=state_main;
//											main_e_ram_addr <= main_e_ram_addr + 8'b1;
//										end
//									2'b01:
//										begin
//											state_main<=validity_check_init;
//											main_e_ram_ram_addr_sel<=1'b1;
//										end
//									default:
//										begin
//											state_main<=state_main;
//										end
//								endcase
//							end
//						validity_check_init:
//							begin
//								if(main_e_ram_addr!=8'b0)
//									begin
//										main_e_ram_ram_addr_sel<=1'b1;
//										state_main<=validity_check;
//									end
//								else
//									begin
//										main_e_ram_ram_addr_sel<=1'b0;
//										state_main<=normal_op_init;
//									end
//							end
//						validity_check:
//							begin
//								if(e_ram_data_out[main_e_ram_addr[5:1]])
//									begin
//										state_main<=user_space_valid_odd_init;
//										main_e_ram_ram_addr_sel<=1'b0;
//									end
//								else
//									begin
//										state_main<=user_space_invalid_odd;
//										main_e_ram_ram_addr_sel<=1'b1;
//									end
//							end
//						user_space_invalid_odd:
//							begin
//								main_e_ram_ram_addr_sel<=1'b1;
//								if(addr_read!=main_len_count_0)
//									begin
//										state_main<=user_space_invalid_even;
//										main_e_ram_addr <= main_e_ram_addr + 8'b1;
//									end
//								else
//									begin
//										state_main<=state_main;
//									end
//							end
//						user_space_invalid_even:
//							begin
//								main_e_ram_ram_addr_sel<=1'b1;
//								if(addr_read!=main_len_count_0)
//									begin
//										state_main<=validity_check_init;
//										main_e_ram_addr <= main_e_ram_addr + 8'b1;
//									end
//								else
//									begin
//										state_main<=state_main;
//									end
//							end	
//						user_space_valid_odd_init:
//							begin
//								
//								if(addr_read!=main_len_count_0)
//									begin
//										state_main<=user_space_valid_odd_0;
//										pipeline_reg_0<=e_ram_data_out[7:0];
//										en_cmd_i_o<=1'b1;
//									end
//								else
//									begin
//										state_main<=state_main;
//									end
//							end
//						user_space_valid_odd_0:
//							begin
//								pipeline_reg_0<=e_ram_data_out[15:8];
//								en_cmd_i_o<=1'b0;
//								en_device_addr_i_o<=1'b1;
//								state_main<=user_space_valid_odd_1;
//							end
//						user_space_valid_odd_1:
//							begin
//								pipeline_reg_0<=e_ram_data_out[23:16];
//								en_device_addr_i_o<=1'b0;
//								en_reg_addr_i_o[0]<=1'b1;
//								state_main<=user_space_valid_odd_2;
//							end
//						user_space_valid_odd_2:
//							begin
//								pipeline_reg_0<=e_ram_data_out[31:24];
//								en_reg_addr_i_o[0]<=1'b0;
//								en_reg_addr_i_o[1]<=1'b1;
//								state_main<=user_space_valid_odd_3;
//							end
//						user_space_valid_odd_3:
//							begin
//								pipeline_reg_0<=e_ram_data_out[23:16];
//								en_reg_addr_i_o[1]<=1'b0;
//								state_main<=user_space_valid_even_init;
//								main_e_ram_addr <= main_e_ram_addr + 8'b1;
//							end
//						user_space_valid_even_init:
//							begin
//								
//								if(addr_read!=main_len_count_0)
//									begin
//										state_main<=user_space_valid_even_0;
//										pipeline_reg_0<=e_ram_data_out[7:0];
//										en_data_i_o[0]<=1'b1;
//									end
//								else
//									begin
//										state_main<=state_main;
//									end
//							end
//						user_space_valid_even_0:
//							begin
//								pipeline_reg_0<=e_ram_data_out[15:8];
//								en_data_i_o[0]<=1'b0;
//								en_data_i_o[1]<=1'b1;
//								state_main<=user_space_valid_even_1;
//							end
//						user_space_valid_even_1:
//							begin
//								pipeline_reg_0<=e_ram_data_out[23:16];
//								en_data_i_o[1]<=1'b0;
//								en_data_i_o[2]<=1'b1;
//								state_main<=user_space_valid_even_2;
//							end
//						user_space_valid_even_2:
//							begin
//								pipeline_reg_0<=e_ram_data_out[31:24];
//								en_data_i_o[2]<=1'b0;
//								en_data_i_o[3]<=1'b1;
//								state_main<=user_space_valid_even_3;
//							end
//						user_space_valid_even_3:
//							begin
//								pipeline_reg_0<=e_ram_data_out[23:16];
//								en_data_i_o[3]<=1'b0;
//								state_main<=validity_check_init;
//								main_e_ram_addr <= main_e_ram_addr + 8'b1;
//								main_e_ram_ram_addr_sel<=1'b1;
//							end
//						normal_op_init://start new frame
//							begin
//								if((count_addr_0!=main_count_addr) && receive_mac_0)
//									begin
//										main_count_addr<=~main_count_addr;
//										pipeline_reg_0<=data_0;
//										state_main<=SFD_main;
//									end
//								else
//									begin
//										main_count_addr<=1'b0;
//										pipeline_reg_0<=data_0;
//										state_main<=state_main;
//									end
//							end
//						SFD_main:
//							begin
//								casex({(pipeline_reg_0==8'b11010101),(count_addr_0!=main_count_addr),(stay_trig || receive_mac_0)})
//									3'b111:
//										begin
//											state_main<=s_d_addr_main;
//											main_count_addr<=~main_count_addr;
//											main_len_count_0<=12'b0;
//										end
//									3'0xx:
//										begin
//											state_main<=frame_error_main;
//											main_count_addr<=1'b0;
//										end
//									3'1x0:
//										begin
//											state_main<=frame_error_main;
//											main_count_addr<=1'b0;
//										end
//									default:
//										begin
//											state_main<=state_main;
//											main_count_addr<=main_count_addr;
//										end
//								endcase
//							end
//						s_d_addr_main:
//							begin
//								casex({(main_len_count_0[3:0]==4'b1100),(count_addr_0!=main_count_addr),(stay_trig || receive_mac_0)})
//									3'b111:
//										begin
//											state_main<=frame_len_1_main;
//											main_count_addr<=~main_count_addr;
//											pipeline_reg_0<=data_0;
//										end
//									3'011:
//										begin
//											main_len_count_0<=main_len_count_0+12'b1;
//											state_main<=state_main;
//											main_count_addr<=main_count_addr;
//										end
//									3'xx0:
//										begin
//											state_main<=frame_error_main;
//											main_count_addr<=1'b0;
//										end
//									default:
//										begin
//											main_len_count_0<=main_len_count_0;
//											state_main<=state_main;
//											main_count_addr<=main_count_addr;
//										end
//								endcase
//							end
//						frame_len_1_main:
//							begin
//								casex({(count_addr_0!=main_count_addr),(stay_trig || receive_mac_0)})
//									2'b11:
//										begin
//											state_main<=frame_len_2_main;
//											main_count_addr<=~main_count_addr;
//											pipeline_reg_0<=data_0;
//											main_len_0[11:8]<=pipeline_reg_0[3:0];
//										end
//									2'01:
//										begin
//											pipeline_reg_0<=pipeline_reg_0;
//											state_main<=state_main;
//											main_count_addr<=main_count_addr;
//										end
//									2'x0:
//										begin
//											state_main<=frame_error_main;
//											main_count_addr<=1'b0;
//										end
//									default:
//										begin
//											main_len_count_0<=main_len_count_0;
//											state_main<=state_main;
//											main_count_addr<=main_count_addr;
//										end
//								endcase
//							end
//						frame_len_2_main:
//							begin
//								casex({(count_addr_0!=main_count_addr),(stay_trig || receive_mac_0)})
//									2'b11:
//										begin
//											state_main<=c1_cmd_main;
//											main_count_addr<=~main_count_addr;
//											pipeline_reg_0<=data_0;
//											main_len_0[7:0]<=pipeline_reg_0[7:0];
//										end
//									2'01:
//										begin
//											pipeline_reg_0<=pipeline_reg_0;
//											state_main<=state_main;
//											main_count_addr<=main_count_addr;
//										end
//									2'x0:
//										begin
//											state_main<=frame_error_main;
//											main_count_addr<=1'b0;
//										end
//									default:
//										begin
//											main_len_count_0<=main_len_count_0;
//											state_main<=state_main;
//											main_count_addr<=main_count_addr;
//										end
//								endcase
//							end
//						c1_cmd_main:
//							begin
//								casex({pipeline_reg_0[7:4],(count_addr_0!=main_count_addr),(stay_trig || receive_mac_0)})
//									6'bxxxxx0:
//										begin
//											state_main<=frame_error_main;
//											main_count_addr<=1'b0;
//										end
//									6'bxxxx01:
//										begin
//											pipeline_reg_0<=pipeline_reg_0;
//											state_main<=state_main;
//											main_count_addr<=main_count_addr;
//										end
//									6'b000011://padding
//										begin
//											state_main<=c1_pad_len_main;
//											main_count_addr<=~main_count_addr;
//											pipeline_reg_0<=data_0;
//											main_len_1[11:8]<=pipeline_reg_0[3:0];
//										end
//									6'b000111://read addr
//										begin
//											state_main<=c1_read_addr_len_main;
//											main_count_addr<=~main_count_addr;
//											pipeline_reg_0<=data_0;
//											main_len_0[7:0]<=pipeline_reg_0[7:0];
//										end
//									6'b001011://update addr
//										begin
//											state_main<=c1_write_addr_len_main;
//											main_count_addr<=~main_count_addr;
//											pipeline_reg_0<=data_0;
//											main_len_0[7:0]<=pipeline_reg_0[7:0];
//										end
//									6'b001111://periodic sync 
//										begin
//											state_main<=c1_periodic_len_main;
//											main_count_addr<=~main_count_addr;
//											pipeline_reg_0<=data_0;
//											main_len_0[7:0]<=pipeline_reg_0[7:0];
//										end
//									6'b010011://set transmitter
//										
//									
//							
//						default
//							begin	
//							
//							end
//					endcase




/*c1_def_time_check_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							
							
							case({(greater_buff_0 && (sec_data_read_state_0 != main_data_read_state_0)),(greater_buff_1 && (sec_data_read_state_1 != main_data_read_state_1))})
									2'b10:
										begin
											state_sec<=c1_crc_check_sec_1;
											pipeline_reg_4<=slave_addr;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_compare_value<=4'b0100;
											sec_compare_count<=sec_compare_count;
										end
									2'b01:
										begin
											state_sec<=c1_def_time_buff_0_update_sec;
											pipeline_reg_4<=slave_addr;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_compare_value<=4'b0100;
											sec_compare_count<=sec_compare_count;
										end
									2'b00:
										begin
											state_sec<=c1_def_time_normal_update_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_compare_value<=4'b0101;
											sec_compare_count<=sec_compare_count+4'b1;
										end
									
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_data;
										end
								
						
						end	*/
						/*c2_reg_read_user_sec:
					begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;//command
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_data_read_state_0!=main_data_read_state_0),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=c2_reg_read_user_i_o_buff_0_sec;
											pipeline_reg_4<=main_i_o_read_buff_0[0];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b1;
											sec_compare_value<=4'b0100;
											sec_data_read_state_0<=~sec_data_read_state_0;
										end
									4'b0111:
										begin
											state_sec<=c2_reg_read_user_i_o_buff_1_sec;
											pipeline_reg_4<=main_i_o_read_buff_1[0];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b1;
											sec_compare_value<=4'b0100;
											sec_data_read_state_1<=~sec_data_read_state_1;
										end
									4'bx011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=sec_compare_count+4'b1;
											
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=1'b0;
											
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_data;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											
										end
								endcase
					end
				c2_reg_read_user_i_o_buff_0_sec:
					begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;//command
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_len_2==sec_len_count_2),(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									5'b11111:
										begin
											state_sec<=c1_crc_check_sec_1;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											
											
										end
									5'b10111:
										begin
											state_sec<=c1_general_cmd_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
											
										end
									5'b00111:
										begin
											state_sec<=c1_general_slave_match_cmd_sec;
											pipeline_reg_4<=pipeline_reg_3;
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'bx;
											
										end
									5'b00011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=main_i_o_read_buff_0[sec_compare_count];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=sec_compare_count+4'b1;
											
										end
									5'bxxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=1'b0;
											
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_data;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											
										end
								endcase
					end
				c2_reg_read_user_i_o_buff_1_sec:
					begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;//command
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_len_2==sec_len_count_2),(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									5'b11111:
										begin
											state_sec<=c1_crc_check_sec_1;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											
											
										end
									5'b10111:
										begin
											state_sec<=c1_general_cmd_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
											
										end
									5'b00111:
										begin
											state_sec<=c1_general_slave_match_cmd_sec;
											pipeline_reg_4<=pipeline_reg_3;
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'bx;
											
										end
									5'b00011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=main_i_o_read_buff_1[sec_compare_count];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=sec_compare_count+4'b1;
											
										end
									5'bxxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=1'b0;
											
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_data;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											
										end
								endcase
					end
				c2_digital_read_user_sec_1:
					begin
								casex({(sec_data_read_state_0!=main_data_read_state_0),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=c2_digital_read_user_sec_2;
											pipeline_reg_4<=main_i_o_read_buff_0[0];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b1;
											sec_compare_value<=4'b0100;
											sec_data_read_state_0<=~sec_data_read_state_0;
										end
									4'b0111:
										begin
											state_sec<=c2_digital_read_user_sec_2;
											pipeline_reg_4<=main_i_o_read_buff_1[0];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b1;
											sec_compare_value<=4'b0100;
											sec_data_read_state_1<=~sec_data_read_state_1;
										end
									4'bx011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=sec_compare_count+4'b1;
											
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=1'b0;
											
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_data;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											
										end
								endcase
					end
				c2_digital_read_user_sec_2:
					begin
						sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;//command
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_len_2==sec_len_count_2),(sec_len_1==sec_len_count_1),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=c1_crc_check_sec_1;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											
										end
									4'b1011:
										begin
											state_sec<=c1_general_cmd_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
											
										end
									4'b0011:
										begin
											state_sec<=c1_general_slave_match_cmd_sec;
											pipeline_reg_4<=pipeline_reg_3;
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'bx;
											
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=1'b0;
											
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_data;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											
										end
								endcase
					end
				c2_analog_read_user_sec_1:
					begin
							casex({(sec_data_read_state_0!=main_data_read_state_0),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=c2_analog_read_user_buff_0_sec_1;
											pipeline_reg_4<=main_i_o_read_buff_0[0];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b1;
											sec_compare_value<=4'x;
											sec_data_read_state_0<=~sec_data_read_state_0;
										end
									4'b0111:
										begin
											state_sec<=c2_analog_read_user_buff_1_sec_1;
											pipeline_reg_4<=main_i_o_read_buff_1[0];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b1;
											sec_compare_value<=4'x;
											sec_data_read_state_1<=~sec_data_read_state_1;
										end
									4'bx011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=sec_compare_count+4'b1;
											
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=1'b0;
											
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_data;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											
										end
								endcase
					end
				c2_analog_read_user_buff_0_sec_1:
					begin
								casex({trig_en,stay_trig})
								
									2'b11:
										begin
											state_sec<=c2_digital_read_user_sec_2;
											pipeline_reg_4<=main_i_o_read_buff_0[sec_compare_count];
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
										end
									2'bx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_tx_data<=8'bx;
											sec_tx_state<=1'b0;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
										end
								endcase
					end
				c2_analog_read_user_buff_1_sec_1:
					begin
								casex({trig_en,stay_trig})
								
									2'b11:
										begin
											state_sec<=c2_digital_read_user_sec_2;
											pipeline_reg_4<=main_i_o_read_buff_1[sec_compare_count];
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
										end
									2'bx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_tx_data<=8'bx;
											sec_tx_state<=1'b0;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
										end
								endcase
					end
				c2_general_pipeline_data_read_sec:
					begin
						begin
							sec_compare_value_2<=sec_compare_value_2;
							sec_compare_value<=sec_compare_value;
							casex({(sec_data_read_state_0!=main_data_read_state_0),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=c2_general_read_buff_0_sec;
											pipeline_reg_4<=main_i_o_read_buff_0[0];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b1;
											sec_data_read_state_0<=~sec_data_read_state_0;
										end
									4'b0111:
										begin
											state_sec<=c2_general_read_buff_1_sec;
											pipeline_reg_4<=main_i_o_read_buff_1[0];
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b1;
											sec_data_read_state_1<=~sec_data_read_state_1;
										end
									4'bx011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											
											mode_crc_gen_sec<=2'b10;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=sec_compare_count+4'b1;
											
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=1'b0;
											
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_data;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											
										end
								endcase
					end*/