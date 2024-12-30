`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: tb.v
//   > 描述: 单周期CPU测试平台
//   > 功能: 
//          1. 生成时钟和复位信号
//          2. 监控CPU运行状态
//          3. 验证特殊数列计算结果
//          4. 调试关键信号变化
//*************************************************************************
module tb;
    // 时钟和复位信号
    reg clk;                  // CPU主时钟
    reg clk0;                // 寄存器文件时钟
    reg resetn;              // 复位信号，低电平有效
    
    // 调试接口信号
    reg [4:0] rf_addr;       // 寄存器堆读地址
    reg [31:0] mem_addr;     // 存储器读地址

    // CPU运行状态信号
    wire [31:0] rf_data;     // 寄存器数据
    wire [31:0] mem_data;    // 存储器数据
    wire [31:0] cpu_pc;      // 当前PC值
    wire [31:0] cpu_inst;    // 当前指令

    // 例化单周期CPU
    single_cycle_cpu uut (
        .clk0     (clk0     ),  // 寄存器文件时钟
        .clk      (clk      ),  // CPU主时钟
        .resetn   (resetn   ),  // 复位信号
        .rf_addr  (rf_addr  ),  // 寄存器读地址
        .mem_addr (mem_addr ),  // 存储器读地址
        .rf_data  (rf_data  ),  // 寄存器数据
        .mem_data (mem_data ),  // 存储器数据
        .cpu_pc   (cpu_pc   ),  // 程序计数器
        .cpu_inst (cpu_inst )   // 当前指令
    );

    // 初始化和复位过程
    initial begin
        // 初始化信号
        clk = 0;
        clk0 = 0;
        resetn = 0;
        rf_addr = 0;
        mem_addr = 0;

        // 复位延时
        #100;
        resetn = 1;
        
        // 等待计算完成
        #2000;
        
        // 验证计算结果
        check_result(5'd5, 32'd9,  "a2");  // 检查第2项
        #200;
        check_result(5'd5, 32'd24, "a3");  // 检查第3项
        #200;
        check_result(5'd5, 32'd75, "a4");  // 检查第4项
        
        // 测试完成
        #100;
        $display("测试完成");
        $finish;
    end

    // 监控寄存器和指令执行
    initial begin
        // 监控关键寄存器的值变化
        $monitor("Time=%3d PC=%h Inst=%h | $1=%d $2=%d $3=%d $11=%d $12=%d", 
                 $time,                     // 仿真时间
                 cpu_pc,                    // 程序计数器
                 cpu_inst,                  // 当前指令
                 uut.rf_module.rf[1],      // $1 - 常数2和3
                 uut.rf_module.rf[2],      // $2 - an
                 uut.rf_module.rf[3],      // $3 - an+1
                 uut.rf_module.rf[11],     // $11 - 3an项
                 uut.rf_module.rf[12]      // $12 - 2an+1项
                );

        // 监控乘法器运行状态
        $monitor("DEBUG: mul_op1=%d mul_op2=%d product=%d mult_end=%b", 
                 uut.alu_module.multiply_module.mult_op1,    // 乘数1
                 uut.alu_module.multiply_module.mult_op2,    // 乘数2
                 uut.alu_module.multiply_module.product,     // 乘积
                 uut.alu_module.multiply_module.mult_end     // 乘法完成标志
        );
    end

    // 监控指令执行过程
    always @(posedge clk) begin
        // 显示当前指令和关键寄存器的值
        $display("Time=%5d PC=%h Inst=%h | $1=%10d $2=%10d $3=%10d $11=%10d $12=%10d",
                 $time, cpu_pc, cpu_inst,
                 uut.rf_module.rf[1],      // $1  - 常数
                 uut.rf_module.rf[2],      // $2  - an
                 uut.rf_module.rf[3],      // $3  - an+1
                 uut.rf_module.rf[11],     // $11 - 3an项
                 uut.rf_module.rf[12]      // $12 - 2an+1项
        );

        // 监控乘法指令执行
        if (cpu_inst[31:26] == 6'b011100 && cpu_inst[5:0] == 6'b000010) begin
            $display("MUL: %d * %d = %d", 
                     uut.alu_operand1,     // 乘数1
                     uut.alu_operand2,     // 乘数2
                     uut.alu_result        // 乘积
            );
        end

        // 监控加法指令执行
        if (cpu_inst[31:26] == 6'b000000 && cpu_inst[5:0] == 6'b100001) begin
            $display("ADD: %d + %d = %d ($7)",
                     uut.alu_operand1,     // 加数1
                     uut.alu_operand2,     // 加数2
                     uut.alu_result        // 和
            );
        end
    end

    // 监控ALU运算过程
    initial begin
        $monitor("ALU: op1=%d op2=%d result=%d | MUL: control=%b end=%b", 
                 uut.alu_operand1,         // ALU操作数1
                 uut.alu_operand2,         // ALU操作数2
                 uut.alu_result,           // ALU结果
                 uut.alu_control,          // ALU控制信号
                 uut.alu_end               // ALU运算完成标志
                );
    end

    // 时钟信号生成
    always #50 clk = ~clk;    // 主时钟周期100ns
    always #5  clk0 = ~clk0;  // 寄存器文件时钟周期10ns

    // 结果检查任务
    task check_result;
        input [4:0] addr;         // 要检查的寄存器地址
        input [31:0] expected;    // 期望值
        input [8*10:1] stage;     // 检查阶段说明
        begin
            rf_addr = addr;
            #10;
            if (rf_data === expected) begin
                $display("第 %s 项计算正确: $%0d = %0d", stage, addr, rf_data);
            end else begin
                $display("第 %s 项计算错误: $%0d = %0d, 期望值为 %0d", stage, addr, rf_data, expected);
            end
        end
    endtask

endmodule

