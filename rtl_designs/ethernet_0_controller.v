module ethernet_0_controller(
	//Rx_0
	input Rx_DV_0,
	input [3:0] Rx_data_0,
	input Rx_clk_0,
	
	//Tx_0
	input Tx_clk_0,
	output Tx_ER_0,
	output Tx_EN_0,
	output [3:0] Tx_data_0,
	
	//MD_0
	
	output IRQ_link_down_0,
	inout MDIO_0,
	output MDC_0,
	
	//Rx_1
	input Rx_DV_1,
	input [3:0] Rx_data_1,
	input Rx_clk_1,
	
	//Tx_1
	input Tx_clk_1,
	output Tx_ER_1,
	output Tx_EN_1,
	output [3:0] Tx_data_1,
	
	//MD_1
	
	output IRQ_link_down_1,
	inout MDIO_1,
	output MDC_1,
	
	//
	input clk_50,
	input reset_n,
	
	output reg [1:0] mode_0 =2'b01,
	output reg [1:0] mode_1 =2'b01,
	
	input [6:0] addr_0,
	input [6:0] addr_1,
	
	output [7:0] out_q_0,
	output [7:0] out_q_1,
	
	input clk_input_400,
	input start_but
	);
	wire ready_1,ready_0;
	
	wire clk_200;
	wire reset_pin;
	
	assign reset_pin=reset_n;
	
	wire count_addr_0;
	wire receive_mac_0;
	wire receive_tx_0;
	wire crc_correct_0;
	(* keep *) wire [4:0] packet_no_0;
	(* keep *) wire [7:0] packet_data_0;
	
	wire count_addr_1;
	wire receive_mac_1;
	wire receive_tx_1;
	wire crc_correct_1;
	(* keep *) wire [4:0] packet_no_1;
	(* keep *) wire [7:0] packet_data_1;
	
	wire [7:0] data_in_0;
	reg [7:0] data_out_0;
	reg [7:0] data_out_0_0;
	
	wire [7:0] data_in_1;
	reg [7:0] data_out_1;
	reg [7:0] data_out_1_1;
	
	wire clk_400_out;
	
	c300 clk300(.inclk0(clk_input_400),.c0(clk_400_out));
	
	RX_Ethernet rx_port_0(.clk(clk_200), .reset_n(reset_pin), .Rx_DV_wire(Rx_DV_0), .Rx_clk(Rx_clk_0), .Rx_data_wire(Rx_data_0), .count_addr(count_addr_0), .receive_mac(receive_mac_0), .data(data_in_0), .receive_tx(receive_tx_0), .crc_correct(crc_correct_0));
	
	TX_Ethernet tx_port_0(.clk(clk_200), .reset_n(reset_pin), .Tx_EN_wire(Tx_EN_0), .Tx_ER_wire(Tx_ER_0), .Tx_clk(Tx_clk_0), .Tx_data(Tx_data_0), .count_addr(count_addr_0), .receive_mac(receive_mac_0), .data(data_in_0), .mode(mode_0), .packet_no(packet_no_0), .packet_data(packet_data_0), .receive_tx(receive_tx_0), .crc_correct_wire(crc_correct_0));
	
	MD_unit_E0 md_0(.MDIO(MDIO_0), .clk_in(clk_200), .reset_n(reset_pin), .clk_25(MDC_0), .ready(ready_0) , .IRQ_link_down(IRQ_link_down_0));
	
	
	RX_Ethernet rx_port_1(.clk(clk_200), .reset_n(reset_pin), .Rx_DV_wire(Rx_DV_1), .Rx_clk(Rx_clk_1), .Rx_data_wire(Rx_data_1), .count_addr(count_addr_1), .receive_mac(receive_mac_1), .data(data_in_1), .receive_tx(receive_tx_1), .crc_correct(crc_correct_1));
	
	TX_Ethernet tx_port_1(.clk(clk_200), .reset_n(reset_pin), .Tx_EN_wire(Tx_EN_1), .Tx_ER_wire(Tx_ER_1), .Tx_clk(Tx_clk_1), .Tx_data(Tx_data_1), .count_addr(count_addr_1), .receive_mac(receive_mac_1), .data(data_in_1), .mode(mode_1), .packet_no(packet_no_1), .packet_data(packet_data_1), .receive_tx(receive_tx_1), .crc_correct_wire(crc_correct_1));
	
	MD_unit_E1 md_1(.MDIO(MDIO_1), .clk_in(clk_200), .reset_n(reset_pin), .clk_25(MDC_1), .ready(ready_1) , .IRQ_link_down(IRQ_link_down_1));
	
	
	clk_200_ pll(.inclk0(clk_50), .c0(clk_200));
	
	reg [2:0] state;
	parameter ideal=3'b0,start_=3'd1,exit_=3'd2;//restart_4=3'd3,restart_5=3'd4;
	
	reg [31:0] count;
	
	always @(posedge clk_200 or negedge reset_n)
		begin
			
			if(~reset_n)
				begin
					mode_0<=2'b01;
					mode_1<=2'b01;
					state<=ideal;
					count<=32'b0;
				end
			else
				begin
					case(state)
						ideal:
							begin
								mode_0<=2'b01;
								mode_1<=2'b01;
								count<=32'b0;
								if (start_but)
									begin
										state<=ideal;
										
									end
								else
									begin
										state<=start_;
									end
							end
						start_:
							begin
								mode_0<=2'b10;
								mode_1<=2'b01;
								count<=count+32'b1;
								if(count[31])
									begin
										state<=exit_;
									end
								else
									begin
										state<=start_;
									end
							end
						exit_:
							begin
								mode_0<=2'b01;
								mode_1<=2'b01;
								count<=32'b0;
								if (start_but)
									begin
										state<=ideal;
										
									end
								else
									begin
										state<=exit_;
									end
							end
						default:
							begin
								mode_0<=2'b01;
								mode_1<=2'b01;
								state<=ideal;
								count<=32'b0;
							end
					endcase
				end
		end
	always @(posedge clk_200)
		begin
			data_out_0_0<=data_in_0;
			data_out_0<=data_out_0_0;
			data_out_1_1<=data_in_1;
			data_out_1<=data_out_1_1;
		end
	reg [6:0] ram_addr_0=7'b0;	
	reg [6:0] ram_addr_1=7'b0;
	reg wEn_0;
	reg wEn_1;
	
	reg count_addr_in_0;
	reg count_addr_in_1;
	
	always @(posedge clk_200)
		begin
			if(count_addr_in_0 != count_addr_0)
				begin
					count_addr_in_0<=~count_addr_in_0;
					wEn_0<=1'b1;
					ram_addr_0<=ram_addr_0+7'b1;
				end
			else
				begin
					count_addr_in_0<=count_addr_in_0;
					wEn_0<=1'b0;
					ram_addr_0<=ram_addr_0;
				end
		end
	
	always @(posedge clk_200)
		begin
			if(count_addr_in_1 != count_addr_1)
				begin
					count_addr_in_1<=~count_addr_in_1;
					wEn_1<=1'b1;
					ram_addr_1<=ram_addr_1+7'b1;
				end
			else
				begin
					count_addr_in_1<=count_addr_in_1;
					wEn_1<=1'b0;
					ram_addr_1<=ram_addr_1;
				end
		end
	
	
	ram_test r0(.data(data_in_0),.read_addr(addr_0), .write_addr(ram_addr_0),.we(wEn_0), .clk(clk_200),.q(out_q_0));
	ram_test r1(.data(data_in_1),.read_addr(addr_1), .write_addr(ram_addr_1),.we(wEn_1), .clk(clk_200),.q(out_q_1));
	
endmodule
	
	