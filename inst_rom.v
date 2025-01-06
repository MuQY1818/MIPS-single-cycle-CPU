`timescale 1ns / 1ps
module inst_rom(
    input      [4 :0] addr, // 地址
    output reg [31:0] inst       // 指令
    );

    wire [31:0] inst_rom[20:0];  // 指令存储器20个指令，每个指令32位
    //------------- 指令序列 ---------|地址|--- 行为 -----|- 结果 -----//
    assign inst_rom[ 0] = 32'h24020001; // 00H: addiu $2,$0,#1    | $2 = 1 (第一个数a0)
    assign inst_rom[ 1] = 32'h24030001; // 04H: addiu $3,$0,#1    | $3 = 1 (第二个数a1)
    assign inst_rom[ 2] = 32'h24010002; // 08H: addiu $1,$0,#2    | $1 = 2 (常数2)
    assign inst_rom[ 3] = 32'h70236002; // 0CH: mul   $12,$1,$3   | $12 = 2 * $3 (2an+1)
    assign inst_rom[ 4] = 32'h24010003; // 10H: addiu $1,$0,#3    | $1 = 3 (常数3)
    assign inst_rom[ 5] = 32'h70225802; // 14H: mul   $11,$1,$2   | $11 = 3 * $2 (3an)
    assign inst_rom[ 6] = 32'h016C3821; // 18H: addu  $7,$11,$12  | $7 = $11 + $12 (2an+1 + 3an)
    assign inst_rom[ 7] = 32'h00601025; // 1CH: or    $2,$3,$0    | $2 = $3 (更新an)
    assign inst_rom[ 8] = 32'h00E01825; // 20H: or    $3,$7,$0    | $3 = $7 (更新an+1)
    assign inst_rom[ 9] = 32'h08000002; // 24H: j     08H         | 跳回继续计算下一个数

    always @(*)
    begin
        case (addr)
            5'd0 : inst <= inst_rom[0 ];
            5'd1 : inst <= inst_rom[1 ];
            5'd2 : inst <= inst_rom[2 ];
            5'd3 : inst <= inst_rom[3 ];
            5'd4 : inst <= inst_rom[4 ];
            5'd5 : inst <= inst_rom[5 ];
            5'd6 : inst <= inst_rom[6 ];
            5'd7 : inst <= inst_rom[7 ];
            5'd8 : inst <= inst_rom[8 ];
            5'd9 : inst <= inst_rom[9 ];
            5'd10: inst <= inst_rom[10];
            5'd11: inst <= inst_rom[11];
            5'd12: inst <= inst_rom[12];
            5'd13: inst <= inst_rom[13];
            5'd14: inst <= inst_rom[14];
            5'd15: inst <= inst_rom[15];
            5'd16: inst <= inst_rom[16];
            5'd17: inst <= inst_rom[17];
            5'd18: inst <= inst_rom[18];
            5'd19: inst <= inst_rom[19];
            5'd20: inst <= inst_rom[20];
            default: inst <= 32'd0;
        endcase
    end
endmodule