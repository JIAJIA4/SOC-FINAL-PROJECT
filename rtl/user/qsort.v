`timescale 1ns / 1ps
module qsort
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
)
(
    // AXI-Lite
    // write
    output  reg                      awready,
    output  reg                      wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    // read
    output  reg                      arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  reg                      rvalid,
    output  reg  [(pDATA_WIDTH-1):0] rdata, 

    // AXI-Stream   
    // Input data
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  reg                      ss_tready, 
    // Output data
    input   wire                     sm_tready, 
    output  reg                      sm_tvalid, 
    output  reg  [(pDATA_WIDTH-1):0] sm_tdata, 
    output  reg                      sm_tlast, 

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);

// block level signal (0x00)
reg ap_start, n_ap_start;
reg ap_idle, n_ap_idle;
reg ap_done, n_ap_done;
reg stream_in_ready, stream_out_ready;

// axi-lite read
localparam  AXI_READ_IDLE = 0,
            AXI_READ_ADDR = 1,
            AXI_READ_WAIT = 2,
            AXI_READ_DATA = 3;

// axi-lite write
localparam  AXI_WRITE_IDLE = 0,
            AXI_WRITE_ADDR = 1,
            AXI_WRITE_DATA = 2;

// Stream-In
reg n_ss_tready;

// AXI
reg [2:0] axi_read_state, n_axi_read_state;
reg [2:0] axi_write_state, n_axi_write_state;

integer i,j ,k;

// QSORT fsm
localparam  ST_IDLE = 0,
            ST_WAIT = 1,
            ST_SSIN = 2,
			ST_SORT = 3,
            ST_OUT  = 4;

reg [2:0] sort_state, n_sort_state;

reg [31:0] axiwaddr, axiraddr;
reg [31:0] data[9:0];

reg  [31:0] sort_in[9:0];
wire [31:0] sort_out[9:0];

reg [31:0] data0,data1,data2,data3,data4,data5,data6,data7,data8,data9;
reg [31:0] sort_in0,sort_in1,sort_in2,sort_in3,sort_in4,sort_in5,sort_in6,sort_in7,sort_in8,sort_in9;
reg [31:0] sort_out0,sort_out1,sort_out2,sort_out3,sort_out4,sort_out5,sort_out6,sort_out7,sort_out8,sort_out9;

reg [4:0] cnt_out;
reg [4:0] cnt_sort;
reg [4:0] cnt_in;

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
        axiwaddr <= 0;
        axiraddr <= 0;
    end
    else begin
        axiwaddr <= (awvalid == 1 && awready == 1) ? awaddr :  axiwaddr;
        axiraddr <= (arvalid == 1 && arready == 1) ? araddr :  axiraddr;
    end
end


// ======================= AXI-Lite: Read ======================================
always @(*) begin
    case (axi_read_state)
        AXI_READ_IDLE:  n_axi_read_state = (arvalid == 1) ? AXI_READ_ADDR : AXI_READ_IDLE;
        AXI_READ_ADDR:  n_axi_read_state = AXI_READ_WAIT;
        AXI_READ_WAIT:  n_axi_read_state = AXI_READ_DATA;
        AXI_READ_DATA:  n_axi_read_state = (rvalid == 1) ? AXI_READ_IDLE : AXI_READ_DATA;
        default: n_axi_read_state = AXI_READ_IDLE;
    endcase
end


always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
        axi_read_state  <= AXI_READ_IDLE;
        arready <= 0;
        rvalid  <= 0;
    end else begin
        axi_read_state  <= n_axi_read_state;
        arready <= (n_axi_read_state == AXI_READ_ADDR) ? 1 : 0;
        rvalid  <= (n_axi_read_state == AXI_READ_DATA) ? 1 : 0;
    end
end

always @(*) begin
	case (axiraddr)
		'h00: rdata = {
			stream_out_ready,       // [5]
			stream_in_ready,        // [4]
			1'b0,                   // [3]
			ap_idle,                // [2]
			ap_done,                // [1]
			ap_start                // [0]
		};                          // block level signals
		default: rdata = 0;
	endcase
end

// ======================= AXI-Lite: Write ======================================
always @(*) begin
    case (axi_write_state)
        AXI_WRITE_IDLE: n_axi_write_state = (awvalid == 1) ? AXI_WRITE_ADDR : AXI_WRITE_IDLE;
        AXI_WRITE_ADDR: n_axi_write_state = AXI_WRITE_DATA;
        AXI_WRITE_DATA: n_axi_write_state = (wvalid == 1) ? AXI_WRITE_IDLE : AXI_WRITE_DATA;
        default: n_axi_write_state = AXI_WRITE_IDLE;
    endcase
end

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
        axi_write_state  <= AXI_WRITE_IDLE;
        awready <= 0;
        wready  <= 0;
    end else begin
        axi_write_state  <= n_axi_write_state;
        awready <= (n_axi_write_state == AXI_WRITE_ADDR) ? 1 : 0;
        wready  <= (n_axi_write_state == AXI_WRITE_DATA) ? 1 : 0;
    end
end

// ======================= Stream-In ============================================
always @(*) begin
    if (sort_state == ST_SSIN)  ss_tready = 1;
    else                        ss_tready = 0;
end

// ======================= Stream-Out ===========================================
always @(*) begin
    if (sort_state == ST_OUT) begin
        sm_tvalid = 1;
        sm_tdata = data[0];
        sm_tlast = (cnt_out == 'd9) ? 1 : 0;
    end
    else begin
        sm_tvalid = 0;
        sm_tdata = 0;
        sm_tlast = 0;
    end
end


// ======================= Block level Signals ===================================
// ap_start
always @(*) begin
    if      (axiwaddr == 'h00 && wready == 1 && wvalid == 1 && wdata == 1)  n_ap_start = wdata;     // Host program ap_start = 1
    else if (sort_state == ST_SSIN)                                         n_ap_start = 0;         // Reset to 0, when 1st AXI-Stream handshake
    else                                                                    n_ap_start = ap_start;
end

// ap_idle
always @(*) begin
    if      (axiwaddr == 'h00 && wready == 1 && wvalid == 1 && wdata == 1)  n_ap_idle = 0;      // Host program ap_start = 1
    else if (sort_state == ST_OUT && cnt_out == 9 && sm_tready == 1)        n_ap_idle = 1;      // Reset to 1, when last data had axi-streamed out
    else                                                                    n_ap_idle = ap_idle;   
end

// ap_done
always @(*) begin
    if      (sort_state == ST_OUT && cnt_out == 9 && sm_tready == 1)   n_ap_done = 1;
    else if (sort_state == ST_SSIN)                                     n_ap_done = 0;
    else                                                                n_ap_done = ap_done;
end

// stream_in_ready, stream_out_ready
always @(*) begin
    stream_in_ready     = (sort_state == ST_WAIT);
    stream_out_ready    = (sort_state == ST_OUT);
end


always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
        ap_start    <= 0;
        ap_idle     <= 1;
        ap_done     <= 0;
    end else begin
        ap_start    <= n_ap_start;
        ap_idle     <= n_ap_idle;
        ap_done     <= n_ap_done;
    end
end

// ======================= SORT Engine ============================================
// output counter
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n)    cnt_out <= 0;
    else begin
        if      (sort_state == ST_IDLE)             cnt_out <= 0;
        else if (sm_tready == 1 && sm_tvalid == 1)  cnt_out <= cnt_out + 1;
    end
end

//stream input counter
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n)    cnt_in <= 0;
    else begin
        if      (sort_state == ST_IDLE)  cnt_in <= 0;
        else if (sort_state == ST_SSIN)  cnt_in <= cnt_in + 1;
    end
end

//sort counter
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n)    cnt_sort <= 0;
    else begin
        if      (sort_state == ST_IDLE) cnt_sort <= 0;
        else if (sort_state == ST_SORT) cnt_sort <= cnt_sort + 1;
    end
end

always @(*)begin
	data0 <= data[0];
	data1 <= data[1];
	data2 <= data[2];
	data3 <= data[3];
	data4 <= data[4];
	data5 <= data[5];
	data6 <= data[6];
	data7 <= data[7];
	data8 <= data[8];
	data9 <= data[9];
	
	sort_in0 <= sort_in[0];
	sort_in1 <= sort_in[1];
	sort_in2 <= sort_in[2];
	sort_in3 <= sort_in[3];
	sort_in4 <= sort_in[4];
	sort_in5 <= sort_in[5];
	sort_in6 <= sort_in[6];
	sort_in7 <= sort_in[7];
	sort_in8 <= sort_in[8];
	sort_in9 <= sort_in[9];
	
	sort_out0 <= sort_out[0];
	sort_out1 <= sort_out[1];
	sort_out2 <= sort_out[2];
	sort_out3 <= sort_out[3];
	sort_out4 <= sort_out[4];
	sort_out5 <= sort_out[5];
	sort_out6 <= sort_out[6];
	sort_out7 <= sort_out[7];
	sort_out8 <= sort_out[8];
	sort_out9 <= sort_out[9];
end

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
		for (i=0; i<10; i=i+1) begin
			data[i] <= 0;
		end
    end 
	else begin
        if(sort_state == ST_SSIN && ss_tready == 1)begin
			data[9] <= ss_tdata;
			for (i=0; i<9; i=i+1) begin
				data[i] <= data[i+1];
			end
		end
		else if(sort_state == ST_SORT)begin
			if(cnt_sort == 'd0)begin
				//[(0,1),(2,5),(3,6),(4,7),(8,9)]
                data[0] <= sort_out[0];
                data[1] <= sort_out[1];
                        
                data[2] <= sort_out[2];
                data[5] <= sort_out[3];
                        
                data[3] <= sort_out[4];
                data[6] <= sort_out[5];
                        
                data[4] <= sort_out[6];
                data[7] <= sort_out[7];
                        
                data[8] <= sort_out[8];
                data[9] <= sort_out[9];
            end
            else if(cnt_sort == 'd1)begin
                //[(0,6),(1,8),(2,4),(3,9),(5,7)]
                data[0] <= sort_out[0];
                data[6] <= sort_out[1];
                                  
                data[1] <= sort_out[2];
                data[8] <= sort_out[3];
                                  
                data[2] <= sort_out[4];
                data[4] <= sort_out[5];
                                  
                data[3] <= sort_out[6];
                data[9] <= sort_out[7];
                                  
                data[5] <= sort_out[8];
                data[7] <= sort_out[9];
            end 
            else if(cnt_sort == 'd2)begin
                //[(0,2),(1,3),(4,5),(6,8),(7,9)]
                data[0] <= sort_out[0];
                data[2] <= sort_out[1];
                                  
                data[1] <= sort_out[2];
                data[3] <= sort_out[3];
                                  
                data[4] <= sort_out[4];
                data[5] <= sort_out[5];
                                  
                data[6] <= sort_out[6];
                data[8] <= sort_out[7];
                                  
                data[7] <= sort_out[8];
                data[9] <= sort_out[9];
            end
            else if(cnt_sort == 'd3)begin
                //[(0,1),(2,7),(3,5),(4,6),(8,9)]
                data[0] <= sort_out[0];
                data[1] <= sort_out[1];
                                  
                data[2] <= sort_out[2];
                data[7] <= sort_out[3];
                                  
                data[3] <= sort_out[4];
                data[5] <= sort_out[5];
                                  
                data[4] <= sort_out[6];
                data[6] <= sort_out[7];
                                  
                data[8] <= sort_out[8];
                data[9] <= sort_out[9];
            end
            else if(cnt_sort == 'd4)begin
                //[(1,2),(3,4),(5,6),(7,8)]
                data[1] <= sort_out[0];
                data[2] <= sort_out[1];
				                  
                data[3] <= sort_out[2];
                data[4] <= sort_out[3];
                                  
                data[5] <= sort_out[4];
                data[6] <= sort_out[5];
                                  
                data[7] <= sort_out[6];
                data[8] <= sort_out[7];
            end         
            else if(cnt_sort == 'd5)begin
                //[(1,3),(2,4),(5,7),(6,8)]
                data[1] <= sort_out[0];
                data[3] <= sort_out[1];
				                  
                data[2] <= sort_out[2];
                data[4] <= sort_out[3];
                                  
                data[5] <= sort_out[4];
                data[7] <= sort_out[5];
                                  
                data[6] <= sort_out[6];
                data[8] <= sort_out[7];
            end         
            else if(cnt_sort == 'd6)begin
                //[(2,3),(4,5),(6,7)]
                data[2] <= sort_out[0];
                data[3] <= sort_out[1];
                                  
                data[4] <= sort_out[2];
                data[5] <= sort_out[3];
                                  
                data[6] <= sort_out[4];
                data[7] <= sort_out[5];
            end         
		end             
		else if(sort_state == ST_OUT && sm_tready == 1 && sm_tvalid == 1)begin
			for (i=0; i<9; i=i+1) begin
				data[i] <= data[i+1];
			end         
		end
    end
end

always @(*) begin
	sort_in[0] = 0;
    sort_in[1] = 0;
    sort_in[2] = 0;
    sort_in[3] = 0;
    sort_in[4] = 0;
    sort_in[5] = 0;
    sort_in[6] = 0;
    sort_in[7] = 0;
    sort_in[8] = 0;
    sort_in[9] = 0;
	
    if(sort_state == ST_SORT)begin
		if(cnt_sort == 'd0)begin
			//[(0,1),(2,5),(3,6),(4,7),(8,9)]
            sort_in[0] = data[0];
            sort_in[1] = data[1];
		   
            sort_in[2] = data[2];
            sort_in[3] = data[5];
		   
            sort_in[4] = data[3];
            sort_in[5] = data[6];
		   
            sort_in[6] = data[4];
            sort_in[7] = data[7];
		   
            sort_in[8] = data[8];
            sort_in[9] = data[9];
        end
        else if(cnt_sort == 'd1)begin
            //[(0,6),(1,8),(2,4),(3,9),(5,7)]
            sort_in[0] = data[0];
            sort_in[1] = data[6];
		   
            sort_in[2] = data[1];
            sort_in[3] = data[8];
		   
            sort_in[4] = data[2];
            sort_in[5] = data[4];
		   
            sort_in[6] = data[3];
            sort_in[7] = data[9];
		   
            sort_in[8] = data[5];
            sort_in[9] = data[7];
        end 
        else if(cnt_sort == 'd2)begin
            //[(0,2),(1,3),(4,5),(6,8),(7,9)]
            sort_in[0] = data[0];
            sort_in[1] = data[2];
                       
            sort_in[2] = data[1];
            sort_in[3] = data[3];
                       
            sort_in[4] = data[4];
            sort_in[5] = data[5];
                       
            sort_in[6] = data[6];
            sort_in[7] = data[8];
                       
            sort_in[8] = data[7];
            sort_in[9] = data[9];
        end
        else if(cnt_sort == 'd3)begin
            //[(0,1),(2,7),(3,5),(4,6),(8,9)]
            sort_in[0] = data[0];
            sort_in[1] = data[1];
	          
            sort_in[2] = data[2];
            sort_in[3] = data[7];
	          
            sort_in[4] = data[3];
            sort_in[5] = data[5];
	          
            sort_in[6] = data[4];
            sort_in[7] = data[6];
	          
            sort_in[8] = data[8];
            sort_in[9] = data[9];
        end
        else if(cnt_sort == 'd4)begin
            //[(1,2),(3,4),(5,6),(7,8)]
            sort_in[0] = data[1];
            sort_in[1] = data[2];
                       
            sort_in[2] = data[3];
            sort_in[3] = data[4];
                       
            sort_in[4] = data[5];
            sort_in[5] = data[6];
                       
            sort_in[6] = data[7];
            sort_in[7] = data[8];
        end            
        else if(cnt_sort == 'd5)begin
            //[(1,3),(2,4),(5,7),(6,8)]
            sort_in[0] = data[1];
            sort_in[1] = data[3];
                       
            sort_in[2] = data[2];
            sort_in[3] = data[4];
                       
            sort_in[4] = data[5];
            sort_in[5] = data[7];
                       
            sort_in[6] = data[6];
            sort_in[7] = data[8];
        end            
        else if(cnt_sort == 'd6)begin
            //[(2,3),(4,5),(6,7)]
            sort_in[0] = data[2];
            sort_in[1] = data[3];
                       
            sort_in[2] = data[4];
            sort_in[3] = data[5];
                       
            sort_in[4] = data[6];
            sort_in[5] = data[7];
        end          
    end                   
end                        
                           
comp comp1(.in1(sort_in[0]), .in2(sort_in[1]), .out1(sort_out[0]), .out2(sort_out[1]));
comp comp2(.in1(sort_in[2]), .in2(sort_in[3]), .out1(sort_out[2]), .out2(sort_out[3]));
comp comp3(.in1(sort_in[4]), .in2(sort_in[5]), .out1(sort_out[4]), .out2(sort_out[5]));
comp comp4(.in1(sort_in[6]), .in2(sort_in[7]), .out1(sort_out[6]), .out2(sort_out[7]));
comp comp5(.in1(sort_in[8]), .in2(sort_in[9]), .out1(sort_out[8]), .out2(sort_out[9]));


// SORT fsm
always @(*) begin
    case (sort_state)
        ST_IDLE:   n_sort_state = (wready == 1 && wvalid == 1 && wdata == 1) ?  ST_WAIT : ST_IDLE;
        ST_WAIT:   n_sort_state = (ss_tvalid == 1) ? ST_SSIN : ST_WAIT;     // wait for Stream-In data
        ST_SSIN:begin
			if(ss_tready == 1 && cnt_in == 'd9)  n_sort_state = ST_SORT; // Get Stream-In data
			else if(ss_tready == 1)              n_sort_state = ST_WAIT;
			else                                 n_sort_state = ST_SSIN;
        end
		ST_SORT:   n_sort_state = (cnt_sort == 'd7) ? ST_OUT  : ST_SORT;     // SORT
        ST_OUT: begin
            if      (sm_tready == 1 &  cnt_out == 'd9)  n_sort_state = ST_IDLE; // reset
            else                                        n_sort_state = ST_OUT;  // wait for handshake
        end
        default: n_sort_state = sort_state;
    endcase
end

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n)    sort_state   <= ST_IDLE;
    else                sort_state   <= n_sort_state;
end

endmodule

module comp(
    input wire [31:0] in1,
    input wire [31:0] in2,
    output wire [31:0] out1,
    output wire [31:0] out2
);

assign out1 = (in1 > in2) ? in2 : in1;
assign out2 = (in1 > in2) ? in1 : in2;

endmodule
