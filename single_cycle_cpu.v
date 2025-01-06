`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: single_cycle_cpu.v
//   > 描述: 单周期CPU顶层模块
//   > 功能: 实现16条MIPS指令的单周期CPU，包括：
//          1. R型指令：ADDU, SUBU, SLT, AND, NOR, OR, XOR, SLL, SRL, MUL
//          2. I型指令：ADDIU, LW, SW, LUI, BEQ, BNE
//          3. J型指令：J
//   > 特点: 指令ROM和数据RAM采用异步读取，便于单周期CPU实现
//*************************************************************************
`define STARTADDR 32'd0  // 程序起始地址

module single_cycle_cpu(
    input  clk0,              // 时钟信号0
    input  clk,               // CPU时钟
    input  resetn,            // 复位信号，低电平有效

    // 调试接口
    input  [ 4:0] rf_addr,    // 寄存器堆读地址
    input  [31:0] mem_addr,   // 存储器读地址
    output [31:0] rf_data,    // 寄存器数据
    output [31:0] mem_data,   // 存储器数据
    output [31:0] cpu_pc,     // 当前PC值
    output [31:0] cpu_inst    // 当前指令
    );

//-----{取指模块}begin-----
    // PC寄存器与下一条指令地址计算
    reg  [31:0] pc;           // 程序计数器
    wire [31:0] next_pc;      // 下一条指令地址
    wire [31:0] seq_pc;       // 顺序执行的下一条指令地址
    wire [31:0] jbr_target;   // 跳转目标地址
    wire        jbr_taken;    // 跳转信号

    // 计算顺序执行的下一条指令地址：PC = PC + 4
    assign seq_pc[31:2] = pc[31:2] + 1'b1;
    assign seq_pc[1:0]  = pc[1:0];
    
    // 根据跳转信号选择下一条指令地址
    assign next_pc = jbr_taken ? jbr_target : seq_pc;

    // PC寄存器更新
    always @(posedge clk) begin
        if (!resetn) begin
            pc <= `STARTADDR;  // 复位时指向程序起始地址
        end
        else begin
            pc <= next_pc;     // 更新为下一条指令地址
        end
    end

    // 指令存储器接口
    wire [31:0] inst_addr;    // 指令地址
    wire [31:0] inst;         // 当前指令
    assign inst_addr = pc;    // 指令地址就是PC的值
    
    // 例化指令存储器
    inst_rom inst_rom_module(
        .addr  (inst_addr[6:2]),  // 输入指令地址
        .inst  (inst          )   // 输出指令
    );

    // 简单来说就是，根据输入的地址，从指令存储器中取出对应的指令
    
    // 调试接口输出
    assign cpu_pc   = pc;
    assign cpu_inst = inst;
//-----{取指模块}end-----

//-----{译码模块}begin-----
    // 指令分解
    wire [5:0] op;       // 操作码
    wire [4:0] rs;       // 源操作数1地址
    wire [4:0] rt;       // 源操作数2地址
    wire [4:0] rd;       // 目标操作数地址
    wire [4:0] sa;       // 移位量
    wire [5:0] funct;    // 功能码
    wire [15:0] imm;     // 立即数
    wire [15:0] offset;  // 分支跳转偏移量
    wire [25:0] target;  // 跳转目标地址

    // 指令分段
    assign op     = inst[31:26];
    assign rs     = inst[25:21];
    assign rt     = inst[20:16];
    assign rd     = inst[15:11];
    assign sa     = inst[10:6];
    assign funct  = inst[5:0];
    assign imm    = inst[15:0];
    assign offset = inst[15:0];
    assign target = inst[25:0];

    // 指令类型判断
    wire op_zero;    // 操作码全0
    wire sa_zero;    // sa域全0
    assign op_zero = ~(|op);
    assign sa_zero = ~(|sa);
    
    // 指令解码，所有支持的指令
    wire inst_ADDU, inst_SUBU, inst_SLT, inst_AND;
    wire inst_NOR , inst_OR  , inst_XOR, inst_SLL;
    wire inst_SRL , inst_ADDIU, inst_BEQ, inst_BNE;
    wire inst_LW  , inst_SW   , inst_LUI, inst_J;
    wire inst_MUL;

    // R型指令解码
    assign inst_ADDU = op_zero & sa_zero & (funct == 6'b100001);  // 无符号加法
    assign inst_SUBU = op_zero & sa_zero & (funct == 6'b100011);  // 无符号减法
    assign inst_SLT  = op_zero & sa_zero & (funct == 6'b101010);  // 小于则置位
    assign inst_AND  = op_zero & sa_zero & (funct == 6'b100100);  // 按位与
    assign inst_NOR  = op_zero & sa_zero & (funct == 6'b100111);  // 按位或非
    assign inst_OR   = op_zero & sa_zero & (funct == 6'b100101);  // 按位或
    assign inst_XOR  = op_zero & sa_zero & (funct == 6'b100110);  // 按位异或
    assign inst_SLL  = op_zero & (rs==5'd0) & (funct == 6'b000000);  // 逻辑左移
    assign inst_SRL  = op_zero & (rs==5'd0) & (funct == 6'b000010);  // 逻辑右移
    assign inst_MUL  = (op == 6'b011100) & sa_zero & (funct == 6'b000010);  // 乘法

    // I型指令解码
    assign inst_ADDIU = (op == 6'b001001);  // 立即数无符号加法
    assign inst_BEQ   = (op == 6'b000100);  // 相等分支
    assign inst_BNE   = (op == 6'b000101);  // 不等分支
    assign inst_LW    = (op == 6'b100011);  // 从内存加载
    assign inst_SW    = (op == 6'b101011);  // 存储到内存
    assign inst_LUI   = (op == 6'b001111);  // 立即数加载到高半字节

    // J型指令解码
    assign inst_J     = (op == 6'b000010);  // 无条件跳转

    // 跳转指令处理
    wire        j_taken;     // J指令跳转信号
    wire [31:0] j_target;    // J指令跳转目标
    assign j_taken = inst_J;
    // J指令跳转目标地址：PC={PC[31:28],target<<2}
    assign j_target = {pc[31:28], target, 2'b00};

    // 分支指令处理
    wire        beq_taken;    // BEQ指令跳转信号
    wire        bne_taken;    // BNE指令跳转信号
    wire [31:0] br_target;    // 分支指令跳转目标
    assign beq_taken = (rs_value == rt_value);  // 相等时跳转
    assign bne_taken = ~beq_taken;              // 不等时跳转
    // 分支跳转目标地址：PC=PC+offset<<2
    assign br_target[31:2] = pc[31:2] + {{14{offset[15]}}, offset};
    assign br_target[1:0]  = pc[1:0];

    // 跳转信号和目标地址的最终确定
    assign jbr_taken = j_taken                // 无条件跳转
                    | inst_BEQ & beq_taken    // 相等分支跳转
                    | inst_BNE & bne_taken;   // 不等分支跳转
    assign jbr_target = j_taken ? j_target : br_target;

    // 寄存器堆接口信号
    wire rf_wen;          // 寄存器写使能
    wire [4:0] rf_waddr;  // 寄存器写地址
    wire [31:0] rf_wdata; // 寄存器写数据
    wire [31:0] rs_value; // rs寄存器值
    wire [31:0] rt_value; // rt寄存器值

    // 例化寄存器堆模块
    regfile rf_module(
        .clk       (clk      ),
        .wen       (rf_wen   ),
        .raddr1    (rs       ),
        .raddr2    (rt       ),
        .waddr     (rf_waddr ),
        .wdata     (rf_wdata ),
        .rdata1    (rs_value ),
        .rdata2    (rt_value ),
        .test_addr (rf_addr  ),
        .test_data (rf_data  )
    );
    
    // ALU控制信号生成
    wire inst_add, inst_sub, inst_slt, inst_sltu;
    wire inst_and, inst_nor, inst_or, inst_xor;
    wire inst_sll, inst_srl, inst_sra, inst_lui;
    
    // 算术运算指令
    assign inst_add  = inst_ADDU | inst_ADDIU | inst_LW | inst_SW;
    assign inst_sub  = inst_SUBU;
    assign inst_slt  = inst_SLT;
    assign inst_sltu = 1'b0;      // 未实现
    
    // 逻辑运算指令
    assign inst_and = inst_AND;
    assign inst_nor = inst_NOR;
    assign inst_or  = inst_OR;
    assign inst_xor = inst_XOR;
    
    // 移位指令
    assign inst_sll = inst_SLL;
    assign inst_srl = inst_SRL;
    assign inst_sra = 1'b0;       // 未实现
    assign inst_lui = inst_LUI;

    // 立即数处理
    wire [31:0] sext_imm;         // 符号扩展后的立即数
    wire inst_shf_sa;             // 使用sa域作为偏移量的指令
    wire inst_imm_sign;           // 需要立即数符号扩展的指令
    assign sext_imm     = {{16{imm[15]}}, imm};
    assign inst_shf_sa  = inst_SLL | inst_SRL;
    assign inst_imm_sign = inst_ADDIU | inst_LUI | inst_LW | inst_SW;
    
    // ALU输入信号
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;
    wire [12:0] alu_control;
    
    // ALU第一个操作数选择
    assign alu_operand1 = inst_shf_sa ? {27'd0,sa} : rs_value;
    
    // ALU第二个操作数选择
    assign alu_operand2 = inst_imm_sign ? sext_imm : rt_value;
    
    // ALU控制信号
    assign alu_control = {inst_MUL,
                         inst_add,
                         inst_sub,
                         inst_slt,
                         inst_sltu,
                         inst_and,
                         inst_nor,
                         inst_or, 
                         inst_xor,
                         inst_sll,
                         inst_srl,
                         inst_sra,
                         inst_lui};
//-----{译码模块}end-----

//-----{执行模块}begin-----
    wire [31:0] alu_result;  // ALU计算结果
    wire alu_end;            // ALU计算完成信号
    
    // 例化ALU模块
    alu alu_module(
        .clk         (clk0        ),
        .alu_control (alu_control ),
        .alu_src1    (alu_operand1),
        .alu_src2    (alu_operand2),
        .alu_result  (alu_result  ),
        .alu_end     (alu_end     )
    );
//-----{执行模块}end-----

//-----{访存模块}begin-----
    wire [3:0]  dm_wen;     // 数据存储器写使能
    wire [31:0] dm_addr;    // 数据存储器读写地址
    wire [31:0] dm_wdata;   // 数据存储器写数据
    wire [31:0] dm_rdata;   // 数据存储器读数据
    
    // 数据存储器写使能信号：SW指令有效且CPU不在复位状态
    assign dm_wen   = {4{inst_SW}} & {4{resetn}};
    assign dm_addr  = alu_result;               // 读写地址为ALU计算值
    assign dm_wdata = rt_value;                 // 写数据为rt寄存器值
    
    // 例化数据存储器模块
    data_ram data_ram_module(
        .clk        (clk          ),
        .wen        (dm_wen       ),
        .addr       (dm_addr[6:2] ),
        .wdata      (dm_wdata     ),
        .rdata      (dm_rdata     ),
        .test_addr  (mem_addr[6:2]),
        .test_data  (mem_data     )
    );
//-----{访存模块}end-----

//-----{写回模块}begin-----
    wire inst_wdest_rt;   // 寄存器写回地址为rt的指令
    wire inst_wdest_rd;   // 寄存器写回地址为rd的指令
    
    // 写回地址选择信号
    assign inst_wdest_rt = inst_ADDIU | inst_LW | inst_LUI;
    assign inst_wdest_rd = inst_ADDU | inst_SUBU | inst_SLT | inst_AND | inst_NOR
                        | inst_OR   | inst_XOR  | inst_SLL | inst_SRL;
    
    // 寄存器写使能信号
    assign rf_wen = (inst_wdest_rt | inst_wdest_rd | (inst_MUL&alu_end)) & resetn;
    
    // 寄存器写回地址选择：使用rd的指令或乘法指令选rd，其他选rt
    assign rf_waddr = (inst_wdest_rd | (inst_MUL&alu_end)) ? rd : rt;
    
    // 寄存器写回数据选择：LW指令写回存储器数据，其他指令写回ALU结果
    assign rf_wdata = inst_LW ? dm_rdata : alu_result;
//-----{写回模块}end-----

endmodule
