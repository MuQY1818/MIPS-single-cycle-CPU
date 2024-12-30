`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: multiply.v
//   > 功能：32位有符号数乘法器
//   > 特点：
//   >   - 支持32位有符号数相乘
//   >   - 采用移位加法算法
//   >   - 组合逻辑实现，单周期完成
//   >   - 输出64位结果
//*************************************************************************
module multiply(
    input         clk,         // 时钟信号（本模块未使用）
    input         mult_begin,  // 乘法开始信号
    input  [31:0] mult_op1,   // 乘数1
    input  [31:0] mult_op2,   // 乘数2
    output [63:0] product,    // 乘积结果
    output        mult_end    // 乘法完成信号
);
    // 第一步：取绝对值
    // 获取操作数的符号位（1为负，0为正）
    wire        op1_sign = mult_op1[31];
    wire        op2_sign = mult_op2[31];
    // 如果是负数则通过取反加1获取绝对值
    wire [31:0] op1_absolute = op1_sign ? (~mult_op1+1) : mult_op1;
    wire [31:0] op2_absolute = op2_sign ? (~mult_op2+1) : mult_op2;

    // 第二步：执行无符号数乘法
    wire [63:0] product_temp;  // 临时存储乘积结果
    reg  [63:0] temp;         // 用于累加的临时变量
    integer i;                // 循环计数器

    // 移位加法实现乘法
    always @(*) begin
        temp = 64'd0;  // 初始化结果为0
        // 遍历乘数2的每一位
        for(i = 0; i < 32; i = i + 1) begin
            if(op2_absolute[i])  // 如果当前位为1
                // 将乘数1左移i位后加到结果中
                // {32'd0,op1_absolute}将32位扩展到64位以防止溢出
                temp = temp + ({32'd0,op1_absolute} << i);
        end
    end
    
    assign product_temp = temp;
    
    // 第三步：确定最终结果的符号
    // 如果两个操作数符号相同，结果为正；符号不同，结果为负
    wire product_sign = op1_sign ^ op2_sign;
    
    // 根据符号决定是否需要对结果取反
    // 如果结果应该为负数，则对临时结果取反加1
    assign product = product_sign ? (~product_temp+1) : product_temp;

    // 由于是组合逻辑实现，乘法可以在一个周期内完成
    assign mult_end = mult_begin;  

endmodule
