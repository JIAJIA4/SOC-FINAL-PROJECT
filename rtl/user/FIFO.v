module FIFO #(parameter DSIZE = 8,
			   parameter ASIZE = 3)(
	//Input Port
	rst_n,
	clk,
    //Input Port (read)
    ren,
	//Input Port (write)
    wen,
	wdata,

    //Output Port (read)
    rempty,
	rdata,
    //Output Port (write)
    wfull
);

//-----------------------------------------------------------------------------------------------------------------
//   PORT DECLARATION                                                  
//-----------------------------------------------------------------------------------------------------------------
input wire             rst_n, clk, ren, wen;
input wire [DSIZE-1:0] wdata;

output wire              rempty;
output wire              wfull;
output wire  [DSIZE-1:0] rdata;

//-----------------------------------------------------------------------------------------------------------------
//   LOGIC DECLARATION                                                 
//-----------------------------------------------------------------------------------------------------------------
integer i;
localparam DEPTH = 1<<ASIZE;

reg [DSIZE-1:0] mem[DEPTH-1:0];
wire [DSIZE-1:0] mem_w0,mem_w1,mem_w2,mem_w3,mem_w4,mem_w5,mem_w6,mem_w7;

reg [ASIZE-1:0] waddr, raddr;
reg [ASIZE:0]   fifo_cnt;

//-----------------------------------------------------------------------------------------------------------------
//   Design                                                            
//-----------------------------------------------------------------------------------------------------------------

assign rdata = mem[raddr];
assign rempty = (fifo_cnt == 0);
assign wfull  = (fifo_cnt == DEPTH);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		fifo_cnt <= 0;
	end
	else begin
		if(!wfull && wen)begin
			fifo_cnt <= fifo_cnt + 1;
		end
		else if(!rempty && ren)begin
			fifo_cnt <= fifo_cnt - 1;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for (i=0; i<DEPTH; i=i+1) begin
            mem[i] <= 0;
        end
	end
	else begin
		if(wen && !wfull)begin
			mem[waddr] <= wdata;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		waddr <= 0;
	end
	else begin
		if(wen)begin
			if(waddr == (DEPTH-1))begin
				waddr <= 0;
			end
			else begin
				waddr <= waddr + 1;
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		raddr <= 0;
	end
	else begin
		if(ren && !rempty)begin
			if(raddr == (DEPTH-1))begin
				raddr <= 0;
			end
			else begin
				raddr <= raddr + 1;
			end
		end
	end
end

assign mem_w0 = mem[0];
assign mem_w1 = mem[1];
assign mem_w2 = mem[2];
assign mem_w3 = mem[3];
assign mem_w4 = mem[4];
assign mem_w5 = mem[5];
assign mem_w6 = mem[6];
assign mem_w7 = mem[7];

endmodule

