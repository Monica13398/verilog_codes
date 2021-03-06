module d5m_i2c(input clk,
						output i2c_clk,
						inout i2c_data);
						
parameter total_count=5'd25;

reg sclk=1'b1;
reg sda=1'b1;
reg [7:0]clk_count=8'd0;
reg [4:0]data_count=5'd0;     
reg [5:0]bit_count=6'd0;
reg [31:0]sda_mem;
reg [23:0]reg_data;

assign i2c_clk=(bit_count>=6'd3 && bit_count<=6'd39) ? ~sclk : 1'b1;
assign i2c_data=sda;

always@(posedge clk)
 begin
  if(clk_count==8'd250)
   begin
	 clk_count<=8'd1;
	 sclk<=~sclk;
	end
  else
   begin
	 clk_count<=clk_count+1'b1;
	 sclk<=sclk;
	end
 end
always@(*)
  begin
			case(data_count)
			
					5'd0	:	reg_data	<=	24'h000000;
					5'd1	:	reg_data	<=	24'h20C000;				  	//	Mirror Row and Columns
					5'd2	:	reg_data	<=	24'h0907C0;    			//	Exposure
					5'd3	:	reg_data	<=	24'h050000;					//	H_Blanking
					5'd4	:	reg_data	<=	24'h060019;					//	V_Blanking	
					5'd5	:	reg_data	<=	24'h0A8000;					//	change latch
					5'd6	:	reg_data	<=	24'h2B000b;					//	Green 1 Gain
					5'd7	:	reg_data	<=	24'h2C000f;					//	Blue Gain
					5'd8	:	reg_data	<=	24'h2D000f;					//	Red Gain
					5'd9	:	reg_data	<=	24'h2E000b;					//	Green 2 Gain
					5'd10	:	reg_data	<=	24'h100051;					//	set up PLL power on
					5'd11	:	reg_data	<=	24'h111807;					//	PLL_m_Factor<<8+PLL_n_Divider //-- 111807
					5'd12	:	reg_data	<=	24'h120002;					//	PLL_p1_Divider //-- h120001/2
					5'd13	:	reg_data	<=	24'h100053;					//	set USE PLL	 
					5'd14	:	reg_data	<=	24'h980000;					//	disble calibration 	
					5'd15	:	reg_data	<=	24'h010000;					//	set start row	
					5'd16	:	reg_data	<=	24'h020000;					//	set start column 	
					5'd17	:	reg_data	<=	24'h03077F;					//	set row size	//--
					5'd18	:	reg_data	<=	24'h0409FF;					//	set column size
					5'd19	:	reg_data	<=	24'h220011;					//	set row mode in bin mode
					5'd20	:	reg_data	<=	24'h230011;					//	set column mode in bin mode
					5'd21	:	reg_data	<=	24'h4901A8;					//	row black target
					5'd22	:	reg_data	<=	24'hA00000;				   //	Test pattern control 
					5'd23 :	reg_data	<=	24'hA10000;				   //	Test green pattern value
					5'd24	:	reg_data	<=	24'hA20FFF;
				   //	Test red pattern value
			default:reg_data	<=	24'h000000;
			endcase
  end  
  
always@(posedge sclk)
 begin
  if(data_count==total_count - 1'b1)
   data_count<=data_count; //--
  else
   begin
	 if(bit_count==6'd40)
	  begin
	   bit_count<=6'd0;
	   data_count<=data_count+1'b1;
	  end
	 else
	  bit_count<=bit_count+1'b1;
	end
	
  case(bit_count)
   6'd0	:			sda<=1'b1;				//idle_condition
	6'd1	:	begin	sda<=1'b0;	sda_mem<={8'hBA,reg_data};	end			//start_bit
	6'd2	:			sda<=sda_mem[31];		//slave_address[31:24]
	6'd3	:			sda<=sda_mem[30];
	6'd4	:			sda<=sda_mem[29];
	6'd5	:			sda<=sda_mem[28];
	6'd6	:			sda<=sda_mem[27];
	6'd7	:			sda<=sda_mem[26];
	6'd8	:			sda<=sda_mem[25];
	6'd9	:			sda<=sda_mem[24];
	6'd10	:			sda<=1'bz;				//ack1
	6'd11	:			sda<=sda_mem[23];		//register_address[23:16]
	6'd12	:			sda<=sda_mem[22];
	6'd13	:			sda<=sda_mem[21];
	6'd14	:			sda<=sda_mem[20];
	6'd15	:			sda<=sda_mem[19];
	6'd16	:			sda<=sda_mem[18];
	6'd17	:			sda<=sda_mem[17];
	6'd18	:			sda<=sda_mem[16];
	6'd19	:			sda<=1'bz;				//ack2
	6'd20	:			sda<=sda_mem[15];		//MSB_data[15:8]
	6'd21	:			sda<=sda_mem[14];
	6'd22	:			sda<=sda_mem[13];
	6'd23	:			sda<=sda_mem[12];
	6'd24	:			sda<=sda_mem[11];
	6'd25	:			sda<=sda_mem[10];
	6'd26	:			sda<=sda_mem[9];
	6'd27	:			sda<=sda_mem[8];
	6'd28	:			sda<=1'bz;				//ack3
	6'd29	:			sda<=sda_mem[7];		//LSB_data[7:0]
	6'd30	:			sda<=sda_mem[6];
	6'd31	:			sda<=sda_mem[5];
	6'd32	:			sda<=sda_mem[4];
	6'd33	:			sda<=sda_mem[3];
	6'd34	:			sda<=sda_mem[2];
	6'd35	:			sda<=sda_mem[1];
	6'd36	:			sda<=sda_mem[0];
	6'd37	:			sda<=1'bz;				//ack4
	6'd38	:			sda<=1'b0;
	6'd39	:			sda<=1'b1;				//stop_bit
	6'd40	:			sda<=1'b1;
  endcase
 end
endmodule
