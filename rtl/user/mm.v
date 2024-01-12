`timescale 1ns / 1ps
module mm
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

// MM fsm
localparam  ST_IDLE = 0,
            ST_WAIT = 1,
            ST_SSIN = 2,
			ST_MM   = 3,
            ST_OUT  = 4;

reg [2:0] mm_state, n_mm_state;

reg [31:0] axiwaddr, axiraddr;

reg [31:0] A[3:0][3:0];
reg [31:0] B[3:0][3:0];
reg [31:0] C[3:0][3:0];

reg [31:0] A00,A01,A02,A03,A10,A11,A12,A13,A20,A21,A22,A23,A30,A31,A32,A33,A40,A41,A42,A43;
reg [31:0] B00,B01,B02,B03,B10,B11,B12,B13,B20,B21,B22,B23,B30,B31,B32,B33,B40,B41,B42,B43;
reg [31:0] C00,C01,C02,C03,C10,C11,C12,C13,C20,C21,C22,C23,C30,C31,C32,C33,C40,C41,C42,C43;

reg [5:0] cnt_out;
reg [5:0] cnt_mm;
reg [5:0] cnt_in;

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
    if (mm_state == ST_SSIN)  ss_tready = 1;
    else                        ss_tready = 0;
end

// ======================= Stream-Out ===========================================
always @(*) begin
    if (mm_state == ST_OUT) begin
        sm_tvalid = 1;
        sm_tdata = C[0][0];
        sm_tlast = (cnt_out == 'd15);
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
    else if (mm_state == ST_SSIN)                                           n_ap_start = 0;         // Reset to 0, when 1st AXI-Stream handshake
    else                                                                    n_ap_start = ap_start;
end

// ap_idle
always @(*) begin
    if      (axiwaddr == 'h00 && wready == 1 && wvalid == 1 && wdata == 1)  n_ap_idle = 0;      // Host program ap_start = 1
    else if (mm_state == ST_OUT && cnt_out == 15 && sm_tready == 1)         n_ap_idle = 1;      // Reset to 1, when last data had axi-streamed out
    else                                                                    n_ap_idle = ap_idle;   
end

// ap_done
always @(*) begin
    if      (mm_state == ST_OUT && cnt_out == 15 && sm_tready == 1)   n_ap_done = 1;
    else if (mm_state == ST_SSIN)                                     n_ap_done = 0;
    else                                                                n_ap_done = ap_done;
end

// stream_in_ready, stream_out_ready
always @(*) begin
    stream_in_ready     = (mm_state == ST_WAIT);
    stream_out_ready    = (mm_state == ST_OUT);
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
        if      (mm_state == ST_IDLE)             cnt_out <= 0;
        else if (sm_tready == 1 && sm_tvalid == 1)  cnt_out <= cnt_out + 1;
    end
end

//stream input counter
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n)    cnt_in <= 0;
    else begin
        if      (mm_state == ST_IDLE)  cnt_in <= 0;
        else if (mm_state == ST_SSIN)  cnt_in <= cnt_in + 1;
    end
end

//sort counter
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n)    cnt_mm <= 0;
    else begin
        if      (mm_state == ST_IDLE) cnt_mm <= 0;
        else if (mm_state == ST_MM)   cnt_mm <= cnt_mm + 1;
    end
end

always @(*)begin
	A00 = A[0][0];
	A01 = A[0][1];
	A02 = A[0][2];
	A03 = A[0][3];
	A10 = A[1][0];
	A11 = A[1][1];
	A12 = A[1][2];
	A13 = A[1][3];
	A20 = A[2][0];
	A21 = A[2][1];
	A22 = A[2][2];
	A23 = A[2][3];
	A30 = A[3][0];
	A31 = A[3][1];
	A32 = A[3][2];
	A33 = A[3][3];
			 
	B00 = B[0][0];
	B01 = B[0][1];
	B02 = B[0][2];
	B03 = B[0][3];
	B10 = B[1][0];
	B11 = B[1][1];
	B12 = B[1][2];
	B13 = B[1][3];
	B20 = B[2][0];
	B21 = B[2][1];
	B22 = B[2][2];
	B23 = B[2][3];
	B30 = B[3][0];
	B31 = B[3][1];
	B32 = B[3][2];
	B33 = B[3][3];
	
	C00 = C[0][0];
	C01 = C[0][1];
	C02 = C[0][2];
	C03 = C[0][3];
	C10 = C[1][0];
	C11 = C[1][1];
	C12 = C[1][2];
	C13 = C[1][3];
	C20 = C[2][0];
	C21 = C[2][1];
	C22 = C[2][2];
	C23 = C[2][3];
	C30 = C[3][0];
	C31 = C[3][1];
	C32 = C[3][2];
	C33 = C[3][3];
end

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
		for (i=0; i<4; i=i+1) begin
			A[i][3] <= 0;
			A[i][2] <= 0;
			A[i][1] <= 0;
			A[i][0] <= 0;
				    
			B[i][3] <= 0;
			B[i][2] <= 0;
			B[i][1] <= 0;
			B[i][0] <= 0;
			
		end
    end 
	else begin
        if(mm_state == ST_SSIN && ss_tready == 1)begin
			B[3][3] <= ss_tdata;
			B[3][2] <= B[3][3];
			B[3][1] <= B[3][2];
			B[3][0] <= B[3][1];
			B[2][3] <= B[3][0];
			B[2][2] <= B[2][3];
			B[2][1] <= B[2][2];
			B[2][0] <= B[2][1];
			B[1][3] <= B[2][0];
			B[1][2] <= B[1][3];
			B[1][1] <= B[1][2];
			B[1][0] <= B[1][1];
			B[0][3] <= B[1][0];
			B[0][2] <= B[0][3];
			B[0][1] <= B[0][2];
			B[0][0] <= B[0][1];
					
			A[3][3] <= B[0][0];
			A[3][2] <= A[3][3];
			A[3][1] <= A[3][2];
			A[3][0] <= A[3][1];
			A[2][3] <= A[3][0];
			A[2][2] <= A[2][3];
			A[2][1] <= A[2][2];
			A[2][0] <= A[2][1];
			A[1][3] <= A[2][0];
			A[1][2] <= A[1][3];
			A[1][1] <= A[1][2];
			A[1][0] <= A[1][1];
			A[0][3] <= A[1][0];
			A[0][2] <= A[0][3];
			A[0][1] <= A[0][2];
			A[0][0] <= A[0][1];
		end
		else if(mm_state == ST_MM)begin
			A[0][0] <= A[1][0];
			A[0][1] <= A[1][1];
			A[0][2] <= A[1][2];
			A[0][3] <= A[1][3];
			A[1][0] <= A[2][0];
			A[1][1] <= A[2][1];
			A[1][2] <= A[2][2];
			A[1][3] <= A[2][3];
			A[2][0] <= A[3][0];
			A[2][1] <= A[3][1];
			A[2][2] <= A[3][2];
			A[2][3] <= A[3][3];
		end
    end
end

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
		for (i=0; i<4; i=i+1) begin
			for (j=0; j<4; j=j+1) begin
				C[i][j] <= 0;
			end
		end
    end 
	else begin
		if(mm_state == ST_MM)begin
			C[3][0] <= A[0][0]*B[0][0] + A[0][1]*B[1][0] + A[0][2]*B[2][0] + A[0][3]*B[3][0];
			C[3][1] <= A[0][0]*B[0][1] + A[0][1]*B[1][1] + A[0][2]*B[2][1] + A[0][3]*B[3][1];
			C[3][2] <= A[0][0]*B[0][2] + A[0][1]*B[1][2] + A[0][2]*B[2][2] + A[0][3]*B[3][2];
			C[3][3] <= A[0][0]*B[0][3] + A[0][1]*B[1][3] + A[0][2]*B[2][3] + A[0][3]*B[3][3];
			C[2][0] <= C[3][0];
			C[2][1] <= C[3][1];
			C[2][2] <= C[3][2];
			C[2][3] <= C[3][3];
			C[1][0] <= C[2][0];
			C[1][1] <= C[2][1];
			C[1][2] <= C[2][2];
			C[1][3] <= C[2][3];
			C[0][0] <= C[1][0];
			C[0][1] <= C[1][1];
			C[0][2] <= C[1][2];
			C[0][3] <= C[1][3];
		end 
		else if(mm_state == ST_OUT && sm_tready == 1 && sm_tvalid == 1)begin
			C[3][2] <= C[3][3];
			C[3][1] <= C[3][2];
			C[3][0] <= C[3][1];
			C[2][3] <= C[3][0];
			C[2][2] <= C[2][3];
			C[2][1] <= C[2][2];
			C[2][0] <= C[2][1];
			C[1][3] <= C[2][0];
			C[1][2] <= C[1][3];
			C[1][1] <= C[1][2];
			C[1][0] <= C[1][1];
			C[0][3] <= C[1][0];
			C[0][2] <= C[0][3];
			C[0][1] <= C[0][2];
			C[0][0] <= C[0][1];
		end
    end
end

// MM fsm
always @(*) begin
    case (mm_state)
        ST_IDLE:   n_mm_state = (wready == 1 && wvalid == 1 && wdata == 1) ?  ST_WAIT : ST_IDLE;
        ST_WAIT:   n_mm_state = (ss_tvalid == 1) ? ST_SSIN : ST_WAIT;     // wait for Stream-In data
        ST_SSIN:begin
			if(ss_tready == 1 && cnt_in == 'd31)  n_mm_state = ST_MM; // Get Stream-In data
			else if(ss_tready == 1)              n_mm_state = ST_WAIT;
			else                                 n_mm_state = ST_SSIN;
        end
		ST_MM:   n_mm_state = (cnt_mm == 'd3) ? ST_OUT  : ST_MM;     // MM
        ST_OUT: begin
            if      (sm_tready == 1 &  cnt_out == 'd15)  n_mm_state = ST_IDLE; // reset
            else                                        n_mm_state = ST_OUT;  // wait for handshake
        end
        default: n_mm_state = mm_state;
    endcase
end

always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n)    mm_state   <= ST_IDLE;
    else                mm_state   <= n_mm_state;
end

endmodule