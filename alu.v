`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: alu.v
//   > 描述: 算术逻辑单元(ALU)
//   > 主要功能:
//   >   1. 算术运算：加法、减法、乘法
//   >   2. 逻辑运算：AND、OR、XOR、NOR
//   >   3. 移位操作：逻辑左移(SLL)、逻辑右移(SRL)、算术右移(SRA)
//   >   4. 比较运算：有符号比较(SLT)、无符号比较(SLTU)
//   >   5. 立即数加载：LUI指令支持
//*************************************************************************
module alu(
    input         clk,          // 时钟信号
    input  [12:0] alu_control, // ALU控制信号，决定运算类型
    input  [31:0] alu_src1,    // 第一个源操作数
    input  [31:0] alu_src2,    // 第二个源操作数
    output [31:0] alu_result,  // ALU运算结果
    output        alu_end      // 运算完成信号
    );

    // ALU控制信号解码
    wire alu_mul;   // 乘法操作控制位
    wire alu_add;   // 加法操作控制位
    wire alu_sub;   // 减法操作控制位
    wire alu_slt;   // 有符号小于比较控制位
    wire alu_sltu;  // 无符号小于比较控制位
    wire alu_and;   // 与运算控制位
    wire alu_nor;   // 或非运算控制位
    wire alu_or;    // 或运算控制位
    wire alu_xor;   // 异或运算控制位
    wire alu_sll;   // 逻辑左移控制位
    wire alu_srl;   // 逻辑右移控制位
    wire alu_sra;   // 算术右移控制位
    wire alu_lui;   // 立即数加载控制位

    // 控制信号位分配
    assign alu_mul  = alu_control[12];
    assign alu_add  = alu_control[11];
    assign alu_sub  = alu_control[10];
    assign alu_slt  = alu_control[9];
    assign alu_sltu = alu_control[8];
    assign alu_and  = alu_control[7];
    assign alu_nor  = alu_control[6];
    assign alu_or   = alu_control[5];
    assign alu_xor  = alu_control[4];
    assign alu_sll  = alu_control[3];
    assign alu_srl  = alu_control[2];
    assign alu_sra  = alu_control[1];
    assign alu_lui  = alu_control[0];

    // 运算结果寄存器和中间结果声明
    reg [31:0] mul_result;        // 乘法结果寄存器
    wire [31:0] add_sub_result;   // 加减法结果
    wire [31:0] slt_result;       // 有符号比较结果
    wire [31:0] sltu_result;      // 无符号比较结果
    wire [31:0] and_result;       // 与运算结果
    wire [31:0] nor_result;       // 或非运算结果
    wire [31:0] or_result;        // 或运算结果
    wire [31:0] xor_result;       // 异或运算结果
    wire [31:0] sll_result;       // 逻辑左移结果
    wire [31:0] srl_result;       // 逻辑右移结果
    wire [31:0] sra_result;       // 算术右移结果
    wire [31:0] lui_result;       // 立即数加载结果

    // 基本逻辑运算实现
    assign and_result = alu_src1 & alu_src2;           // 按位与
    assign or_result  = alu_src1 | alu_src2;           // 按位或
    assign nor_result = ~or_result;                    // 或非
    assign xor_result = alu_src1 ^ alu_src2;           // 按位异或
    assign lui_result = {alu_src2[15:0], 16'd0};       // 立即数加载到高16位

    //-----{乘法器实现}begin
    wire mult_end;                // 乘法完成信号
    wire [63:0] product_t;        // 64位乘法结果
    wire [31:0] mul_result_t = product_t[31:0];  // 取低32位作为最终结果
    
    // 乘法器模块例化
    multiply multiply_module (
        .clk       (clk       ),
        .mult_begin(alu_mul   ),
        .mult_op1  (alu_src1  ), 
        .mult_op2  (alu_src2  ),
        .product   (product_t ),
        .mult_end  (mult_end  )
    );
    
    // ALU结果多路选择器
    assign alu_result = alu_mul ? (mult_end ? product_t[31:0] : mul_result) :
                       (alu_add|alu_sub) ? add_sub_result[31:0] : 
                       alu_slt          ? slt_result :
                       alu_sltu         ? sltu_result :
                       alu_and          ? and_result :
                       alu_nor          ? nor_result :
                       alu_or           ? or_result  :
                       alu_xor          ? xor_result :
                       alu_sll          ? sll_result :
                       alu_srl          ? srl_result :
                       alu_sra          ? sra_result :
                       alu_lui          ? lui_result :
                       32'd0;

    // 乘法结果更新
    always @(posedge clk) begin
        if (mult_end) begin
            mul_result <= product_t[31:0];
        end
    end
    //-----{乘法器实现}end

    //-----{加减法和比较运算实现}begin
    wire [31:0] adder_operand1;
    wire [31:0] adder_operand2;
    wire        adder_cin;
    wire [31:0] adder_result;
    wire        adder_cout;

    // 加减法操作数准备
    assign adder_operand1 = alu_src1;
    assign adder_operand2 = alu_add ? alu_src2 : ~alu_src2;  // 减法时对第二个操作数取反
    assign adder_cin      = ~alu_add;  // 减法时需要加1(补码)

    // 加法器模块例化
    adder adder_module(
        .operand1(adder_operand1),
        .operand2(adder_operand2),
        .cin     (adder_cin     ),
        .result  (adder_result  ),
        .cout    (adder_cout    )
    );

    // 加减运算结果
    assign add_sub_result = adder_result;

    // 有符号数比较(SLT)实现
    // 根据操作数符号和结果判断大小关系：
    // 1. 当两个操作数符号不同时，负数必然小于正数
    // 2. 当两个操作数符号相同时，通过减法结果判断大小
    assign slt_result[31:1] = 31'd0;
    assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31]) | 
                             (~(alu_src1[31]^alu_src2[31]) & adder_result[31]);

    // 无符号数比较(SLTU)实现
    // 通过比较减法结果的进位来判断大小
    assign sltu_result = {31'd0, ~adder_cout};
    //-----{加减法和比较运算实现}end

    //-----{移位运算实现}begin
    wire [4:0] shf;         // 移位位数
    wire [1:0] shf_1_0;    // 第一级移位控制
    wire [1:0] shf_3_2;    // 第二级移位控制
    
    assign shf = alu_src1[4:0];    // 移位位数为alu_src1的低5位
    assign shf_1_0 = shf[1:0];
    assign shf_3_2 = shf[3:2];
    
    // 逻辑左移实现（三级移位）
    wire [31:0] sll_step1;  // 第一级移位结果
    wire [31:0] sll_step2;  // 第二级移位结果
    
    // 第一级移位：0-3位移位
    assign sll_step1 = {32{shf_1_0 == 2'b00}} & alu_src2                   |  // 移0位
                      {32{shf_1_0 == 2'b01}} & {alu_src2[30:0], 1'd0}     |  // 移1位
                      {32{shf_1_0 == 2'b10}} & {alu_src2[29:0], 2'd0}     |  // 移2位
                      {32{shf_1_0 == 2'b11}} & {alu_src2[28:0], 3'd0};       // 移3位

    // 第二级移位：0-12位移位
    assign sll_step2 = {32{shf_3_2 == 2'b00}} & sll_step1                  |  // 移0位
                      {32{shf_3_2 == 2'b01}} & {sll_step1[27:0], 4'd0}    |  // 移4位
                      {32{shf_3_2 == 2'b10}} & {sll_step1[23:0], 8'd0}    |  // 移8位
                      {32{shf_3_2 == 2'b11}} & {sll_step1[19:0], 12'd0};     // 移12位

    // 第三级移位：0-16位移位
    assign sll_result = shf[4] ? {sll_step2[15:0], 16'd0} : sll_step2;       // 移16位或不移位

    // 逻辑右移实现（与左移类似，但填充0）
    wire [31:0] srl_step1;
    wire [31:0] srl_step2;
    
    assign srl_step1 = {32{shf_1_0 == 2'b00}} & alu_src2                   |
                      {32{shf_1_0 == 2'b01}} & {1'd0, alu_src2[31:1]}     |
                      {32{shf_1_0 == 2'b10}} & {2'd0, alu_src2[31:2]}     |
                      {32{shf_1_0 == 2'b11}} & {3'd0, alu_src2[31:3]};

    assign srl_step2 = {32{shf_3_2 == 2'b00}} & srl_step1                  |
                      {32{shf_3_2 == 2'b01}} & {4'd0, srl_step1[31:4]}    |
                      {32{shf_3_2 == 2'b10}} & {8'd0, srl_step1[31:8]}    |
                      {32{shf_3_2 == 2'b11}} & {12'd0, srl_step1[31:12]};

    assign srl_result = shf[4] ? {16'd0, srl_step2[31:16]} : srl_step2;

    // 算术右移实现（与逻辑右移类似，但填充符号位）
    wire [31:0] sra_step1;
    wire [31:0] sra_step2;
    
    assign sra_step1 = {32{shf_1_0 == 2'b00}} & alu_src2                                 |
                      {32{shf_1_0 == 2'b01}} & {alu_src2[31], alu_src2[31:1]}           |
                      {32{shf_1_0 == 2'b10}} & {{2{alu_src2[31]}}, alu_src2[31:2]}      |
                      {32{shf_1_0 == 2'b11}} & {{3{alu_src2[31]}}, alu_src2[31:3]};

    assign sra_step2 = {32{shf_3_2 == 2'b00}} & sra_step1                                |
                      {32{shf_3_2 == 2'b01}} & {{4{sra_step1[31]}}, sra_step1[31:4]}    |
                      {32{shf_3_2 == 2'b10}} & {{8{sra_step1[31]}}, sra_step1[31:8]}    |
                      {32{shf_3_2 == 2'b11}} & {{12{sra_step1[31]}}, sra_step1[31:12]};

    assign sra_result = shf[4] ? {{16{sra_step2[31]}}, sra_step2[31:16]} : sra_step2;
    //-----{移位运算实现}end

    // 运算完成信号生成
    assign alu_end = alu_mul ? mult_end : |alu_control;

endmodule
