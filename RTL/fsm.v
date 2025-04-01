
module fsm_control(clock,resetn,pkt_valid,
						 data_in,parity_done,low_packet_valid,
						 fifo_full,fifo_empty_0,fifo_empty_1,fifo_empty_2,
						 soft_reset_0,soft_reset_1,soft_reset_2,
						 write_enb_reg,detect_add,ld_state,laf_state,
						 lfd_state,full_state,rst_int_reg,busy);

//Input/Outport_Declaration
 input clock,resetn,pkt_valid,parity_done,low_packet_valid,
 fifo_full,fifo_empty_0,fifo_empty_1,fifo_empty_2,
 soft_reset_0,soft_reset_1,soft_reset_2;
 input [1:0] data_in;
 output write_enb_reg,detect_add,ld_state,laf_state,
 lfd_state,full_state,rst_int_reg,busy;
//State_Parameter_Declaration 
 localparam decode_address = 3'b000, //0
				wait_till_empty = 3'b001, //1
				load_first_data = 3'b010, //2
				load_data = 3'b011, //3
				load_parity = 3'b100, //4
				fifo_full_state = 3'b101, //5
				load_after_full = 3'b110, //6
				check_parity_error = 3'b111; //7
//Internal_Registers
reg [2:0] present_state, next_state;
reg [1:0] temp;
//temp_logic
 always@(posedge clock)
begin
 if(~resetn)
temp <= 2'b0;
 else if(detect_add) 
temp <= data_in;
end
//_______________________________________________________________________________________
//Present state_logic 
 always@(posedge clock)
		begin
		 if(!resetn)
		 present_state <= decode_address;
		 else if ((soft_reset_0) || (soft_reset_1) || (soft_reset_2))
		 present_state <= decode_address;
		 else
		 present_state <= next_state;
		end
//_______________________________________________________________________________________
//Next state_Logic 
 always@(*)
begin
 case(present_state)
		decode_address : begin
								 if((pkt_valid && (data_in==2'b00) && fifo_empty_0)||
									 (pkt_valid && (data_in==2'b01) && fifo_empty_1)||
									 (pkt_valid && (data_in==2'b10) && fifo_empty_2))
									 
									 next_state = load_first_data;
								 
								 else if((pkt_valid && (data_in==2'b00) && !fifo_empty_0)||
											 (pkt_valid && (data_in==2'b01) && !fifo_empty_1)||
											 (pkt_valid && (data_in==2'b10) && !fifo_empty_2))
								 
											next_state = wait_till_empty;
								 else

								 next_state = decode_address; 

								 end
		//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		load_first_data : begin
								 next_state = load_data;
								 end
		//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		wait_till_empty : begin
								 if((fifo_empty_0 && (temp==0))||
										(fifo_empty_1 && (temp==1))||
											(fifo_empty_2 && (temp==2)))
												
												next_state=load_first_data;
								 else
												next_state=wait_till_empty;
								 end
		load_data : begin
						 if(fifo_full==1'b1)
							next_state=fifo_full_state;
						 else
							 begin
							 if (!fifo_full && !pkt_valid)
									next_state=load_parity;
							 else
									next_state=load_data;
							 end
						 end
		//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		fifo_full_state : begin
								 if(fifo_full==0)
										next_state=load_after_full;
								 else
										next_state=fifo_full_state;
							 end
		//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		load_after_full : begin
								 if(!parity_done && low_packet_valid)
										next_state=load_parity;
								 else if(!parity_done && !low_packet_valid)
										next_state=load_data;
								 else if(parity_done==1'b1)
											next_state=decode_address;
									else
											next_state=load_after_full;
									
								 end
		//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		 load_parity : begin
								next_state=check_parity_error;
							end
		//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		check_parity_error : begin
										 if(!fifo_full)
												next_state=decode_address;
										 else
												next_state=fifo_full_state;
										 end
		//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		default :
						next_state = next_state;
	endcase
end
//Output_Logic
assign busy=((present_state==load_first_data)||
					(present_state==load_parity)||
					 (present_state==fifo_full_state)||
					(present_state==load_after_full)||
					 (present_state==wait_till_empty)||
					(present_state==check_parity_error))?1'b1:1'b0;
assign write_enb_reg=(/*(present_state==load_first_data)||*/
								(present_state==load_data)||
							 (present_state==load_after_full)||
							 (present_state==load_parity))?1'b1:1'b0;
assign ld_state =((present_state==load_data))?1'b1:1'b0;
assign detect_add =((present_state==decode_address))?1'b1:1'b0;
assign lfd_state =((present_state==load_first_data))?1'b1:1'b0;
assign full_state =((present_state==fifo_full_state))?1'b1:1'b0;
assign laf_state =((present_state==load_after_full))?1'b1:1'b0;
assign rst_int_reg=((present_state==check_parity_error))?1'b1:1'b0;


endmodule




