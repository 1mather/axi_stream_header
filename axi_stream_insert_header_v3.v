`timescale 1ns / 1ps
module axi_stream_insert_header_v3#(
    parameter                   DATA_WD=32,
    parameter                   DATA_BYTE_WD=DATA_WD/8,
    parameter                   BYTE_CNT_WD=$clog2(DATA_BYTE_WD)
)(
    input clk,
    input rst_n,
    
    //axi input orginal data
    input                       valid_in,
    input [DATA_WD-1:0]         data_in,
    input [DATA_BYTE_WD-1:0]    keep_in,
    input                       las_in,
    output                      ready_in,       //control r6
    //axi  output with header inseted
    output                      valid_out,      //control r1
    output [DATA_WD-1:0]        data_out,       //control r2
    output [DATA_BYTE_WD-1:0]   keep_out,       //control r3  
    output                      last_out,       //control r4
    input                       ready_out,      
    //header input to be inserted to axi stream
    input                       valid_insert,
    input [DATA_WD-1:0]         data_insert,
    input [DATA_BYTE_WD-1:0]    keep_insert,
    input [BYTE_CNT_WD:0]       byte_insert_cnt,
    output                      ready_insert    //control r5
);
    /*********************register*****************************/
    

    /*------------ data_out 2 data_in----------*/                                     
    reg                         r_ready_in;    
    /*------------ data_out 2 insert_in--------*/
    reg                         r_ready_insert;
    
    /*------------ data_out output------------*/  
    reg [DATA_WD-1:0]           r_data_out;
    reg [DATA_BYTE_WD-1:0]      r_keep_out;
    reg                         r_last_out;        
    reg                         r_valid_out;

    

    //reg                     r_byte_insert_cnt;   //store the value of insert_cnt

    

                        
    reg                         las_in_delay_1;
    reg [DATA_WD-1:0]           data_in_delay_1;   
    reg [DATA_BYTE_WD-1:0]      keep_in_delay_1;    
    reg                         las_in_delay;
    reg [DATA_WD-1:0]           data_in_delay;   //data_in from the former circle
    reg [DATA_BYTE_WD-1:0]      keep_in_delay;  //which will be used in compensatory burst

    reg                         count;          //a flag of the first transfer of data'1'
    reg                         compens;        // a flag of the compensatory transfer
    reg [BYTE_CNT_WD:0]         byte_in_cnt;
    reg [BYTE_CNT_WD:0]         byte_insert_cnt_temp;
    reg [BYTE_CNT_WD:0]         r_byte_insert_cnt;
    /****************************connection******************************/
    
    assign valid_out    =   r_valid_out;
    assign data_out     =   r_data_out;
    assign keep_out     =   r_keep_out;
    assign last_out     =   r_last_out;
    assign ready_insert =   r_ready_insert;

    assign ready_in     =   r_ready_in;
    /*********************combinational path*****************************/  
    integer i;
    always @(*) begin
        byte_in_cnt = 0;
        for (i = 0; i < DATA_BYTE_WD; i = i + 1) begin
            byte_in_cnt = byte_in_cnt + keep_in[i];
        end
    end
    
    always @(*) begin
        byte_insert_cnt_temp=byte_insert_cnt;
    end
    
    

    /*********************sequential data path*****************************/  
    
    always@(posedge clk)begin
    if (!rst_n) begin
    r_byte_insert_cnt=0; 
    end  
    else if(valid_insert&ready_insert)begin
    r_byte_insert_cnt=byte_insert_cnt_temp;
    end
    end
    
    
    
/****************************************data_out**************************************************/
/*------first cyle------- */

always @(posedge clk) begin
    if (!rst_n) begin
        r_data_out <= 0;
        count<=0;
    end 
    else if (valid_insert&r_valid_out&ready_out&~las_in&~count&~compens&~las_in_delay_1) begin
        r_keep_out<={(DATA_WD/8){1'b1}};
               count<=1;
        case (r_byte_insert_cnt)
            1: begin
                if(DATA_WD>=16)begin  
                r_data_out <= {data_in[DATA_WD-9:0], data_insert[DATA_WD-1:DATA_WD-8]};
                 end
                else
                r_data_out <=  data_insert;  
            end
        
            2: begin
                if(DATA_WD>=32)begin
                r_data_out <= {data_in[DATA_WD-17:0], data_insert[DATA_WD-1:DATA_WD-16]};
                end
                else
                r_data_out <=  data_insert;
            end
            3: begin
                if(DATA_WD>=32)begin
                r_data_out <= {data_in[DATA_WD-25:0], data_insert[DATA_WD-1:DATA_WD-24]};
                end
                else
                r_data_out <=  data_insert;
            end
            4: begin
                if(DATA_WD>=64)begin
                r_data_out <= {data_in[DATA_WD-33:0], data_insert[DATA_WD-1:DATA_WD-32]};
                end
                else
                r_data_out <=  data_insert;
            end
            5:begin
                if(DATA_WD>=64)begin
                r_data_out <= {data_in[DATA_WD-41:0], data_insert[DATA_WD-1:DATA_WD-40]};
                end
                else
                r_data_out <=  data_insert;
            end
            6:begin
                if(DATA_WD>=64)begin
                r_data_out <= {data_in[DATA_WD-49:0], data_insert[DATA_WD-1:DATA_WD-48]};
                end
                else
                r_data_out <=  data_insert;
            end
            7: begin
                if(DATA_WD>=64)begin
                r_data_out <= {data_in[DATA_WD-57:0], data_insert[DATA_WD-1:DATA_WD-56]};
                end
                else
                r_data_out <=  data_insert;
            end
            8: begin
                if(DATA_WD>=64)begin
                r_data_out <=  data_insert;
                end
            end
            default: r_data_out <=  data_insert;
        endcase
    end
    
//end

/*------middle cycle------- */
/* always @(posedge clk) begin
    if (!rst_n) begin
        r_data_out <= 0;
    end  */
    else if (r_valid_out&ready_out&~las_in&~compens&count) begin
        r_keep_out <= {(DATA_WD/8){1'b1}};
        
        case (r_byte_insert_cnt)        
            1: begin
                if (DATA_WD >= 16) begin
                    r_data_out <= {data_in[DATA_WD-9:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                end else begin
                    r_data_out <= data_in_delay;
                end
            end
            2: begin
                if (DATA_WD >= 32) begin
                    r_data_out <= {data_in[DATA_WD-17:0], data_in_delay_1[DATA_WD-1:DATA_WD-16]};
                end else begin
                    r_data_out <= data_in_delay;
                end
            end
            3: begin
                if (DATA_WD >= 32) begin
                    r_data_out <= {data_in[DATA_WD-25:0], data_in_delay_1[DATA_WD-1:DATA_WD-24]};
                end else begin
                    r_data_out <= data_in_delay;
                end
            end
            4: begin
                if (DATA_WD >= 64) begin
                    r_data_out <= {data_in[DATA_WD-33:0], data_in_delay_1[DATA_WD-1:DATA_WD-32]};
                end else begin
                    r_data_out <= data_in_delay;
                end
            end
            5: begin
                if (DATA_WD >= 64) begin
                    r_data_out <= {data_in[DATA_WD-41:0], data_in_delay_1[DATA_WD-1:DATA_WD-40]};
                end else begin
                    r_data_out <= data_in_delay;
                end
            end
            6: begin
                if (DATA_WD >= 64) begin
                    r_data_out <= {data_in[DATA_WD-49:0], data_in_delay_1[DATA_WD-1:DATA_WD-48]};
                end else begin
                    r_data_out <= data_in_delay;
                end
            end
            7: begin
                if (DATA_WD >= 64) begin
                    r_data_out <= {data_in[DATA_WD-57:0], data_in_delay_1[DATA_WD-1:DATA_WD-56]};
                end else begin
                    r_data_out <= data_in_delay;
                end
            end
            8: begin
                r_data_out <= data_in_delay_1;
            end
            default: r_data_out <= data_in_delay_1;
        endcase
    end
end

/*------last cycle------- */
always @(posedge clk) begin
    if (!rst_n) begin
        r_data_out <= 0;
    end else if (r_valid_out & ready_out & las_in & ~compens) begin
        if (DATA_BYTE_WD < byte_insert_cnt + byte_in_cnt) begin ////////////not yet
            r_keep_out <= {(DATA_WD/8){1'b1}};
            if (count == 1) begin
                compens <= 1;
            end
            case (r_byte_insert_cnt)
                1: begin
                    if (DATA_WD >= 16) begin
                        r_data_out <= {data_in[DATA_WD-9:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                    end else begin
                        r_data_out <= data_in_delay;
                    end
                end
                2: begin
                    if (DATA_WD >= 32) begin
                        r_data_out <= {data_in[DATA_WD-17:0], data_in_delay_1[DATA_WD-1:DATA_WD-16]};
                    end else begin
                        r_data_out <= data_in_delay;
                    end
                end
                3: begin
                    if (DATA_WD >= 32) begin
                        r_data_out <= {data_in[DATA_WD-25:0], data_in_delay_1[DATA_WD-1:DATA_WD-24]};
                    end else begin
                        r_data_out <= data_in_delay;
                    end
                end
                4: begin
                    if (DATA_WD >= 64) begin
                        r_data_out <= {data_in[DATA_WD-33:0], data_in_delay_1[DATA_WD-1:DATA_WD-32]};
                    end else begin
                        r_data_out <= data_in_delay;
                    end
                end
                5: begin
                    if (DATA_WD >= 64) begin
                        r_data_out <= {data_in[DATA_WD-41:0], data_in_delay_1[DATA_WD-1:DATA_WD-40]};
                    end else begin
                        r_data_out <= data_in_delay;
                    end
                end
                6: begin
                    if (DATA_WD >= 64) begin
                        r_data_out <= {data_in[DATA_WD-49:0], data_in_delay_1[DATA_WD-1:DATA_WD-48]};
                    end else begin
                        r_data_out <= data_in_delay;
                    end
                end
                7: begin
                    if (DATA_WD >= 64) begin
                        r_data_out <= {data_in[DATA_WD-57:0], data_in_delay_1[DATA_WD-1:DATA_WD-56]};
                    end else begin
                        r_data_out <= data_in_delay;
                    end
                end
                8: begin
                    r_data_out <= data_in_delay;
                end
                default: r_data_out <= data_in_delay;
            endcase
        end 

        else ////finished
        begin
            r_last_out<=1;
            count <= 0;
            case (r_byte_insert_cnt)
                1: begin
                    case (byte_in_cnt)
                        1: begin
                            if(DATA_WD >= 16) begin
                                r_data_out <= {{(DATA_WD-16){1'b0}}, data_in[7:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                                r_keep_out <= {{((DATA_WD-16)/8){1'b0}}, {1{1'b1}}, {1{1'b1}}};
                            end else begin

                            end
                        
                        end 
                        2: begin
                            if(DATA_WD >= 32) begin
                                r_data_out <= {{(DATA_WD-24){1'b0}}, data_in[15:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                                r_keep_out <= {{((DATA_WD-24)/8){1'b0}}, {2{1'b1}}, {1{1'b1}}};
                            end else begin
                                //r_data_out <= {data_in[7:0], data_in_delay[DATA_WD-1:DATA_WD-8]};
                                //r_keep_out <= {{1{1'b1}}, {1{1'b1}}};
                            end
                        end
                        3: begin
                            if(DATA_WD >= 32) begin
                                r_data_out <= {{(DATA_WD-32){1'b0}}, data_in[23:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                                r_keep_out <= {{((DATA_WD-32)/8){1'b0}}, {3{1'b1}}, {1{1'b1}}};
                            end else begin
                                //r_data_out <= {data_in[7:0], data_in_delay[DATA_WD-1:DATA_WD-8]};
                                //r_keep_out <= {{3{1'b1}}, {1{1'b1}}};
                            end
                        end
                        4: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-40){1'b0}}, data_in[31:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                                r_keep_out <= {{((DATA_WD-40)/8){1'b0}}, {4{1'b1}}, {1{1'b1}}};
                            end else begin
                                //r_data_out <= {data_in[7:0], data_in_delay[DATA_WD-1:DATA_WD-8]};
                                //r_keep_out <= {{4{1'b1}}, {1{1'b1}}};
                            end
                        end
                        5: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-48){1'b0}}, data_in[39:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                                r_keep_out <= {{((DATA_WD-48)/8){1'b0}}, {5{1'b1}}, {1{1'b1}}};
                            end else begin
                                //r_data_out <= {data_in[7:0], data_in_delay[DATA_WD-1:DATA_WD-8]};
                                //r_keep_out <= {{5{1'b1}}, {1{1'b1}}};
                            end
                        end
                        6: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-56){1'b0}}, data_in[47:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                                r_keep_out <= {{((DATA_WD-56)/8){1'b0}}, {6{1'b1}}, {1{1'b1}}};
                            end else begin
                                //r_data_out <= {data_in[7:0], data_in_delay[DATA_WD-1:DATA_WD-8]};
                                //r_keep_out <= {{1{1'b1}}, {1{1'b1}}};
                            end
                        end
                        7: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {data_in[55:0], data_in_delay_1[DATA_WD-1:DATA_WD-8]};
                                r_keep_out <= {{((DATA_WD-64)/8){1'b0}}, {6{1'b1}}, {2{1'b1}}};
                            end else begin
                                //r_data_out <= {data_in[7:0], data_in_delay[DATA_WD-1:DATA_WD-8]};
                                //r_keep_out <= {{1{1'b1}}, {1{1'b1}}};
                            end
                        end
                    endcase                
                end
                2: begin
                    case (byte_in_cnt)
                        1: begin
                            if(DATA_WD >= 32) begin
                                r_data_out <= {{(DATA_WD-24){1'b0}}, data_in[7:0], data_in_delay_1[DATA_WD-1:DATA_WD-16]};
                                r_keep_out <= {{((DATA_WD-24)/8){1'b0}}, {1{1'b1}}, {2{1'b1}}};
                            end else begin
                                
                            end
                        end
                        2: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-32){1'b0}}, data_in[15:0], data_in_delay_1[DATA_WD-1:DATA_WD-16]};
                                r_keep_out <= {{((DATA_WD-32)/8){1'b0}}, {2{1'b1}}, {2{1'b1}}};
                            end else begin
                                
                            end
                        end
                        3: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-40){1'b0}}, data_in[23:0], data_in_delay_1[DATA_WD-1:DATA_WD-16]};
                                r_keep_out <= {{((DATA_WD-40)/8){1'b0}}, {3{1'b1}}, {2{1'b1}}};
                            end else begin
                            end
                        end
                        4: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-48){1'b0}}, data_in[31:0], data_in_delay_1[DATA_WD-1:DATA_WD-16]};
                                r_keep_out <= {{((DATA_WD-48)/8){1'b0}}, {4{1'b1}}, {2{1'b1}}};
                            end else begin
                            end
                        end
                        5: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-56){1'b0}}, data_in[39:0], data_in_delay_1[DATA_WD-1:DATA_WD-16]};
                                r_keep_out <= {{((DATA_WD-56)/8){1'b0}}, {5{1'b1}}, {2{1'b1}}};
                            end else begin
                            end
                        end
                        6: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-64){1'b0}}, data_in[47:0], data_in_delay_1[DATA_WD-1:DATA_WD-16]};
                                r_keep_out <= {{((DATA_WD-64)/8){1'b0}}, {6{1'b1}}, {2{1'b1}}};
                            end else begin
                            end
                        end
                    endcase
                end
                3: begin
                    case (byte_in_cnt)
                        1: begin
                            if(DATA_WD >= 32) begin
                                r_data_out <= {{(DATA_WD-32){1'b0}}, data_in[7:0], data_in_delay_1[DATA_WD-1:DATA_WD-24]};
                                r_keep_out <= {{((DATA_WD-32)/8){1'b0}}, {1{1'b1}}, {3{1'b1}}};
                            end else begin
                            end
                        end
                        2: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-40){1'b0}}, data_in[15:0], data_in_delay_1[DATA_WD-1:DATA_WD-24]};
                                r_keep_out <= {{((DATA_WD-40)/8){1'b0}}, {2{1'b1}}, {3{1'b1}}};
                            end else begin
                            end
                        end
                        3: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-48){1'b0}}, data_in[23:0], data_in_delay_1[DATA_WD-1:DATA_WD-24]};
                                r_keep_out <= {{((DATA_WD-48)/8){1'b0}}, {3{1'b1}}, {3{1'b1}}};
                            end else begin
                            end
                        end
                        4: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-56){1'b0}}, data_in[31:0], data_in_delay_1[DATA_WD-1:DATA_WD-24]};
                                r_keep_out <= {{((DATA_WD-56)/8){1'b0}}, {4{1'b1}}, {3{1'b1}}};
                            end else begin
                            end
                        end
                        5: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-64){1'b0}}, data_in[39:0], data_in_delay_1[DATA_WD-1:DATA_WD-24]};
                                r_keep_out <= {{((DATA_WD-64)/8){1'b0}}, {5{1'b1}}, {3{1'b1}}};
                            end else begin
                            end
                        end
                    endcase
                end
                4: begin
                    case (byte_in_cnt)
                        1: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-40){1'b0}}, data_in[7:0], data_in_delay_1[DATA_WD-1:DATA_WD-32]};
                                r_keep_out <= {{((DATA_WD-40)/8){1'b0}}, {1{1'b1}}, {4{1'b1}}};
                            end else begin
                            end
                        end
                        2: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-48){1'b0}}, data_in[15:0], data_in_delay_1[DATA_WD-1:DATA_WD-32]};
                                r_keep_out <= {{((DATA_WD-48)/8){1'b0}}, {2{1'b1}}, {4{1'b1}}};
                            end else begin
                            end
                        end
                        3: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-56){1'b0}}, data_in[23:0], data_in_delay_1[DATA_WD-1:DATA_WD-32]};
                                r_keep_out <= {{((DATA_WD-56)/8){1'b0}}, {3{1'b1}}, {4{1'b1}}};
                            end else begin
                            end
                        end
                        4: begin
                            if(DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-64){1'b0}}, data_in[31:0], data_in_delay_1[DATA_WD-1:DATA_WD-32]};
                                r_keep_out <= {{((DATA_WD-64)/8){1'b0}}, {4{1'b1}}, {4{1'b1}}};
                            end else begin
                            end
                        end
                    endcase
                end
                5: begin
                    case (byte_in_cnt)
                        1: begin
                            if (DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-48){1'b0}}, data_in[7:0], data_in_delay_1[DATA_WD-1:DATA_WD-40]};
                                r_keep_out <= {{((DATA_WD-48)/8){1'b0}}, {1{1'b1}}, {5{1'b1}}};
                            end else begin
                            end
                        end
                        2: begin
                            if (DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-56){1'b0}}, data_in[15:0], data_in_delay_1[DATA_WD-1:DATA_WD-40]};
                                r_keep_out <= {{((DATA_WD-56)/8){1'b0}}, {2{1'b1}}, {5{1'b1}}};
                            end else begin
                            end
                        end
                        3: begin
                            if (DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-64){1'b0}}, data_in[23:0], data_in_delay_1[DATA_WD-1:DATA_WD-40]};
                                r_keep_out <= {{((DATA_WD-64)/8){1'b0}}, {3{1'b1}}, {5{1'b1}}};
                            end else begin
                            end
                        end
                    endcase
                end
                6: begin
                    case (byte_in_cnt)
                        1: begin
                            if (DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-56){1'b0}}, data_in[7:0], data_in_delay_1[DATA_WD-1:DATA_WD-48]};
                                r_keep_out <= {{((DATA_WD-56)/8){1'b0}}, {1{1'b1}}, {6{1'b1}}};
                            end else begin
                            end
                        end
                        2: begin
                            if (DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-64){1'b0}}, data_in[15:0], data_in_delay_1[DATA_WD-1:DATA_WD-48]};
                                r_keep_out <= {{((DATA_WD-64)/8){1'b0}}, {2{1'b1}}, {6{1'b1}}};
                            end else begin
                            end
                        end
                    endcase
                end
                7: begin
                    case (byte_in_cnt)
                        1: begin
                            if (DATA_WD >= 64) begin
                                r_data_out <= {{(DATA_WD-64){1'b0}}, data_in[7:0], data_in_delay_1[DATA_WD-1:DATA_WD-56]};
                                r_keep_out <= {{((DATA_WD-64)/8){1'b0}}, {1{1'b1}}, {7{1'b1}}};
                            end 
							else begin
                            end
                        end
                    endcase
                end
                default: r_data_out <= data_in;
            endcase
        end
    end
end

///*------stable cycle------- */
//always @(posedge clk) begin
//    if (!rst_n) begin
//        r_data_out <= 0;
//    end else if (r_valid_out & ready_out & r_last_out & ~compens) begin
//        r_data_out <= 0;
//        r_keep_out <= {(DATA_WD/8){1'b0}};
//    end
//end

/*------compensatory cyle------- */
always @(posedge clk) begin
    if (!rst_n) begin
        r_data_out <= 0;
    end 
    else if (r_valid_out & ready_out & las_in_delay_1 & compens) begin
        r_last_out <= 1;
        count <= 0;
        compens <= 0;
        case (r_byte_insert_cnt)
            1: begin
                case (byte_in_cnt)
                    1: begin
                        if (DATA_WD == 8) begin
                            r_data_out <= {{(2 * DATA_WD - 16){1'b0}}, data_in[7:DATA_WD-8]};
                            r_keep_out <= {{((2 * DATA_WD - 16) / 8){1'b0}}, {((16 - DATA_WD) / 8){1'b1}}};
                        end    
                    end
                    2: begin
                        if (DATA_WD == 16) begin
                            r_data_out <= {{(2 * DATA_WD - 24){1'b0}}, data_in[15:DATA_WD-8]};
                            r_keep_out <= {{((2 * DATA_WD - 24) / 8){1'b0}}, {((24 - DATA_WD) / 8){1'b1}}};
                        end
                        else begin
                        end
                    end
                    3: begin
                        if (DATA_WD == 16) begin
                            r_data_out <= {{(2 * DATA_WD - 32){1'b0}}, data_in[23:DATA_WD-8]};
                            r_keep_out <= {{((2 * DATA_WD - 32) / 8){1'b0}}, {((32 - DATA_WD) / 8){1'b1}}};
                        end
                        else begin
                        end
                    end
                    4: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 40){1'b0}}, data_in[31:DATA_WD-8]};
                            r_keep_out <= {{((2 * DATA_WD - 40) / 8){1'b0}}, {((40 - DATA_WD) / 8){1'b1}}};
                        end
                        else begin
                        end
                    end
                    5: begin
                        if (DATA_WD == 32) begin
                        end
                    end
                    6: begin
                        if (DATA_WD == 32) begin
                        end
                    end
                    7: begin
                        if (DATA_WD == 32) begin
                        end
                    end
                    8: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 56){1'b0}}, data_in[63:DATA_WD-8]};
                            r_keep_out <= {{((2 * DATA_WD - 64) / 8){1'b0}}, {((64 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                endcase
            end
            2: begin
                case (byte_in_cnt)
                    1: begin
                        if (DATA_WD == 16) begin
                            r_data_out <= {{(2 * DATA_WD - 24){1'b0}}, data_in[7:DATA_WD-16]};
                            r_keep_out <= {{((2 * DATA_WD - 24) / 8){1'b0}}, {((24 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    2: begin
                        if (DATA_WD == 16) begin
                            r_data_out <= {{(2 * DATA_WD - 32){1'b0}}, data_in[15:DATA_WD-16]};
                            r_keep_out <= {{((2 * DATA_WD - 32) / 8){1'b0}}, {((32 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    3: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 40){1'b0}}, data_in[23:DATA_WD-16]};
                            r_keep_out <= {{((2 * DATA_WD - 40) / 8){1'b0}}, {((40 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    4: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 48){1'b0}}, data_in[31:DATA_WD-16]};
                            r_keep_out <= {{((2 * DATA_WD - 48) / 8){1'b0}}, {((48 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    5: begin
                    end
                    6: begin
                    end
                    7: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 72){1'b0}}, data_in[55:DATA_WD-16]};
                            r_keep_out <= {{((2 * DATA_WD - 72) / 8){1'b0}}, {((72 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    8: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 80){1'b0}}, data_in[63:DATA_WD-16]};
                            r_keep_out <= {{((2 * DATA_WD - 80) / 8){1'b0}}, {((80 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                endcase
            end
            3: begin
                case (byte_in_cnt)
                    1: begin
                        if (DATA_WD == 32) begin
                        end
                    end
                    2: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 40){1'b0}}, data_in[15:DATA_WD-24]};
                            r_keep_out <= {{((2 * DATA_WD - 40) / 8){1'b0}}, {((40 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    3: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 48){1'b0}}, data_in[23:DATA_WD-24]};
                            r_keep_out <= {{((2 * DATA_WD - 48) / 8){1'b0}}, {((48 - DATA_WD) / 8){1'b1}}};
                        end
                    end

                    4: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 56){1'b0}}, data_in[31:DATA_WD-24]};
                            r_keep_out <= {{((2 * DATA_WD - 56) / 8){1'b0}}, {((56 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    5: begin
                    end
                    6: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 72){1'b0}}, data_in[47:DATA_WD-24]};
                            r_keep_out <= {{((2 * DATA_WD - 72) / 8){1'b0}}, {((72 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    7: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 80){1'b0}}, data_in[55:DATA_WD-24]};
                            r_keep_out <= {{((2 * DATA_WD - 80) / 8){1'b0}}, {((80 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    8: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 88){1'b0}}, data_in[63:DATA_WD-24]};
                            r_keep_out <= {{((2 * DATA_WD - 88) / 8){1'b0}}, {((88 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                endcase
            end
            4: begin
                case (byte_in_cnt)
                    1: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 40){1'b0}}, data_in[7:DATA_WD-32]};
                            r_keep_out <= {{((2 * DATA_WD - 40) / 8){1'b0}}, {((40 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    2: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 48){1'b0}}, data_in[15:DATA_WD-32]};
                            r_keep_out <= {{((2 * DATA_WD - 48) / 8){1'b0}}, {((48 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    3: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 56){1'b0}}, data_in[23:DATA_WD-32]};
                            r_keep_out <= {{((2 * DATA_WD - 56) / 8){1'b0}}, {((56 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    4: begin
                        if (DATA_WD == 32) begin
                            r_data_out <= {{(2 * DATA_WD - 64){1'b0}}, data_in[31:DATA_WD-32]};
                            r_keep_out <= {{((2 * DATA_WD - 64) / 8){1'b0}}, {((64 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    5: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 72){1'b0}}, data_in[39:DATA_WD-32]};
                            r_keep_out <= {{((2 * DATA_WD - 72) / 8){1'b0}}, {((72 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    6: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 80){1'b0}}, data_in[47:DATA_WD-32]};
                            r_keep_out <= {{((2 * DATA_WD - 80) / 8){1'b0}}, {((80 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    7: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 88){1'b0}}, data_in[55:DATA_WD-32]};
                            r_keep_out <= {{((2 * DATA_WD - 88) / 8){1'b0}}, {((88 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                    8: begin
                        if (DATA_WD == 64) begin
                            r_data_out <= {{(2 * DATA_WD - 96){1'b0}}, data_in[63:DATA_WD-32]};
                            r_keep_out <= {{((2 * DATA_WD - 96) / 8){1'b0}}, {((96 - DATA_WD) / 8){1'b1}}};
                        end
                    end
                endcase
            end

                5: begin
                    case (byte_in_cnt)
                        1: begin
                            if (DATA_WD == 64) begin

                            end
                        end
                        2: begin
                            if (DATA_WD == 64) begin

                            end
                        end
                        3: begin
                            if (DATA_WD == 64) begin

                            end
                        end
                        4: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 72){1'b0}}, data_in[31:DATA_WD-40]};
                                r_keep_out <= {{((2 * DATA_WD - 72) / 8){1'b0}}, {((72 - DATA_WD) / 8){1'b1}}};
                            end
                        end
                        
                        5: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 80){1'b0}}, data_in[39:DATA_WD-40]};
                                r_keep_out <= {{((2 * DATA_WD - 80) / 8){1'b0}}, {(80 - DATA_WD){1'b1}}}; 
                            end 
                        end
                        6: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 88){1'b0}}, data_in[47:DATA_WD-40]};
                                r_keep_out <= {{((2 * DATA_WD - 88) / 8){1'b0}}, {(88 - DATA_WD) / 8{1'b1}}};
                            end
                        end
                        7: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 96){1'b0}}, data_in[55:DATA_WD-40]};
                                r_keep_out <= {{((2 * DATA_WD - 96) / 8){1'b0}}, {((96 - DATA_WD) / 8){1'b1}}};
                            end
                        end
                        8: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 104){1'b0}}, data_in[63:DATA_WD-40]};
                                r_keep_out <= {{((2 * DATA_WD - 104) / 8){1'b0}}, {((104 - DATA_WD) / 8){1'b1}}};
                            end
                        end    
                    endcase                        
                end
                6: begin
                    case (byte_in_cnt)
                        1: begin
                            if (DATA_WD == 64) begin

                            end
                        end
                        2: begin
                            if (DATA_WD == 64) begin

                            end
                        end
                        3: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 72){1'b0}}, data_in[23:DATA_WD-48]};
                                r_keep_out <= {{((2 * DATA_WD - 72) / 8){1'b0}}, {(72 - DATA_WD){1'b1}}}; 
                            end
                        end
                        4: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 80){1'b0}}, data_in[31:DATA_WD-48]};
                                r_keep_out <= {{((2 * DATA_WD - 80) / 8){1'b0}}, {((80 - DATA_WD) / 8){1'b1}}};
                            end
                        end
                        
                        5: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 88){1'b0}}, data_in[39:DATA_WD-48]};
                                r_keep_out <= {{((2 * DATA_WD - 88) / 8){1'b0}}, {(88 - DATA_WD){1'b1}}}; 
                            end 
                        end
                        6: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 96){1'b0}}, data_in[47:DATA_WD-48]};
                                r_keep_out <= {{((2 * DATA_WD - 96) / 8){1'b0}}, {(96 - DATA_WD) / 8{1'b1}}};
                            end
                        end
                        7: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 104){1'b0}}, data_in[55:DATA_WD-48]};
                                r_keep_out <= {{((2 * DATA_WD - 104) / 8){1'b0}}, {((104 - DATA_WD) / 8){1'b1}}};
                            end
                        end
                        8: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 112){1'b0}}, data_in[63:DATA_WD-48]};
                                r_keep_out <= {{((2 * DATA_WD - 112) / 8){1'b0}}, {((112 - DATA_WD) / 8){1'b1}}};
                            end
                        end    
                    endcase                    
                end
                7: begin
                    case (byte_in_cnt)
                        1: begin
                            if (DATA_WD == 64) begin

                            end
                        end
                        2: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 72){1'b0}}, data_in[15:DATA_WD-56]};
                                r_keep_out <= {{((2 * DATA_WD - 72) / 8){1'b0}}, {(72 - DATA_WD){1'b1}}}; 
                            end
                        end
                        3: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 80){1'b0}}, data_in[23:DATA_WD-56]};
                                r_keep_out <= {{((2 * DATA_WD - 80) / 8){1'b0}}, {(80 - DATA_WD){1'b1}}}; 
                            end
                        end
                        4: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 88){1'b0}}, data_in[31:DATA_WD-56]};
                                r_keep_out <= {{((2 * DATA_WD - 88) / 8){1'b0}}, {((88 - DATA_WD) / 8){1'b1}}};
                            end

                        end
                        
                        5: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 96){1'b0}}, data_in[39:DATA_WD-56]};
                                r_keep_out <= {{((2 * DATA_WD - 96) / 8){1'b0}}, {(96 - DATA_WD){1'b1}}}; 
                            end 
                        end
                        6: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 104){1'b0}}, data_in[47:DATA_WD-56]};
                                r_keep_out <= {{((2 * DATA_WD - 104) / 8){1'b0}}, {(104 - DATA_WD) / 8{1'b1}}};
                            end
                        end
                        7: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 112){1'b0}}, data_in[55:DATA_WD-56]};
                                r_keep_out <= {{((2 * DATA_WD - 112) / 8){1'b0}}, {((112 - DATA_WD) / 8){1'b1}}};
                            end
                        end
                        8: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 120){1'b0}}, data_in[63:DATA_WD-56]};
                                r_keep_out <= {{((2 * DATA_WD - 120) / 8){1'b0}}, {((120 - DATA_WD) / 8){1'b1}}};
                            end
                        end                                    
                    endcase
                end
                        
                8: begin
                    case (byte_in_cnt)
                        1: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 72){1'b0}}, data_in[7:0]};
                                r_keep_out <= {{((2 * DATA_WD - 72) / 8){1'b0}}, {(72 - DATA_WD){1'b1}}}; 
                            end
                        end
                        2: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 80){1'b0}}, data_in[15:0]};
                                r_keep_out <= {{((2 * DATA_WD - 80) / 8){1'b0}}, {(80 - DATA_WD){1'b1}}}; 
                            end
                        end
                        3: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 88){1'b0}}, data_in[23:0]};
                                r_keep_out <= {{((2 * DATA_WD - 88) / 8){1'b0}}, {(88 - DATA_WD){1'b1}}}; 
                            end
                        end
                        4: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 96){1'b0}}, data_in[31:0]};
                                r_keep_out <= {{((2 * DATA_WD - 96) / 8){1'b0}}, {((96 - DATA_WD) / 8){1'b1}}};
                            end
                        end
                        
                        5: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 104){1'b0}}, data_in[39:0]};
                                r_keep_out <= {{((2 * DATA_WD - 104) / 8){1'b0}}, {(104 - DATA_WD){1'b1}}}; 
                            end 
                        end
                        6: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 112){1'b0}}, data_in[47:0]};
                                r_keep_out <= {{((2 * DATA_WD - 112) / 8){1'b0}}, {(112 - DATA_WD) / 8{1'b1}}};
                            end
                        end
                        7: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 120){1'b0}}, data_in[55:0]};
                                r_keep_out <= {{((2 * DATA_WD - 120) / 8){1'b0}}, {((120 - DATA_WD) / 8){1'b1}}};
                            end
                        end
                        8: begin
                            if (DATA_WD == 64) begin
                                r_data_out <= {{(2 * DATA_WD - 128){1'b0}}, data_in[63:0]};
                                r_keep_out <= {{((2 * DATA_WD - 128) / 8){1'b0}}, {((128 - DATA_WD) / 8){1'b1}}};
                            end
                        end
                    endcase
                end
		endcase
    end
end








/****************************************r_ready_insert**************************************************/
always@(posedge clk) begin
    if (!rst_n ) begin // unable after first burst
        r_ready_insert <= 'd0;
    end else if (valid_insert) begin
        r_ready_insert <= 'd1;
    end else begin
        r_ready_insert <= 'd0;
    end
end

/****************************************r_ready_in**************************************************/
always @ (posedge clk) begin
    if (!rst_n ) begin // stable during whole period of a transfer
        r_ready_in <= 'd0;
    end else if (valid_in) begin
        r_ready_in <= 'd1;
    end else begin
        r_ready_in <= 'd0;
    end
end

/****************************************r_valid_out**************************************************/
always @(posedge clk) begin
    if (!rst_n) begin
        r_valid_out <= 0;
    end else if (ready_out) begin
        r_valid_out <= 1;
    end else begin
        r_valid_out <= 0;
    end
end

/****************************************r_last_out**************************************************/
always @(posedge clk) begin
    if (!rst_n || ready_insert || r_last_out) begin
        r_last_out <= 0;
        //r_keep_out <= 0;
    end
end
/****************************************compens**************************************************/
always @(posedge clk) begin
    if (!rst_n) begin
        compens <= 0;
    end

    end
/*----- delay the signal and data_in------*/
// Delay the axis_tvalid and axis_tlast signal by one clock cycle
// to match the latency of DATA
always @(posedge clk) begin
    if (!rst_n) begin
        data_in_delay_1 <= 0;
        data_in_delay <= 0;
    end else begin
        data_in_delay_1 <= data_in;
        data_in_delay <= data_in_delay_1;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        keep_in_delay_1 <= 0;
        keep_in_delay <= 0;
    end else begin
        keep_in_delay_1 <= keep_in;
        keep_in_delay <= keep_in_delay_1;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        las_in_delay_1 <= 1'b0;
        las_in_delay <= 1'b0;
    end else begin
        las_in_delay_1 <= las_in;
        las_in_delay <= las_in_delay_1;
    end
end

endmodule
	
	