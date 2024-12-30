`timescale 1ns / 1ps
//******************************************************************
//   > 文件名: data_ram.v
//   > 功能：异步读取、同步写入的数据存储器模块
//   > 特点：
//   >   - 支持按字节写入（4字节独立写使能）
//   >   - 异步读取（组合逻辑）
//   >   - 同步写入（时钟上升沿）
//   >   - 总容量：32个字（32位/字）
//******************************************************************
module data_ram(
    input         clk,         // 时钟信号
    input  [3:0]  wen,         // 字节写使能信号（每位控制一个字节）
    input  [4:0]  addr,        // 读写地址（5位，寻址32个字）
    input  [31:0] wdata,       // 写入数据（32位）
    output reg [31:0] rdata,   // 读出数据（32位）
    
    // 调试接口
    input  [4:0]  test_addr,   // 调试地址
    output reg [31:0] test_data // 调试数据输出
);
    // 数据存储器主体，32个32位字
    reg [31:0] DM[31:0];
    
    integer i;
    initial
    begin
        for(i = 0; i < 32; i = i + 1) begin
            DM[i] <= 0;
        end 
    end

    // 写入数据
    always @(posedge clk)    // 写信号为1时，写入数据到对应字节
    begin
        if (wen[3])
        begin
            DM[addr][31:24] <= wdata[31:24];
        end
    end
    always @(posedge clk)
    begin
        if (wen[2])
        begin
            DM[addr][23:16] <= wdata[23:16];
        end
    end
    always @(posedge clk)
    begin
        if (wen[1])
        begin
            DM[addr][15: 8] <= wdata[15: 8];
        end
    end
    always @(posedge clk)
    begin
        if (wen[0])
        begin
            DM[addr][7 : 0] <= wdata[7 : 0];
        end
    end
    
    // 读出数据
    always @(*)
    begin
        case (addr)
            5'd0 : rdata <= DM[0 ];
            5'd1 : rdata <= DM[1 ];
            5'd2 : rdata <= DM[2 ];
            5'd3 : rdata <= DM[3 ];
            5'd4 : rdata <= DM[4 ];
            5'd5 : rdata <= DM[5 ];
            5'd6 : rdata <= DM[6 ];
            5'd7 : rdata <= DM[7 ];
            5'd8 : rdata <= DM[8 ];
            5'd9 : rdata <= DM[9 ];
            5'd10: rdata <= DM[10];
            5'd11: rdata <= DM[11];
            5'd12: rdata <= DM[12];
            5'd13: rdata <= DM[13];
            5'd14: rdata <= DM[14];
            5'd15: rdata <= DM[15];
            5'd16: rdata <= DM[16];
            5'd17: rdata <= DM[17];
            5'd18: rdata <= DM[18];
            5'd19: rdata <= DM[19];
            5'd20: rdata <= DM[20];
            5'd21: rdata <= DM[21];
            5'd22: rdata <= DM[22];
            5'd23: rdata <= DM[23];
            5'd24: rdata <= DM[24];
            5'd25: rdata <= DM[25];
            5'd26: rdata <= DM[26];
            5'd27: rdata <= DM[27];
            5'd28: rdata <= DM[28];
            5'd29: rdata <= DM[29];
            5'd30: rdata <= DM[30];
            5'd31: rdata <= DM[31];
        endcase
    end
    // 调试接口
    always @(*)
    begin
        case (test_addr)
            5'd0 : test_data <= DM[0 ];
            5'd1 : test_data <= DM[1 ];
            5'd2 : test_data <= DM[2 ];
            5'd3 : test_data <= DM[3 ];
            5'd4 : test_data <= DM[4 ];
            5'd5 : test_data <= DM[5 ];
            5'd6 : test_data <= DM[6 ];
            5'd7 : test_data <= DM[7 ];
            5'd8 : test_data <= DM[8 ];
            5'd9 : test_data <= DM[9 ];
            5'd10: test_data <= DM[10];
            5'd11: test_data <= DM[11];
            5'd12: test_data <= DM[12];
            5'd13: test_data <= DM[13];
            5'd14: test_data <= DM[14];
            5'd15: test_data <= DM[15];
            5'd16: test_data <= DM[16];
            5'd17: test_data <= DM[17];
            5'd18: test_data <= DM[18];
            5'd19: test_data <= DM[19];
            5'd20: test_data <= DM[20];
            5'd21: test_data <= DM[21];
            5'd22: test_data <= DM[22];
            5'd23: test_data <= DM[23];
            5'd24: test_data <= DM[24];
            5'd25: test_data <= DM[25];
            5'd26: test_data <= DM[26];
            5'd27: test_data <= DM[27];
            5'd28: test_data <= DM[28];
            5'd29: test_data <= DM[29];
            5'd30: test_data <= DM[30];
            5'd31: test_data <= DM[31];
        endcase
    end
endmodule
