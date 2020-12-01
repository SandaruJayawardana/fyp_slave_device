// Quartus Prime Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock

module EEPROM_I2C_RAM
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=8)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1):0] q
);

	// Declare the RAM variable
	(* ramstyle = "M9K" *) reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	// Specify the initial contents.  You can also use the $readmemb
	// system task to initialize the RAM variable from a text file.
	// See the $readmemb template page for details.
	initial 
	begin 
		ram[0]=32'h00000000;
		ram[1]=32'hffffff05;//addr
		ram[2]=32'h05761ff0;//sync0
		ram[3]=32'hf0a51001;//sync1
		ram[4]=32'h000d0000;
		ram[5]=32'h00000000;
		ram[6]=32'h00000000;
		ram[7]=32'h80000000;
		ram[8]=32'h0000000b;//type
		ram[9]=32'h00000000;
		ram[10]=32'h00000000;
		ram[11]=32'h00000000;
		ram[12]=32'h00000000;
		ram[13]=32'h00000000;
		ram[14]=32'h00000000;
		ram[15]=32'h00000000;
		ram[16]=32'h01ff510f;
		ram[17]=32'h0275101f;
		ram[18]=32'h0102550a;
		ram[19]=32'h00000000;
		ram[20]=32'h00000000;
		ram[21]=32'h00000000;
		ram[22]=32'h00000000;
		ram[23]=32'h00000000;
		ram[24]=32'h00000000;
		ram[25]=32'h00000000;
		ram[26]=32'h00000000;
		ram[27]=32'h00000000;
		ram[28]=32'h00000000;
		ram[29]=32'h00000000;
		ram[30]=32'h00000000;
		ram[31]=32'h0104a1b1;
		ram[32]=32'h01075afa;
		ram[33]=32'h0101affa;
		ram[34]=32'h50010678;
		ram[35]=32'h15406baf;
		ram[36]=32'h07780051;
		ram[37]=32'h05561001;
		ram[38]=32'h00000000;
		ram[39]=32'h00000000;
		ram[254]=32'hff00ffa1;
		ram[255]=32'ha1fabcde;
	end 

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[addr] <= data;

		addr_reg <= addr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];

endmodule
