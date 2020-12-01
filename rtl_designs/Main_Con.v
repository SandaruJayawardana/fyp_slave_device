module Main_Con(
	input clk_in,
	input reset_n,
	output reg boot_error,//drive led to  idicate boot error
	//interrupts
	input IRQ0,
	input IRQ1,
	input IRQ2,
	input IRQ3,
	
	//Avalon Maser
	output [31:0] data_write_avm,
	output [1:0] mode_avm, //00- Normal operation, 01-EEPROM read full, 10-singlewrite, 11-single read
	input [31:0] e_ram_data_read_avm,
	output [15:0] r_w_addr_avm,
	input [7:0] e_ram_addr_read_avm,//EEPROM_addr
	input e_ram_write_en_avm,
	input EEPROM_error_avm,//1- error
	input wait_request_avm,
	output new_avm,//00-boot 01-write 10-read
	
	
	//Port 0 
	
	//RX_MAC
	input state_rx_0,//=count_addr_0,
	input receive_mac_rx_0,
	input [7:0] data_rx_0,
	
	//TX_MAC
	output state_tx_0,//=count_addr_tx_0,
	output receive_mac_tx_0,
	output [7:0] data_tx_0,
	output [1:0] mode_tx_0,
	output [4:0] packet_no_tx_0,
	input [7:0] packet_data_tx_0,
	input [3:0] jitter_count_tx_0,
	input available_packet_data_tx_0,
	//Port 1
	
	//RX_MAC
	input state_rx_1,//=count_addr_1,
	input receive_mac_rx_1,
	input [7:0] data_rx_1,
	
	//TX_MAC
	output state_tx_1,//=count_addr_tx_1,
	output receive_mac_tx_1,
	output [7:0] data_tx_1,
	output [1:0] mode_tx_1,
	output [4:0] packet_no_tx_1,
	input [7:0] packet_data_tx_1,
	input [3:0] jitter_count_tx_1,
	input available_packet_data_tx_1,
	//I_O Interface
	output [65:0] i_o_65,
	output [31:0] clk_32,
	//output wait_reg;//to identify runnignstatemachine for i2c write (i2c write only perforn during back state machine running (wait_reg=1))
	input [31:0] i_o_data_in_wire,
	input [2:0] success_ready_wait_request,//[0] wait request [1] ready_wait [2] success
	output [1:0] sync_interrupt,//1- sync 1 ,0 - sync 0
	input i_o_error,
	
	
	input [1:0] user_timer_mode,
	input [1:0] user_mode
	);
	////
	reg [7:0] back_center_reg;
	reg [7:0] pipeline_reg_0;
	reg [63:0] timer = 64'b0;
	reg main_state_rx_0;
	wire [3:0] jitter_count_tx_wire;
	
	////
	
	
	wire [7:0] i_o_data_in [3:0];
	assign {i_o_data_in[3],i_o_data_in[2],i_o_data_in[1],i_o_data_in[0]}=i_o_data_in_wire;
	
	wire [7:0] e_ram_data_read_avm_wire [3:0];
	assign {e_ram_data_read_avm_wire[3],e_ram_data_read_avm_wire[2],e_ram_data_read_avm_wire[1],e_ram_data_read_avm_wire[0]}=e_ram_data_read_avm;
	
	reg wait_reg;//0- main 1- back
	//**********************prop_delay_RAM************
	
	reg [5:0] sec_prop_delay_ram_addr;
	wire [7:0] prop_delay_ram_out;
	
	reg port_selection_packet_data;
	wire [7:0] prop_delay_ram_in;
	reg [5:0] prop_delay_ram_write_addr;
	reg [4:0] packet_no_read;
	assign prop_delay_ram_in=(port_selection_packet_data)? packet_data_tx_1:packet_data_tx_0;
	assign packet_no_tx_0=packet_no_read;
	assign packet_no_tx_1=packet_no_read;
	reg [1:0] prop_ram_state;
	reg last_available_packet_data_tx_1;
	reg last_available_packet_data_tx_0;
	//reg [4:0] prop_count;
	reg prop_delay_ram_w_en;
	reg [1:0] port_data_available;
	
	parameter port_read_init=2'd0, port_0_read=2'b1, port_rest_read=2'd2;
	
	always @(posedge clk_in or negedge reset_n)
		begin
			if (~reset_n)
				begin
					packet_no_read<=5'b0;
					prop_delay_ram_write_addr<=6'b0;
					port_selection_packet_data<=1'b0;
					prop_ram_state<=2'b0;
					last_available_packet_data_tx_0<=1'b1;
					last_available_packet_data_tx_1<=1'b1;
					port_data_available<=2'b0;
				end
			else	
				begin
					case(prop_ram_state)
						port_read_init:
							begin
								prop_delay_ram_write_addr<=6'b0;
								port_selection_packet_data<=1'b0;//select port 0
								packet_no_read<=5'b0;
								last_available_packet_data_tx_0<=available_packet_data_tx_0;
								last_available_packet_data_tx_1<=available_packet_data_tx_1;
								casex({(last_available_packet_data_tx_0==1'b0 && available_packet_data_tx_0==1'b1),((last_available_packet_data_tx_1==1'b0 && available_packet_data_tx_1==1'b1)|| IRQ1),port_data_available})
									4'b11xx:
										begin
											prop_ram_state<=port_0_read;
											prop_delay_ram_w_en<=1'b1;
											port_data_available<=2'b11;
										end
									4'b10xx:
										begin
											prop_ram_state<=prop_ram_state;
											prop_delay_ram_w_en<=1'b0;
											port_data_available<={1'b1,port_data_available[0]};
										end
									4'b01xx:
										begin
											prop_ram_state<=prop_ram_state;
											prop_delay_ram_w_en<=1'b0;
											port_data_available<={port_data_available[1],1'b1};
										end
									4'b0011:
										begin
											prop_ram_state<=port_0_read;
											prop_delay_ram_w_en<=1'b1;
											port_data_available<=port_data_available;
										end
									default:
										begin
											prop_ram_state<=prop_ram_state;
											prop_delay_ram_w_en<=1'b0;
											port_data_available<=port_data_available;
										end
									endcase
							end
						port_0_read:
							begin
								last_available_packet_data_tx_0<=1'b1;
								last_available_packet_data_tx_1<=1'b1;
								prop_delay_ram_w_en<=1'b1;
								prop_delay_ram_write_addr<=prop_delay_ram_write_addr+1'b1;
								port_data_available<=2'b0;
								if(packet_no_read!=5'b01000)	
									begin
										prop_ram_state<=prop_ram_state;
										packet_no_read<=packet_no_read+5'b1;
										port_selection_packet_data<=1'b0;
									end
								else
									begin
										prop_ram_state<=port_rest_read;
										packet_no_read<=5'b0;
										port_selection_packet_data<=1'b1;
									end
									
							end
						port_rest_read:
							begin
								last_available_packet_data_tx_0<=1'b1;
								last_available_packet_data_tx_1<=1'b1;
								packet_no_read<=packet_no_read+5'b1;
								prop_delay_ram_write_addr<=prop_delay_ram_write_addr+1'b1;
								port_selection_packet_data<=1'b1;
								port_data_available<=2'b0;
								if(packet_no_read!=5'b11010)	
									begin
										prop_delay_ram_w_en<=1'b1;
										prop_ram_state<=prop_ram_state;
									end
								else	
									begin
										prop_delay_ram_w_en<=1'b0;
										prop_ram_state<=port_read_init;
									end
									
							end
						default:
							begin
								last_available_packet_data_tx_0<=1'b1;
								last_available_packet_data_tx_1<=1'b1;
								packet_no_read<=5'b0;
								prop_delay_ram_write_addr<=6'b0;
								port_selection_packet_data<=1'b0;
								port_data_available<=2'b0;
								prop_delay_ram_w_en<=1'b0;
								prop_ram_state<=port_read_init;
							end
							
					endcase
				end
		end
	wire [5:0] prop_delay_ram_read_addr;
	
	prop_delay_RAM prop_delay_ram(.data(prop_delay_ram_in),.read_addr(prop_delay_ram_read_addr), .write_addr(prop_delay_ram_write_addr),.we(prop_delay_ram_w_en), .clk(clk_in),.q(prop_delay_ram_out));
	
	
	assign prop_delay_ram_read_addr=sec_prop_delay_ram_addr;
	
	//**********************EEPROM RAM****************
	
	// ******data read
	wire [7:0] e_ram_data_out [3:0];
	reg main_e_ram_addr_sel;
	wire [8:0] main_e_ram_addr_wire;
	wire [31:0] e_ram_data_out_wire;
	assign e_ram_data_out_wire={e_ram_data_out[3],e_ram_data_out[2],e_ram_data_out[1],e_ram_data_out[0]};
	//***read addr
	reg [8:0] back_e_ram_addr;
	reg [8:0] main_e_ram_addr;
	//mux_e_ram_data_read_addr
	wire [8:0] e_ram_read_addr;
	assign e_ram_read_addr=(wait_reg)? back_e_ram_addr:main_e_ram_addr_wire;
	//mux main e ram addr sel
	assign main_e_ram_addr_wire=(main_e_ram_addr_sel)? {7'b0000001,main_e_ram_addr[7:6]}:main_e_ram_addr;
	
	//*******data write
	reg back_e_ram_w_en;
	wire e_ram_we;
	wire [31:0] e_ram_data_in;
	reg [7:0] back_e_ram_data_write [3:0];
	wire [8:0] e_ram_write_addr;
	reg [8:0] back_e_ram_write_addr;
	//mux_e_ram_w_en
	assign e_ram_we=(wait_reg)? back_e_ram_w_en:e_ram_write_en_avm;
	
	//mux_e_ram_write_data
	assign e_ram_data_in=(wait_reg)? {back_e_ram_data_write[3],back_e_ram_data_write[2],back_e_ram_data_write[1],back_e_ram_data_write[0]}:e_ram_data_read_avm;
	
	//mux_e_ram_write_addr
	assign e_ram_write_addr=(wait_reg)? back_e_ram_write_addr:{1'b0,e_ram_addr_read_avm};
	
	EEPROM_RAM eeprom_ram(.data(e_ram_data_in),.read_addr(e_ram_read_addr), .write_addr(e_ram_write_addr),.we(e_ram_we), .clk(clk_in),.q({e_ram_data_out[3],e_ram_data_out[2],e_ram_data_out[1],e_ram_data_out[0]}));
	
	
	//**********************i_o register****************
	reg [7:0] main_i_o_reg [7:0];//reg [65:0] main_i_o_reg;
	reg [7:0] back_i_o_reg [7:0];//reg [65:0] back_i_o_reg;
	reg [1:0] main_i_o_reg_2;// 1-wait request 0-new
	reg [1:0] back_i_o_reg_2;
	
	wire [65:0] i_o_wire;
	//mux_i_o_reg
	assign i_o_wire=(wait_reg)? {back_i_o_reg_2,back_i_o_reg[7],back_i_o_reg[6],back_i_o_reg[5],back_i_o_reg[4],back_i_o_reg[3],back_i_o_reg[2],back_i_o_reg[1],back_i_o_reg[0]}:{main_i_o_reg_2,main_i_o_reg[7],main_i_o_reg[6],main_i_o_reg[5],main_i_o_reg[4],main_i_o_reg[3],main_i_o_reg[2],main_i_o_reg[1],main_i_o_reg[0]};
	
	//main_i_o_buff
	reg [7:0] main_i_o_read_buff_0 [4:0];
	reg [7:0] main_i_o_read_buff_1 [4:0];
	reg main_i_o_read_buff_0_40;
	reg main_i_o_read_buff_1_40;
	
	//wire main_i_o_read_buff_pointer;
	reg main_i_o_read_buff_last_pointer;
	
	//assign main_i_o_read_buff_pointer=(main_i_o_read_buff_last_pointer[1])? main_i_o_read_buff_last_pointer[0]:(sec_data_read_state_0==main_data_read_state_0);
	
	reg sec_data_read_state_0;
	reg sec_data_read_state_1;
	reg main_data_read_state_0;
	reg main_data_read_state_1;
	
	//****** i_o interface********
	
	assign i_o_65=i_o_wire;
	
	//**********************AVM Interface**************
	
	reg [7:0] back_avm_data_write [3:0];
	assign data_write_avm={back_avm_data_write[3],back_avm_data_write[2],back_avm_data_write[1],back_avm_data_write[0]};
	//r_w_addr
	reg [8:0] back_avm_r_w_addr;
	assign r_w_addr_avm={7'b0,back_avm_r_w_addr};
	//new_avm
	reg main_avm_new;
	reg back_avm_new;
	assign new_avm=(wait_reg)? back_avm_new:main_avm_new;
	//mode_avm
	reg [1:0] main_avm_mode;
	reg [1:0] back_avm_mode;
	assign mode_avm=(wait_reg)? back_avm_mode:main_avm_mode;
	
	//**********************slave addr*****************
	reg [7:0] slave_addr;
	
	wire [7:0] in_slave_addr;
	wire en_slave_addr;
	reg main_slave_addr_en;
	reg back_slave_addr_en;
	
	assign in_slave_addr=(wait_reg)? back_center_reg:pipeline_reg_0;
	assign en_slave_addr=(wait_reg)? back_slave_addr_en:main_slave_addr_en;
	
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					slave_addr<=8'b0;
				end
			else		
				begin
					if(en_slave_addr)
						begin
							slave_addr<=in_slave_addr;
						end
					else		
						begin
							slave_addr<=slave_addr;
						end
				end
		end
	
	
	//**********************sync register**************
	//Sync 0 register
	reg [31:0] sync_reg_0;
	reg [3:0] back_sync_0_en;
	reg [3:0] main_sync_0_en;
	wire [3:0] en_sync_0;
	wire [7:0] in_sync_0;
	assign sync_interrupt[0]=(sync_reg_0==timer[31:0]);
	
	
	assign in_sync_0=(wait_reg)? back_center_reg:pipeline_reg_0;
	assign en_sync_0=(wait_reg)? back_sync_0_en:main_sync_0_en;
	
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					sync_reg_0[7:0]<=8'b0;
				end
			else		
				begin
					if(en_sync_0[0])
						begin
							sync_reg_0[7:0]<=in_sync_0;
						end
					else		
						begin
							sync_reg_0[7:0]<=sync_reg_0[7:0];
						end
				end
		end
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					sync_reg_0[15:8]<=8'b0;
				end
			else		
				begin
					if(en_sync_0[1])
						begin
							sync_reg_0[15:8]<=in_sync_0;
						end
					else		
						begin
							sync_reg_0[15:8]<=sync_reg_0[15:8];
						end
				end
		end
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					sync_reg_0[23:16]<=8'b0;
				end
			else		
				begin
					if(en_sync_0[2])
						begin
							sync_reg_0[23:16]<=in_sync_0;
						end
					else		
						begin
							sync_reg_0[23:16]<=sync_reg_0[23:16];
						end
				end
		end
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					sync_reg_0[31:24]<=8'b0;
				end
			else		
				begin
					if(en_sync_0[3])
						begin
							sync_reg_0[31:24]<=in_sync_0;
						end
					else		
						begin
							sync_reg_0[31:24]<=sync_reg_0[31:24];
						end
				end
		end
	
	// Sync 1 register
	
	reg [31:0] sync_reg_1;
	reg [3:0] back_sync_1_en;
	reg [3:0] main_sync_1_en;
	wire [3:0] en_sync_1;
	wire [7:0] in_sync_1;
	
	assign in_sync_1=(wait_reg)? back_center_reg:pipeline_reg_0;
	assign en_sync_1=(wait_reg)? back_sync_1_en:main_sync_1_en;
	assign sync_interrupt[1]=(sync_reg_1==timer[31:0]);
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					sync_reg_1[7:0]<=8'b0;
				end
			else		
				begin
					if(en_sync_1[0])
						begin
							sync_reg_1[7:0]<=in_sync_1;
						end
					else		
						begin
							sync_reg_1[7:0]<=sync_reg_1[7:0];
						end
				end
		end
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					sync_reg_1[15:8]<=8'b0;
				end
			else		
				begin
					if(en_sync_1[1])
						begin
							sync_reg_1[15:8]<=in_sync_1;
						end
					else		
						begin
							sync_reg_1[15:8]<=sync_reg_1[15:8];
						end
				end
		end
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					sync_reg_1[23:16]<=8'b0;
				end
			else		
				begin
					if(en_sync_1[2])
						begin
							sync_reg_1[23:16]<=in_sync_1;
						end
					else		
						begin
							sync_reg_1[23:16]<=sync_reg_1[23:16];
						end
				end
		end
	
	always @(posedge clk_in or negedge reset_n)
		begin	
			if(~reset_n)
				begin
					sync_reg_1[31:24]<=8'b0;
				end
			else	
				begin
					if(en_sync_1[3])
						begin
							sync_reg_1[31:24]<=in_sync_1;
						end
					else	
						begin
							sync_reg_1[31:24]<=sync_reg_1[31:24];
						end
				end
		end
	
	//**********************Clock main******************
	
	//wire sync0_i_o,sync1_i_o;
	reg [7:0] main_clock_def [3:0];
	reg [63:0] main_64_clk ;
	reg [7:0] main_64_temp_clk [7:0];
	reg [15:0] main_delay;
	//reg [7:0] main_prop_delay [1:0];
	reg [11:0] main_jitter_correction;
	//reg [63:0] timer;
	wire [63:0] timer_in_wire;
	reg [7:0] back_prop_delay [1:0];
	
	reg [1:0] timer_mode;
   wire timer_cin_1;
	wire timer_cin_2;
	reg main_64_clk_mode;
	wire main_64_clk_32_cin;
	wire [63:0] main_64_clk_in_wire;
	
//	assign sync0_i_o=(timer[31:0]==sync_reg_0);
//	assign sync1_i_o=(timer[31:0]==sync_reg_1);
	assign clk_32=timer[31:0];
	
	assign main_64_clk_in_wire={main_64_temp_clk[7],main_64_temp_clk[6],main_64_temp_clk[5],main_64_temp_clk[4],main_64_temp_clk[3],main_64_temp_clk[2],main_64_temp_clk[1],main_64_temp_clk[0]}+{32'b0,main_delay};
	assign timer_in_wire=main_64_clk;
	
	and main_64_clk_32_cin_and(main_64_clk_32_cin,main_64_clk[0],main_64_clk[1],main_64_clk[2],main_64_clk[3],main_64_clk[4],main_64_clk[5],main_64_clk[6],main_64_clk[7],main_64_clk[8],main_64_clk[9],main_64_clk[10],main_64_clk[11],main_64_clk[12],main_64_clk[13],main_64_clk[14],main_64_clk[15],main_64_clk[16],main_64_clk[17],main_64_clk[18],main_64_clk[19],main_64_clk[20],main_64_clk[21],main_64_clk[22],main_64_clk[23],main_64_clk[24],main_64_clk[25],main_64_clk[26],main_64_clk[27],main_64_clk[28],main_64_clk[29],main_64_clk[30],main_64_clk[31]);

	always @(posedge clk_in or negedge reset_n)
		begin
			if (~reset_n)
				begin
					main_64_clk<=64'b0;
				end
			else		
				begin
					if(main_64_clk_mode)
						begin
							main_64_clk<=main_64_clk_in_wire;
						end
					else		
						begin	
							main_64_clk[31:0]<=main_64_clk[31:0] + 32'b1;
							main_64_clk[63:32]<=main_64_clk[63:32] + {31'b0,main_64_clk_32_cin};
						end
				end
		end
	 

	and timer_and_1(timer_cin_1,timer[0],timer[1],timer[2],timer[3],timer[4],timer[5],timer[6],timer[7],timer[8],timer[9],timer[10],timer[11],timer[12],timer[13],timer[14],timer[15],timer[16],timer[17],timer[18],timer[19],timer[20],timer[21],timer[22],timer[23],timer[24],timer[25],timer[26],timer[27],timer[28],timer[29],timer[30],timer[31]);
	and timer_and_2(timer_cin_2,timer[1],timer[2],timer[3],timer[4],timer[5],timer[6],timer[7],timer[8],timer[9],timer[10],timer[11],timer[12],timer[13],timer[14],timer[15],timer[16],timer[17],timer[18],timer[19],timer[20],timer[21],timer[22],timer[23],timer[24],timer[25],timer[26],timer[27],timer[28],timer[29],timer[30],timer[31]);

	always @(posedge clk_in or negedge reset_n)
		begin
			if (~reset_n)
				begin
					timer<=64'b0;
				end
			else	
				begin
					casex(timer_mode)
						2'b00://+1
							begin
								timer[31:0]<=timer[31:0] + 32'b1;
								timer[63:32]<=timer[63:32] + {31'b0,timer_cin_1};
							end
						2'b01://+2
							begin
								timer[31:0]<=timer[31:0] + 32'd2;
								timer[63:32]<=timer[63:32] + {31'b0,timer_cin_2};
							end
						2'b11://load
							begin
								timer<=timer_in_wire;
							end
						default://+0
							begin	
								timer<=timer;
							end
					endcase	
				end
		end
	 
		
	
	//***********len registers************
	reg [11:0] main_len_count_0;
	reg [11:0] main_len_count_1;
	reg [7:0] main_len_count_2;
	reg [11:0] main_len_0;
	reg [11:0] main_len_1;
	reg [7:0] main_len_2;
	
	reg [11:0] sec_len_count_0;
	reg [11:0] sec_len_count_1;
	reg [7:0] sec_len_count_2;
	reg [11:0] sec_len_0;
	reg [11:0] sec_len_1;
	reg [7:0] sec_len_2;
	
	//**********Pipeline registers*********
	
	reg [7:0] back_reg_0;
	reg [7:0] pipeline_reg_0_backup_crc;
	reg [7:0] pipeline_reg_1;
	reg [7:0] pipeline_reg_2;
	reg [7:0] pipeline_reg_3;
	reg [7:0] pipeline_reg_4;
	reg available_reg_0;
	reg available_reg_1;
	reg available_reg_2;
	reg available_reg_3;
	reg available_reg_4;
	
	//**************CRC registers**************
	
	reg [1:0] mode_crc_check_main;
	reg [1:0] mode_crc_gen_sec;
	reg [7:0] data_crc_check;
	reg [7:0] data_crc_gen;

	//**************CRC check module***********
	
	reg [2:0] crc_check_addr;
	wire crc_check_data_in;
	reg crc_check_en;
	reg crc_check_reset_n=1'b1;
	wire crc_correct;
	wire [31:0] crc_check_out;
	
	CRC_shift_register_bank crc_check_bank(.crc_out(crc_check_out),.in_data(crc_check_data_in),.clk_in(clk_in),.en(crc_check_en),.reset_n(crc_check_reset_n));
	
	assign crc_check_data_in=data_crc_check[crc_check_addr];
	assign crc_correct=(crc_check_out==32'b0);
	
	always @(posedge clk_in)
		begin
			casex({mode_crc_check_main,(crc_check_addr==3'b0)})
				3'b000:
					begin
						crc_check_reset_n<=1'b1;
						crc_check_addr<=crc_check_addr+3'b1;
						crc_check_en<=1'b1;
					end
				3'b001:
					begin
						crc_check_reset_n<=1'b1;
						crc_check_en<=1'b0;
						crc_check_addr<=crc_check_addr;
					end
				3'b01x:
					begin
						crc_check_reset_n<=1'b1;
						crc_check_en<=1'b0;
						crc_check_addr<=3'b111;
					end
				3'b11x:
					begin
						crc_check_reset_n<=1'b0;
						crc_check_en<=1'b0;
						crc_check_addr<=3'b111;
					end

				default:
					begin
						
						crc_check_reset_n<=1'b1;
						crc_check_en<=1'b0;
						crc_check_addr<=3'b111;
					end
			endcase
		end
		
	//CRC generating module

	reg [2:0] crc_gen_addr;
	wire crc_gen_data_in;
	reg crc_gen_en;
	reg crc_gen_reset_n=1'b1;
	wire [7:0] crc_gen_out [3:0];
	
	CRC_shift_register_bank crc_gen_bank(.crc_out({crc_gen_out[3],crc_gen_out[2],crc_gen_out[1],crc_gen_out[0]}),.in_data(crc_gen_data_in),.clk_in(clk_in),.en(crc_gen_en),.reset_n(crc_gen_reset_n));
	
	assign crc_gen_data_in=data_crc_gen[crc_gen_addr];
	
	always @(posedge clk_in)
		begin
			casex({mode_crc_gen_sec,(crc_gen_addr==3'b0)})
				3'b000:
					begin
						crc_gen_reset_n<=1'b1;
						crc_gen_addr<=crc_gen_addr+3'b1;
						crc_gen_en<=1'b1;
					end
				3'b001:
					begin
						crc_gen_reset_n<=1'b1;
						crc_gen_en<=1'b0;
						crc_gen_addr<=crc_gen_addr;
					end
				3'b01x:
					begin
						crc_gen_reset_n<=1'b1;
						crc_gen_en<=1'b0;
						crc_gen_addr<=3'b111;
					end
				3'b11x:
					begin
						crc_gen_reset_n<=1'b0;
						crc_gen_en<=1'b0;
						crc_gen_addr<=3'b111;
					end

				default:
					
						begin
						crc_gen_reset_n<=1'b1;
						crc_gen_en<=1'b0;
						crc_gen_addr<=3'b111;
					end
			endcase	
		end
	
	//**********Error *********************
	
	reg [15:0] error_reg;// 0-new port 1-port loss 2-i_o_error 3-eeprom 4-MD error
	reg [2:0] available_ports;
	reg main_error_controller_rst=1'b1;
	reg [1:0] error_con_state;
	reg back_prop_delay_available;
	reg last_b_prop_delay_available;
	
	parameter error_con_reset =2'b0,error_monitor_mode=2'b10;
	
	always @(posedge clk_in or negedge main_error_controller_rst)
		begin
			if(~main_error_controller_rst)
				begin
					available_ports<=3'b0;
					error_con_state<=2'b0;
					error_reg<=16'b0;
				end
			else		
				begin
					case(error_con_state)
						error_con_reset:
							begin
								available_ports<={IRQ1,IRQ2,IRQ3};
								last_b_prop_delay_available<=back_prop_delay_available;
								error_con_state<=error_monitor_mode;
								error_reg<=16'b0;
							
							end
						error_monitor_mode:
							begin
								if(back_prop_delay_available==1'b1 && last_b_prop_delay_available==1'b0)
									begin
										error_con_state<=error_con_reset;
									end
								else
									begin
										error_con_state<=error_con_state;
									end
								error_reg[0]<=((available_ports[0])&& ~IRQ1) || ((available_ports[1])&& ~IRQ2) || ((available_ports[2])&& ~IRQ3);
								error_reg[1]<=(~(available_ports[0])&& IRQ1) || (~(available_ports[1])&& IRQ2) || (~(available_ports[2])&& IRQ3);
								error_reg[2]<=i_o_error;
								error_reg[3]<=EEPROM_error_avm;
								error_reg[15:4]<=12'b0;
								available_ports<=available_ports;
								last_b_prop_delay_available<=back_prop_delay_available;
							end
						default:
							begin
								available_ports<=3'b0;
								error_con_state<=2'b0;
								error_reg<=16'b0;
								last_b_prop_delay_available<=back_prop_delay_available;
							end
					endcase	
				end
		end
	
	//****************** Write _back**********
	
	//**** ram pointers
	reg [2:0] sec_b_ram_pointer;
	reg [2:0] back_b_ram_pointer;
	wire [2:0] sec_b_ram_next_pointer;
	
	assign sec_b_ram_next_pointer=sec_b_ram_pointer+3'b1;
	
	//**** ram addr
	reg [9:0] sec_b_ram_addr_write;
	reg [9:0] back_b_ram_addr_read;
	
	//reg [9:0] sec_b_ram_last_addr;
	
	//reg [7:0] back_center_reg;
	
	wire [7:0] end_addr_b_RAM_out;
	wire [7:0] start_addr_b_RAM_out;
	wire [7:0] write_back_ram_out;
	//reg sec_b_ram_w_en;
	
	reg [7:0] sec_write_back_ram_data_in_buff;
	reg sec_write_back_ram_w_en;
	
	write_back_RAM write_back_ram(.data(sec_write_back_ram_data_in_buff),.read_addr(back_b_ram_addr_read), .write_addr(sec_b_ram_addr_write),.we(sec_write_back_ram_w_en), .clk(clk_in),.q(write_back_ram_out));
	
	//write_b_addr_RAM end_addr_b_RAM(.data(sec_b_ram_addr_write),.read_addr(back_b_ram_pointer), .write_addr(sec_b_ram_pointer),.we(sec_b_ram_w_en), .clk(clk_in),.q(end_addr_b_RAM_out));
	//write_b_addr_RAM start_addr_b_RAM(.data(sec_b_ram_addr_write),.read_addr(back_b_ram_pointer), .write_addr(sec_b_ram_pointer),.we(sec_b_ram_w_en), .clk(clk_in),.q(start_addr_b_RAM_out));
	//reg [9:0] end_addr_b_RAM[3:0];
	reg [9:0] start_addr_b_ram[7:0];
	
	//***************** Boot settings ********
	
	reg main_boot_done;//should be high after booting main controller and i/o registers 
	reg back_boot_done;//should be start after main boot and this should be high after the the ethernet MD boot
	
	
	//******Trigger Module*******
	
	reg [1:0] trig_count=2'b0;
	wire stay_trig;
	reg trig_en=1'b0;
	
	always @(posedge clk_in)
		begin
			casex({receive_mac_rx_0,available_reg_4})
				2'b1x:
					begin
						trig_count<=2'b0;
					end
				2'b01:
					begin
						trig_count<=trig_count+2'b1;
					end
				default:
					begin
						trig_count<=2'b0;
					end
			endcase				
		end
	assign stay_trig=available_reg_3 || available_reg_4;//available_reg_4 && //main_success_frame_receive; //(available_reg_0||available_reg_1||available_reg_2||available_reg_3||available_reg_4) && //main_success_frame_receive;
	
	always @(posedge clk_in)
		begin
			trig_en<=(trig_count==2'b11) || (state_rx_0!=main_state_rx_0);
		end
		
	
	// ************************* Main State machine ************************
	//reg main_state_rx_0;
	reg c1_read_addr_type_update_status_reg;
	reg [3:0] main_compare_count;
	reg [3:0] main_compare_count_2;
	reg [3:0] main_compare_value;
	reg [3:0] main_compare_value_2;
	//reg main_success_frame_receive;//this should be high after successful frame receive and remain high until new frame receive
	reg request_main;// inform back state machine to stop update. wait_reg will be shiffted to high
	reg [5:0] state_main;
	
//	parameter boot_init=6'd0,boot_local_space=6'd1,boot_local_space_slave_addr_0=6'd2,boot_local_space_sync0_0=6'd3;
//	parameter boot_local_space_sync1_0=6'd4,user_space_init=6'd5,validity_check_init=6'd6,back_boot_wait=6'd7;
//	parameter validity_check=6'd8,user_space_invalid_odd=6'd9,user_space_valid_odd_init=6'd10,user_space_valid_odd_0=6'd11;
//	parameter user_space_i_o_wait=6'd12, normal_op_init=6'd13,SFD_main=6'd14,frame_error_main=6'd15,s_d_addr_main=6'd16,frame_len_1_main=7'd65,frame_len_2_main=7'd66;
//	parameter c1_cmd_main=6'd17,c1_len_main=6'd18,crc_check=6'd19,end_frame_crc=6'd20,c1_ideal_main=6'd21,c1_read_addr_check_type_main=6'd22,c1_read_addr_type_update_1=6'd23;
//	parameter c1_read_addr_handle_main=6'd24,c1_periodic_sync_handle_main_1=6'd25,c1_periodic_sync_handle_64_jitter_main_1=6'd26,c1_periodic_sync_handle_64_jitter_main_2=6'd27;
//	parameter c1_periodic_sync_handle_64_jitter_main_3=6'd28,c1_periodic_sync_handle_64_jitter_main_4=6'd29,c1_periodic_sync_handle_64_jitter_main_5=6'd30,c1_periodic_sync_def_main_1=6'd31;
//	parameter c2_invalid_slv_len_1=6'd32,c2_invalid_slv_len_2=6'd33,c2_valid_slv_len_1=6'd34,c2_valid_slv_mode=6'd35;
//	parameter c2_ideal_main=6'd36,c2_reg_read_main_addr_1=6'd37,c2_reg_read_main_addr_2=6'd38,c2_reg_read_main_data_1=6'd39,c2_digital_input_read_main_1=6'd40,c2_analog_input_read_main_1=6'd41;
//	parameter c2_i2c_read_main_1=6'd42,c2_i2c_read_main_2=6'd43,c2_slv_addr=6'd44,c1_periodic_sync_handle_64_jitter_main_6=6'd45,c1_periodic_sync_buff_0_update_main=6'd46;
//	parameter c1_periodic_sync_buff_0_update_main_2=6'd47,c2_reg_read_userspace_main_1=6'd48,c1_main_i_o_read_buff_data_load_1=6'd49,c1_main_i_o_read_buff_init=6'd50;
//	parameter c1_periodic_sync_buff_1_update_main=6'd51,c1_periodic_sync_buff_1_update_main_2=6'd52,c1_main_i_o_read_buff_data_load_2=6'd53,c1_main_i_o_read_buff_data_load_3=6'd54,c1_tx_set_sec=6'd55,c1_prop_measure_watch_time_sec=6'd56;
//	parameter c1_prop_read_time_sec_1=6'd57,c1_prop_save_addr_check_sec_1=6'd58,c1_diagnose_check_addr_sec=6'd59,c1_prop_measure_sec=6'd60,c1_general_cmd_slave_addr_sec=6'd61,c1_update_new_crc_sec=6'd62,c1_update_old_crc_sec=6'd63;
//	
	
	
	
	
	parameter boot_init=6'd0,boot_local_space=6'd1,boot_local_space_slave_addr_0=6'd2,boot_local_space_sync0_0=6'd3,boot_local_space_sync1_0=6'd4,user_space_init=6'd5,validity_check_init=6'd6,back_boot_wait=6'd7,validity_check=6'd8;
	parameter user_space_invalid_odd=6'd9,user_space_valid_odd_init_1=6'd10,user_space_valid_odd_0=6'd11,user_space_i_o_wait=6'd12,normal_op_init=6'd13,SFD_main=6'd14,frame_error_main=6'd15,s_d_addr_main=6'd16,frame_len_1_main=6'd17;
	parameter frame_len_2_main=6'd18,c1_cmd_main=6'd19,c1_len_main=6'd20,crc_check=6'd21,end_frame_crc=6'd22,c1_ideal_main=6'd23,c1_read_addr_check_type_main=6'd24,c1_read_addr_type_update_1=6'd25,c1_read_addr_handle_main=6'd26;
	parameter c1_periodic_sync_handle_main_1=6'd27,c1_periodic_sync_handle_64_jitter_main_1=6'd28,c1_periodic_sync_handle_64_jitter_main_2=6'd29,c1_periodic_sync_handle_64_jitter_main_3=6'd30;
	parameter c1_periodic_sync_handle_64_jitter_main_4=6'd31,c1_periodic_sync_handle_64_jitter_main_5=6'd32,c1_periodic_sync_handle_64_jitter_main_6=6'd33,c1_periodic_sync_def_main_1=6'd34,c1_periodic_sync_buff_0_update_main=6'd35;
	parameter c1_periodic_sync_buff_0_update_main_2=6'd36,c1_periodic_sync_buff_1_update_main=6'd37,c1_periodic_sync_buff_1_update_main_2=6'd38,c2_slv_addr=6'd39,c2_invalid_slv_len_1=6'd40,c2_invalid_slv_len_2=6'd41;
	parameter c2_valid_slv_len_1=6'd42,c2_valid_slv_mode=6'd43,c2_ideal_main=6'd44,c2_reg_read_main_addr_1=6'd45,c2_reg_read_main_addr_2=6'd46,c2_reg_read_main_data_1=6'd47,error_update_field_1=6'd48,error_update_field_2=6'd50;
	parameter c1_main_i_o_read_buff_init=6'd51,c1_main_i_o_read_buff_data_load_1=6'd52,c1_main_i_o_read_buff_data_load_2=6'd53,c1_main_i_o_read_buff_data_load_3=6'd54,c2_main_i_o_data_write_1=6'd55,c2_main_i_o_data_write_2=6'd56;
	parameter user_space_valid_even_0=6'd57,user_space_valid_even_init_1=6'd58,c1_periodic_sync_handle_64_jitter_main_4_1=6'd59,user_space_valid_even_init_2=6'd60,user_space_valid_odd_init_2=6'd61;
	//
	always @(posedge clk_in)
		begin
			if(((state_rx_0 != main_state_rx_0) && receive_mac_rx_0) || ((~receive_mac_rx_0) && stay_trig && trig_en))
				begin
					available_reg_0<=receive_mac_rx_0;
					available_reg_1<=available_reg_0;
					available_reg_2<=available_reg_1;
					available_reg_3<=available_reg_2;
					available_reg_4<=available_reg_3;
					pipeline_reg_1<=pipeline_reg_0;
					pipeline_reg_2<=pipeline_reg_1;
					pipeline_reg_3<=pipeline_reg_2;
				end
			else		
				begin
					available_reg_0<=available_reg_0;
					available_reg_1<=available_reg_1;
					available_reg_2<=available_reg_2;
					available_reg_3<=available_reg_3;
					available_reg_4<=available_reg_4;
					pipeline_reg_1<=pipeline_reg_1;
					pipeline_reg_2<=pipeline_reg_2;
					pipeline_reg_3<=pipeline_reg_3;
				end
		end
		
	always @(posedge clk_in or negedge reset_n)
		begin
		
			if (~reset_n)
				begin
					state_main<= 6'b0;
					wait_reg<=1'b0;
					main_boot_done<=1'b0;
					pipeline_reg_0<=8'b0;
					//main_success_frame_receive<=1'b0;
					//avm registers
					main_avm_new<=1'b0;
					main_avm_mode<=2'b0;
					//e ram register
					main_e_ram_addr_sel<=1'b0;
					main_e_ram_addr<=9'b0;
					//len and count reset
					main_len_count_0 <= 12'b0;
					main_len_count_1<= 12'b0;
					main_len_count_2<= 8'b0;
					main_compare_count<=4'b0;
					main_len_0<= 12'b0;
					main_len_1<= 12'b0;
					main_len_2<= 8'b0;
					main_compare_value<=4'b0;
					//rx toggle register
					main_state_rx_0<=1'b0;
					//i o interface rergister
					main_i_o_reg[7]<=8'bx;
					main_i_o_reg[6]<=8'bx;
					main_i_o_reg[5]<=8'bx;
					main_i_o_reg[4]<=8'bx;
					main_i_o_reg[3]<=8'bx;
					main_i_o_reg[2]<=8'bx;
					main_i_o_reg[1]<=8'bx;
					main_i_o_reg[0]<=8'bx;
					main_i_o_reg_2<=2'b00;
					
					main_data_read_state_0<=1'b0;
					main_data_read_state_1<=1'b0;
					//crc mode register
					mode_crc_check_main<=2'b0;
					//register control
					main_slave_addr_en<=1'b0;
					main_sync_0_en<=1'b0;
					main_sync_1_en<=1'b0;
					main_64_clk_mode<=1'b0;
				end
			else		
				begin
					case(state_main)
						boot_init:
							begin
								
								
								pipeline_reg_0<=8'bx;
								//main_success_frame_receive<=1'bx;
								//avm registers
								
								
								//e ram register
								main_e_ram_addr_sel<=1'b0;
								main_e_ram_addr<=9'b0;
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								main_compare_value<=4'bx;
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'bx;
								main_sync_0_en<=4'bx;
								main_sync_1_en<=4'bx;
								
								
								main_compare_count<=4'b0;
								main_avm_new<=1'b1;
								main_avm_mode<=2'b0;
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								state_main<= boot_local_space;
							end
							
						boot_local_space:
							begin
								
								
								//main_success_frame_receive<=1'bx;
								//avm registers
								
								//e ram register
								main_e_ram_addr_sel<=1'b0;
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								
								
								main_compare_value<=4'b0011;
								main_avm_new<=1'b1;
								main_avm_mode<=2'b0;
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								pipeline_reg_0<=e_ram_data_out[main_compare_count[1:0]];
								
								
								
								casex({(e_ram_addr_read_avm!=main_e_ram_addr), main_e_ram_addr[1:0]})
									3'b0xx:
										begin
											
											main_sync_0_en<=4'b0;
											main_sync_1_en<=4'b0;
											main_slave_addr_en<=1'b0;
											state_main<=state_main;
											main_e_ram_addr <= main_e_ram_addr;
											main_compare_count<=4'b0;
										end
									3'b101://slave addr
										begin
											main_sync_0_en<=4'b0;
											main_sync_1_en<=4'b0;
											main_slave_addr_en<=1'b1;
											state_main<=boot_local_space_slave_addr_0;
											main_e_ram_addr <= main_e_ram_addr;
											main_compare_count<=4'bx;
										end
									3'b110://sync 0
										begin
											
											main_sync_0_en<=4'b0001;
											main_sync_1_en<=4'b0;
											main_slave_addr_en<=1'b0;
											state_main<=boot_local_space_sync0_0;
											main_e_ram_addr <= main_e_ram_addr;
											main_compare_count<=main_compare_count+4'b1;
										end
									3'b111://sync 1
										begin
											
											main_sync_0_en<=4'b0;
											main_sync_1_en<=4'b0001;
											main_slave_addr_en<=1'b0;
											state_main<=boot_local_space_sync1_0;
											main_e_ram_addr <= main_e_ram_addr;
											main_compare_count<=main_compare_count+4'b1;
										end
									
									default:
										begin
											main_sync_0_en<=4'b0;
											main_sync_1_en<=4'b0;
											main_slave_addr_en<=1'b0;
											state_main<=state_main;
											main_e_ram_addr <= main_e_ram_addr + 9'b1;
											main_compare_count<=4'b0;
										end
								endcase	
							end
						boot_local_space_slave_addr_0:
							begin
								
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b1;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr_sel<=1'b0;
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								main_compare_value<=4'bx;
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_compare_count<=4'b0;
								pipeline_reg_0<=8'bx;//e_ram_data_out[main_compare_count];
								main_slave_addr_en<=1'b0;
								state_main<=boot_local_space;
								main_e_ram_addr <= main_e_ram_addr + 9'b1;
							end
							
						boot_local_space_sync0_0:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b1;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr_sel<=1'b0;
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_1_en<=4'b0;
								main_compare_value<=4'b0011;
								main_compare_count<=main_compare_count+4'b1;
								
								pipeline_reg_0<=e_ram_data_out[main_compare_count[1:0]];
								main_sync_0_en<=main_sync_0_en << 1;
								if(main_compare_value!=main_compare_count)
									begin
										state_main<=state_main;
										main_e_ram_addr<=main_e_ram_addr;
									end
								else
									begin
										state_main<=boot_local_space;
										main_e_ram_addr<=main_e_ram_addr+9'b1;
									end
							end
						boot_local_space_sync1_0:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr_sel<=1'b0;
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								
								main_compare_value<=4'b0011;
								main_compare_count<=main_compare_count+4'b1;
								pipeline_reg_0<=e_ram_data_out[main_compare_count[1:0]];
								main_sync_1_en<=main_sync_1_en << 1;
								if(main_compare_value!=main_compare_count)
									begin
										state_main<=state_main;
										main_e_ram_addr<=main_e_ram_addr;
									end
								else
									begin
										state_main<=user_space_init;
										main_e_ram_addr<=main_e_ram_addr+9'b1;
									end
							end
						
						user_space_init://wait until user space start
							begin
								pipeline_reg_0<=8'bx;
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_compare_count<=4'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								main_compare_value<=4'bx;
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_e_ram_addr_sel<=1'b1;
								casex({(e_ram_addr_read_avm!=main_e_ram_addr), main_e_ram_addr[5]})
									2'b1x:
										begin
											state_main<=state_main;
											main_e_ram_addr <= main_e_ram_addr + 9'b1;
											
										end
									2'b01:
										begin
											state_main<=validity_check_init;
											main_e_ram_addr <= main_e_ram_addr;
											
										end
									default:
										begin
											state_main<=state_main;
											main_e_ram_addr <= main_e_ram_addr;
											
										end
								endcase	
							end
						validity_check_init:
							begin
								pipeline_reg_0<=8'bx;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_compare_count<=4'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								main_compare_value<=4'bx;
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								if(main_e_ram_addr[7:0] !=8'b0)
									begin
										main_e_ram_addr_sel<=1'b1;
										state_main<=validity_check;
										main_boot_done<=1'b0;
										wait_reg<=1'b0;
									end
								else	
									begin
										main_e_ram_addr_sel<=1'b0;
										state_main<=back_boot_wait;
										main_boot_done<=1'b1;
										wait_reg<=1'b1;
									end
							end
						back_boot_wait:
							begin
								main_boot_done<=1'b1;
								pipeline_reg_0<=8'bx;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_compare_count<=4'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								main_compare_value<=4'bx;
								//rx toggle register
								main_state_rx_0<=1'b0;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								if(back_boot_done)
									begin
										state_main<=normal_op_init;
										wait_reg<=1'b0;
									end
								else	
									begin
										state_main<=state_main;
										wait_reg<=1'b1;
									end
							end
						validity_check:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								pipeline_reg_0<=8'bx;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_compare_count<=4'b0;
								main_compare_value<=4'b1;
								if(e_ram_data_out_wire[main_e_ram_addr[5:1]])
									begin
										state_main<=user_space_valid_odd_init_1;
										main_e_ram_addr_sel<=1'b0;
									end
								else		
									begin
										state_main<=user_space_invalid_odd;
										main_e_ram_addr_sel<=1'b1;
									end
							end
						user_space_invalid_odd:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								pipeline_reg_0<=8'bx;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								main_compare_value<=4'b0001;
								main_e_ram_addr_sel<=1'b1;
								casex({(e_ram_addr_read_avm!=main_e_ram_addr),(main_compare_value!=main_compare_count)})
									2'b10:
										begin
											state_main<=validity_check_init;
											main_e_ram_addr <= main_e_ram_addr + 9'b1;
											main_compare_count<=4'bx;
										end
									2'b11:
										begin
											state_main<=state_main;
											main_e_ram_addr <= main_e_ram_addr + 9'b1;
											main_compare_count<=main_compare_count+4'b1;
										end
									default:
										begin
											state_main<=state_main;
											main_e_ram_addr <= main_e_ram_addr;
											main_compare_count<=main_compare_count;
										end
								endcase
							end
						user_space_valid_odd_init_1:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_compare_value<=4'bx;
								pipeline_reg_0<=8'bx;
								main_e_ram_addr_sel<=1'b0;
								main_e_ram_addr <= main_e_ram_addr;
								main_compare_count_2<=4'bx;
								state_main<=user_space_valid_odd_init_2;
								main_compare_count<=4'b0;
									
							end	
						user_space_valid_odd_init_2:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_compare_value<=4'b0100;
								pipeline_reg_0<=e_ram_data_out[main_compare_count[1:0]];
								main_e_ram_addr_sel<=1'b0;
								main_e_ram_addr <= main_e_ram_addr;
								main_compare_count_2<=4'b0;
								if(e_ram_addr_read_avm!=main_e_ram_addr)
									begin
										state_main<=user_space_valid_odd_0;
										main_compare_count<=main_compare_count+4'b1;
									end
								else	
									begin
										state_main<=state_main;
										main_compare_count<=4'b0;
									end
							end
						
						user_space_valid_odd_0:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								main_e_ram_addr <= main_e_ram_addr;
								main_i_o_reg_2<=2'b0;
								main_e_ram_addr_sel<=1'b0;
								pipeline_reg_0<=e_ram_data_out[main_compare_count[1:0]];
								main_i_o_reg[main_compare_count_2[2:0]]<=pipeline_reg_0;
								main_compare_value<=4'b0100;
								if(main_compare_value!=main_compare_count)
									begin
										state_main<=state_main;
										main_compare_count<=main_compare_count+4'b1;
										main_compare_count_2<=main_compare_count_2+4'b1;
										main_e_ram_addr<=main_e_ram_addr;
									end
								else
									begin
										state_main<=user_space_valid_even_init_1;
										main_compare_count<=4'b0;
										main_compare_count_2<=4'bx;
										main_e_ram_addr <= main_e_ram_addr+9'b1;
									end
								
							end
						user_space_valid_even_init_1:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=main_i_o_reg[3];
								main_i_o_reg[2]<=main_i_o_reg[2];
								main_i_o_reg[1]<=main_i_o_reg[1];
								main_i_o_reg[0]<=main_i_o_reg[0];
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_compare_value<=4'bx;
								pipeline_reg_0<=8'bx;
								main_e_ram_addr_sel<=1'b0;
								main_e_ram_addr <= main_e_ram_addr;
								main_compare_count_2<=4'bx;
								state_main<=user_space_valid_even_init_2;
								main_compare_count<=4'b0;
									
							end
						user_space_valid_even_init_2:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=main_i_o_reg[3];
								main_i_o_reg[2]<=main_i_o_reg[2];
								main_i_o_reg[1]<=main_i_o_reg[1];
								main_i_o_reg[0]<=main_i_o_reg[0];
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_compare_value<=4'b0100;
								pipeline_reg_0<=e_ram_data_out[main_compare_count[1:0]];
								main_e_ram_addr_sel<=1'b0;
								main_e_ram_addr <= main_e_ram_addr;
								main_compare_count_2<=4'b0100;
								if(e_ram_addr_read_avm!=main_e_ram_addr)
									begin
										state_main<=user_space_valid_even_0;
										main_compare_count<=main_compare_count+4'b1;
										
									end
								else	
									begin
										state_main<=state_main;
										main_compare_count<=1'b0;
									end
							end
						user_space_valid_even_0:
							begin
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								main_e_ram_addr <= main_e_ram_addr;
								main_e_ram_addr_sel<=1'b0;
								pipeline_reg_0<=e_ram_data_out[main_compare_count[1:0]];
								main_i_o_reg[main_compare_count_2[2:0]]<=pipeline_reg_0;
								main_compare_value<=4'b0100;
								if(main_compare_value!=main_compare_count)
									begin
										state_main<=state_main;
										main_compare_count<=main_compare_count+4'b1;
										main_compare_count_2<=main_compare_count_2+4'b1;
										main_e_ram_addr <= main_e_ram_addr;
										main_i_o_reg_2<=2'b0;
									end
								else
									begin
										state_main<=user_space_i_o_wait;
										main_compare_count<=4'bx;
										main_compare_count_2<=4'bx;
										main_e_ram_addr <= main_e_ram_addr+9'b1;
										main_i_o_reg_2<=2'b10;
									end
							end
						user_space_i_o_wait:
							begin	
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								//main_success_frame_receive<=1'bx;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_compare_count<=4'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								main_compare_value<=4'bx;
								//rx toggle register
								main_state_rx_0<=1'bx;
								//i o interface rergister
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								main_i_o_reg[7]<=main_i_o_reg[7];
								main_i_o_reg[6]<=main_i_o_reg[6];
								main_i_o_reg[5]<=main_i_o_reg[5];
								main_i_o_reg[4]<=main_i_o_reg[4];
								main_i_o_reg[3]<=main_i_o_reg[3];
								main_i_o_reg[2]<=main_i_o_reg[2];
								main_i_o_reg[1]<=main_i_o_reg[1];
								main_i_o_reg[0]<=main_i_o_reg[0];
								
								pipeline_reg_0<=8'bx;
								main_e_ram_addr <= main_e_ram_addr;
								main_e_ram_addr_sel<=1'b1;
								//main_i_o_reg<=main_i_o_reg_2;
								if(success_ready_wait_request[0])// 0- wait request
									begin
										state_main<=state_main;
										main_i_o_reg_2<=2'b10;
									end
								else
									begin
										main_i_o_reg_2<=2'b00;
										state_main<=validity_check_init;
									end
							end
							
						normal_op_init://start new frame
							begin
								
								main_boot_done<=1'b1;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0 <= 12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_compare_count<=4'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								main_compare_value<=4'bx;
								//rx toggle register
								
								//i o interface rergister
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								mode_crc_check_main<=2'bx;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								wait_reg<=1'b1;// give chance to back state machine to update receive data
								request_main<=1'b0;// inform back state machine to stop updating
								pipeline_reg_0<=data_rx_0;
								pipeline_reg_0_backup_crc<=data_rx_0;
								if((state_rx_0!=main_state_rx_0) && receive_mac_rx_0)
									begin
										main_state_rx_0<=~main_state_rx_0;
										state_main<=SFD_main;
										
									end
								else		
									begin
										main_state_rx_0<=1'b0;
										state_main<=state_main;
										
									end
							end
						SFD_main:
							begin
								main_boot_done<=1'b1;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0<=12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								wait_reg<=1'b1;// give chance to back state machine to update receive data
								request_main<=1'b0;// inform back state machine to stop updating
								
								main_compare_count<=4'b0;
								main_compare_value<=4'b1011;
								mode_crc_check_main<=2'b11;//reset
								data_crc_check<=8'b0;
								casex({(pipeline_reg_0_backup_crc==8'b11010101),(state_rx_0!=main_state_rx_0), receive_mac_rx_0})
									3'b111:
										begin
											state_main<=s_d_addr_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
										end
									3'b011:
										begin
											pipeline_reg_0<=data_rx_0;
											state_main<=state_main;
											main_state_rx_0<=~main_state_rx_0;
										end
									3'bxx0:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
										end
								endcase
							end
						frame_error_main:
							begin
								main_boot_done<=1'b1;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								main_len_count_0<=12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_compare_count<=4'bx;
								main_compare_value<=4'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								wait_reg<=1'b1;// give chance to back state machine to update receive data
								request_main<=1'b0;// inform back state machine to stop updating
								mode_crc_check_main<=2'bxx;//reset
								pipeline_reg_0<=data_rx_0;
								main_state_rx_0<=1'bx;
								if(receive_mac_rx_0)	
									begin
										state_main<=state_main;
									end
								else
									begin
										state_main<=normal_op_init;
									end
									
							end
//						
						s_d_addr_main:
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b1;// give chance to back state machine to update receive data
								request_main<=1'b0;// inform back state machine to stop updating
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
								main_len_count_0<=12'bx;
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								main_compare_value<=4'b1011;
								
								casex({(main_compare_count==main_compare_value ),(state_rx_0!=main_state_rx_0), receive_mac_rx_0})//main_len_count_0[3:0]==4'b1011
									3'b111:
										begin
											main_compare_count<=4'b0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_state_rx_0<=~main_state_rx_0;
											state_main<=frame_len_1_main;
										end
									3'b011:
										begin
											main_compare_count<=main_compare_count+4'b1;
											state_main<=state_main;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
										end
									3'bxx0:
										begin
											main_compare_count<=4'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											pipeline_reg_0<=8'bx;
										end
									default:
										begin
											main_compare_count<=main_compare_count;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											pipeline_reg_0<=pipeline_reg_0;
										end
								endcase
							end
								
						frame_len_1_main:
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b1;// give chance to back state machine to update receive data
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
								
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b0;
								main_len_0[11]<=pipeline_reg_0[4];
								main_len_0[10]<=pipeline_reg_0[5];
								main_len_0[9]<=pipeline_reg_0[6];
								main_len_0[8]<=pipeline_reg_0[7];
								main_len_0[7:0]<=main_len_0[7:0];
								
								main_len_count_0<=12'bx;
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											state_main<=frame_len_2_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											data_crc_check<=pipeline_reg_0;
											mode_crc_check_main<=2'b01;
											
										end
									2'bx0:
										begin
											pipeline_reg_0<=8'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;

										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;

										end
								endcase	
							end

						frame_len_2_main:
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b1;// give chance to back state machine to update receive data
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
								
								main_len_count_1<= 12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating
								
								main_len_0[7]<=pipeline_reg_0[0];
								main_len_0[6]<=pipeline_reg_0[1];
								main_len_0[5]<=pipeline_reg_0[2];
								main_len_0[4]<=pipeline_reg_0[3];
								main_len_0[3]<=pipeline_reg_0[4];
								main_len_0[2]<=pipeline_reg_0[5];
								main_len_0[1]<=pipeline_reg_0[6];
								main_len_0[0]<=pipeline_reg_0[7];
								main_len_0[11:8]<=main_len_0[11:8];
								
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											state_main<=c1_cmd_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
										end
									2'bx0:
										begin
											pipeline_reg_0<=8'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=12'b0;
										end
								endcase
							end
						c1_cmd_main:
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b1;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
								
								main_len_count_2<= 8'bx;
								
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating
								
								main_len_count_1<= 12'b0;
								main_len_0<=main_len_0;
								main_len_1[11]<=pipeline_reg_0[4];
								main_len_1[10]<=pipeline_reg_0[5];
								main_len_1[9]<=pipeline_reg_0[6];
								main_len_1[8]<=pipeline_reg_0[7];
								main_len_1[7:0]<=main_len_1[7:0];
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											state_main<=c1_len_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
										end
									2'bx0:
										begin
											pipeline_reg_0<=8'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
										end
								endcase	
							end
						c1_len_main:
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
						
								//len and count reset
								
								main_len_count_2<= 8'bx;
								
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating
								
								main_e_ram_addr<=9'd8;
								main_e_ram_addr_sel<=1'b0;
								c1_read_addr_type_update_status_reg<=1'b0;
								main_len_0<=main_len_0;
								main_len_1[7]<=pipeline_reg_0[0];
								main_len_1[6]<=pipeline_reg_0[1];
								main_len_1[5]<=pipeline_reg_0[2];
								main_len_1[4]<=pipeline_reg_0[3];
								main_len_1[3]<=pipeline_reg_0[4];
								main_len_1[2]<=pipeline_reg_0[5];
								main_len_1[1]<=pipeline_reg_0[6];
								main_len_1[0]<=pipeline_reg_0[7];
								main_len_1[11:8]<=main_len_1[11:8];
								casex({pipeline_reg_1[3:0],(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									6'bxxxxx0:
										begin
											pipeline_reg_0<=8'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b0;
											data_crc_check<=8'bx;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'bxxxx01:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											mode_crc_check_main<=2'b00;
											data_crc_check<=data_crc_check;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									
									6'b000011://padding 
										begin
											state_main<=c1_ideal_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b100011://read addr
										begin
											state_main<=c1_read_addr_check_type_main;//c1_read_addr_handle_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0_backup_crc<=data_rx_0;
											pipeline_reg_0<=data_rx_0;//pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
										end
									6'b010011://update addr
										begin
											state_main<=c1_ideal_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b110011://periodic sync 
										begin
											state_main<=c1_periodic_sync_handle_main_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'b0;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'b0111;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b001011://set transmitter
										begin
											state_main<=c1_ideal_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b101011://start propagation delay measuring
										begin
											state_main<=c1_ideal_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b111011:// collect propagation data
										begin
											state_main<=c1_ideal_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b000111:// save propagation delay
										begin
											state_main<=c1_ideal_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b010111://diagnose report
										begin
											state_main<=c1_ideal_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b100111://reset
										begin
											state_main<=c1_ideal_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									6'b111111:// general cmd (c2) 
										begin
											state_main<=c2_slv_addr;//c1_cmd_main
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									default://wrong cmd
										begin	
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b00;
											data_crc_check<=data_crc_check;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_compare_count<=4'bx;
											main_compare_count_2<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
								endcase	
							end
						error_update_field_1:
							begin
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											state_main<=error_update_field_2;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
										end
									2'bx0:
										begin
											pipeline_reg_0<=8'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
										end
								endcase	
							end
						error_update_field_2:
							begin
								main_compare_value<=4'b0011;
								main_compare_count<=4'b0;
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											state_main<=crc_check;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
										end
									2'bx0:
										begin
											pipeline_reg_0<=8'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
										end
								endcase	
							end
						crc_check://end frame crc check
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
								main_len_count_1<=12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating
								
								main_compare_value<=4'b0011;
								main_len_0<=main_len_0;
								
								main_data_read_state_0<=1'b0;
								main_data_read_state_1<=1'b0;
								casex({(main_len_count_0==main_len_0),(main_compare_count==main_compare_value ),(state_rx_0!=main_state_rx_0), receive_mac_rx_0})//main_len_count_2[1:0]==2'b11
									4'b1111:
										begin
											state_main<=end_frame_crc;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=12'bx;
											main_compare_count<=4'b0;
										end
									4'b0111:
										begin
											state_main<=c1_cmd_main;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_compare_count<=4'b0;
										end
									4'b0011:
										begin
											main_len_count_0<=main_len_count_0+12'b1;
											main_compare_count<=main_compare_count+4'b1;
											state_main<=state_main;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
										end
									4'bxxx0:
										begin
											main_compare_count<=4'bx;
											main_len_count_0<=12'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b0;
											data_crc_check<=8'bx;
											pipeline_reg_0<=8'bx;
										end
									default:
										begin
											main_compare_count<=main_compare_count;
											main_len_count_0<=main_len_count_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											mode_crc_check_main<=2'b00;
											data_crc_check<=data_crc_check;
											pipeline_reg_0<=pipeline_reg_0;
										end
								endcase
							end
						
						end_frame_crc:
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
								main_len_count_0<=12'bx;
								main_len_count_1<=12'bx;
								main_len_count_2<= 8'bx;
								
								main_len_0<= 12'bx;
								main_len_1<= 12'bx;
								main_len_2<= 8'bx;
								
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating

								main_compare_value<=4'b10;//4'b0010
								mode_crc_check_main<=2'b00;
								data_crc_check<=data_crc_check;
								casex({(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0), receive_mac_rx_0})//main_len_count_2[1:0]==2'b10
									3'b111:
										begin
											
											state_main<=normal_op_init;
											main_state_rx_0<=~main_state_rx_0;
											main_compare_count<=4'b0;
											pipeline_reg_0<=data_rx_0;
										end
									3'b011:
										begin
											
											main_compare_count<=main_compare_count+4'b1;
											state_main<=state_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
										end
									3'bxx0:
										begin
											main_compare_count<=4'b0;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											pipeline_reg_0<=pipeline_reg_0;
										end
									default:
										begin
											main_compare_count<=main_compare_count;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											pipeline_reg_0<=pipeline_reg_0;
										end
								endcase	
							end
						c1_ideal_main:
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
								
								main_len_count_2<= 8'bx;
								
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating
								
								main_len_0<=main_len_0;
								main_len_1<=main_len_1;
								main_compare_value<=4'b0011;//for crc check
								main_compare_count<=4'b0;
								casex({(main_len_count_1==main_len_1),(state_rx_0!=main_state_rx_0), receive_mac_rx_0})
									3'b111:
										begin
											pipeline_reg_0<=data_rx_0;
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_1<=12'b0;
											main_len_count_0<=main_len_count_0+12'b1;
										end
									3'b011:
										begin
											pipeline_reg_0<=data_rx_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											state_main<=state_main;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_state_rx_0<=~main_state_rx_0;
											
										end
									3'bxx0:
										begin
											pipeline_reg_0<=8'bx;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b0;
											data_crc_check<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											mode_crc_check_main<=2'b00;
											data_crc_check<=data_crc_check;
										end
								endcase
							end
						c1_read_addr_check_type_main://check whether the even addr is 8'b0
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								
								main_len_count_2<= 8'bx;
								
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating
								
								main_e_ram_addr<=9'd8;
								main_e_ram_addr_sel<=1'b0;
								main_compare_count<=4'b0;
								main_compare_value<=4'b0010;
								main_len_0<=main_len_0;
								main_len_1<=main_len_1;
								c1_read_addr_type_update_status_reg<=1'b0;
								casex({(pipeline_reg_0==8'b0),(state_rx_0!=main_state_rx_0), receive_mac_rx_0})
									3'b111:
										begin
											state_main<=c1_read_addr_type_update_1;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0_backup_crc<=data_rx_0;
											pipeline_reg_0<=data_rx_0;// slave addr shall be updated by sec statemachine
											data_crc_check<=pipeline_reg_0_backup_crc;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
										end
									3'b011:
										begin
											state_main<=c1_read_addr_handle_main;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0_backup_crc<=data_rx_0;
											pipeline_reg_0<=data_rx_0;
											data_crc_check<=pipeline_reg_0_backup_crc;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
										end
									3'bxx0:
										begin
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b0;
											pipeline_reg_0<=8'bx;
											data_crc_check<=8'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									default:
										begin
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											mode_crc_check_main<=2'b00;
											pipeline_reg_0<=pipeline_reg_0;
											pipeline_reg_0_backup_crc<=pipeline_reg_0_backup_crc;
											data_crc_check<=data_crc_check;
										end
								endcase
							end
						
						c1_read_addr_type_update_1:		
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								
								main_len_count_2<= 8'bx;
								
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating
								
								main_compare_count<=4'b0;
								main_compare_value<=4'b0011;//for crc
								
								main_len_0<=main_len_0;
								main_len_1<=main_len_1;
								main_len_count_0<=main_len_count_0;
								main_len_count_1<=main_len_count_1;
								
								pipeline_reg_0[3:0]<=e_ram_data_out_wire[3:0];
								pipeline_reg_0[7:4]<=pipeline_reg_0[7:4];
								pipeline_reg_0_backup_crc<=pipeline_reg_0_backup_crc;
								state_main<=c1_read_addr_handle_main;
								c1_read_addr_type_update_status_reg<=1'b1;
							end
						c1_read_addr_handle_main:
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								
								//len and count reset
								
								main_len_count_2<= 8'bx;
								
								main_len_2<= 8'bx;
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating
								
								main_e_ram_addr<=9'd8;
								main_e_ram_addr_sel<=1'b0;
								main_len_0<=main_len_0;
								main_len_1<=main_len_1;
								
								
								c1_read_addr_type_update_status_reg<=c1_read_addr_type_update_status_reg;
								main_compare_count<=4'b0;
								main_compare_value<=4'b0011;
								casex({(main_len_count_1==main_len_1),(state_rx_0!=main_state_rx_0), receive_mac_rx_0,c1_read_addr_type_update_status_reg})
									4'b1111:
										begin
											state_main<=error_update_field_1;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											data_crc_check<=pipeline_reg_0_backup_crc;
											main_len_count_1<=12'b0;
											main_len_count_0<=main_len_count_0+12'b1;
											pipeline_reg_0<=data_rx_0;
											pipeline_reg_0_backup_crc<=data_rx_0;
										end
									4'b0110:
										begin
											state_main<=c1_read_addr_check_type_main;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											data_crc_check<=pipeline_reg_0_backup_crc;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											pipeline_reg_0<=data_rx_0;
											pipeline_reg_0_backup_crc<=data_rx_0;
										end
									4'b0111:
										begin
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											state_main<=state_main;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											data_crc_check<=pipeline_reg_0_backup_crc;
											pipeline_reg_0<=data_rx_0;
											pipeline_reg_0_backup_crc<=data_rx_0;
										end
									4'bxx0x:
										begin
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b0;
											pipeline_reg_0<=8'bx;
											data_crc_check<=8'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									default:
										begin
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											mode_crc_check_main<=2'b00;
											data_crc_check<=data_crc_check;
											pipeline_reg_0<=pipeline_reg_0;
											pipeline_reg_0_backup_crc<=pipeline_reg_0_backup_crc;
										end
								endcase	
							end
						c1_periodic_sync_handle_main_1://store 64 time stamp of ref clk
							begin
								main_boot_done<=1'b1;
								wait_reg<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr <= 9'bx;
								main_e_ram_addr_sel<=1'bx;
								//len and count reset
							
								main_len_count_2<= 8'bx;
								
								
								main_len_2<= 8'bx;
								
								//rx toggle register
								
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'bx;
								main_data_read_state_1<=1'bx;
								//crc mode register
								
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=4'b0;
								main_sync_1_en<=4'b0;
								
								request_main<=1'b1;// inform back state machine to stop updating

								main_compare_value<=4'b0111;//4'b0111
								casex({(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0), receive_mac_rx_0})//main_len_count_2[2:0]==3'b111
									3'b111:
										begin
											
											state_main<=c1_periodic_sync_handle_64_jitter_main_1;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_64_temp_clk[main_compare_count[2:0]]<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'b0;
										end
									3'b011:
										begin
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=main_compare_count+4'b1;
											state_main<=state_main;
											mode_crc_check_main<=2'b01;
											main_state_rx_0<=~main_state_rx_0;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_64_temp_clk[main_compare_count[2:0]]<=pipeline_reg_0;
										end
									3'bxx0:
										begin
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_compare_count<=4'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b0;
											pipeline_reg_0<=8'bx;
											data_crc_check<=8'bx;
											main_64_temp_clk[0]<=main_64_temp_clk[0];//have to assign individually all array elements
											main_64_temp_clk[1]<=main_64_temp_clk[1];
											main_64_temp_clk[2]<=main_64_temp_clk[2];
											main_64_temp_clk[3]<=main_64_temp_clk[3];
											main_64_temp_clk[4]<=main_64_temp_clk[4];
											main_64_temp_clk[5]<=main_64_temp_clk[5];
											main_64_temp_clk[6]<=main_64_temp_clk[6];
											main_64_temp_clk[7]<=main_64_temp_clk[7];
										end
									default:
										begin
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_compare_count<=main_compare_count;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											mode_crc_check_main<=2'b0;
											pipeline_reg_0<=pipeline_reg_0;
											data_crc_check<=data_crc_check;
											main_64_temp_clk[0]<=main_64_temp_clk[0];//have to assign individually all array elements
											main_64_temp_clk[1]<=main_64_temp_clk[1];
											main_64_temp_clk[2]<=main_64_temp_clk[2];
											main_64_temp_clk[3]<=main_64_temp_clk[3];
											main_64_temp_clk[4]<=main_64_temp_clk[4];
											main_64_temp_clk[5]<=main_64_temp_clk[5];
											main_64_temp_clk[6]<=main_64_temp_clk[6];
											main_64_temp_clk[7]<=main_64_temp_clk[7];
										end
								endcase
							end
						c1_periodic_sync_handle_64_jitter_main_1:
							begin
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											state_main<=c1_periodic_sync_handle_64_jitter_main_2;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_jitter_correction[7:0]<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
										end
									2'bx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											pipeline_reg_0<=8'bx;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
										end
								endcase	
							end
						c1_periodic_sync_handle_64_jitter_main_2:
							begin
								main_jitter_correction[11:8]<=pipeline_reg_0[3:0];
								state_main<=c1_periodic_sync_handle_64_jitter_main_3;
							end
						c1_periodic_sync_handle_64_jitter_main_3:
							begin
								main_jitter_correction<=main_jitter_correction+{8'b0,4'b0101};//jitter_count_tx_wire};//**********
								main_delay<={4'b0,main_jitter_correction}+16'b0;//{back_prop_delay[1],back_prop_delay[0]};//allow 2 clock cycles to update =>( main_64_temp_clk + main_delay )
								state_main<=c1_periodic_sync_handle_64_jitter_main_4;
							end
						c1_periodic_sync_handle_64_jitter_main_4:
							begin
								main_64_clk_mode<=1'b1;//leave 2 clocks to update
								state_main<=c1_periodic_sync_handle_64_jitter_main_4_1;
							end
						c1_periodic_sync_handle_64_jitter_main_4_1://to update the main_64_clk
							begin
								main_64_clk_mode<=1'b0;
								state_main<=c1_periodic_sync_handle_64_jitter_main_5;
							end
						c1_periodic_sync_handle_64_jitter_main_5:
							begin
								main_64_clk_mode<=1'b0;
								{main_clock_def[3],main_clock_def[2],main_clock_def[1],main_clock_def[0]}<=timer[31:0]-main_64_clk[31:0];
								state_main<=c1_periodic_sync_handle_64_jitter_main_6;
								main_compare_count<=4'bx;
								main_compare_value<=4'bx;
							end
						c1_periodic_sync_handle_64_jitter_main_6:
							begin
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											state_main<=c1_periodic_sync_def_main_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'b0;
											main_compare_value<=4'b0101;
										end
									2'bx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											pipeline_reg_0<=8'bx;
											main_compare_value<=4'bx;
											main_compare_count<=4'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_compare_value<=4'bx;
											main_compare_count<=4'bx;
										end
								endcase
							end
						c1_periodic_sync_def_main_1:// there is a slave address between def time stamps
							begin
								main_compare_value<=4'b0101;
								casex({(main_data_read_state_0==sec_data_read_state_0),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									3'b111:
										begin
											state_main<=c1_periodic_sync_buff_0_update_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=main_compare_count+4'b1;
											main_data_read_state_0<=~main_data_read_state_0;
											main_data_read_state_1<=main_data_read_state_1;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=pipeline_reg_0;
											
											main_i_o_read_buff_1[0]<=main_i_o_read_buff_1[0];
											main_i_o_read_buff_1[1]<=main_i_o_read_buff_1[1];
											main_i_o_read_buff_1[2]<=main_i_o_read_buff_1[2];
											main_i_o_read_buff_1[3]<=main_i_o_read_buff_1[3];
										end
									3'b011:
										begin
											state_main<=c1_periodic_sync_buff_1_update_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=main_compare_count+4'b1;
											main_data_read_state_0<=main_data_read_state_0;
											main_data_read_state_1<=~main_data_read_state_1;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=pipeline_reg_0;
											
											main_i_o_read_buff_0[0]<=main_i_o_read_buff_0[0];
											main_i_o_read_buff_0[1]<=main_i_o_read_buff_0[1];
											main_i_o_read_buff_0[2]<=main_i_o_read_buff_0[2];
											main_i_o_read_buff_0[3]<=main_i_o_read_buff_0[3];
										end
									3'bxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											pipeline_reg_0<=8'bx;
											main_compare_count<=4'bx;
											main_data_read_state_0<=1'b0;
											main_data_read_state_1<=1'b0;
											main_i_o_read_buff_1[0]<=main_i_o_read_buff_1[0];
											main_i_o_read_buff_1[1]<=main_i_o_read_buff_1[1];
											main_i_o_read_buff_1[2]<=main_i_o_read_buff_1[2];
											main_i_o_read_buff_1[3]<=main_i_o_read_buff_1[3];
											main_i_o_read_buff_0[0]<=main_i_o_read_buff_0[0];
											main_i_o_read_buff_0[1]<=main_i_o_read_buff_0[1];
											main_i_o_read_buff_0[2]<=main_i_o_read_buff_0[2];
											main_i_o_read_buff_0[3]<=main_i_o_read_buff_0[3];
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_compare_count<=main_compare_count;
											main_data_read_state_0<=main_data_read_state_0;
											main_data_read_state_1<=main_data_read_state_1;
											main_i_o_read_buff_1[0]<=main_i_o_read_buff_1[0];
											main_i_o_read_buff_1[1]<=main_i_o_read_buff_1[1];
											main_i_o_read_buff_1[2]<=main_i_o_read_buff_1[2];
											main_i_o_read_buff_1[3]<=main_i_o_read_buff_1[3];
											main_i_o_read_buff_0[0]<=main_i_o_read_buff_0[0];
											main_i_o_read_buff_0[1]<=main_i_o_read_buff_0[1];
											main_i_o_read_buff_0[2]<=main_i_o_read_buff_0[2];
											main_i_o_read_buff_0[3]<=main_i_o_read_buff_0[3];
										end
								endcase
							end
						c1_periodic_sync_buff_0_update_main:
							begin	
								main_i_o_read_buff_0[main_compare_count[2:0]]<=pipeline_reg_0;
								main_data_read_state_0<=main_data_read_state_0;
								main_data_read_state_1<=main_data_read_state_1;
								main_compare_count<=main_compare_count+4'b1;
								state_main<=c1_periodic_sync_buff_0_update_main_2;
								mode_crc_check_main<=2'b0;
							end
						c1_periodic_sync_buff_0_update_main_2:
							begin
								main_data_read_state_0<=main_data_read_state_0;
								main_data_read_state_1<=main_data_read_state_1;
								main_i_o_read_buff_last_pointer<=1'b0;
								casex({(main_len_count_1==main_len_1),(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									4'b1111:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'b011;
										end
									4'b0111://slave address read
										begin
											state_main<=c1_periodic_sync_def_main_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'b0;
											main_compare_value<=4'b101;
										end
									4'b0011:
										begin
											state_main<=c1_periodic_sync_buff_0_update_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
										end
									4'bxxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_compare_count<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
										end
								endcase
							end
						c1_periodic_sync_buff_1_update_main:
							begin	
								main_i_o_read_buff_1[main_compare_count[2:0]]<=pipeline_reg_0;
								main_data_read_state_0<=main_data_read_state_0;
								main_data_read_state_1<=main_data_read_state_1;
								main_compare_count<=main_compare_count+4'b1;
								state_main<=c1_periodic_sync_buff_1_update_main_2;
								mode_crc_check_main<=2'b0;
							end
						c1_periodic_sync_buff_1_update_main_2:
							begin
								main_data_read_state_0<=main_data_read_state_0;
								main_data_read_state_1<=main_data_read_state_1;
								main_i_o_read_buff_last_pointer<=1'b1;
								casex({(main_len_count_1==main_len_1),(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									4'b1111:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'b011;
										end
									4'b0111://slave address read
										begin
											state_main<=c1_periodic_sync_def_main_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=4'b0;
											main_compare_value<=4'b101;
										end
									4'b0011:
										begin
											state_main<=c1_periodic_sync_buff_1_update_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
										end
									4'bxxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_compare_count<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
										end
								endcase
							end
						
						c2_slv_addr:
							begin
								main_len_count_2<=8'b0;
								casex({(pipeline_reg_0==slave_addr),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									3'b111:
										begin
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											state_main<=c2_valid_slv_len_1;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
										end
									3'b011:
										begin
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											state_main<=c2_invalid_slv_len_1;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
										end
									3'bx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											pipeline_reg_0<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
										end
								endcase	
							end
						c2_invalid_slv_len_1:
							begin
								main_len_2[7]<=pipeline_reg_0[0];
								main_len_2[6]<=pipeline_reg_0[1];
								main_len_2[5]<=pipeline_reg_0[2];
								main_len_2[4]<=pipeline_reg_0[3];
								main_len_2[3]<=pipeline_reg_0[4];
								main_len_2[2]<=pipeline_reg_0[5];
								main_len_2[1]<=pipeline_reg_0[6];
								main_len_2[0]<=pipeline_reg_0[7];
								main_state_rx_0<=main_state_rx_0;
								mode_crc_check_main<=2'b0;
								data_crc_check<=data_crc_check;
								main_len_count_0<=main_len_count_0;
								main_len_count_1<=main_len_count_1;
								main_len_count_2<=8'b0;//main_len_count_2+8'b1;
								state_main<=c2_invalid_slv_len_2;
							end		
						c2_invalid_slv_len_2:
							begin
								main_compare_count<=4'b0;
								main_compare_value<=4'b011;//CRC check
								casex({(main_len_count_1==main_len_1),(main_len_count_2==main_len_2),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									4'b1111:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
										end
									4'b0111:
										begin
											state_main<=c2_slv_addr;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=8'bx;
										end
									4'b0011:
										begin
											state_main<=state_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
										end
									4'bxxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											pipeline_reg_0<=8'bx;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
										end
								endcase	
							end
						c2_valid_slv_len_1:
							begin
								main_len_2[7]<=pipeline_reg_0[0];
								main_len_2[6]<=pipeline_reg_0[1];
								main_len_2[5]<=pipeline_reg_0[2];
								main_len_2[4]<=pipeline_reg_0[3];
								main_len_2[3]<=pipeline_reg_0[4];
								main_len_2[2]<=pipeline_reg_0[5];
								main_len_2[1]<=pipeline_reg_0[6];
								main_len_2[0]<=pipeline_reg_0[7];
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;//mode
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											state_main<=c2_valid_slv_mode;	
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=8'b1;
										end
									2'bx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=8'b1;
										end
								endcase	
							end
						c2_valid_slv_mode:
							begin
								casex({pipeline_reg_0[3:0],(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									6'bxxxx01:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_compare_value_2<=4'bx;
											main_compare_value<=4'bx;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
											main_compare_count<=4'b0;
											main_i_o_reg_2<=2'b0;
										end
									6'bxxxxx0:
										begin
											main_compare_value_2<=4'bx;
											main_compare_value<=4'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b00;
											pipeline_reg_0<=8'bx;
											main_i_o_reg_2<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											main_compare_count<=4'bx;
										end
									6'b100x11:// register write (user + local)
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'b0101;// cmd total bytes-1
											main_compare_value_2<=4'bx;
											main_compare_count<=4'b0;
											state_main<=c2_ideal_main;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b0;
											//main_i_o_reg<=main_i_o_reg;
										end
									6'b010011:// register read local space 
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'bx;
											main_compare_value_2<=4'bx;
											main_compare_count<=4'bx;
											state_main<=c2_reg_read_main_addr_1;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b0;
											//main_i_o_reg<=main_i_o_reg;
										end
									6'b010111:// register read user space
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'b1;//cmd+addr-2
											main_compare_value_2<=4'b11;//data field -1
											main_compare_count<=main_compare_count+4'b1;
											state_main<=c2_main_i_o_data_write_1;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b0;
											main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;//main_i_o_reg[7:0]<=pipeline_reg_0;//
										end
									6'b001011:// Digital input read
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'bx;
											main_compare_value_2<=4'b0;//data field -1
											main_compare_count<=main_compare_count+4'b1;
											state_main<=c2_main_i_o_data_write_2;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b0;
											main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;//main_i_o_reg[7:0]<=pipeline_reg_0;//
										end
									6'b101011:// Digital output write
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'b0001;// cmd total bytes-1
											main_compare_value_2<=4'bx;
											main_compare_count<=4'b0;
											state_main<=c2_ideal_main;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b0;
											//main_i_o_reg<=main_i_o_reg;
										end
									6'b011011:// analog input read
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'bx;
											main_compare_value_2<=4'b1;//data field -1
											main_compare_count<=main_compare_count+4'b1;
											state_main<=c2_main_i_o_data_write_2;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b0;
											main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;//main_i_o_reg[7:0]<=pipeline_reg_0;//
										end
									6'b111011:// PWM write
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'b0010;// cmd total bytes-1
											main_compare_value_2<=4'bx;
											main_compare_count<=4'b0;
											state_main<=c2_ideal_main;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b0;
											//main_i_o_reg<=main_i_o_reg;
										end
									6'b000111:// I2C Read/write
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'b0010;
											main_compare_value_2<=4'b0001;// data bytes-1
											main_compare_count<=main_compare_count+4'b1;
											state_main<=c2_main_i_o_data_write_1;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;//main_i_o_reg[7:0]<=pipeline_reg_0;//
											main_i_o_reg_2<=2'b0;
										end
									6'b101111:// SPI Read/write
										begin
											main_compare_value_2<=4'bx;
											main_compare_value<=4'bx;
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b0;
											data_crc_check<=8'bx;
											pipeline_reg_0<=8'bx;
											main_i_o_reg_2<=2'b0;
											main_compare_count<=4'bx;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
										end
									6'b001111:// servo pulse count write
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'b0011;// cmd total bytes-1
											main_compare_value_2<=4'bx;
											main_compare_count<=4'b0;
											state_main<=c2_ideal_main;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b0;
											//main_i_o_reg<=main_i_o_reg;
										end
									6'b110111:// servo position read
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'b0011;
											main_compare_value_2<=4'bx;// data bytes-1
											main_compare_count<=4'b0;
											state_main<=c1_main_i_o_read_buff_data_load_1;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b10;
											main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;//main_i_o_reg[7:0]<=pipeline_reg_0;//
										end
								
									6'b110011:// Read triggered time of output
										begin
											main_state_rx_0<=~main_state_rx_0;
											main_compare_value<=4'bx;
											main_compare_value_2<=4'b11;//data field -1
											main_compare_count<=main_compare_count+4'b1;
											state_main<=c2_main_i_o_data_write_2;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											pipeline_reg_0<=data_rx_0;
											main_i_o_reg_2<=2'b10;
											main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;//main_i_o_reg[7:0]<=pipeline_reg_0;//
										end
									default://wrong cmd
										begin
											state_main<=frame_error_main;
											main_i_o_reg_2<=2'b0;
											main_compare_value_2<=4'bx;
											main_compare_value<=4'bx;
											main_state_rx_0<=1'b0;
											mode_crc_check_main<=2'b11;
											data_crc_check<=data_crc_check;
											pipeline_reg_0<=pipeline_reg_0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
										end
								endcase
							end
						c2_ideal_main:
							begin
								main_compare_value<=main_compare_value;
								casex({(main_len_count_1==main_len_1),(main_len_count_2==main_len_2),(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									5'b11111:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'b0;
											main_compare_count<=4'b0;
											main_compare_value<=4'b11;
										end
									5'b01111:
										begin
											state_main<=c2_slv_addr;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=8'b0;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
										end
									5'b00111:
										begin
											state_main<=c2_valid_slv_mode;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
										end
									5'b00011:
										begin
											state_main<=state_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=main_compare_count+4'b1;
											main_compare_value<=main_compare_value;
										end
									5'bxxxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b00;
											main_compare_count<=4'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
											main_compare_value<=4'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
										end
								endcase	
							end
						c2_reg_read_main_addr_1:
							begin
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_e_ram_addr[7:0]<=pipeline_reg_0;
											state_main<=c2_reg_read_main_addr_2;	
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
										end
									2'bx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
											main_e_ram_addr[7:0]<=main_e_ram_addr[7:0];
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
											main_e_ram_addr[7:0]<=main_e_ram_addr[7:0];
										end
								endcase	
							end
						c2_reg_read_main_addr_2://this should be the data from e ram 
							begin
								main_e_ram_addr_sel<=1'b0;
								wait_reg<=1'b0;
								main_compare_count<=4'b0;
								main_compare_value<=4'b0100;
								mode_crc_check_main<=2'b00;
								main_e_ram_addr[8]<=pipeline_reg_0[0];//this has an error
								state_main<=c2_reg_read_main_data_1;
								pipeline_reg_0_backup_crc<=data_rx_0;
							end
						c2_reg_read_main_data_1:
							begin
								casex({(main_len_count_1==main_len_1),(main_len_count_2==main_len_2),(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									5'b11111:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0_backup_crc;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'b11;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									5'b01111:
										begin
											state_main<=c2_slv_addr;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0_backup_crc;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=8'bx;
											main_compare_count<=4'bx;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									5'b00111:
										begin
											state_main<=c2_valid_slv_mode;
											main_state_rx_0<=~main_state_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0_backup_crc;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=4'b0;
											pipeline_reg_0<=data_rx_0;
											main_compare_value<=4'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									5'b00011:
										begin
											state_main<=state_main;
											main_state_rx_0<=~main_state_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0_backup_crc;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=main_compare_count+4'b1;
											pipeline_reg_0<=e_ram_data_out[main_compare_count[1:0]];
											pipeline_reg_0_backup_crc<=data_rx_0;
											main_compare_value<=main_compare_value;
										end
									5'bxxxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_compare_count<=4'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
											pipeline_reg_0_backup_crc<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
											pipeline_reg_0_backup_crc<=pipeline_reg_0_backup_crc;
										end
								endcase	
							end
						
						c2_main_i_o_data_write_1:
							begin
								main_i_o_reg_2<=2'b00;
								main_compare_value<=main_compare_value;
								casex({(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									
									3'b111:
										begin
											state_main<=c2_main_i_o_data_write_2;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=main_compare_count+4'b1;
											
										end
									3'b011:
										begin
											state_main<=state_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=main_compare_count+4'b1;
											
										end
									3'bxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b00;
											main_compare_count<=4'bx;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
											main_compare_count<=main_compare_count;
											//main_i_o_reg<=main_i_o_reg;
											
										end
								endcase	
							end
							
						c2_main_i_o_data_write_2:
							begin
								mode_crc_check_main<=2'b00;
								main_i_o_reg[main_compare_count[2:0]]<=pipeline_reg_0;
								main_i_o_reg_2<=2'b10;
								state_main<=c1_main_i_o_read_buff_init;
								main_compare_count<=4'b0;
								main_compare_value<=main_compare_value_2;
							end
						c1_main_i_o_read_buff_init:
							begin
								main_compare_count<=main_compare_count;
								main_compare_value<=main_compare_value;
								
								main_i_o_reg_2<=2'b11;
								
								casex({(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									2'b11:
										begin
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											state_main<=c1_main_i_o_read_buff_data_load_1;	
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
										end
									2'bx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
										end
								endcase	
							end	
						c1_main_i_o_read_buff_data_load_1:// there is a slave address between def time stamps
							begin
								
								casex({(main_len_count_1==main_len_1),(main_len_count_2==main_len_2),(main_compare_count==main_compare_value),(main_data_read_state_0==sec_data_read_state_0),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									6'b111111:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'b011;
											main_data_read_state_0<=~main_data_read_state_0;
											main_data_read_state_1<=main_data_read_state_1;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_read_buff_0_40<=success_ready_wait_request[2] ;//success error
											main_i_o_read_buff_1_40<=main_i_o_read_buff_1_40;
											main_i_o_reg_2<=2'b00;
										end
									6'b011111:
										begin
											state_main<=c2_slv_addr;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
											main_data_read_state_0<=~main_data_read_state_0;
											main_data_read_state_1<=main_data_read_state_1;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_read_buff_0_40<=success_ready_wait_request[2] ;//success error
											main_i_o_read_buff_1_40<=main_i_o_read_buff_1_40;
											main_i_o_reg_2<=2'b00;
										end
									6'b001111:
										begin
											state_main<=c2_valid_slv_mode;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
											main_data_read_state_0<=~main_data_read_state_0;
											main_data_read_state_1<=main_data_read_state_1;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_read_buff_0_40<=success_ready_wait_request[2] ;//success error
											main_i_o_read_buff_1_40<=main_i_o_read_buff_1_40;
											main_i_o_reg_2<=2'b00;
										end
									6'b111011:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'b011;
											main_data_read_state_0<=main_data_read_state_0;
											main_data_read_state_1<=~main_data_read_state_1;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_read_buff_1_40<=success_ready_wait_request[2] ;//success error
											main_i_o_read_buff_0_40<=main_i_o_read_buff_0_40;
											main_i_o_reg_2<=2'b00;
										end
									6'b011011:
										begin
											state_main<=c2_slv_addr;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
											main_data_read_state_0<=main_data_read_state_0;
											main_data_read_state_1<=~main_data_read_state_1;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_read_buff_1_40<=success_ready_wait_request[2] ;//success error
											main_i_o_read_buff_0_40<=main_i_o_read_buff_0_40;
											main_i_o_reg_2<=2'b00;
										end
									6'b001011:
										begin
											state_main<=c2_valid_slv_mode;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
											main_data_read_state_0<=main_data_read_state_0;
											main_data_read_state_1<=~main_data_read_state_1;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_read_buff_1_40<=success_ready_wait_request[2] ;//success error
											main_i_o_read_buff_0_40<=main_i_o_read_buff_0_40;
											main_i_o_reg_2<=2'b00;
										end
									6'bxx0111:
										begin
											state_main<=c1_main_i_o_read_buff_data_load_2;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=main_compare_count+4'b1;
											main_compare_value<=main_compare_value;
											main_data_read_state_0<=~main_data_read_state_0;
											main_data_read_state_1<=main_data_read_state_1;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_read_buff_0_40<=success_ready_wait_request[2] ;//success error
											main_i_o_read_buff_1_40<=main_i_o_read_buff_1_40;
											main_i_o_reg_2<=2'b11;
										end
									6'bxx0011:
										begin
											state_main<=c1_main_i_o_read_buff_data_load_3;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=main_compare_count+4'b1;
											main_compare_value<=main_compare_value;
											main_data_read_state_0<=main_data_read_state_0;
											main_data_read_state_1<=~main_data_read_state_1;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_read_buff_1_40<=success_ready_wait_request[2] ;//success error
											main_i_o_read_buff_0_40<=main_i_o_read_buff_0_40;
											main_i_o_reg_2<=2'b11;
										end
									6'bxxxxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
											main_compare_count<=4'bx;
											main_data_read_state_0<=1'bx;
											main_data_read_state_1<=1'bx;
											main_i_o_reg_2<=2'b0;
											main_i_o_read_buff_0_40<=1'bx;
											main_i_o_read_buff_1_40<=1'bx;
											main_compare_value<=4'bx;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
											main_data_read_state_0<=main_data_read_state_0;
											main_data_read_state_1<=main_data_read_state_1;
											main_i_o_read_buff_0_40<=main_i_o_read_buff_0_40;
											main_i_o_read_buff_1_40<=main_i_o_read_buff_1_40;
											main_i_o_reg_2<=main_i_o_reg_2;
										end
								endcase
							end
						
						c1_main_i_o_read_buff_data_load_2:
							begin
								casex({(main_len_count_1==main_len_1),(main_len_count_2==main_len_2),(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									5'b11111:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'b011;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_reg_2<=2'b00;
										end
									5'b01111://slave address read
										begin
											state_main<=c2_slv_addr;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_reg_2<=2'b00;
										end
									5'b00111://slave address read
										begin
											state_main<=c2_valid_slv_mode;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_reg_2<=2'b00;
										end
									5'b00011:
										begin
											state_main<=state_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_value<=main_compare_value;
											main_i_o_read_buff_0[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_compare_count<=main_compare_count+4'b1;
											main_i_o_reg_2<=2'b11;
										end
									5'bxxxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
											main_compare_count<=4'bx;
											main_compare_value<=4'bx;
											main_i_o_reg_2<=2'b0;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
											main_i_o_reg_2<=main_i_o_reg_2;
										end
								endcase
							end
						
						c1_main_i_o_read_buff_data_load_3:
							begin
								casex({(main_len_count_1==main_len_1),(main_len_count_2==main_len_2),(main_compare_count==main_compare_value),(state_rx_0!=main_state_rx_0),receive_mac_rx_0})
									5'b11111:
										begin
											state_main<=error_update_field_1;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'b011;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_reg_2<=2'b00;
										end
									5'b01111://slave address read
										begin
											state_main<=c2_slv_addr;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=8'bx;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_reg_2<=2'b00;
										end
									5'b00111://slave address read
										begin
											state_main<=c2_valid_slv_mode;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_count<=4'b0;
											main_compare_value<=4'bx;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_i_o_reg_2<=2'b00;
										end
									5'b00011:
										begin
											state_main<=state_main;
											main_state_rx_0<=~main_state_rx_0;
											pipeline_reg_0<=data_rx_0;
											mode_crc_check_main<=2'b01;
											data_crc_check<=pipeline_reg_0;
											main_len_count_0<=main_len_count_0+12'b1;
											main_len_count_1<=main_len_count_1+12'b1;
											main_len_count_2<=main_len_count_2+8'b1;
											main_compare_value<=main_compare_value;
											main_i_o_read_buff_1[main_compare_count[2:0]]<=i_o_data_in[main_compare_count[1:0]];
											main_compare_count<=main_compare_count+4'b1;
											main_i_o_reg_2<=2'b11;
										end
									5'bxxxx0:
										begin
											state_main<=frame_error_main;
											main_state_rx_0<=1'b0;
											data_crc_check<=8'bx;
											mode_crc_check_main<=2'b0;
											main_len_count_0<=12'bx;
											main_len_count_1<=12'bx;
											main_len_count_2<=8'bx;
											pipeline_reg_0<=8'bx;
											main_compare_count<=4'bx;
											main_compare_value<=4'bx;
											main_i_o_reg_2<=2'b0;
										end
									default:
										begin
											pipeline_reg_0<=pipeline_reg_0;
											state_main<=state_main;
											main_state_rx_0<=main_state_rx_0;
											data_crc_check<=data_crc_check;
											mode_crc_check_main<=2'b00;
											main_len_count_0<=main_len_count_0;
											main_len_count_1<=main_len_count_1;
											main_len_count_2<=main_len_count_2;
											main_compare_count<=main_compare_count;
											main_compare_value<=main_compare_value;
											main_i_o_reg_2<=main_i_o_reg_2;
										end
								endcase
							end
	
						default:
							begin
								state_main<= 6'b0;
								wait_reg<=1'b0;
								main_boot_done<=1'b0;
								pipeline_reg_0<=8'b0;
								//main_success_frame_receive<=1'b0;
								//avm registers
								main_avm_new<=1'b0;
								main_avm_mode<=2'b0;
								//e ram register
								main_e_ram_addr_sel<=1'b0;
								main_e_ram_addr<=9'b0;
								//len and count reset
								main_len_count_0 <= 12'b0;
								main_len_count_1<= 12'b0;
								main_len_count_2<= 8'b0;
								main_compare_count<=4'b0;
								main_len_0<= 12'b0;
								main_len_1<= 12'b0;
								main_len_2<= 8'b0;
								main_compare_value<=4'b0;
								//rx toggle register
								main_state_rx_0<=1'b0;
								//i o interface rergister
								main_i_o_reg[7]<=8'bx;
								main_i_o_reg[6]<=8'bx;
								main_i_o_reg[5]<=8'bx;
								main_i_o_reg[4]<=8'bx;
								main_i_o_reg[3]<=8'bx;
								main_i_o_reg[2]<=8'bx;
								main_i_o_reg[1]<=8'bx;
								main_i_o_reg[0]<=8'bx;
								main_i_o_reg_2<=2'b00;
								main_data_read_state_0<=1'b0;
								main_data_read_state_1<=1'b0;
								//crc mode register
								mode_crc_check_main<=2'b0;
								//register control
								main_slave_addr_en<=1'b0;
								main_sync_0_en<=1'b0;
								main_sync_1_en<=1'b0;
							end
					endcase	
			end
	end
	
	
	
	//secondary state machine
	reg [5:0] state_sec;
//	trig_en
//		reg main_boot_done;//should be high after booting main controller and i/o registers 
//	reg back_boot_done;
//	stay_trig
//		reg [1:0] mode_crc_gen_sec;
//	reg [7:0] data_crc_check;
//	reg [7:0] data_crc_gen;
//		reg [1:0] sec_b_ram_pointer;
//	reg [1:0] back_b_ram_pointer;
//	
//	//**** ram addr
//	reg [9:0] sec_b_ram_addr_write;
//	reg [9:0] back_b_ram_addr_read;
//	reg [9:0] sec_b_ram_last_addr;
//	
	reg sec_tx_state;
	reg [7:0] sec_tx_data;
	
//	assign data_tx_0=sec_tx_data;
//	assign state_tx_0=sec_tx_state;
//	
//		
//	reg [7:0] sec_write_back_ram_data_in_buff;
//	reg sec_write_back_ram_w_en;
//	
//	reg [3:0] sec_b_ram_next_pointer;
//	
	parameter boot_sec=6'd0,wait_SFD_sec=6'd1,SFD_sec=6'd2,s_d_addr_sec=6'd3,frame_len_sec_1=6'd4,frame_len_sec_2=6'd5,c1_cmd_sec=6'd6,c1_len_sec=6'd7,c1_pad_sec=6'd8,c1_crc_check_sec_1=6'd9,c1_crc_check_sec_2=6'd10,c1_crc_check_sec_3=6'd11;
	parameter frame_end_check_sec_1=6'd12,frame_end_crc_sec=6'd12,c1_addr_read_slave_addr_sec=6'd13,c1_addr_read_update_slave_addr_sec=6'd14;
	parameter c1_addr_read_sec=6'd16,c1_addr_update_slave_addr_sec=6'd17,c1_addr_update_new_slave_addr_sec=6'd18,c1_64_time_sec=6'd19,c1_def_time_check_sec=6'd20,c1_def_time_normal_update_sec=6'd21;
	parameter c1_def_self_time_update_sec=6'd22,c1_def_time_buff_0_update_sec=6'd23,c1_def_time_buff_1_update_sec=6'd24,c1_tx_set_sec=6'd25,c1_prop_measure_watch_time_sec=6'd26,c1_prop_measure_sec=6'd27,c1_prop_save_addr_check_sec_1=6'd49;
	parameter c1_prop_save_addr_check_sec_2=6'd28,c1_prop_read_time_sec_1=6'd29,c1_prop_read_time_sec_2=6'd30,c1_prop_read_time_sec_3=6'd31,c1_prop_read_time_sec_4=6'd32,c1_diagnose_update_sec_1=6'd33,c1_diagnose_check_addr_sec=6'd34;
	parameter c1_general_cmd_slave_addr_sec=6'd35,c1_general_slave_unmatch_data_sec=6'd37,c1_general_slave_match_len_sec=6'd38,c1_general_slave_match_cmd_sec=6'd39;
	parameter c2_reg_write_sec=6'd40,c2_reg_read_local_sec=6'd41,c2_general_read_buff_0_sec=6'd42,c2_general_read_buff_1_sec=6'd43;
	parameter c1_update_new_crc_sec=6'd44,c1_update_old_crc_sec=6'd45,c1_jitter_update_sec=6'd46,c1_delay_time_check_sec=6'd47,c1_general_slave_unmatch_len_sec=6'd48,error_update_sec=6'd49,error_update_sec_2=6'd50;
	
	wire main_i_o_read_buff_40_valid;
	assign main_i_o_read_buff_40_valid=(sec_data_read_state_0!=main_data_read_state_0)? main_i_o_read_buff_0_40:main_i_o_read_buff_1_40;
	wire greater_buff_0;
	wire greater_buff_1;
	assign greater_buff_0=({main_clock_def[3],main_clock_def[2],main_clock_def[1],main_clock_def[0]}>{main_i_o_read_buff_0[4],main_i_o_read_buff_0[3],main_i_o_read_buff_0[2],main_i_o_read_buff_0[1]});
	assign greater_buff_1=({main_clock_def[3],main_clock_def[2],main_clock_def[1],main_clock_def[0]}>{main_i_o_read_buff_1[4],main_i_o_read_buff_1[3],main_i_o_read_buff_1[2],main_i_o_read_buff_1[1]});
	
	
	wire b_ram_free;
	assign b_ram_free=sec_b_ram_next_pointer!=back_b_ram_pointer;
	reg sec_update_data;
	reg [3:0] last_cmd_sec;
	reg [3:0] sec_compare_count;
	reg [3:0] sec_compare_value;
	reg [3:0] sec_compare_value_2;
	
	
	reg sec_receive_tx;
	wire final_receive_tx_main_controller;
	or receive_con_or(final_receive_tx_main_controller,sec_receive_tx,receive_mac_rx_0);
	wire [7:0] error_load_1;
	wire [7:0] error_load_2;
	
	assign error_load_1=error_reg[7:0] || pipeline_reg_3;
	assign error_load_2=error_reg[15:8] || pipeline_reg_3;
	
	always @(posedge clk_in or negedge reset_n)
		begin
		if(~reset_n)
			begin
				state_sec<=boot_sec;
				pipeline_reg_4<=8'b0;
				mode_crc_gen_sec<=2'b0;
				data_crc_gen<=8'b0;
				sec_b_ram_pointer<=2'b0;
				sec_b_ram_addr_write<=10'b0;
				//sec_b_ram_last_addr<=10'b0;
				sec_compare_count<=4'b0;
				sec_compare_value<=4'b0;
				sec_tx_state<=1'b0;
				sec_receive_tx<=1'b0;
				
			end
		else	
			begin
				case(state_sec)
					boot_sec:
						begin
							mode_crc_gen_sec<=2'b11;
							data_crc_gen<=8'bx;
							sec_tx_state<=1'b0;
							start_addr_b_ram[sec_b_ram_pointer]<=sec_b_ram_addr_write;
							state_sec<=boot_sec;
							pipeline_reg_4<=8'b0;
							mode_crc_gen_sec<=2'b0;
							data_crc_gen<=8'b0;
							sec_b_ram_pointer<=2'b0;
							sec_b_ram_addr_write<=10'b0;
							//sec_b_ram_last_addr<=10'b0;
							sec_compare_count<=4'b0;
							sec_compare_value<=4'b0;
							sec_tx_state<=1'b0;
							sec_receive_tx<=1'b0;
							if(back_boot_done)
								begin
									state_sec<=wait_SFD_sec;
								end
							else	
								begin	
									state_sec<=state_sec;
								end
						end
					wait_SFD_sec:
						begin
							mode_crc_gen_sec<=2'b11;
							data_crc_gen<=8'bx;
							sec_tx_state<=1'b0;
							sec_tx_data<=8'bx;
							sec_receive_tx<=1'b0;
							sec_data_read_state_0<=1'b0;
							sec_data_read_state_1<=1'b0;
							sec_b_ram_addr_write<=start_addr_b_ram[sec_b_ram_pointer];
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							if(trig_en && stay_trig)
								begin
									state_sec<=SFD_sec;
									pipeline_reg_4<=pipeline_reg_3;
								end
							else	
								begin	
									state_sec<=state_sec;
									pipeline_reg_4<=8'bx;
								end
						end			
					SFD_sec:
						begin
							mode_crc_gen_sec<=2'b11;
							data_crc_gen<=8'b0;
							sec_compare_value<=4'b1011;
							sec_compare_count<=4'b0;
							casex({(pipeline_reg_4==8'b11010101),trig_en,stay_trig})
								
								3'b111:
									begin
										state_sec<=s_d_addr_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_receive_tx<=1'b1;
									end
								3'bxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										sec_tx_data<=8'bx;
										sec_tx_state<=1'b0;
										sec_receive_tx<=sec_receive_tx;
									end
								3'b011://error
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;//
										sec_tx_data<=pipeline_reg_3;
										sec_tx_state<=~sec_tx_state;
										sec_receive_tx<=1'b1;
									end
								default://error
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										sec_tx_data<=sec_tx_data;
										sec_tx_state<=sec_tx_state;
										sec_receive_tx<=sec_receive_tx;
									end
							endcase
						end
					s_d_addr_sec:
						begin
							
							sec_compare_value<=sec_compare_value;
							casex({(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
								3'b111:
									begin
										state_sec<=frame_len_sec_1;
										pipeline_reg_4<=pipeline_reg_3;
										sec_compare_count<=4'bx;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								3'b011:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_compare_count<=sec_compare_count+4'b1;
										sec_tx_state<=~sec_tx_state;
										sec_tx_data<=pipeline_reg_4;
									end
								3'bxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=8'bx;
										sec_compare_count<=4'bx;
										sec_tx_state<=~sec_tx_state;
										sec_tx_data<=pipeline_reg_4;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=data_crc_gen;
										sec_compare_count<=sec_compare_count;
										sec_tx_state<=sec_tx_state;
										sec_tx_data<=sec_tx_data;
									end
							endcase
						
						end
					frame_len_sec_1:
						begin
							sec_compare_count<=4'bx;
							sec_compare_value<=4'bx;
							sec_len_0[11]<=pipeline_reg_4[4];
							sec_len_0[10]<=pipeline_reg_4[5];
							sec_len_0[9]<=pipeline_reg_4[6];
							sec_len_0[8]<=pipeline_reg_4[7];
							sec_len_0[7:0]<=sec_len_0[7:0];
							sec_len_count_0<=12'b0;
							casex({trig_en,stay_trig})
								
								2'b11:
									begin
										state_sec<=frame_len_sec_2;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								2'bx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b0;
										data_crc_gen<=8'bx;
										sec_tx_state<=~sec_tx_state;
										sec_tx_data<=pipeline_reg_4;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=data_crc_gen;
										sec_tx_state<=sec_tx_state;
										sec_tx_data<=sec_tx_data;
									end
							endcase
						end
					frame_len_sec_2:
						begin
							sec_compare_count<=4'bx;
							sec_compare_value<=4'bx;
							sec_len_0[7]<=pipeline_reg_4[0];
							sec_len_0[6]<=pipeline_reg_4[1];
							sec_len_0[5]<=pipeline_reg_4[2];
							sec_len_0[4]<=pipeline_reg_4[3];
							sec_len_0[3]<=pipeline_reg_4[4];
							sec_len_0[2]<=pipeline_reg_4[5];
							sec_len_0[1]<=pipeline_reg_4[6];
							sec_len_0[0]<=pipeline_reg_4[7];
							sec_len_0[11:8]<=sec_len_0[11:8];
							
							casex({trig_en,stay_trig})
								
								2'b11:
									begin
										state_sec<=c1_cmd_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_len_count_0<=sec_len_count_0+12'b1;
									end
								2'bx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=8'bx;
										sec_len_count_0<=12'b0;
										sec_tx_state<=~sec_tx_state;
										sec_tx_data<=pipeline_reg_4;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=data_crc_gen;
										sec_len_count_0<=12'b0;
										sec_tx_state<=sec_tx_state;
										sec_tx_data<=sec_tx_data;
									end
							endcase
						
						end
					c1_cmd_sec:
						begin
							sec_compare_count<=4'bx;
							sec_compare_value<=4'bx;
							sec_len_1[11]<=pipeline_reg_4[4];
							sec_len_1[10]<=pipeline_reg_4[5];
							sec_len_1[9]<=pipeline_reg_4[6];
							sec_len_1[8]<=pipeline_reg_4[7];
							sec_len_1[7:0]<=sec_len_1[7:0];
							sec_len_0<=sec_len_0;
							last_cmd_sec<=pipeline_reg_4[3:0];
							sec_len_count_1<=12'b0;
							casex({trig_en,stay_trig})
								2'b11:
									begin
										state_sec<=c1_len_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								2'bx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b0;
										data_crc_gen<=8'bx;
										sec_len_count_0<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=data_crc_gen;
										sec_len_count_0<=sec_len_count_0;
										sec_tx_data<=sec_tx_data;
										sec_tx_state<=sec_tx_state;
									end
							endcase
						end
					c1_len_sec:
						begin
							
							sec_len_1[7]<=pipeline_reg_4[0];
							sec_len_1[6]<=pipeline_reg_4[1];
							sec_len_1[5]<=pipeline_reg_4[2];
							sec_len_1[4]<=pipeline_reg_4[3];
							sec_len_1[3]<=pipeline_reg_4[4];
							sec_len_1[2]<=pipeline_reg_4[5];
							sec_len_1[1]<=pipeline_reg_4[6];
							sec_len_1[0]<=pipeline_reg_4[7];
							sec_len_1[11:8]<=sec_len_1[11:8];
							sec_len_0<=sec_len_0;
							casex({last_cmd_sec,trig_en,stay_trig})
								
									6'b000011://padding
										begin
											state_sec<=c1_pad_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
										end
									6'b100011://address read local space
										begin
											state_sec<=c1_addr_read_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
										end
									6'b010011://address update local space
										begin
											state_sec<=c1_addr_update_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={4'b0+last_cmd_sec};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
										end
									6'b110011://sync msg
										begin
											state_sec<=c1_64_time_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={4'b0+last_cmd_sec};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0111;//8_sync+2_jitter
										end
									6'b001011://transmitter set msg
										begin
											state_sec<=c1_tx_set_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;//
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
										end
									6'b101011://start propagation process
										begin
											state_sec<=c1_prop_measure_watch_time_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={4'b0+last_cmd_sec};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0001;//8_sync+2_jitter
										end
									6'b111011://read propagation delay
										begin
											state_sec<=c1_prop_read_time_sec_1;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0000;//
										end
									6'b000111://save propagation time 
										begin
											state_sec<=c1_prop_save_addr_check_sec_1;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={4'b0+last_cmd_sec};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0;//8_sync+2_jitter
										end
									6'b010111://diagnose report
										begin
											state_sec<=c1_diagnose_check_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0000;
										end
									6'b100111://reset all 
										begin
											state_sec<=c1_prop_measure_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={4'b0+last_cmd_sec};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;//8_sync+2_jitter
										end
									6'b111111://general commands 
										begin
											state_sec<=c1_general_cmd_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;//8_sync+2_jitter
										end
									6'bxxxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;//go to last pointer
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=12'b0;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
										end
								endcase
						
						end
					c1_pad_sec:
						begin
							sec_compare_count<=4'b0;// for crc check
							sec_compare_value<=4'bx;
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_len_count_1==sec_len_1),trig_en,stay_trig})
								
								3'b111:
									begin
										state_sec<=error_update_sec;
										pipeline_reg_4<=error_load_1;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								3'b011:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								3'bxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=8'bx;
										sec_len_count_0<=12'bx;
										sec_len_count_1<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
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
					
					error_update_sec:
						begin
							casex({trig_en,stay_trig})
								2'b11:
									begin
										state_sec<=error_update_sec_2;
										pipeline_reg_4<=error_load_2;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								2'bx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b0;
										data_crc_gen<=8'bx;
										sec_len_count_0<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=data_crc_gen;
										sec_len_count_0<=sec_len_count_0;
										sec_tx_data<=sec_tx_data;
										sec_tx_state<=sec_tx_state;
									end
							endcase
						end
					error_update_sec_2:
						begin
							casex({trig_en,stay_trig})
								2'b11:
									begin
										state_sec<=c1_crc_check_sec_1;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								2'bx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b0;
										data_crc_gen<=8'bx;
										sec_len_count_0<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=data_crc_gen;
										sec_len_count_0<=sec_len_count_0;
										sec_tx_data<=sec_tx_data;
										sec_tx_state<=sec_tx_state;
									end
							endcase
						end
					c1_crc_check_sec_1://crc_gen_out
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							sec_compare_value<=4'b0011;//for crc check
							mode_crc_gen_sec<=2'b0;
							data_crc_gen<=data_crc_gen;
							casex({crc_correct,((start_addr_b_ram[sec_b_ram_pointer]!=sec_b_ram_addr_write) && b_ram_free),trig_en,stay_trig})
								
									4'b1111:
										begin
											sec_b_ram_pointer<=sec_b_ram_pointer+2'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											state_sec<=c1_update_new_crc_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_tx_data<=crc_gen_out[sec_compare_count[1:0]];
											sec_tx_state<=~sec_tx_state;
											sec_compare_count<=sec_compare_count+4'b1;
											sec_len_count_0<=sec_len_count_0+12'b1;
										end
									4'b0x11:
										begin
											sec_b_ram_addr_write<=start_addr_b_ram[sec_b_ram_pointer];
											sec_b_ram_pointer<=sec_b_ram_pointer;
											state_sec<=c1_update_old_crc_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_compare_count<=sec_compare_count+4'b1;
											sec_len_count_0<=sec_len_count_0+12'b1;
										end
									4'b1011:
										begin
											sec_b_ram_addr_write<=start_addr_b_ram[sec_b_ram_pointer];
											sec_b_ram_pointer<=sec_b_ram_pointer;
											state_sec<=c1_update_new_crc_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_tx_data<=crc_gen_out[sec_compare_count[1:0]];
											sec_tx_state<=~sec_tx_state;
											sec_compare_count<=sec_compare_count+4'b1;
											sec_len_count_0<=sec_len_count_0+12'b1;
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_b_ram_addr_write<=start_addr_b_ram[sec_b_ram_pointer];
											sec_b_ram_pointer<=sec_b_ram_pointer;
											sec_len_count_0<=12'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											sec_compare_count<=4'b0;
											sec_b_ram_pointer<=sec_b_ram_pointer;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
										end
								endcase
						
						end
					c1_update_new_crc_sec://((start_addr_b_ram[sec_b_ram_pointer]!=sec_b_ram_addr_writet) && crc_correct),
						begin
							mode_crc_gen_sec<=2'b0;
							data_crc_gen<=8'b0;
							sec_compare_value<=4'b0011;
							start_addr_b_ram[sec_b_ram_pointer]<=sec_b_ram_addr_write;
							casex({(sec_len_count_0==sec_len_0),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								4'b1111:
									begin
										state_sec<=frame_end_crc_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_len_count_0<=12'bx;
										sec_tx_data<=crc_gen_out[sec_compare_count[1:0]];
										sec_tx_state<=~sec_tx_state;
										sec_compare_count<=4'b0;
										mode_crc_gen_sec<=2'b11;
									end
								4'b0111:
									begin
										state_sec<=c1_cmd_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_tx_data<=crc_gen_out[sec_compare_count[1:0]];
										sec_tx_state<=~sec_tx_state;
										sec_compare_count<=4'bx;
										mode_crc_gen_sec<=2'b11;
									end
								4'b0011:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_tx_data<=crc_gen_out[sec_compare_count[1:0]];
										sec_tx_state<=~sec_tx_state;
										sec_compare_count<=sec_compare_count+4'b1;
										mode_crc_gen_sec<=2'b0;
									end
								4'bxxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										sec_len_count_0<=12'bx;
										mode_crc_gen_sec<=2'b0;
										sec_tx_data<=crc_gen_out[sec_compare_count[1:0]];
										sec_tx_state<=~sec_tx_state;
										sec_compare_count<=4'bx;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0;
										sec_compare_count<=sec_compare_count;
										sec_tx_data<=sec_tx_data;
										sec_tx_state<=sec_tx_state;
										mode_crc_gen_sec<=2'b0;
									end
							endcase
						end
					c1_update_old_crc_sec:
						begin
							
							data_crc_gen<=8'b0;
							sec_compare_value<=4'b0011;
							start_addr_b_ram[sec_b_ram_pointer]<=sec_b_ram_addr_write;
							casex({(sec_len_count_0==sec_len_0),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								4'b1111:
									begin
										state_sec<=frame_end_crc_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_len_count_0<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_compare_count<=4'b0;
										mode_crc_gen_sec<=2'b11;
									end
								4'b0111:
									begin
										state_sec<=c1_cmd_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_compare_count<=4'bx;
										mode_crc_gen_sec<=2'b11;
									end
								4'b0011:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_compare_count<=sec_compare_count+4'b1;
										mode_crc_gen_sec<=2'b0;
									end
								4'bxxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										sec_len_count_0<=12'bx;
										mode_crc_gen_sec<=2'b0;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_compare_count<=4'bx;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0;
										sec_compare_count<=sec_compare_count;
										sec_tx_data<=sec_tx_data;
										sec_tx_state<=sec_tx_state;
										mode_crc_gen_sec<=2'b0;
									end
							endcase
						end
					
					frame_end_crc_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							mode_crc_gen_sec<=2'b00;
							data_crc_gen<=8'bx;
							sec_compare_value<=4'b0011;
							casex({(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									3'b111:
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'b0;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
										end
									3'b011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=sec_compare_count+4'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
										end
									3'bxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
										end
								endcase
						end
					c1_addr_read_slave_addr_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							sec_compare_value<=4'bx;
							sec_compare_count<=4'bx;
							mode_crc_gen_sec<=2'b00;
							data_crc_gen<=data_crc_gen;
							sec_len_count_0<=sec_len_count_0;
							sec_len_count_1<=sec_len_count_1;
							sec_tx_data<=sec_tx_data;
							sec_tx_state<=sec_tx_state;
							if(pipeline_reg_4==8'b0)
								begin
									pipeline_reg_4<=slave_addr;
									state_sec<=c1_addr_read_update_slave_addr_sec;
									sec_update_data<=1'b1;
								end
							else	
								begin
									pipeline_reg_4<=pipeline_reg_4;
									state_sec<=c1_addr_read_update_slave_addr_sec;
									sec_update_data<=1'b0;
								end
						end
					c1_addr_read_update_slave_addr_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							sec_compare_value<=4'bx;
							sec_compare_count<=4'bx;
							sec_update_data<=sec_update_data;
							casex({sec_update_data,trig_en,stay_trig})
									
								3'b111:
									begin
										state_sec<=c1_addr_read_sec;
										pipeline_reg_4<={1'b1,IRQ1,IRQ2,IRQ3,pipeline_reg_3[3:0]};
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
									end
								3'b011:
									begin
										state_sec<=c1_addr_read_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								3'bxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=8'bx;
										sec_len_count_0<=12'bx;
										sec_len_count_1<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
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
					
					c1_addr_read_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							sec_compare_value<=4'bx;
							sec_compare_count<=4'bx;
							sec_update_data<=sec_update_data;
							casex({(sec_len_1==sec_len_count_1),sec_update_data,trig_en,stay_trig})
								
								4'b1x11:
									begin
										state_sec<=error_update_sec;
										pipeline_reg_4<=error_load_1;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								4'b0111:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								4'b0011:
									begin
										state_sec<=c1_addr_read_slave_addr_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								4'bxxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=8'bx;
										sec_len_count_0<=12'bx;
										sec_len_count_1<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
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
					c1_addr_update_slave_addr_sec:
						begin	
								
							sec_write_back_ram_w_en<=1'b0;
							sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;
						   sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_b_ram_pointer<=sec_b_ram_pointer;
							
							casex({(sec_len_1==sec_len_count_1),sec_len_count_1[0] && (pipeline_reg_4==slave_addr),trig_en,stay_trig})
							
								4'b1x11:
									begin
										state_sec<=error_update_sec;
										pipeline_reg_4<=error_load_1;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								4'b0111:
									begin
										state_sec<=c1_addr_update_new_slave_addr_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								4'b0011:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_3;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
									end
								4'bxxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b0;
										data_crc_gen<=8'bx;
										sec_len_count_0<=12'bx;
										sec_len_count_1<=12'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
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
						
					c1_addr_update_new_slave_addr_sec:
						begin
							sec_write_back_ram_data_in_buff<=pipeline_reg_4;
							sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
							sec_write_back_ram_w_en<=1'b1;
							state_sec<=c1_addr_update_slave_addr_sec;
							sec_compare_value<=4'bx;
							sec_compare_count<=4'bx;
							pipeline_reg_4<=pipeline_reg_4;
							mode_crc_gen_sec<=2'b00;
							data_crc_gen<=data_crc_gen;
							sec_len_count_0<=sec_len_count_0;
							sec_len_count_1<=sec_len_count_1;
							sec_tx_data<=sec_tx_data;
							sec_tx_state<=sec_tx_state;
						end
						
					c1_64_time_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							
							sec_compare_value<=sec_compare_value;
							casex({(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									3'b111:
										begin
											state_sec<=c1_jitter_update_sec;
											pipeline_reg_4<=main_jitter_correction[7:0];
											sec_compare_count<=4'b0;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									3'b011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=sec_compare_count+4'b1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									3'bxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b0;
											data_crc_gen<=8'bx;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
										end
								endcase
						
						end
					c1_jitter_update_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							
							sec_compare_value<=sec_compare_value;
							casex({trig_en,stay_trig})
								
									2'b11:
										begin
											state_sec<=c1_delay_time_check_sec;
											pipeline_reg_4<={pipeline_reg_4[7:4],main_jitter_correction[11:8]};
											sec_compare_count<=4'b0;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									2'bx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b0;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=4'bx;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b0;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
										end
								endcase
						
						end
					c1_delay_time_check_sec:
						begin
							state_sec<=c1_def_time_check_sec;
							sec_compare_count<=4'b0;
							sec_compare_value<=4'bx;
							mode_crc_gen_sec<=2'b0;
							data_crc_gen<=data_crc_gen;
							sec_tx_data<=sec_tx_data;
							sec_tx_state<=sec_tx_state;
							sec_len_count_0<=sec_len_count_0;
							sec_len_count_1<=sec_len_count_1;
						end
					
					c1_def_time_check_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							sec_compare_value<=4'b0100;
							sec_compare_count<=4'b0;
							mode_crc_gen_sec<=2'b0;
							data_crc_gen<=data_crc_gen;
							sec_tx_data<=sec_tx_data;
							sec_tx_state<=sec_tx_state;
							sec_len_count_0<=sec_len_count_0;
							sec_len_count_1<=sec_len_count_1;
							if((~main_i_o_read_buff_last_pointer && greater_buff_0) || (main_i_o_read_buff_last_pointer && greater_buff_1))
								begin
									state_sec<=c1_def_self_time_update_sec;
									pipeline_reg_4<=slave_addr;
								end
							else	
								begin
									state_sec<=c1_def_time_normal_update_sec;
									pipeline_reg_4<=pipeline_reg_3;
								end
							
						end	
					c1_def_time_normal_update_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							
							sec_compare_value<=sec_compare_value;
							casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
								4'b1111:
									begin
										state_sec<=error_update_sec;
										pipeline_reg_4<=error_load_1;
										sec_compare_count<=4'b0;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_data_read_state_0<=1'b0;
										sec_data_read_state_1<=1'b0;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=12'bx;
									end
								4'b0111:
									begin
										state_sec<=c1_delay_time_check_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_compare_count<=4'b0;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_data_read_state_0<=(~sec_data_read_state_0 && (sec_data_read_state_0!=main_data_read_state_0))||(sec_data_read_state_0 && (sec_data_read_state_0==main_data_read_state_0));
										sec_data_read_state_1<=(~sec_data_read_state_1 && (sec_data_read_state_1!=main_data_read_state_1))||(sec_data_read_state_1 && (sec_data_read_state_1==main_data_read_state_1));
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
									end
								4'b0011:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_3;
										sec_compare_count<=sec_compare_count+4'b1;
										mode_crc_gen_sec<=2'b01;
										data_crc_gen<=pipeline_reg_4;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_data_read_state_0<=sec_data_read_state_0;
										sec_data_read_state_1<=sec_data_read_state_1;
										sec_len_count_0<=sec_len_count_0+12'b1;
										sec_len_count_1<=sec_len_count_1+12'b1;
									end
								4'bxxx0://error
									begin
										state_sec<=wait_SFD_sec;
										pipeline_reg_4<=8'bx;
										mode_crc_gen_sec<=2'b0;
										data_crc_gen<=8'bx;
										sec_compare_count<=4'bx;
										sec_tx_data<=pipeline_reg_4;
										sec_tx_state<=~sec_tx_state;
										sec_data_read_state_0<=1'b0;
										sec_data_read_state_1<=1'b0;
										sec_len_count_0<=12'bx;
										sec_len_count_1<=12'bx;
									end
								default:
									begin
										state_sec<=state_sec;
										pipeline_reg_4<=pipeline_reg_4;
										mode_crc_gen_sec<=2'b00;
										data_crc_gen<=data_crc_gen;
										sec_compare_count<=sec_compare_count;
										sec_tx_data<=sec_tx_data;
										sec_tx_state<=sec_tx_state;
										sec_data_read_state_0<=sec_data_read_state_0;
										sec_data_read_state_1<=sec_data_read_state_1;
										sec_len_count_0<=sec_len_count_0;
										sec_len_count_1<=sec_len_count_1;
									end
							
							endcase
						end
					c1_def_self_time_update_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							
							//sec_compare_value<=sec_compare_value;
							casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),(main_i_o_read_buff_last_pointer),trig_en,stay_trig})//critical point
								
									5'b1xx11:// don't care is important
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'bx;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_data_read_state_0<=1'b0;
											sec_data_read_state_1<=1'b0;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b01111:
										begin
											state_sec<=c1_def_time_buff_0_update_sec;
											pipeline_reg_4<=main_i_o_read_buff_0[0];//slave addr
											sec_compare_count<=4'b1;
											sec_compare_value<=4'b0101;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_data_read_state_0<=~sec_data_read_state_0;
											sec_data_read_state_1<=sec_data_read_state_1;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b01011:
										begin
											state_sec<=c1_def_time_buff_1_update_sec;
											pipeline_reg_4<=main_i_o_read_buff_1[0];//slave addr
											sec_compare_count<=4'b1;
											sec_compare_value<=4'b0101;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_data_read_state_0<=sec_data_read_state_0;
											sec_data_read_state_1<=~sec_data_read_state_1;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b00011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=main_clock_def[sec_compare_count[1:0]];
											sec_compare_count<=sec_compare_count+4'b1;
											sec_compare_value<=sec_compare_value;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_data_read_state_0<=sec_data_read_state_0;
											sec_data_read_state_1<=sec_data_read_state_1;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'bxxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_data_read_state_0<=1'b0;
											sec_data_read_state_1<=1'b0;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_compare_value<=4'bx;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_data_read_state_0<=sec_data_read_state_0;
											sec_data_read_state_1<=sec_data_read_state_1;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
										end
								endcase
						end
					c1_def_time_buff_0_update_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							
							sec_compare_value<=sec_compare_value;
							casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'bx;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_data_read_state_0<=1'bx;
											sec_data_read_state_1<=1'bx;
										end
									4'b0111:
										begin
											state_sec<=c1_def_time_buff_1_update_sec;
											pipeline_reg_4<=main_i_o_read_buff_1[0];
											sec_compare_count<=4'b1;
											sec_compare_value<=4'b0101;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_data_read_state_0<=sec_data_read_state_0;
											sec_data_read_state_1<=~sec_data_read_state_1;
										end
									4'b0011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=main_i_o_read_buff_0[sec_compare_count[2:0]];
											sec_compare_count<=sec_compare_count+4'b1;
											sec_compare_value<=sec_compare_value;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_data_read_state_0<=sec_data_read_state_0;
											sec_data_read_state_1<=sec_data_read_state_1;
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_data_read_state_0<=1'b0;
											sec_data_read_state_1<=1'b0;
											sec_compare_value<=4'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_data_read_state_0<=sec_data_read_state_0;
											sec_data_read_state_1<=sec_data_read_state_1;
											sec_compare_value<=sec_compare_value;
										end
								
							endcase
						
						end
					c1_def_time_buff_1_update_sec:
						begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							
							sec_compare_value<=sec_compare_value;
							casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											sec_compare_count<=4'b0;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_data_read_state_0<=1'bx;
											sec_data_read_state_1<=1'bx;
										end
									4'b0111:
										begin
											state_sec<=c1_def_time_buff_0_update_sec;
											pipeline_reg_4<=main_i_o_read_buff_0[0];
											sec_compare_count<=4'b1;
											sec_compare_value<=4'b0101;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_data_read_state_0<=~sec_data_read_state_0;
											sec_data_read_state_1<=sec_data_read_state_1;
										end
									4'b0011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=main_i_o_read_buff_1[sec_compare_count[2:0]];
											sec_compare_count<=sec_compare_count+4'b1;
											sec_compare_value<=sec_compare_value;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_data_read_state_0<=sec_data_read_state_0;
											sec_data_read_state_1<=sec_data_read_state_1;
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_data_read_state_0<=1'b0;
											sec_data_read_state_1<=1'b0;
											sec_compare_value<=4'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_data_read_state_0<=sec_data_read_state_0;
											sec_data_read_state_1<=sec_data_read_state_1;
											sec_compare_value<=sec_compare_value;
										end
								endcase
						end
				c1_tx_set_sec:
						begin						
							sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;
							sec_compare_value<=4'bx;
							sec_compare_count<=4'bx;
							sec_data_read_state_0<=1'bx;
							sec_data_read_state_1<=1'bx;
							
							casex({(sec_len_1==sec_len_count_1),(slave_addr==pipeline_reg_4),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={4'b0+last_cmd_sec};//command
											sec_write_back_ram_w_en<=1'b1;
										end
									4'b1011:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;
											sec_write_back_ram_w_en<=1'b0;
										end
									4'b0111:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={4'b0+last_cmd_sec};//command
											sec_write_back_ram_w_en<=1'b1;
										end
									4'b0011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;
											sec_write_back_ram_w_en<=1'b0;
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_write_back_ram_w_en<=1'b0;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;
											sec_write_back_ram_w_en<=1'b0;
										end
							endcase
						end	
				c1_prop_measure_watch_time_sec:
					begin
							sec_update_data<=1'b0;
							sec_compare_value<=sec_compare_value;
							casex({(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									3'b111:
										begin
											state_sec<=c1_prop_measure_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'bx;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
										end
									3'b011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=sec_compare_count+4'b1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
										end
									3'bxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_write_back_ram_w_en<=1'b0;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;//command
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;
											sec_write_back_ram_w_en<=1'b0;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
										end
								endcase
					end
				c1_prop_measure_sec:
				
					begin
						sec_write_back_ram_data_in_buff<=8'bx;
						sec_b_ram_addr_write<=sec_b_ram_addr_write;
						sec_write_back_ram_w_en<=1'b0;
						casex({(sec_len_1==sec_len_count_1),trig_en,stay_trig})
									3'b111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
										end
									3'b011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
										end
									3'bxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;	
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
				c1_prop_save_addr_check_sec_1:
					begin
						sec_data_read_state_0<=sec_data_read_state_0;
						sec_data_read_state_1<=sec_data_read_state_1;
						casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),(slave_addr==pipeline_reg_4),trig_en,stay_trig})
								
									5'b1xx11:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
										end
									5'b01111:
										begin
											state_sec<=c1_prop_save_addr_check_sec_2;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0001;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b01011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0010;//slv addr+delay1+delay2 - 1
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b00x11:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=sec_compare_count+4'b1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_compare_value<=sec_compare_value;
										end
									5'bxxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_compare_value<=4'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_compare_value<=sec_compare_value;
										end
								endcase
					end
				c1_prop_save_addr_check_sec_2:
					begin
								casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
									4'b1111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_value<=4'bx;
										end
									4'b0111:
										begin
											state_sec<=c1_prop_save_addr_check_sec_1;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
										end
									4'b0011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=sec_compare_count+4'b1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_value<=sec_compare_value;
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_compare_value<=4'bx;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_compare_value<=sec_compare_value;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;//command
											sec_write_back_ram_w_en<=1'b0;
										end
								endcase
					end
				c1_prop_read_time_sec_1:
					begin
						sec_data_read_state_0<=sec_data_read_state_0;
						sec_data_read_state_1<=sec_data_read_state_1;
						casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),(slave_addr==pipeline_reg_4),trig_en,stay_trig})
								
									5'b1xx11:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
										end
									5'b01111:
										begin
											state_sec<=c1_prop_read_time_sec_2;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b1001;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b01011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b1010;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b00x11:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=sec_compare_count+4'b1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_compare_value<=sec_compare_value;
										end
									5'bxxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_compare_value<=4'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_compare_value<=sec_compare_value;
										end
								endcase
					end
				c1_prop_read_time_sec_2:
					begin
						state_sec<=c1_prop_read_time_sec_3;
						sec_compare_count<=sec_compare_count;
						sec_compare_value<=sec_compare_value;
						case(pipeline_reg_4[3:0])
							4'b1000:
								begin
									sec_prop_delay_ram_addr<=6'b0;
								end
							4'b0100:
								begin
									sec_prop_delay_ram_addr<=6'd9;
								end
							4'b0010:
								begin
									sec_prop_delay_ram_addr<=6'd18;
								end
							4'b0001:
								begin
									sec_prop_delay_ram_addr<=6'd27;
								end
							default:
								begin
									sec_prop_delay_ram_addr<=6'b0;
								end
						endcase
					end
				c1_prop_read_time_sec_3://prop_delay_ram_out
					begin
						sec_data_read_state_0<=sec_data_read_state_0;
						sec_data_read_state_1<=sec_data_read_state_1;
						casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
							
							4'b1111:
								begin
									state_sec<=error_update_sec;
									pipeline_reg_4<=error_load_1;
									sec_compare_count<=4'b0;
									sec_compare_value<=4'bx;
									mode_crc_gen_sec<=2'b01;
									data_crc_gen<=pipeline_reg_4;
									sec_tx_data<=pipeline_reg_4;
									sec_tx_state<=~sec_tx_state;
									sec_len_count_0<=sec_len_count_0+12'b1;
									sec_len_count_1<=12'bx;
								end
							4'b0111:
								begin
									state_sec<=c1_prop_read_time_sec_1;
									pipeline_reg_4<=pipeline_reg_3;
									sec_compare_count<=4'b0;
									sec_compare_value<=4'b0;
									mode_crc_gen_sec<=2'b01;
									data_crc_gen<=pipeline_reg_4;
									sec_tx_data<=pipeline_reg_4;
									sec_tx_state<=~sec_tx_state;
									sec_len_count_0<=sec_len_count_0+12'b1;
									sec_len_count_1<=sec_len_count_1+12'b1;
								end
							4'b0011:
								begin
									state_sec<=c1_prop_read_time_sec_4;
									pipeline_reg_4<=prop_delay_ram_out;
									sec_compare_count<=sec_compare_count+4'b1;
									mode_crc_gen_sec<=2'b01;
									data_crc_gen<=pipeline_reg_4;
									sec_tx_data<=pipeline_reg_4;
									sec_tx_state<=~sec_tx_state;
									sec_len_count_0<=sec_len_count_0+12'b1;
									sec_len_count_1<=sec_len_count_1+12'b1;
									sec_compare_value<=sec_compare_value;
								end
							4'bxxx0://error
								begin
									state_sec<=wait_SFD_sec;
									pipeline_reg_4<=8'bx;
									mode_crc_gen_sec<=2'b00;
									data_crc_gen<=8'bx;
									sec_compare_count<=4'bx;
									sec_tx_data<=pipeline_reg_4;
									sec_tx_state<=~sec_tx_state;
									sec_len_count_0<=12'bx;
									sec_len_count_1<=12'bx;
									sec_compare_value<=4'bx;
								end
							default:
								begin
									state_sec<=state_sec;
									pipeline_reg_4<=pipeline_reg_4;
									mode_crc_gen_sec<=2'b00;
									data_crc_gen<=data_crc_gen;
									sec_compare_count<=sec_compare_count;
									sec_tx_data<=sec_tx_data;
									sec_tx_state<=sec_tx_state;
									sec_len_count_0<=sec_len_count_0;
									sec_len_count_1<=sec_len_count_1;
									sec_compare_value<=sec_compare_value;
								end
						endcase
					end
				c1_prop_read_time_sec_4:
					begin
						state_sec<=c1_prop_read_time_sec_3;
						sec_prop_delay_ram_addr<=sec_prop_delay_ram_addr+6'b1;
						sec_compare_value<=sec_compare_value;
						sec_compare_count<=sec_compare_count;
					end
				
				c1_diagnose_update_sec_1:
					begin
					
								sec_data_read_state_0<=sec_data_read_state_0;
								sec_data_read_state_1<=sec_data_read_state_1;
								casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									4'b1111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											sec_compare_count<=4'bx;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_compare_value<=4'bx;
										end
									4'b0111:
										begin
											state_sec<=c1_diagnose_check_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									4'b0011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=error_reg[15:8];
											sec_compare_count<=sec_compare_count+4'b1;
											sec_compare_value<=sec_compare_value;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									4'bxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_compare_value<=4'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_compare_value<=sec_compare_value;
										end
								endcase
					end
				c1_diagnose_check_addr_sec:
					begin
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_data_read_state_0<=sec_data_read_state_0;
							sec_data_read_state_1<=sec_data_read_state_1;
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),(slave_addr==pipeline_reg_4),trig_en,stay_trig})
								
									5'b1xx11:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
										end
									5'b01111:
										begin
											state_sec<=c1_diagnose_update_sec_1;
											pipeline_reg_4<=error_reg[7:0];
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0001;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b01011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0010;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									5'b00x11:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											sec_compare_count<=sec_compare_count+4'b1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_compare_value<=sec_compare_value;
										end
									5'bxxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_compare_count<=4'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_compare_value<=4'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_compare_value<=sec_compare_value;
										end
								endcase
					end
				c1_general_cmd_slave_addr_sec:
					begin		
								sec_compare_count<=4'bx;
								sec_compare_value<=4'bx;
								sec_b_ram_addr_write<=sec_b_ram_addr_write;
								sec_write_back_ram_data_in_buff<=8'bx;//command
								sec_write_back_ram_w_en<=1'b0;
								casex({(slave_addr==pipeline_reg_4),trig_en,stay_trig})
								
									3'b111:
										begin
											state_sec<=c1_general_slave_match_len_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									3'b011:
										begin
											state_sec<=c1_general_slave_unmatch_len_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
										end
									3'bxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
										end
								endcase
					end
				c1_general_slave_unmatch_len_sec:
					begin
							sec_len_2[7]<=pipeline_reg_4[0];
							sec_len_2[6]<=pipeline_reg_4[1];
							sec_len_2[5]<=pipeline_reg_4[2];
							sec_len_2[4]<=pipeline_reg_4[3];
							sec_len_2[3]<=pipeline_reg_4[4];
							sec_len_2[2]<=pipeline_reg_4[5];
							sec_len_2[1]<=pipeline_reg_4[6];
							sec_len_2[0]<=pipeline_reg_4[7];
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;
							sec_write_back_ram_w_en<=1'b0;
							sec_compare_value<=4'bx;
							sec_compare_count<=4'bx;
							sec_update_data<=1'b0;
							casex({trig_en,stay_trig})
									2'b11:
										begin
											state_sec<=c1_general_slave_unmatch_data_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
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
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=8'bx;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=8'b0;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
										end
								endcase
					end
				c1_general_slave_unmatch_data_sec:
					begin
						sec_compare_value<=4'bx;	
						sec_compare_count<=4'bx;
						sec_data_read_state_0<=sec_data_read_state_0;
						sec_data_read_state_1<=sec_data_read_state_1;
					   sec_write_back_ram_w_en<=1'b0;
						casex({(sec_len_2==sec_len_count_2),(sec_len_1==sec_len_count_1),trig_en,stay_trig})
						
							4'b1111:
								begin
									state_sec<=error_update_sec;
									pipeline_reg_4<=error_load_1;
									mode_crc_gen_sec<=2'b01;
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
									mode_crc_gen_sec<=2'b01;
									data_crc_gen<=pipeline_reg_4;
									sec_tx_data<=pipeline_reg_4;
									sec_tx_state<=~sec_tx_state;
									sec_len_count_0<=sec_len_count_0+12'b1;
									sec_len_count_1<=sec_len_count_1+12'b1;
									sec_len_count_2<=8'bx;
								end
							4'b0011:
								begin
									state_sec<=state_sec;
									pipeline_reg_4<=pipeline_reg_3;
									mode_crc_gen_sec<=2'b01;
									data_crc_gen<=pipeline_reg_4;
									sec_tx_data<=pipeline_reg_4;
									sec_tx_state<=~sec_tx_state;
									sec_len_count_0<=sec_len_count_0+12'b1;
									sec_len_count_1<=sec_len_count_1+12'b1;
									sec_len_count_2<=sec_len_count_2+8'b1;
								end
							4'bxxx0://error
								begin
									state_sec<=wait_SFD_sec;
									pipeline_reg_4<=8'bx;
									mode_crc_gen_sec<=2'b00;
									data_crc_gen<=8'bx;
									sec_tx_data<=pipeline_reg_4;
									sec_tx_state<=~sec_tx_state;
									sec_len_count_0<=12'bx;
									sec_len_count_1<=12'bx;
									sec_len_count_2<=8'bx;
								end
							default:
								begin
									state_sec<=state_sec;
									pipeline_reg_4<=pipeline_reg_4;
									mode_crc_gen_sec<=2'b00;
									data_crc_gen<=data_crc_gen;
									sec_tx_data<=sec_tx_data;
									sec_tx_state<=sec_tx_state;
									sec_len_count_0<=sec_len_count_0;
									sec_len_count_1<=sec_len_count_1;
									sec_len_count_2<=sec_len_count_2;
								end
						endcase
					end
				c1_general_slave_match_len_sec:
					begin
						sec_len_2[7]<=pipeline_reg_4[0];
						sec_len_2[6]<=pipeline_reg_4[1];
						sec_len_2[5]<=pipeline_reg_4[2];
						sec_len_2[4]<=pipeline_reg_4[3];
						sec_len_2[3]<=pipeline_reg_4[4];
						sec_len_2[2]<=pipeline_reg_4[5];
						sec_len_2[1]<=pipeline_reg_4[6];
						sec_len_2[0]<=pipeline_reg_4[7];
						sec_b_ram_addr_write<=sec_b_ram_addr_write;
						sec_write_back_ram_data_in_buff<=8'bx;
						sec_write_back_ram_w_en<=1'b0;
						sec_compare_value<=4'bx;
						sec_compare_count<=4'bx;
						sec_update_data<=1'b0;
						casex({trig_en,stay_trig})
							
							2'b11:
								begin
									state_sec<=c1_general_slave_match_cmd_sec;
									pipeline_reg_4<=pipeline_reg_3;
									mode_crc_gen_sec<=2'b01;
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
									pipeline_reg_4<=8'bx;
									mode_crc_gen_sec<=2'b00;
									data_crc_gen<=8'bx;
									sec_len_count_0<=12'bx;
									sec_len_count_1<=12'bx;
									sec_len_count_2<=8'bx;
									sec_tx_data<=pipeline_reg_4;
									sec_tx_state<=~sec_tx_state;
								end
							default:
								begin
									state_sec<=state_sec;
									pipeline_reg_4<=pipeline_reg_4;
									mode_crc_gen_sec<=2'b00;
									data_crc_gen<=data_crc_gen;
									sec_len_count_0<=sec_len_count_0;
									sec_len_count_1<=sec_len_count_1;
									sec_len_count_2<=8'b0;
									sec_tx_data<=sec_tx_data;
									sec_tx_state<=sec_tx_state;
								end
						endcase
					end
				c1_general_slave_match_cmd_sec:
					begin
						sec_len_count_0<=sec_len_count_0;
						sec_len_count_1<=sec_len_count_1;
						sec_len_count_2<=sec_len_count_2;
						sec_tx_data<=sec_tx_data;
						sec_tx_state<=sec_tx_state;
						mode_crc_gen_sec<=2'b00;
						data_crc_gen<=data_crc_gen;
						
								casex({pipeline_reg_4[3:0]})
									
									4'b100x://register write(local & user)
										begin
											state_sec<=c2_reg_write_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+1'b1+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={pipeline_reg_4[3:0]+4'b0};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0110;//8_sync+2_jitter (len)
											sec_compare_value_2<=4'bx;
										end
									4'b0100://register read local 
										begin
											state_sec<=c2_reg_read_local_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+1'b1+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0110;//8_sync+2_jitter (len)
											sec_compare_value_2<=4'bx;
										end
									4'b0101://register read user 
										begin
											state_sec<=c2_general_read_buff_0_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+main_i_o_read_buff_40_valid+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0001;//sec_compare_count<=4'b0; *(len-1)
											sec_compare_value_2<=4'b0100;//sec_compare_count<=4'b1; *(len)
										end
								
									4'b0010://digital read user 
										begin
											state_sec<=c2_general_read_buff_0_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+main_i_o_read_buff_40_valid+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0000;//sec_compare_count<=4'b0; *(len -1)
											sec_compare_value_2<=4'b0001;//sec_compare_count<=4'b1; *(len)
										end
									4'b1010://digital write
										begin
											state_sec<=c2_reg_write_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+1'b1+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={pipeline_reg_4[3:0]+4'b0};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0010;//
											sec_compare_value_2<=4'bx;
										end
									4'b0110://analog read user 
										begin
											state_sec<=c2_general_read_buff_0_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+main_i_o_read_buff_40_valid+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0000;//sec_compare_count<=4'b0;
											sec_compare_value_2<=4'b0010;//sec_compare_count<=4'b1;
											
										end
									4'b1110://PWM write user 
										begin
											state_sec<=c2_reg_write_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+1'b1+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={pipeline_reg_4[3:0]+4'b0};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0011;//8_sync+2_jitter *(len)
											sec_compare_value_2<=4'bx;
										end
									4'b0011://pulse count write user 
										begin
											state_sec<=c2_reg_write_sec;
											pipeline_reg_4<={pipeline_reg_3[7:6]+1'b1+pipeline_reg_3[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<={pipeline_reg_4[3:0]+4'b0};//command
											sec_write_back_ram_w_en<=1'b1;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0100;//8_sync+2_jitter *(len)
											sec_compare_value_2<=4'bx;
										end
									4'b1100://input triggered stamp read user 
										begin
											state_sec<=c2_general_read_buff_0_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+main_i_o_read_buff_40_valid+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0000;//sec_compare_count<=4'b0; *(len-1)
											sec_compare_value_2<=4'b0100;//sec_compare_count<=4'b1; *(len)
											
										end
									4'b1101://servo position read
										begin
											state_sec<=c2_general_read_buff_0_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+main_i_o_read_buff_40_valid+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0000;//sec_compare_count<=4'b0;
											sec_compare_value_2<=4'b0100;//sec_compare_count<=4'b1;
											
										end
									4'b0001://i2c read write 
										begin
											state_sec<=c2_general_read_buff_0_sec;
											pipeline_reg_4<={pipeline_reg_4[7:6]+main_i_o_read_buff_40_valid+pipeline_reg_4[4:0]};
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
											sec_compare_count<=4'b0;
											sec_compare_value<=4'b0010;//sec_compare_count<=4'b0; *(len-1)
											sec_compare_value_2<=4'b0010;//sec_compare_count<=4'b1; *(len)
											
										end
									default://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=pipeline_reg_4;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
											sec_compare_value_2<=4'bx;
											sec_write_back_ram_w_en<=1'b0;
										end
								endcase
					end
				c2_reg_write_sec:
					begin
							casex({(sec_len_2==sec_len_count_2),(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									5'b11111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
										end
									5'b10111:
										begin
											state_sec<=c1_general_cmd_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
										end
									5'b00111:
										begin
											state_sec<=c1_general_slave_match_cmd_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'bx;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
										end
									5'b00011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=sec_compare_count+4'b1;
											sec_b_ram_addr_write<=sec_b_ram_addr_write+10'b1;
											sec_write_back_ram_data_in_buff<=pipeline_reg_4;//command
											sec_write_back_ram_w_en<=1'b1;
										end
									5'bxxxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b0;
											data_crc_gen<=8'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
											sec_b_ram_addr_write<=10'bx;
											sec_write_back_ram_data_in_buff<=8'bx;//command
											sec_write_back_ram_w_en<=1'b0;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											sec_b_ram_addr_write<=sec_b_ram_addr_write;
											sec_write_back_ram_data_in_buff<=sec_write_back_ram_data_in_buff;//command
											sec_write_back_ram_w_en<=1'b0;
										end
								endcase
					end
				c2_reg_read_local_sec:
					begin
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;//command
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_len_2==sec_len_count_2),(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									5'b11111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
										end
									5'b10111:
										begin
											state_sec<=c1_general_cmd_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
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
											mode_crc_gen_sec<=2'b01;
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
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
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
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b0;
											data_crc_gen<=8'bx;
											sec_tx_data<=8'bx;
											sec_tx_state<=~sec_tx_state;
											sec_compare_count<=4'bx;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
										end
								endcase
					end
				
				c2_general_read_buff_0_sec:
					begin	
							sec_compare_value_2<=sec_compare_value_2;
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;//command
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_compare_count==sec_compare_value),trig_en,stay_trig})
									3'b111:
										begin
											state_sec<=c2_general_read_buff_1_sec;
											pipeline_reg_4<=pipeline_reg_3;//main_i_o_read_buff_1[0];
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=4'b0;
											sec_compare_value<=sec_compare_value_2;
										end
									3'b011:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=sec_len_count_1+12'b1;
											sec_len_count_2<=sec_len_count_2+8'b1;
											sec_compare_count<=sec_compare_count+4'b1;
											sec_compare_value<=sec_compare_value;
										end
									3'bxx0://error
										begin
											state_sec<=wait_SFD_sec;
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b0;
											data_crc_gen<=8'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
											sec_compare_value<=4'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											sec_compare_value<=sec_compare_value;
										end
								endcase
					end
				c2_general_read_buff_1_sec:
					begin	
							sec_compare_value_2<=4'bx;
							sec_compare_value<=sec_compare_value;
							sec_b_ram_addr_write<=sec_b_ram_addr_write;
							sec_write_back_ram_data_in_buff<=8'bx;//command
							sec_write_back_ram_w_en<=1'b0;
							casex({(sec_len_2==sec_len_count_2),(sec_len_1==sec_len_count_1),(sec_compare_count==sec_compare_value),trig_en,stay_trig})
								
									5'b11111:
										begin
											state_sec<=error_update_sec;
											pipeline_reg_4<=error_load_1;
											mode_crc_gen_sec<=2'b01;
											data_crc_gen<=pipeline_reg_4;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=sec_len_count_0+12'b1;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
										end
									5'b10111:
										begin
											state_sec<=c1_general_cmd_slave_addr_sec;
											pipeline_reg_4<=pipeline_reg_3;
											mode_crc_gen_sec<=2'b01;
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
											mode_crc_gen_sec<=2'b01;
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
											mode_crc_gen_sec<=2'b01;
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
											pipeline_reg_4<=8'bx;
											mode_crc_gen_sec<=2'b0;
											data_crc_gen<=8'bx;
											sec_tx_data<=pipeline_reg_4;
											sec_tx_state<=~sec_tx_state;
											sec_len_count_0<=12'bx;
											sec_len_count_1<=12'bx;
											sec_len_count_2<=8'bx;
											sec_compare_count<=4'bx;
										end
									default:
										begin
											state_sec<=state_sec;
											pipeline_reg_4<=pipeline_reg_4;
											mode_crc_gen_sec<=2'b00;
											data_crc_gen<=data_crc_gen;
											sec_compare_count<=sec_compare_count;
											sec_tx_data<=sec_tx_data;
											sec_tx_state<=sec_tx_state;
											sec_len_count_0<=sec_len_count_0;
											sec_len_count_1<=sec_len_count_1;
											sec_len_count_2<=sec_len_count_2;
											
										end
								endcase
					end
				default:
					begin
						state_sec<=boot_sec;
						pipeline_reg_4<=8'bx;
						mode_crc_gen_sec<=2'bx;
						data_crc_gen<=8'bx;
						sec_b_ram_pointer<=2'b0;
						sec_b_ram_addr_write<=10'b0;
						sec_compare_count<=4'bx;
						sec_compare_value<=4'bx;
						sec_tx_state<=1'bx;
						sec_receive_tx<=1'bx;
						sec_len_count_0<=12'bx;
						sec_len_count_1<=12'bx;
						sec_len_count_2<=8'bx;
					end
			endcase		
		end
	end
	parameter back_ideal=6'b0,back_boot_init=6'd1,back_boot_start=6'd2,back_boot_start_2=6'd3,back_boot_start_3=6'd4,back_boot_start_4=6'd5,back_boot_start_5=6'd6,back_boot_start_6=6'd7,back_write_back_data=6'd8;
	parameter back_b_ram_read_init_1=6'd9,back_b_ram_read_init_2=6'd10,back_cmd_decode=6'd11,back_update_addr=6'd12,back_prop_delay_1=6'd13,back_prop_delay_2=6'd14,back_reg_write_local_1=6'd15;
	parameter back_reg_write_local_2=6'd16,back_reg_write_local_sync0_reg_write_1=6'd17,back_reg_write_local_sync1_reg_write_1=6'd18,back_reg_write_local_normal_write_1b=6'd19;
	parameter back_reg_write_local_control_write_1=6'd20,back_reg_write_avm_write_1=6'd21,back_reg_write_avm_write_2=6'd22,back_reg_write_avm_write_3=6'd23,back_reg_write_avm_read=5'd24;
	parameter back_reg_write_avm_read_2=6'd25,back_reg_write_avm_read_3=6'd26,back_i_o_write_reg_addr=6'd27,back_i_o_write_data=6'd28,back_i_o_write_data_wait=6'd29,bacK_recovery_mode=6'd30,bacK_recovery_mode_2=6'd31;
	parameter back_reg_write_local_normal_write_1=6'd32,back_c2_cmd_run=6'd33;
	reg [5:0] state_back;
	reg back_sync_data_available;
	reg [1:0] back_tx_mode;
	reg back_reset_issue;
	reg [2:0] back_compare_count;
	reg [2:0] back_compare_count_2;
	reg [2:0] back_compare_value;
	wire [9:0] start_addr_b_ram_read;
	reg [7:0] back_center_reg_2;
	
	assign start_addr_b_ram_read=start_addr_b_ram[back_b_ram_pointer+3'b1];
	
	always @(posedge clk_in or negedge reset_n)
		begin
			if(~reset_n)
				begin
					state_back<=6'b0;
					back_b_ram_pointer<=3'b0;
					back_b_ram_addr_read<=10'b0;
					back_e_ram_addr<=9'b0;
					//back_avm_data_write<=32'b0;
					back_avm_r_w_addr<=9'b0;
					back_avm_new<=1'b0;
					back_avm_mode<=2'b0;
					back_slave_addr_en<=1'b0;
					back_sync_0_en<=1'b0;
					back_sync_1_en<=1'b0;
					back_prop_delay_available<=1'b0;
					back_reset_issue<=1'b0;
					back_center_reg=8'b0;
					back_center_reg_2=8'b0;
					back_boot_done=1'b0;
				end
			else
				begin
					case(state_back)	
						back_ideal:
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_center_reg=8'bx;
								back_center_reg_2=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_compare_count_2<=3'b1;
								back_boot_done<=1'b0;
								back_e_ram_addr<=9'd16;
								if(main_boot_done && wait_reg)
									begin
										state_back<=back_boot_init;
									end
								else	
									begin
										state_back<=state_back;
									end
							end
						back_boot_init://to load the data from e ram
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_center_reg<=8'bx;
								back_center_reg_2<=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								back_boot_done<=1'b0;
								back_e_ram_addr<=back_e_ram_addr;
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_compare_count_2<=back_compare_count_2+3'b1;
								state_back<=back_boot_start;
							end
						back_boot_start:
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								back_boot_done<=1'b0;
								back_e_ram_addr<=back_e_ram_addr;
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_compare_count_2<=back_compare_count_2+3'b1;
								back_center_reg<=e_ram_data_out[back_compare_count_2];//2
								state_back<=back_boot_start_2;
							end
						back_boot_start_2:
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								back_boot_done<=1'b0;
								back_e_ram_addr<=back_e_ram_addr;
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								back_compare_count_2<=3'b0;
								back_center_reg<=e_ram_data_out[back_compare_count_2];//3
								back_avm_r_w_addr[7:0]<=back_center_reg;
								back_avm_r_w_addr[8]<=back_avm_r_w_addr[8];
								state_back<=back_boot_start_3;
							end
						back_boot_start_3:
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_compare_count<=3'b0;
								back_center_reg<=e_ram_data_out[back_compare_count_2];//0
								back_avm_r_w_addr[7:0]<=back_avm_r_w_addr[7:0];
								back_avm_r_w_addr[8]<=back_center_reg[0];
								casex({back_center_reg[0]!=1'b0,back_e_ram_addr[4:0]!=5'b0})
									2'bx0:
										begin
											back_e_ram_addr<=back_e_ram_addr;
											state_back<=back_write_back_data;
											back_compare_count_2<=3'bx;
											back_boot_done<=1'b1;
										end
									2'b11:
										begin
											back_e_ram_addr<=back_e_ram_addr;
											state_back<=back_boot_start_4;
											back_compare_count_2<=back_compare_count_2+3'b1;
											back_boot_done<=1'b0;
										end
									2'b01:
										begin
											back_e_ram_addr<=back_e_ram_addr+9'd1;
											state_back<=back_boot_init;
											back_compare_count_2<=3'b1;//for back_boot_init
											back_boot_done<=1'b0;
										end	
								endcase
							end
						back_boot_start_4:
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								back_boot_done<=1'b0;
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								
								back_avm_data_write[back_compare_count]<=back_center_reg;//0
								back_compare_count<=back_compare_count+3'b1;
								back_compare_count_2<=3'bx;
								back_e_ram_addr<=back_e_ram_addr;
								back_avm_r_w_addr<=back_avm_r_w_addr;
								back_center_reg<=e_ram_data_out[back_compare_count_2];//1
								state_back<=back_boot_start_5;
							end
						back_boot_start_5:
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								back_boot_done<=1'b0;
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								
								back_avm_data_write[back_compare_count]<=back_center_reg;//1
								back_compare_count<=3'bx;
								back_compare_count_2<=3'bx;
								back_e_ram_addr<=back_e_ram_addr;
								back_avm_r_w_addr<=back_avm_r_w_addr;
								back_center_reg<=8'bx;
								back_avm_new<=1'b1;
								back_avm_mode<=2'b01;//write
								state_back<=back_boot_start_6;
							end
						back_boot_start_6:
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_avm_data_write[0]<=back_avm_data_write[0];
								back_avm_data_write[1]<=back_avm_data_write[1];
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_compare_count<=3'bx;
								back_compare_count_2<=3'b1;//for boot_init
								back_avm_r_w_addr<=back_avm_r_w_addr;
								back_center_reg<=8'bx;
								back_avm_mode<=back_avm_mode;
								case({wait_request_avm!=1'b0,back_e_ram_addr[4:0]!=5'b11111})
								2'b00:
									begin
										back_e_ram_addr<=back_e_ram_addr;
										state_back<=back_write_back_data;
										back_boot_done<=1'b1;
										back_avm_new<=1'b0;
									end
								2'b01:
									begin
										back_e_ram_addr<=back_e_ram_addr+9'd1;
										state_back<=back_boot_init;
										back_boot_done=1'b0;
										back_avm_new<=1'b0;
									end
								
								default:
									begin
										back_e_ram_addr<=back_e_ram_addr;
										state_back<=state_back;
										back_boot_done=1'b0;
										back_avm_new<=1'b1;
									end
								endcase
							end
						back_write_back_data:
							begin
								back_sync_data_available<=1'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=back_prop_delay_available;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=back_tx_mode;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'bx;
								back_compare_count_2<=3'bx;
								back_center_reg<=8'bx;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_b_ram_pointer<=back_b_ram_pointer;
								back_b_ram_addr_read<=back_b_ram_addr_read;
								if(wait_reg && (sec_b_ram_pointer!=back_b_ram_pointer))
									begin
										state_back<=back_b_ram_read_init_1;
									end
								else
									begin
										state_back<=state_back;
									end
							end
						back_b_ram_read_init_1:
							begin
								back_sync_data_available<=1'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=back_prop_delay_available;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=back_tx_mode;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'bx;
								back_compare_count_2<=3'bx;
								back_center_reg<=8'bx;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_b_ram_pointer<=back_b_ram_pointer;
								state_back<=back_b_ram_read_init_2;
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
							end
						back_b_ram_read_init_2:
							begin
								back_sync_data_available<=1'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=back_prop_delay_available;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=back_tx_mode;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'bx;
								back_compare_count_2<=3'bx;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_b_ram_pointer<=back_b_ram_pointer;
								back_center_reg<=write_back_ram_out;
								state_back<=back_cmd_decode;
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_compare_count<=3'b0;
							end
						back_cmd_decode:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'bx;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								back_compare_count_2<=3'bx;
							
								back_e_ram_w_en<=1'b0;
								back_center_reg<=write_back_ram_out;
								back_slave_addr_en<=1'b0;
								casex({back_center_reg,request_main,(back_b_ram_addr_read==(start_addr_b_ram_read+10'd2))})//need to veryify the point update logic
									10'b0000010000://update adddress
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											state_back<=back_update_addr;
											back_sync_data_available<=1'b0;
											back_tx_mode<=back_tx_mode;
											back_prop_delay_available<=back_prop_delay_available;
											back_reset_issue<=1'b0;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_compare_count<=3'bx;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
									10'b0000110000://periodic sync msg
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											state_back<=state_back;
											back_sync_data_available<=1'b1;
											back_tx_mode<=back_tx_mode;
											back_prop_delay_available<=back_prop_delay_available;
											back_reset_issue<=1'b0;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_compare_count<=3'bx;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
									10'b0000001000://transmitter mode
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											state_back<=state_back;
											back_sync_data_available<=1'b0;
											back_tx_mode<=2'b10;
											back_prop_delay_available<=back_prop_delay_available;
											back_reset_issue<=1'b0;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_compare_count<=3'bx;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
									10'b0000000100://save prop delay
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											state_back<=back_prop_delay_1;
											back_sync_data_available<=1'b0;
											back_tx_mode<=back_tx_mode;
											back_prop_delay_available<=1'b0;
											back_reset_issue<=1'b0;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_compare_count<=3'bx;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
									10'b0000010100://reset
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											state_back<=state_back;
											back_sync_data_available<=1'b0;
											back_tx_mode<=back_tx_mode;
											back_prop_delay_available<=back_prop_delay_available;
											back_reset_issue<=1'b1;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_compare_count<=3'bx;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
									
									10'bxxxx000011:
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											back_compare_count<=3'b0;
											back_compare_value<=3'bx;
											state_back<=back_c2_cmd_run;
											back_center_reg_2<=back_center_reg;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
											
										end
									
									10'bxxxxxxxxx1://back_b_ram_pointer update
										begin
											
											state_back<=back_write_back_data;
											back_b_ram_addr_read<=back_b_ram_addr_read-10'd2;
											back_b_ram_pointer<=back_b_ram_pointer+3'b001;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
											back_compare_count<=3'b0;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
									10'bxxxxxxxx10://master request
										begin
											
											state_back<=back_write_back_data;
											back_b_ram_addr_read<=back_b_ram_addr_read-10'd2;
											back_b_ram_pointer<=back_b_ram_pointer;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
											back_compare_count<=3'bx;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
									
									default:
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											state_back<=bacK_recovery_mode;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
											back_compare_count<=3'bx;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_b_ram_addr_read<=back_b_ram_addr_read;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
								endcase
							
							end
						back_c2_cmd_run:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'bx;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								back_compare_count_2<=3'bx;
							
								back_e_ram_w_en<=1'b0;
								back_center_reg<=write_back_ram_out;
								back_slave_addr_en<=1'b0;
							
								casex(back_center_reg_2[7:4])
								
									4'b1000://register write local space
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											state_back<=back_reg_write_local_1;
											back_compare_count<=3'b0;
											back_reset_issue<=1'b0;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_prop_delay_available<=back_prop_delay_available;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
									4'b1001://register write user space
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											back_compare_count<=back_compare_count+3'b0;
											back_compare_value<=3'b010;
											state_back<=back_i_o_write_reg_addr;
											back_center_reg_2<=back_center_reg_2;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_i_o_reg[back_compare_count]<=back_center_reg;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
										end
									4'b1010://digital write
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											back_compare_count<=back_compare_count+3'b0;
											back_compare_value<=3'b001;
											state_back<=back_i_o_write_reg_addr;
											back_center_reg_2<=back_center_reg_2;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_i_o_reg[back_compare_count]<=back_center_reg;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
										end
									4'b0001://i2c write 
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											back_compare_count<=back_compare_count+3'b0;
											back_compare_value<=3'b011;
											state_back<=back_i_o_write_reg_addr;
											back_center_reg_2<=back_center_reg_2;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_i_o_reg[back_compare_count]<=back_center_reg;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
										end
									4'b1110://PWM write
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											back_compare_count<=back_compare_count+3'b0;
											back_compare_value<=3'b001;
											state_back<=back_i_o_write_reg_addr;
											back_center_reg_2<=back_center_reg_2;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_i_o_reg[back_compare_count]<=back_center_reg;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
										end
									4'b0011://pulse count write
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											back_compare_count<=back_compare_count+3'b0;
											back_compare_value<=3'b000;
											state_back<=back_i_o_write_reg_addr;
											back_center_reg_2<=back_center_reg_2;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
											back_i_o_reg[back_compare_count]<=back_center_reg;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
										end
									default:
										begin
											back_b_ram_pointer<=back_b_ram_pointer;
											state_back<=bacK_recovery_mode;
											back_reset_issue<=1'b0;
											back_prop_delay_available<=back_prop_delay_available;
											back_tx_mode<=back_tx_mode;
											back_sync_data_available<=1'b0;
											back_compare_count<=3'bx;
											back_compare_value<=3'bx;
											back_center_reg_2<=8'bx;
											back_b_ram_addr_read<=back_b_ram_addr_read;
											back_i_o_reg[0]<=8'bx;
											back_i_o_reg[1]<=8'bx;
											back_i_o_reg[2]<=8'bx;
											back_i_o_reg[3]<=8'bx;
											back_i_o_reg[4]<=8'bx;
											back_i_o_reg[5]<=8'bx;
											back_i_o_reg[6]<=8'bx;
											back_i_o_reg[7]<=8'bx;
										end
								endcase
								
							end
						back_update_addr:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'bx;
								back_compare_count_2<=3'bx;
								back_prop_delay_available<=back_prop_delay_available;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_compare_count<=3'b0;
								back_sync_data_available<=1'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_center_reg<=write_back_ram_out;
								back_slave_addr_en<=1'b1;
								state_back<=back_cmd_decode;
							end
						back_prop_delay_1:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_mode<=2'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'bx;
								back_compare_count_2<=3'bx;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_compare_count<=3'b0;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
							
							
							
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_center_reg<=write_back_ram_out;
								back_prop_delay[0]<=back_center_reg;
								back_prop_delay[1]<=8'bx;
								state_back<=back_prop_delay_2;
								back_prop_delay_available<=1'b0;
								back_avm_new<=1'b0;
							end
						back_prop_delay_2:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_mode<=2'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_reset_issue<=1'b0;
								back_center_reg_2<=8'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'bx;
								back_compare_count_2<=3'bx;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_compare_count<=3'b0;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_avm_new<=1'b0;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_center_reg<=write_back_ram_out;
								back_prop_delay[1]<=back_center_reg;
								back_prop_delay[0]<=back_prop_delay[0];
								state_back<=back_cmd_decode;
								back_prop_delay_available<=1'b1;
							end
						back_reg_write_local_1:	
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_mode<=2'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_reset_issue<=1'b0;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_compare_count_2<=3'bx;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_compare_count<=3'b0;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_avm_new<=1'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_avm_r_w_addr[7:0]<=back_center_reg;
								back_avm_r_w_addr[8]<=1'bx;
								back_e_ram_addr[7:0]<=back_center_reg;
								back_e_ram_addr[8]<=1'bx;
								back_e_ram_write_addr[7:0]<=back_center_reg;
								back_e_ram_write_addr[8]<=1'bx;
								back_center_reg_2<=back_center_reg;
								back_center_reg<=write_back_ram_out;
								state_back<=back_reg_write_local_2;
							end
						back_reg_write_local_2:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_mode<=2'b0;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_compare_count_2<=3'bx;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_avm_new<=1'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								
								
								back_center_reg_2<=back_center_reg_2;
								back_compare_count<=3'b0;
								back_compare_value<=3'b011;
								back_center_reg<=write_back_ram_out;
								back_e_ram_write_addr[7:0]<=back_e_ram_write_addr[7:0];
								back_e_ram_write_addr[8]<=back_center_reg[0];
								back_e_ram_addr[8]<=back_center_reg[0];
								back_e_ram_addr[7:0]<=back_e_ram_addr[7:0];
								back_avm_r_w_addr[8]<=back_center_reg[0];
								back_avm_r_w_addr[7:0]<=back_avm_r_w_addr[7:0];
								casex({({back_center_reg[0],back_center_reg_2[7:2]}!=7'b0),back_center_reg_2[1:0]})
									3'b000:
										begin
											back_sync_0_en<=4'b0;
											back_sync_1_en<=4'b0;
											state_back<=back_reg_write_local_control_write_1;
											back_b_ram_addr_read<=back_b_ram_addr_read;
										end
									3'b010:
										begin
											back_sync_0_en<=4'b0001;
											back_sync_1_en<=4'b0;
											state_back<=back_reg_write_local_sync0_reg_write_1;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
										end
									3'b011:
										begin
											back_sync_1_en<=4'b0001;
											back_sync_0_en<=4'b0;
											state_back<=back_reg_write_local_sync1_reg_write_1;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
										end
									3'b1xx:
										begin
											back_sync_0_en<=4'b0;
											back_sync_1_en<=4'b0;
											state_back<=back_reg_write_local_normal_write_1;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
										end
									default:
										begin
											back_sync_0_en<=4'b0;
											back_sync_1_en<=4'b0;
											state_back<=back_reg_write_local_normal_write_1;
											back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
										end
								endcase
							end
						back_reg_write_local_sync0_reg_write_1:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_mode<=2'b0;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_compare_count_2<=3'bx;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_avm_new<=1'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								
								back_avm_r_w_addr<=9'bx;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=back_e_ram_write_addr;
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_compare_count<=back_compare_count+3'b1;
								back_compare_value<=3'b011;
								back_center_reg<=write_back_ram_out;
								back_e_ram_data_write[back_compare_count[1:0]]<=back_center_reg;
								back_sync_0_en<=back_sync_0_en << 1;
								back_sync_1_en<=4'b0;
								if(back_compare_count!=back_compare_value)
									begin
										state_back<=state_back;
										back_e_ram_w_en<=1'b0;
									end
								else	
									begin
										state_back<=back_cmd_decode;
										back_e_ram_w_en<=1'b1;
									end
							end
						back_reg_write_local_sync1_reg_write_1:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_mode<=2'b0;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_compare_count_2<=3'bx;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_avm_new<=1'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								
								back_avm_r_w_addr<=9'bx;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=back_e_ram_write_addr;
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_compare_count<=back_compare_count+3'b1;
								back_compare_value<=3'b011;
								back_center_reg<=write_back_ram_out;
								back_e_ram_data_write[back_compare_count[1:0]]<=back_center_reg;
								back_sync_1_en<=back_sync_1_en << 1;
								back_sync_0_en<=4'b0;
								if(back_compare_count!=back_compare_value)
									begin
										state_back<=state_back;
										back_e_ram_w_en<=1'b0;
									end
								else	
									begin
										state_back<=back_cmd_decode;
										back_e_ram_w_en<=1'b1;
									end
							end
						back_reg_write_local_normal_write_1:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_mode<=2'b0;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_compare_count_2<=3'bx;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_avm_new<=1'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								
								back_avm_r_w_addr<=9'bx;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=back_e_ram_write_addr;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_compare_count<=back_compare_count+3'b1;
								back_compare_value<=3'b011;
								back_center_reg<=write_back_ram_out;
								back_e_ram_data_write[back_compare_count[1:0]]<=back_center_reg;
								if(back_compare_count!=back_compare_value)
									begin
										state_back<=state_back;
										back_e_ram_w_en<=1'b0;
									end
								else	
									begin
										state_back<=back_cmd_decode;
										back_e_ram_w_en<=1'b1;
									end
							end
						back_reg_write_local_control_write_1:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								back_e_ram_addr<=9'bx;
								back_b_ram_addr_read<=back_b_ram_addr_read;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								back_e_ram_write_addr<=back_e_ram_write_addr;
								back_avm_r_w_addr<=back_avm_r_w_addr;
								back_compare_value<=3'b011;
								back_compare_count<=3'b0;
								back_compare_count_2<=3'b0;
								back_center_reg<=8'bx;
								if(back_center_reg[0])
									begin//write to avm
										state_back<=back_reg_write_avm_write_1;
										back_avm_mode<=2'b01;//write
										back_avm_new<=1'b0;
									end
								else	
									begin
										state_back<=back_reg_write_avm_read;
										back_avm_mode<=2'b10;//read
										back_avm_new<=1'b1;
									end
							end
						back_reg_write_avm_write_1:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=9'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								back_avm_mode<=2'b01;//write
								back_avm_r_w_addr<=back_avm_r_w_addr;
								back_b_ram_addr_read<=back_b_ram_addr_read;
								back_compare_count_2<=back_compare_count_2+3'b1;
								back_compare_count<=back_compare_count;
								back_compare_value<=3'b011;
								back_center_reg<=e_ram_data_out[back_compare_count_2[1:0]];
								state_back<=back_reg_write_avm_write_2;
							end
						back_reg_write_avm_write_2:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=9'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								back_avm_r_w_addr<=back_avm_r_w_addr;
								back_b_ram_addr_read<=back_b_ram_addr_read;
								back_compare_count<=back_compare_count+3'b1;
								back_compare_count_2<=back_compare_count_2+3'b1;
								back_compare_value<=3'b011;
								back_center_reg<=e_ram_data_out[back_compare_count_2[1:0]];
								back_avm_data_write[back_compare_count[1:0]]<=back_center_reg;
								back_avm_mode<=2'b01;
								if(back_compare_count!=back_compare_value)
									begin
										state_back<=state_back;
										back_avm_new<=1'b0;
										
									end
								else	
									begin
										state_back<=back_reg_write_avm_write_3;
										back_avm_new<=1'b1;
									end
							
							end
						back_reg_write_avm_write_3:	
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=9'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								back_avm_r_w_addr<=back_avm_r_w_addr;
								back_b_ram_addr_read<=10'bx;
								back_compare_count_2<=3'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_center_reg<=8'bx;
								back_avm_mode<=2'b01;//write
								if(~wait_request_avm)
									begin
										state_back<=back_b_ram_read_init_1;
										back_avm_new<=1'b0;
									end
								else	
									begin
										state_back<=state_back;
										back_avm_new<=1'b1;
									end
							end
						back_reg_write_avm_read:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								back_e_ram_addr<=9'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								back_e_ram_write_addr<=back_e_ram_write_addr;
								back_avm_r_w_addr<=back_avm_r_w_addr;
								back_compare_value<=3'bx;
								back_center_reg<=8'bx;
								back_avm_mode<=2'b10;//read
								back_compare_count<=3'b0;
								back_compare_count_2<=3'b0;
								casex({wait_request_avm,request_main})
									2'bx1:
										begin
											state_back<=back_write_back_data;
											back_b_ram_addr_read<=back_b_ram_addr_read-10'd6;//6 addresses had read after
											back_avm_new<=1'b0;
										end
									2'b00:
										begin
											state_back<=back_reg_write_avm_read_2;
											back_avm_new<=1'b0;
											back_b_ram_addr_read<=back_b_ram_addr_read;
										end
									2'b10:
										begin
											state_back<=state_back;
											back_avm_new<=1'b1;
											back_b_ram_addr_read<=back_b_ram_addr_read;
										end
									default:
										begin
											state_back<=state_back;
											back_avm_new<=back_avm_new;
											back_b_ram_addr_read<=back_b_ram_addr_read;
										end
								endcase
							end
						back_reg_write_avm_read_2:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								back_e_ram_addr<=9'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								
								back_e_ram_write_addr<=back_e_ram_write_addr;
								back_avm_r_w_addr<=9'bx;
								back_avm_mode<=2'bx;
								back_avm_new<=1'b0;
								back_b_ram_addr_read<=back_b_ram_addr_read;
								back_compare_count_2<=back_compare_count_2+3'b1;
								back_compare_count<=3'b0;
								back_compare_value<=3'b011;
								back_center_reg<=e_ram_data_read_avm_wire[back_compare_count_2];
								state_back<=back_reg_write_avm_read_3;
							end
						back_reg_write_avm_read_3:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_center_reg_2<=8'bx;
								back_e_ram_addr<=9'bx;
								
								back_e_ram_write_addr<=back_e_ram_write_addr;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_b_ram_addr_read<=back_b_ram_addr_read;
								back_compare_count<=back_compare_count+3'b1;
								back_compare_count_2<=back_compare_count_2+3'b1;
								back_compare_value<=3'b011;
								back_center_reg<=e_ram_data_read_avm_wire[back_compare_count_2];
								back_e_ram_data_write[back_compare_count]<=back_center_reg;
								back_avm_mode<=2'bx;
								if(back_compare_count!=back_compare_value)
									begin
										state_back<=state_back;
										back_e_ram_w_en<=1'b0;
										
									end
								else	
									begin
										state_back<=back_b_ram_read_init_1;
										back_e_ram_w_en<=1'b1;
									end
							
							end
						back_i_o_write_reg_addr:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=9'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_compare_count_2<=3'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								back_avm_mode<=2'bx;
								
								
								back_center_reg_2<=back_center_reg_2;
								back_i_o_reg_2<=2'b0;
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_center_reg<=write_back_ram_out;
								back_i_o_reg[back_compare_count]<=back_center_reg;
								casex({(back_compare_count!=back_compare_value),back_center_reg_2[7:4]})
								
									5'b0xxxx:
										begin
											state_back<=state_back;
											back_compare_value<=back_compare_value;
											back_compare_count<=back_compare_count+3'b1;
										end
									5'b11001://register write user space
										begin
											state_back<=back_i_o_write_data;
											back_compare_value<=3'b111;
											back_compare_count<=3'b100;
										end
									5'b11101://PWM write 
										begin
											state_back<=back_i_o_write_data;
											back_compare_value<=3'b101;
											back_compare_count<=3'b100;
										end
									5'b10101://PWM write 
										begin
											state_back<=back_i_o_write_data;
											back_compare_value<=3'b100;
											back_compare_count<=3'b100;
										end
									5'b10011://i2c write 
										begin
											state_back<=back_i_o_write_data;
											back_compare_value<=3'b101;
											back_compare_count<=3'b100;
										end
									5'b10111://pulse count write 
										begin
											state_back<=back_i_o_write_data;
											back_compare_value<=3'b111;
											back_compare_count<=3'b100;
										end
									default:
										begin
											state_back<=bacK_recovery_mode;//recovery mode
										end
								endcase
							end
						back_i_o_write_data:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=9'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_compare_count_2<=3'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								back_avm_mode<=2'bx;
								
								
								back_center_reg_2<=back_center_reg_2;
								back_b_ram_addr_read<=back_b_ram_addr_read+10'b1;
								back_compare_count<=back_compare_count+3'b1;
								back_compare_value<=back_compare_value;
								back_center_reg<=write_back_ram_out;
								back_i_o_reg[back_compare_count]<=back_center_reg;
								if(back_compare_count!=back_compare_value)
									begin
										state_back<=state_back;
										back_i_o_reg_2<=2'b0;
									end
								else	
									begin
										state_back<=back_i_o_write_data_wait;
										back_i_o_reg_2<=2'b01;//new data i_o
									end
							end
						back_i_o_write_data_wait:
							begin
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_reset_issue<=1'b0;
								back_boot_done<=1'b1;
								back_tx_mode<=back_tx_mode;
								back_b_ram_pointer<=back_b_ram_pointer;
								back_sync_data_available<=1'b0;
								back_slave_addr_en<=1'b0;
								back_sync_1_en<=4'b0;
								back_sync_0_en<=4'b0;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_e_ram_addr<=9'bx;
								back_e_ram_write_addr<=9'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_compare_count_2<=3'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								back_avm_mode<=2'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_center_reg<=8'bx;
								back_center_reg_2<=8'bx;
								
								back_i_o_reg[0]<=back_i_o_reg[0];
								back_i_o_reg[1]<=back_i_o_reg[1];
								back_i_o_reg[2]<=back_i_o_reg[2];
								back_i_o_reg[3]<=back_i_o_reg[3];
								back_i_o_reg[4]<=back_i_o_reg[4];
								back_i_o_reg[5]<=back_i_o_reg[5];
								back_i_o_reg[6]<=back_i_o_reg[6];
								back_i_o_reg[7]<=back_i_o_reg[7];
								
								if(~success_ready_wait_request[0])
									begin
										state_back<=back_b_ram_read_init_1;
										back_i_o_reg_2<=2'b0;
										back_b_ram_addr_read<=back_b_ram_addr_read-10'd2;
									end
								else	
									begin
										back_b_ram_addr_read<=back_b_ram_addr_read;
										state_back<=state_back;
										back_i_o_reg_2<=2'b01;//new data i_o
									end
							end
						bacK_recovery_mode:
							begin
								back_sync_data_available<=1'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'bx;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_reset_issue<=1'b0;
								back_center_reg=8'bx;
								back_center_reg_2=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=back_tx_mode;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								back_compare_count_2<=3'bx;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'dx;
								
								back_b_ram_addr_read<=back_b_ram_addr_read;
								back_b_ram_pointer<=back_b_ram_pointer+3'b1;
								state_back<=bacK_recovery_mode;
							end
						bacK_recovery_mode_2:
							begin
								back_sync_data_available<=1'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'bx;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_reset_issue<=1'b0;
								back_center_reg=8'bx;
								back_center_reg_2=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=back_tx_mode;
								back_prop_delay[0]<=back_prop_delay[0];
								back_prop_delay[1]<=back_prop_delay[1];
								back_prop_delay_available<=back_prop_delay_available;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								back_compare_count_2<=3'bx;
								back_boot_done<=1'b1;
								back_e_ram_addr<=9'dx;
								
								
								back_b_ram_pointer<=back_b_ram_pointer;
								back_b_ram_addr_read<=start_addr_b_ram_read;
								state_back<=back_write_back_data;
							end
						default:
							begin
								back_sync_data_available<=1'b0;
								back_b_ram_pointer<=3'b0;
								back_b_ram_addr_read<=10'b0;
								back_avm_data_write[0]<=8'bx;
								back_avm_data_write[1]<=8'bx;
								back_avm_data_write[2]<=8'bx;
								back_avm_data_write[3]<=8'bx;
								back_avm_r_w_addr<=9'bx;
								back_avm_new<=1'b0;
								back_avm_mode<=2'b0;
								back_slave_addr_en<=1'b0;
								back_sync_0_en<=4'b0;
								back_sync_1_en<=4'b0;
								back_prop_delay_available<=1'b0;
								back_reset_issue<=1'b0;
								back_center_reg=8'bx;
								back_center_reg_2=8'bx;
								back_compare_count<=3'bx;
								back_compare_value<=3'bx;
								back_i_o_reg[0]<=8'bx;
								back_i_o_reg[1]<=8'bx;
								back_i_o_reg[2]<=8'bx;
								back_i_o_reg[3]<=8'bx;
								back_i_o_reg[4]<=8'bx;
								back_i_o_reg[5]<=8'bx;
								back_i_o_reg[6]<=8'bx;
								back_i_o_reg[7]<=8'bx;
								back_i_o_reg_2<=2'b0;
								back_tx_mode<=2'b0;
								back_prop_delay[0]<=8'bx;
								back_prop_delay[1]<=8'bx;
								back_e_ram_data_write[0]<=8'bx;
								back_e_ram_data_write[1]<=8'bx;
								back_e_ram_data_write[2]<=8'bx;
								back_e_ram_data_write[3]<=8'bx;
								back_compare_count_2<=3'b1;
								back_boot_done<=1'b0;
								back_e_ram_addr<=9'd16;
							
							
								state_back<=back_ideal;
							end
					endcase
				end
		end
	//boot error
	
	always @(posedge clk_in or negedge reset_n)
		begin
			if(~reset_n)
				begin
					boot_error<=1'b0;
				end
			else
				begin
					if(main_avm_new && ~wait_reg && (main_avm_mode == 2'b0))
						begin
							boot_error<=EEPROM_error_avm;
						end
					else
						begin
							boot_error<=boot_error;
						end
				end
		end
	
	// tx port selection
	//wire [3:0] jitter_count_tx_wire;
	assign jitter_count_tx_wire=(IRQ1 || IRQ2 || IRQ3)? jitter_count_tx_1:jitter_count_tx_0;

	assign data_tx_0=(IRQ1 || IRQ2 || IRQ3)? 8'bx:sec_tx_data;
	assign data_tx_1=(IRQ1 || IRQ2 || IRQ3)? sec_tx_data:8'bx;
		
	assign mode_tx_0=(user_mode==2'b01)? 2'b01:back_tx_mode;
	assign mode_tx_1=(user_mode==2'b01)? 2'b01:back_tx_mode;	
	
	assign state_tx_0=(IRQ1 || IRQ2 || IRQ3)? 1'b0:sec_tx_state;	
	assign state_tx_1=(IRQ1 || IRQ2 || IRQ3)? sec_tx_state:1'b0;
	
	assign receive_mac_tx_0=(IRQ1 || IRQ2 || IRQ3)? receive_mac_rx_1:receive_mac_rx_0;
	assign receive_mac_tx_1=(IRQ1 || IRQ2 || IRQ3)? receive_mac_rx_0:1'b0;
	
	always @(posedge clk_in)
		begin
			timer_mode<=user_timer_mode;
		end
	
	
	// CLA Adder
	
	
	
	
	
endmodule 

