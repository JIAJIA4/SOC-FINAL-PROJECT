module WB2AXI_QSORT #(
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
)(
    // Wishbone Slave ports
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wb_valid,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o
);

wire                     awready;
wire                     wready;
wire                     awvalid;
wire [(pADDR_WIDTH-1):0] awaddr;
wire                     wvalid;
wire [(pDATA_WIDTH-1):0] wdata;
wire                     arready;
wire                     rready;
wire                     arvalid;
wire [(pADDR_WIDTH-1):0] araddr;
wire                     rvalid;
wire [(pDATA_WIDTH-1):0] rdata;    
wire                     ss_tvalid; 
wire [(pDATA_WIDTH-1):0] ss_tdata; 
wire                     ss_tlast; 
wire                     ss_tready; 
wire                     sm_tready; 
wire                     sm_tvalid; 
wire [(pDATA_WIDTH-1):0] sm_tdata;
wire                     sm_tlast; 


parameter IDLE         = 3'b000;
parameter AXI_RADDR    = 3'b001;
parameter AXI_RDATA    = 3'b010;
parameter AXI_WADDR    = 3'b011;
parameter AXI_WDATA    = 3'b100;
parameter AXI_SS       = 3'b101;
parameter AXI_SM       = 3'b111;

reg [2:0] axi_state;

always@(posedge wb_clk_i or posedge wb_rst_i)begin
    if(wb_rst_i)    axi_state <= IDLE;
    else begin
        case(axi_state)
            IDLE:begin
                if(wb_valid)begin
                    if(wbs_adr_i == 32'h30002084)           
                        axi_state <= AXI_SM;
                    else if(wbs_adr_i == 32'h30002080)
                        axi_state <= AXI_SS;
                    else if(wbs_we_i)
                        axi_state <= AXI_WADDR;
                    else
                        axi_state <= AXI_RADDR;
                end else
                    axi_state <= IDLE;
            end
            AXI_RADDR: axi_state <= (arready) ? AXI_RDATA : AXI_RADDR;
            AXI_WADDR: axi_state <= (awready) ? AXI_WDATA : AXI_WADDR;
            AXI_RDATA: axi_state <= (wbs_ack_o) ? IDLE : AXI_RDATA;
            AXI_WDATA: axi_state <= (wbs_ack_o) ? IDLE : AXI_WDATA;
            AXI_SS: axi_state <= (wbs_ack_o) ? IDLE : AXI_SS;
            AXI_SM: axi_state <= (wbs_ack_o) ? IDLE : AXI_SM;
        endcase
    end        
end

assign araddr   = (axi_state == AXI_RADDR) ? wbs_adr_i - 32'h30002000 : 0;
assign arvalid  = (axi_state == AXI_RADDR) ? 1 : 0;
assign awaddr   = (axi_state == AXI_WADDR) ? wbs_adr_i - 32'h30002000 : 0;
assign awvalid  = (axi_state == AXI_WADDR) ? 1 : 0;
assign rready   = (axi_state == AXI_RDATA) ? 1 : 0;
assign wvalid   = (axi_state == AXI_WDATA && wready) ? 1 : 0;
assign wdata    = (wvalid) ? wbs_dat_i : 0;
assign ss_tvalid= (axi_state == AXI_SS) ? 1 : 0;
assign ss_tdata = (axi_state == AXI_SS) ? wbs_dat_i : 0;
assign sm_tready= (axi_state == AXI_SM) ? sm_tvalid : 0; 

always@(*)begin
    if(axi_state == AXI_RDATA) 
        wbs_ack_o = rvalid;
    else if(axi_state == AXI_WDATA)  
        wbs_ack_o = wvalid;
    else if(axi_state == AXI_SS)
        wbs_ack_o = ss_tready;
    else if(axi_state == AXI_SM)
        wbs_ack_o = sm_tvalid;
    else
        wbs_ack_o = 0;
end

always@(*)begin
    if(axi_state == AXI_RDATA && rvalid)
        wbs_dat_o = rdata;
    else if(axi_state == AXI_WDATA && wvalid)
        wbs_dat_o = wbs_dat_i;
    else if(axi_state == AXI_SS)
        wbs_dat_o = wbs_dat_i;
    else if(axi_state == AXI_SM)
        wbs_dat_o = sm_tdata;
    else
        wbs_dat_o = 0;
end

qsort qsort(
    .awready        (awready    ),
    .wready         (wready     ),
    .awvalid        (awvalid    ),
    .awaddr         (awaddr     ),
    .wvalid         (wvalid     ),
    .wdata          (wdata      ),
    .arready        (arready    ),
    .rready         (rready     ),
    .arvalid        (arvalid    ),
    .araddr         (araddr     ),
    .rvalid         (rvalid     ),
    .rdata          (rdata      ),

    .ss_tvalid      (ss_tvalid  ),
    .ss_tdata       (ss_tdata   ),
    .ss_tlast       (ss_tlast   ),
    .ss_tready      (ss_tready  ),
    .sm_tready      (sm_tready  ),
    .sm_tvalid      (sm_tvalid  ),
    .sm_tdata       (sm_tdata   ),
    .sm_tlast       (sm_tlast   ),

    .axis_clk       (wb_clk_i   ),
    .axis_rst_n     (~wb_rst_i  )
);

endmodule