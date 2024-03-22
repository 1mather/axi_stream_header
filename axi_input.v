`timescale 1ns / 1ps

module axi_input #(
    parameter DATA_WD = 32, // Data width
    parameter DATA_BYTE_WD = DATA_WD/8, // Byte width of data
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD) // Bit width to count bytes
)(
    output reg valid_in,
    output reg [DATA_WD-1:0] data_in,
    output reg [DATA_BYTE_WD-1:0] keep_in,
    output reg las_in,

    output reg valid_insert,
    output reg [DATA_WD-1:0] data_insert,
    output reg [DATA_BYTE_WD-1:0] keep_insert,
    output reg [BYTE_CNT_WD:0] byte_insert_cnt,

    input wire clk,
    input wire rst_n
);

reg  [BYTE_CNT_WD:0] r_byte_insert_cnt;
reg[4:0]cnt;
//reg r_valid_in;   reg r_valid_insert;
initial begin
    valid_in = 0;
    data_in =  $random;
    keep_in = 0;
    las_in = 0;

    valid_insert = 0;
    data_insert = $random;
    keep_insert = 0;
    byte_insert_cnt = 3; // Assuming a default byte insert count

end

always @(posedge clk) begin
r_byte_insert_cnt<= $random % DATA_BYTE_WD + 1;
end
always @(posedge clk) begin
    if (!rst_n) begin
        // Reset signal behavior
        valid_in <= 0;
        valid_insert <= 0;
        las_in <= 0;
    end
    else begin
        // Simulate data_in input behavior
        valid_in <= 1;
 //       data_in <= $random; // Random data generation
 //       keep_in <= DATA_BYTE_WD - 1; // Assuming some bytes are valid for simplicity        
        
        
        // Simulate data_insert input behavior
        valid_insert <= 1;
//        data_insert <= $random; // Random data generation
//        keep_insert <= DATA_BYTE_WD - 1; // Assuming some bytes are valid for simplicity
     // Randomly select byte insert count

end
end

always @(posedge clk) begin
 
    if(valid_in&~las_in)begin
        data_in <= $random; // Random data generation
       
             case ($random % 4) // 产生一个0到3之间的随机数
            0: keep_in <= 4'b1111; // 全部有效
            1: keep_in <= 4'b1110; // 最低位无效
            2: keep_in <= 4'b1100; // 低两位无效
            3: keep_in <= 4'b1000; // 低三位无效
            // 不需要default因为所有情况都已覆盖
            endcase  
    end
end


always @(posedge clk) begin
 
    if(valid_insert&las_in)begin
     data_insert <= $random; // Random data generation
             case ($random % 4) // 产生一个0到3之间的随机数
            0: keep_insert <= 4'b1111; // 全部有效
            1: keep_insert <= 4'b1110; // 最低位无效
            2: keep_insert <= 4'b1100; // 低两位无效
            3: keep_insert <= 4'b1000; // 低三位无效
            // 不需要default因为所有情况都已覆盖
             endcase
    end
end


always @(posedge clk) begin
    cnt=5;
    if(cnt== $random%10)begin
    las_in<=1;
        if((r_byte_insert_cnt>0)&&(r_byte_insert_cnt<=4))begin
        byte_insert_cnt <= r_byte_insert_cnt;        
        end
    end
end
always @(posedge clk) begin
    if(las_in==1)begin
    las_in<=0;
    end
end
    



endmodule
