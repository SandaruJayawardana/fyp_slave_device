module DFFE (
				input d, 
				input clk, 
				input clrn, 
				//.prn(<active_low_preset>), 
				input ena, 
				output q
				);
	reg a;
	
	assign q=a;
	
	always @(posedge clk or negedge clrn)
		begin
			if(~clrn)
				begin
					a<=1'b0;
				end
			else
				begin
					if(ena)
						begin
							a<=d;
						end
					else	
						begin
							a<=a;
						end
				end
		end
	
endmodule
