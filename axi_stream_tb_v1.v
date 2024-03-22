`timescale 1ns / 1ps

module axi_stream_tb_v1;


    parameter DATA_WD = 32;
    parameter DATA_BYTE_WD = DATA_WD/8;
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);


    reg clk;
    reg rst_n;


    wire valid_in;
    wire [DATA_WD-1:0] data_in;
    wire [DATA_BYTE_WD-1:0] keep_in;
    wire las_in;

    wire valid_insert;
    wire [DATA_WD-1:0] data_insert;
    wire [DATA_BYTE_WD-1:0] keep_insert;
    wire [BYTE_CNT_WD:0] byte_insert_cnt;


    wire ready_in;
    wire valid_out;
    wire [DATA_WD-1:0] data_out;
    wire [DATA_BYTE_WD-1:0] keep_out;
    wire last_out;
    reg ready_out;


    axi_input #(
        .DATA_WD(DATA_WD),
        .DATA_BYTE_WD(DATA_BYTE_WD),
        .BYTE_CNT_WD(BYTE_CNT_WD)
    ) gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .keep_in(keep_in),
        .las_in(las_in),
        .valid_insert(valid_insert),
        .data_insert(data_insert),
        .keep_insert(keep_insert),
        .byte_insert_cnt(byte_insert_cnt)
    );


    axi_stream_insert_header_v3 #(
        .DATA_WD(DATA_WD)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .keep_in(keep_in),
        .las_in(las_in),
        .ready_in(ready_in),
        .valid_out(valid_out),
        .data_out(data_out),
        .keep_out(keep_out),
        .last_out(last_out),
        .ready_out(ready_out),
        .valid_insert(valid_insert),
        .data_insert(data_insert),
        .keep_insert(keep_insert),
        .byte_insert_cnt(byte_insert_cnt),
        .ready_insert()
    );

    initial begin

        clk = 0;
        rst_n = 0;
        ready_out = 1; 

      
        #105;
         rst_n = 1;  

    end


    always #5 clk = ~clk;

endmodule
