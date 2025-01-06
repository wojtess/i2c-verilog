module i2c_slave (
	input wire clk,              //clock input
	input wire rst_n,            //asynchronous reset input, low active
    input wire pin_scl,
    inout wire pin_sda,
    output reg [7:0] addr,
    output reg [7:0] data_in,//data_in means into device not into module
    output reg data_in_ready,//when high means that `data_in` needs to be saved on `addr`
    input wire [7:0] data_out,//data_out means out from device not out from module         NOT IMPLEMENTED
    output reg data_out_en,//high when expected value at address `addr` on data_out        NOT IMPLEMENTED
    input wire data_out_ready//when high can transfer data on i2c                          NOT IMPLEMENTED
);

reg sda_out;
assign pin_sda = sda_out ? 1'bz : 1'b0;

wire pin_scl_synced;
wire pin_sda_synced;

sync_pin sync_pin_scl(
    .pin(pin_scl),
    .clk(clk),
    .rst_n(rst_n),
    .pin_synced(pin_scl_synced)
);

sync_pin sync_pin_sda(
    .pin(pin_sda),
    .clk(clk),
    .rst_n(rst_n),
    .pin_synced(pin_sda_synced)
);

reg [5:0] state;
reg [5:0] next_state;
localparam IDLE = 5'b00000;
localparam RECIVING_ADDRESS = 5'b00001;
localparam RECIVING_DATA = 5'b00010;
localparam RECIVING_ADDRESS_ACK = 5'b00100;
localparam RECIVING_DATA_ACK = 5'b01000;

reg prev_sda;
reg prev_scl;

reg [2:0] counter; //counter is used for counting bits of recived address and data

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_sda = 1'b0;
        prev_scl = 1'b0;
        sda_out <= 1'b1;
        next_state <= IDLE;
        addr <= 8'b0;
        counter <= 3'b0;
        data_in <= 8'b0;
        data_in_ready <= 1'b0;
    end
    else begin
        prev_sda <= pin_sda_synced;
        prev_scl <= pin_scl_synced;
        
        if(state == IDLE) begin
            //START condition detected
            if((prev_sda == 1'b1 && pin_sda_synced == 1'b0) /* falling edge sda */ && (prev_scl == 1'b1 && pin_scl_synced == 1'b1) /* scl equals 1 */ ) begin
                next_state <= RECIVING_ADDRESS;
                counter <= 3'b111;
            end
        end
        if(state == RECIVING_ADDRESS) begin
            if(prev_scl == 1'b0 && pin_scl_synced == 1'b1 /* rising edge scl */) begin
                addr[counter] <= pin_sda_synced;
                counter <= counter - 1;
                if(counter == 0) begin
                    next_state <= RECIVING_ADDRESS_ACK;
                end
            end
        end
        if(state == RECIVING_DATA) begin
            if(pin_scl_synced == 1'b1 && (prev_sda == 1'b0 && pin_sda_synced == 1'b1)) begin
                next_state <= IDLE;
            end else if(prev_scl == 1'b0 && pin_scl_synced == 1'b1 /* rising edge scl */) begin
                data_in[counter] <= pin_sda_synced;
                counter <= counter - 1;
                if(counter == 0) begin
                    next_state <= RECIVING_DATA_ACK;
                    data_in_ready <= 1'b1;
                    addr <= addr + 8'b1;
                end
            end
        end

        if(data_in_ready == 1'b1) begin
            data_in_ready <= 1'b0;
        end

        //ACK
        if(prev_scl == 1'b1 && pin_scl_synced == 1'b0 && (state == RECIVING_ADDRESS_ACK || state == RECIVING_DATA_ACK)) begin
            sda_out <= 1'b0;
        end
        if(prev_scl == 1'b1 && pin_scl_synced == 1'b0/* falling edge scl */ && sda_out == 1'b0) begin
            sda_out <= 1'b1;
            if(state == RECIVING_ADDRESS_ACK || state == RECIVING_DATA_ACK) begin
                next_state <= RECIVING_DATA;
            end
        end
    end
end

endmodule

module sync_pin(
    input wire pin,
    input wire clk,
    input wire rst_n,
    output reg pin_synced
);

reg pin_metastable1;
reg pin_metastable2;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pin_metastable1 <= 1'b0;
        pin_metastable2 <= 1'b0;
        pin_synced <= 1'b0;
    end else begin
        pin_metastable1 <= pin;
        pin_metastable2 <= pin_metastable1;
        pin_synced <= pin_metastable2;
    end
end

endmodule