`timescale 1ns / 1ps
module inst_rom(
    input      [4 :0] addr, // 地址
    output reg [31:0] inst       // 指令
    );

    wire [31:0] inst_rom[20:0];  // 指令存储器20个指令，每个指令32位

    //------------- 指令序列 ---------|地址|--- 行为 -----|- 结果 -----//
    assign inst_rom[ 0] = 32'h24020001; // 00H: addiu $2,$0,#1    | $2 = 1 (a0)
    assign inst_rom[ 1] = 32'h24030001; // 04H: addiu $3,$0,#1    | $3 = 1 (a1)
    assign inst_rom[ 2] = 32'h24040001; // 08H: addiu $4,$0,#1    | $4 = 1 (i从1开始)
    assign inst_rom[ 3] = 32'h24840001; // 0CH: addiu $4,$4,#1    | i++ (递增i)
    assign inst_rom[ 4] = 32'h24010001; // 10H: addiu $1,$0,#1    | $1 = 1
    assign inst_rom[ 5] = 32'h00812824; // 14H: and   $5,$4,$1    | $5 = i & 1 (奇偶判断)
    assign inst_rom[ 6] = 32'h10A00006; // 18H: beq   $5,$0,#6    | 如果是偶数，跳转6条指令
    // 奇数情况：2an+1 + 3an
    assign inst_rom[ 7] = 32'h24010002; // 1CH: addiu $1,$0,#2    | $1 = 2
    assign inst_rom[ 8] = 32'h70236002; // 20H: mul   $12,$1,$3   | $12 = 2 * $3 (2an+1)
    assign inst_rom[ 9] = 32'h24010003; // 24H: addiu $1,$0,#3    | $1 = 3
    assign inst_rom[10] = 32'h70225802; // 28H: mul   $11,$1,$2   | $11 = 3 * $2 (3an)
    assign inst_rom[11] = 32'h08000010; // 2CH: j     40H         | 跳转到合并处理
    // 偶数情况：3an+1 + 2an
    assign inst_rom[12] = 32'h24010003; // 30H: addiu $1,$0,#3    | $1 = 3
    assign inst_rom[13] = 32'h70236002; // 34H: mul   $12,$1,$3   | $12 = 3 * $3
    assign inst_rom[14] = 32'h24010002; // 38H: addiu $1,$0,#2    | $1 = 2
    assign inst_rom[15] = 32'h70225802; // 3CH: mul   $11,$1,$2   | $11 = 2 * $2
    assign inst_rom[16] = 32'h016C3821; // 40H: addu  $7,$11,$12  | $7 = $11 + $12
    assign inst_rom[17] = 32'h00601025; // 44H: or    $2,$3,$0    | $2 = $3 (更新an)
    assign inst_rom[18] = 32'h00E01825; // 48H: or    $3,$7,$0    | $3 = $7 (更新an+1)
    assign inst_rom[19] = 32'h08000003; // 4CH: j     0CH         | 跳回到i++指令

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