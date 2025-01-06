module i2c_slave_tb;
initial
begin
    $dumpfile("i2c_slave_tb.vcd");
    $dumpvars(0, i2c_slave_tb);
end
reg reset_n = 1;

reg clk = 0;
always #1 clk = !clk;

reg pin_scl;
reg pin_sda_out;
reg pin_sda_out_en;
wire pin_sda;
assign pin_sda = pin_sda_out_en ? pin_sda_out : 1'bz;
wire[7:0] addr;
wire[7:0] data_in;
wire data_in_ready;

i2c_slave tested_module(
    .clk(clk),
    .rst_n(reset_n),
    .pin_scl(pin_scl),
    .pin_sda(pin_sda),
    .addr(addr),
    .data_in(data_in),//Data IN device
    .data_in_ready(data_in_ready)
);

task START;
begin
    pin_sda_out_en = 1;
    pin_scl = 1;
    pin_sda_out = 1;
    #10 pin_sda_out = 0;
    #10 pin_scl = 0;
end
endtask

task STOP;
begin
    pin_sda_out_en = 1;
    pin_sda_out = 0;
    pin_scl = 1;
    #10 pin_sda_out = 1;
end
endtask

task ZERO;
begin
    pin_sda_out_en = 1;
    #1 pin_sda_out = 0;
    #9 pin_scl = 1;
    #10 pin_scl = 0;
end
endtask

task ONE;
begin
    pin_sda_out_en = 1;
    #1 pin_sda_out = 1;
    #9 pin_scl = 1;
    #10 pin_scl = 0;
end
endtask

task ACK;
input integer num;
begin
    pin_sda_out = 1'bz;//so it easier to see when pin_sda_out_en = 0
    pin_sda_out_en = 0;
    #10 pin_scl = 1;
    if (pin_sda !== 0) begin
        $display("  Recived NACK when expected ACK(%0d)", num);//it looks better than error in my opinion
    end else begin
        $display("  Recived ACK as expected(%0d)", num);
    end
    #10 pin_scl = 0;
    #10 pin_sda_out_en = 1;
end
endtask

always @(posedge data_in_ready) begin
    $display("  recived data: %b, recived address: %b", data_in, addr);
end

task SEND_DATA;
input integer exec_num;
begin
    $display("Starting execution %0d", exec_num);

    pin_sda_out_en = 1;

    START();

    ZERO();
    ZERO();
    ONE();
    ONE();
    ZERO();
    ONE();
    ZERO();
    ONE();//WRITE

    ACK(1);
    
    ZERO();
    ONE();
    ONE();
    ONE();
    ZERO();
    ONE();
    ZERO();
    ONE();

    ACK(2);

    ZERO();
    ONE();
    ONE();
    ONE();
    ZERO();
    ONE();
    ZERO();
    ZERO();

    ACK(3);

    STOP();

    $display("Ended execution %0d", exec_num);
end
endtask

initial
begin
    reset_n = 0;
    #10 reset_n = 1;
    
    SEND_DATA(1);
    SEND_DATA(2);

    #40 $finish;
end
endmodule