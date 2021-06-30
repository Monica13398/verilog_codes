module d5m(
							input wire 	clk,                // system clk
							/*d5m_i2c --- Declaration*/
							inout wire 	sda,                // i2c inout data pin 
											scl,                // 12c sclk
							
//********************************module d5m_ccd*******************************************************************************************//
							

							input [11:0] p_data,            	//  output bayer data from d5m 
							input 		 p_clk,             	//  pixel clk from d5m to fpga 
							input 		 fval,				  	// field valid signal from d5m to fpga              
							input			 lval,				  	// line valid signal from d5m to fpga
							output		 p_rst,            	// soft reset signal to d5m from fpga
											 trig,					// trigger signal from fpga to d5m 
							output reg   x_clk=1'd0,			// external clk signal from fpga to d5m to generate pixel clk
							
							
//*****************************module sram**********************************************************************************************//
							
							
							
							inout 	 [15:0] 	sram_dq,			// sram inout data pin 
							output 	 [17:0] 	sram_addr,		// sram address pin 
							output 	  reg		ce=1'd1,
													we=1'd0,
													lb=1'd0,		   // sram controll signal
													ub=1'd0,
													oe=1'd0,
													
													
//*****************************************module d5m_vga**********************************************************************************//
							
							output reg	 	   vga_clk  =1'd0,		// vga clk signal 
							output reg [9:0]	r			=10'd0,		// vga red colour output data pin
							output reg [9:0]	g			=10'd0,		// vga GREEN COLOUR  output data pin
							output reg [9:0]	b			=10'd0,		// vga blue colour output data pin
							output reg 			hs,vs,					// vga horizotal and vertical sync pulse			
							output 				vga_sync,				// VGA SYNC SIGNAL
							output 				blank						// vga blank signal to indicate active region
);


//*****************************************i2c instantiation *******************************************************************//
				d5m_i2c i2c(	
							.clk(clk),
							.i2c_clk(scl),
							.i2c_data(sda)
						   );

//******************************************** pll to generate signal tap _clk ************************************************//							
							
				signal_tap_clk  stp(
										.inclk0(clk),
										.c0(clk_100mhz)
										//.c1(clk_200mhz)
										);

	
//******************************************Registers************************************************************************//


						//****************d5m_ccd*****************// 
							reg [9:0]		l_count 			= 10'd0;
							reg [11:0]		p_count			= 12'd0;
							reg [9:0]		mem_count 		= 10'd0;
							reg [7:0]		p_mem[0:639];
							reg [11:0]		d_count = 12'd0;
							
							
							//***********d5m_sram****************//
							
							 
                   reg	[17:0] 	wr_addr    			= 18'd0;
                   reg	[17:0]	rd_addr    			= 18'd0;
                   reg	[7:0] 	sram_data_out   	= 8'd0;
                   reg	[15:0]	sram_data_reg   	= 16'd0;
                   reg	[1:0] 	sram_wr_state   	= 2'd0;
						 reg [1:0] 		sram_rd_state   	= 2'd0;

						//***************d5m_vga*******************//
						

							reg [9:0] 		hcnt 				= 10'd0;		
							reg [9:0] 		vcnt 				= 10'd0;	
							reg 				vga_en;



							
						//*********signal tap *******************//	
							wire            clk_100mhz/*clk_200mhz*/;

//**************************************Assignments ******************************************************************//

							//****************d5m_ccd*****************//
							assign 			p_rst 			= 1'd1,		 
												trig 				= 1'd1; 
											//	str 				= 1;
											
							

			
							 //***********d5m_sram****************//	
							 
							 assign        sram_dq 		= (we==1'd0) ? sram_data_reg : 16'bz;
							 assign 			sram_addr    = (we==1'd0) ? wr_addr : rd_addr;
							 

							//***************d5m_vga*******************//
							
							 assign 			blank			  	= (hcnt > 10'd143 && hcnt < 10'd784 && vcnt < 10'd515 && vcnt > 10'd34 )? 1'd1 : 1'd0;


						//*******************fifo****************
						
						

	
/******************************* d5m_ccd -- x_clk **********************************************************************************/

		always@(posedge clk)		
		 x_clk <= ~ x_clk;
 
//************************************ d5m_ccd -- pixel data ************************************************************************// 
		always@(posedge p_clk)		
		begin
          if( fval == 1'd1 )
          begin
              if( lval == 1'd1 )
                                p_count    <=  p_count + 12'd1;

              else
                                p_count    <= 12'd0;

              if( p_count == 12'd1279)
                                l_count    <= l_count + 10'd1;
				  else
									     l_count    <= l_count;
          end
          else
                                l_count    <= 10'd0;
		end
		
/************************************************************************************************************************************/		
		always@(negedge lval)	// vga start //	
		 begin
		  vga_en <= 1'd1;
		 end
 
	
//*********************************************vga start***********************************************************************//	
		
		
		always@(posedge vga_clk)		// d5m_ccd -- Active pixel data //
		begin
				if(fval && lval) 
				begin
						if(l_count[0] == 1'd0 && l_count < 10'd960) 
						begin
								if(p_count[0] == 1'd1 )
								begin
											p_mem[mem_count] <= p_data[11:4];
											
										if(mem_count == 10'd639)
										
											mem_count        <= 10'd0;
											
										else
										
											mem_count        <= mem_count+10'd1;
								end
						else
											mem_count        <= mem_count ;
						end
				else
				                     mem_count         <= 10'd0;
				end
		end
		
		
		always @( posedge vga_clk )
		begin
				if( blank == 1'd0  && lval == 1'd1 && l_count[0] == 1'd1)
				begin
				
				      if(d_count == 12'd640)
						
								 d_count <=d_count;
								 
						else if(l_count[0] == 1'd0)
						
								d_count <= 12'd0;
						else    
								 d_count <= d_count +12'd1; 
								
						case( sram_wr_state )
						2'd0:
								begin
										wr_addr    			<= ( wr_addr == 18'd153599 ) ? 18'd0 :wr_addr + 18'd1;
										sram_data_reg 		<= p_mem[d_count];
										ce         			<= 1'd0;    // chip enable
										oe         			<= 1'd0;
										we         		   <= 1'd0;    // low for write
										lb         		   <= 1'd0;    // writing in lower byte
										ub         		   <= 1'd1;
										sram_wr_state     <= 2'd1;
								end
						2'd1:
								begin
										sram_data_reg   	<=  p_mem[d_count];
										ce         			<= 1'd0;    // chip enable
										oe         			<= 1'd0;
										we         			<= 1'd0;    // low for write
										lb         			<= 1'd1;
										ub         			<= 1'd0;    // writing in upper byte
										sram_wr_state   	<= 2'd0;
								end
						default:
										sram_wr_state   	<= 2'd0;
						endcase
				end
				
				
				else 
				if( blank == 1'd1 )
				begin
				
						case( sram_rd_state )
						2'd0:
								begin
										rd_addr         	<= ( rd_addr == 18'd153599 ) ? 18'd0 : rd_addr + 18'd1;
										sram_data_out   	<= sram_dq[7:0];
										ce         	  		<= 1'd0;
										oe         	  		<= 1'd0;
										we         	  		<= 1'd1;
										lb         	  		<= 1'd0;
										ub         	  		<= 1'd0;
										sram_rd_state   	<= 2'd1;
								end
						2'd1:
								begin
										sram_data_out   	<= sram_dq[15:8];
										sram_rd_state   	<= 2'd0;
								end
						default:
										sram_rd_state   	<= 2'd0;
						endcase
				end
				else
										ce         		 	<= 1'd1;
		end


/******************************************d5m_vga clk***************************************************************/

		always @(posedge clk)		
		begin          
				vga_clk 	<= ~vga_clk ;     
		end 

//***********************************************VGA_CONFIG***********************************************
		always@(posedge vga_clk)
		begin
		
		if(vga_en)
		begin
		
					if(hcnt<10'd799 && hcnt>10'd95)      	// to generate horizontal sync pulse 
								hs <= 1'd1;
					 else
								hs <= 1'd0;
								
					 if(hcnt<10'd799)					  	// to generate horizontal count 
					 
					  hcnt <= hcnt + 10'd1;
					  
					 else
								hcnt <= 10'd0;
								
								
								
					 if(vcnt<10'd525 && vcnt>=10'd2)		// to generate vertical sync pulse
					 
								vs <= 1'd1;
					 else
								vs <= 1'd0;
								
					 if(hcnt==10'd799 && vcnt<10'd525)  	// to generate vertical count
					 
								vcnt <= vcnt + 10'd1;
								
					 if(vcnt == 525)
					 
								vcnt <= 10'd0;
								
		end
		else
		begin
				 hs 					<= 1'd0;
				 vs 					<= 1'd0;
		       hcnt					<= 10'd0;
				 vcnt					<= 10'd0;
		end			
		end

		always@(posedge vga_clk) 
		begin 
				if(blank)
							{r,g,b}  <= {{sram_data_out,2'd0},{sram_data_out,2'd0},{sram_data_out,2'd0}}	;	
				else
							{r,g,b} 	<= 30'd0;
		end


endmodule 

















