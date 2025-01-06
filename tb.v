`timescale 1ns / 1ps
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
        // 只保留一个主要的monitor语句
        $monitor("Time=%3d PC=%h Inst=%h | i=$4=%d | $5=%d(奇偶) | an=$2=%d an+1=$3=%d | $11=%d(乘积1) $12=%d(乘积2) | $7=%d(和)",
                 $time,                     // 仿真时间
                 cpu_pc,                    // 程序计数器
                 cpu_inst,                  // 当前指令
                 uut.rf_module.rf[4],      // $4 - 计数器i
                 uut.rf_module.rf[5],      // $5 - 奇偶判断结果
                 uut.rf_module.rf[2],      // $2 - an
                 uut.rf_module.rf[3],      // $3 - an+1
                 uut.rf_module.rf[11],     // $11 - 第一个乘积
                 uut.rf_module.rf[12],     // $12 - 第二个乘积
                 uut.rf_module.rf[7]       // $7 - 和
                );
    end

    // 只在关键事件时显示详细信息
    always @(posedge clk) begin
        if (cpu_inst[31:26] == 6'b011100 && cpu_inst[5:0] == 6'b000010) begin  // MUL指令
            $display("\n乘法运算: %d * %d = %d", 
                     uut.alu_operand1, uut.alu_operand2, uut.alu_result);
        end
        else if (cpu_inst[31:26] == 6'b000100) begin  // BEQ指令
            $display("\n分支判断(BEQ): $5=%d, 目标地址=%h", 
                     uut.rf_module.rf[5], uut.jbr_target);
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

