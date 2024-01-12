module WB_Decode(
    // Wishbone Slave ports
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    input wire [37:0] io_in,
    output wire [37:0] io_out,
    output wire [37:0] io_oeb,
    
    output wire [2:0] irq
);

wire axi_ack_o, bram_ack_o, fir_ack_o, qsort_ack_o, mm_ack_o;
wire [31:0] axi_dat_o, bram_dat_o, fir_dat_o, qsort_dat_o, mm_dat_o;

// decode 
reg [4:0] decode; // 2'b00 = invalid, 2'b01 = AXI, 2'b10 = exmem

always@(*)begin
    if(wbs_cyc_i && wbs_stb_i)begin
        if(wbs_adr_i[31:24] == 8'h30)
			// FIR
			if(wbs_adr_i[15:12] == 'h1)
				decode = 5'b00100;
			// QSORT
			else if(wbs_adr_i[15:12] == 'h2)
				decode = 5'b01000; 
			// MM
			else if(wbs_adr_i[15:12] == 'h3)
				decode = 5'b10000;
			// uart
			else 
				decode = 5'b00001;
		//exemem
		else if(wbs_adr_i[31:24] == 8'h38)
            decode = 5'b00010;
		else
            decode = 5'b00000;
    end 
	else begin
        decode = 'b00000;
    end
end

always@(*)begin
    if(decode == 5'b00001)begin
        wbs_ack_o = axi_ack_o;
		wbs_dat_o = axi_dat_o;
    end
	else if(decode == 5'b00010)begin
		wbs_ack_o = bram_ack_o;
		wbs_dat_o = bram_dat_o;
	end
	else if(decode == 5'b00100)begin
		wbs_ack_o = fir_ack_o;
		wbs_dat_o = fir_dat_o;
	end
	else if(decode == 5'b01000)begin
		wbs_ack_o = qsort_ack_o;
		wbs_dat_o = qsort_dat_o;
	end
	else if(decode == 5'b10000)begin
		wbs_ack_o = mm_ack_o;
		wbs_dat_o = mm_dat_o;
	end
	else begin
        wbs_ack_o = 5'b00000;
		wbs_dat_o = 5'b00000;
    end
end

uart uart(
    .wb_clk_i       (wb_clk_i   ),
    .wb_rst_i       (wb_rst_i   ),
    .wb_valid       (decode[0]  ),              
    .wbs_we_i       (wbs_we_i   ),              
    .wbs_sel_i      (wbs_sel_i  ),              
    .wbs_dat_i      (wbs_dat_i  ),              
    .wbs_adr_i      (wbs_adr_i  ),              
    .wbs_ack_o      (axi_ack_o  ),              
    .wbs_dat_o      (axi_dat_o  ),
    .io_in          (io_in      ),
    .io_out         (io_out     ),
    .io_oeb         (io_oeb     ),
    .user_irq       (irq        )
);

exmem exmem(
    .wb_clk_i       (wb_clk_i   ),
    .wb_rst_i       (wb_rst_i   ),
    .wb_valid       (decode[1]  ),              
    .wbs_we_i       (wbs_we_i   ),              
    .wbs_sel_i      (wbs_sel_i  ),              
    .wbs_dat_i      (wbs_dat_i  ),              
    .wbs_adr_i      (wbs_adr_i  ),              
    .wbs_ack_o      (bram_ack_o ),              
    .wbs_dat_o      (bram_dat_o )                 
);

WB2AXI_FIR WB2AXI_FIR(
    .wb_clk_i       (wb_clk_i   ),
    .wb_rst_i       (wb_rst_i   ),
    .wb_valid       (decode[2]  ),              
    .wbs_we_i       (wbs_we_i   ),              
    .wbs_sel_i      (wbs_sel_i  ),              
    .wbs_dat_i      (wbs_dat_i  ),              
    .wbs_adr_i      (wbs_adr_i  ),              
    .wbs_ack_o      (fir_ack_o  ),              
    .wbs_dat_o      (fir_dat_o  )         
);

WB2AXI_QSORT WB2AXI_QSORT(
    .wb_clk_i       (wb_clk_i   ),
    .wb_rst_i       (wb_rst_i   ),
    .wb_valid       (decode[3]  ),              
    .wbs_we_i       (wbs_we_i   ),              
    .wbs_sel_i      (wbs_sel_i  ),              
    .wbs_dat_i      (wbs_dat_i  ),              
    .wbs_adr_i      (wbs_adr_i  ),              
    .wbs_ack_o      (qsort_ack_o  ),              
    .wbs_dat_o      (qsort_dat_o  )         
);

WB2AXI_MM WB2AXI_MM(
    .wb_clk_i       (wb_clk_i   ),
    .wb_rst_i       (wb_rst_i   ),
    .wb_valid       (decode[4]  ),              
    .wbs_we_i       (wbs_we_i   ),              
    .wbs_sel_i      (wbs_sel_i  ),              
    .wbs_dat_i      (wbs_dat_i  ),              
    .wbs_adr_i      (wbs_adr_i  ),              
    .wbs_ack_o      (mm_ack_o  ),              
    .wbs_dat_o      (mm_dat_o  )         
);

endmodule