//AHB TO APB BRIDGE
//By:T.Anushka

module APB_FSM_Controller(
    Hclk,Hresetn,valid,Haddr1,Haddr2,Hwdata1,Hwdata2,Prdata,
    Hwrite,Haddr,Hwdata,Hwritereg,tempselx,
    Pwrite,Penable,Pselx,Paddr,Pwdata,Hreadyout
);

input Hclk,Hresetn,valid,Hwrite,Hwritereg;
input [31:0] Hwdata,Haddr,Haddr1,Haddr2,Hwdata1,Hwdata2,Prdata;
input [2:0] tempselx;

output reg Pwrite,Penable,Hreadyout;
output reg [2:0] Pselx;
output reg [31:0] Paddr,Pwdata;

parameter ST_IDLE     = 3'b000,
          ST_WWAIT    = 3'b001,
          ST_READ     = 3'b010,
          ST_WRITE    = 3'b011,
          ST_WRITEP   = 3'b100,
          ST_RENABLE  = 3'b101,
          ST_WENABLE  = 3'b110,
          ST_WENABLEP = 3'b111;

reg [2:0] PRESENT_STATE,NEXT_STATE;

always @(posedge Hclk) begin
    if (~Hresetn)
        PRESENT_STATE <= ST_IDLE;
    else
        PRESENT_STATE <= NEXT_STATE;
end

always @(*) begin
    case (PRESENT_STATE)

        ST_IDLE:
            if (~valid)
                NEXT_STATE = ST_IDLE;
            else if (valid && Hwrite)
                NEXT_STATE = ST_WWAIT;
            else
                NEXT_STATE = ST_READ;

        ST_WWAIT:
            if (~valid)
                NEXT_STATE = ST_WRITE;
            else
                NEXT_STATE = ST_WRITEP;

        ST_READ:
            NEXT_STATE = ST_RENABLE;

        ST_WRITE:
            if (~valid)
                NEXT_STATE = ST_WENABLE;
            else
                NEXT_STATE = ST_WENABLEP;

        ST_WRITEP:
            NEXT_STATE = ST_WENABLEP;

        ST_RENABLE:
            if (~valid)
                NEXT_STATE = ST_IDLE;
            else if (valid && Hwrite)
                NEXT_STATE = ST_WWAIT;
            else
                NEXT_STATE = ST_READ;

        ST_WENABLE:
            if (~valid)
                NEXT_STATE = ST_IDLE;
            else if (valid && Hwrite)
                NEXT_STATE = ST_WWAIT;
            else
                NEXT_STATE = ST_READ;

        ST_WENABLEP:
            if (~valid && Hwritereg)
                NEXT_STATE = ST_WRITE;
            else if (valid && Hwritereg)
                NEXT_STATE = ST_WRITEP;
            else
                NEXT_STATE = ST_READ;

        default:
            NEXT_STATE = ST_IDLE;
    endcase
end

reg Penable_temp,Hreadyout_temp,Pwrite_temp;
reg [2:0] Pselx_temp;
reg [31:0] Paddr_temp,Pwdata_temp;

always @(*) begin

    Paddr_temp     = Paddr;
    Pwdata_temp    = Pwdata;
    Pwrite_temp    = Pwrite;
    Pselx_temp     = Pselx;
    Penable_temp   = 1'b0;
    Hreadyout_temp = 1'b1;

    case(PRESENT_STATE)

        ST_IDLE: begin
            if (valid && ~Hwrite) begin
                Paddr_temp = Haddr;
                Pwrite_temp = Hwrite;
                Pselx_temp = tempselx;
                Penable_temp = 1'b0;
                Hreadyout_temp = 1'b0;
            end
            else if (valid && Hwrite) begin
                Pselx_temp = 3'b000;
                Penable_temp = 1'b0;
                Hreadyout_temp = 1'b1;
            end
            else begin
                Pselx_temp = 3'b000;
                Penable_temp = 1'b0;
                Hreadyout_temp = 1'b1;
            end
        end

        ST_WWAIT: begin
            Paddr_temp = Haddr1;
            Pwrite_temp = 1'b1;
            Pselx_temp = tempselx;
            Penable_temp = 1'b0;
            Pwdata_temp = Hwdata;
            Hreadyout_temp = 1'b0;
        end

        ST_READ: begin
            Penable_temp = 1'b1;
            Hreadyout_temp = 1'b1;
        end

        ST_WRITE: begin
            Penable_temp = 1'b1;
            Hreadyout_temp = 1'b1;
        end

        ST_WRITEP: begin
            Penable_temp = 1'b1;
            Hreadyout_temp = 1'b1;
        end

        ST_RENABLE: begin
            if (valid && ~Hwrite) begin
                Paddr_temp = Haddr;
                Pwrite_temp = Hwrite;
                Pselx_temp = tempselx;
                Penable_temp = 1'b0;
                Hreadyout_temp = 1'b0;
            end
            else if (valid && Hwrite) begin
                Pselx_temp = 3'b000;
                Penable_temp = 1'b0;
                Hreadyout_temp = 1'b1;
            end
            else begin
                Pselx_temp = 3'b000;
                Penable_temp = 1'b0;
                Hreadyout_temp = 1'b1;
            end
        end

        ST_WENABLEP: begin
            Paddr_temp = Haddr2;
            Pwrite_temp = Hwritereg;
            Pselx_temp = tempselx;
            Penable_temp = 1'b0;
            Pwdata_temp = Hwdata;
            Hreadyout_temp = 1'b0;
        end

        ST_WENABLE: begin
            Pselx_temp = 3'b000;
            Penable_temp = 1'b0;
            Hreadyout_temp = 1'b0;
        end

        default: begin
            Pselx_temp = 3'b000;
            Penable_temp = 1'b0;
            Hreadyout_temp = 1'b1;
        end
    endcase
end

always @(posedge Hclk) begin
    if (~Hresetn) begin
        Paddr <= 32'b0;
        Pwrite <= 1'b0;
        Pselx <= 3'b000;
        Pwdata <= 32'b0;
        Penable <= 1'b0;
        Hreadyout <= 1'b0;
    end
    else begin
        Paddr <= Paddr_temp;
        Pwrite <= Pwrite_temp;
        Pselx <= Pselx_temp;
        Pwdata <= Pwdata_temp;
        Penable <= Penable_temp;
        Hreadyout <= Hreadyout_temp;
    end
end

endmodule
