`timescale 1ns / 1ps
//*************************************************************************
//   > 文件名: single_cycle_cpu_display.v
//   > 描述: 单周期CPU显示模块
//   > 功能: 实现FPGA开发板上的显示功能，包括：
//          1. CPU运行状态显示
//          2. 寄存器内容显示
//          3. 存储器内容显示
//          4. 用户交互界面
//*************************************************************************
module single_cycle_cpu_display(
    // 时钟与复位
    input clk,                  // 系统时钟
    input resetn,              // 复位信号，低电平有效
    
    // 单步调试控制
    input btn_clk,             // 按键时钟，用于单步执行
    
    // LCD显示接口
    output lcd_rst,            // LCD复位信号
    output lcd_cs,             // LCD片选信号
    output lcd_rs,             // LCD数据/命令选择
    output lcd_wr,             // LCD写使能
    output lcd_rd,             // LCD读使能
    inout[15:0] lcd_data_io,  // LCD数据总线
    output lcd_bl_ctr,         // LCD背光控制
    inout ct_int,              // 触摸屏中断
    inout ct_sda,              // 触摸屏SDA
    output ct_scl,             // 触摸屏SCL
    output ct_rstn             // 触摸屏复位
    );

//-----{时钟和复位信号处理}begin
    // 按键去抖动和脉冲产生
    reg btn_clk_r1;
    reg btn_clk_r2;
    
    // 按键信号延迟两个时钟周期
    always @(posedge clk) begin
        if (!resetn) begin
            btn_clk_r1 <= 1'b0;
        end
        else begin
            btn_clk_r1 <= ~btn_clk;
        end
        btn_clk_r2 <= btn_clk_r1;
    end

    // 产生CPU时钟使能信号
    wire clk_en;
    assign clk_en = !resetn || (!btn_clk_r1 && btn_clk_r2);
    
    // CPU时钟门控
    wire cpu_clk;
    BUFGCE cpu_clk_cg(.I(clk), .CE(clk_en), .O(cpu_clk));
//-----{时钟和复位信号处理}end

//-----{单周期CPU核心}begin
    // CPU核心信号
    wire [31:0] cpu_pc;        // 当前执行的指令地址
    wire [31:0] cpu_inst;      // 当前执行的指令
    wire [ 4:0] rf_addr;       // 寄存器堆读地址
    wire [31:0] rf_data;       // 寄存器堆读出数据
    reg  [31:0] mem_addr;      // 存储器读地址
    wire [31:0] mem_data;      // 存储器读出数据

    // 例化CPU核心
    single_cycle_cpu cpu(
        .clk0    (clk       ),  // 时钟信号
        .clk     (cpu_clk   ),  // CPU时钟
        .resetn  (resetn    ),  // 复位信号
        
        .rf_addr (rf_addr   ),  // 寄存器读地址
        .mem_addr(mem_addr  ),  // 存储器读地址
        .rf_data (rf_data   ),  // 寄存器数据
        .mem_data(mem_data  ),  // 存储器数据
        .cpu_pc  (cpu_pc    ),  // 程序计数器
        .cpu_inst(cpu_inst  )   // 指令
    );
//-----{单周期CPU核心}end

//-----{LCD显示模块}begin
    // 显示相关信号
    reg         display_valid;     // 显示有效信号
    reg  [39:0] display_name;      // 显示名称
    reg  [31:0] display_value;     // 显示数值
    wire [5 :0] display_number;    // 显示编号
    wire        input_valid;       // 输入有效
    wire [31:0] input_value;       // 输入数值

    // 例化LCD显示模块
    lcd_module lcd_module(
        .clk            (clk           ),  // 时钟信号
        .resetn         (resetn        ),  // 复位信号
        
        // 显示信号
        .display_valid  (display_valid ),  // 显示有效
        .display_name   (display_name  ),  // 显示名称
        .display_value  (display_value ),  // 显示数值
        .display_number (display_number),  // 显示编号
        .input_valid    (input_valid   ),  // 输入有效
        .input_value    (input_value   ),  // 输入数值
        
        // LCD物理接口
        .lcd_rst        (lcd_rst       ),
        .lcd_cs         (lcd_cs        ),
        .lcd_rs         (lcd_rs        ),
        .lcd_wr         (lcd_wr        ),
        .lcd_rd         (lcd_rd        ),
        .lcd_data_io    (lcd_data_io   ),
        .lcd_bl_ctr     (lcd_bl_ctr    ),
        .ct_int         (ct_int        ),
        .ct_sda         (ct_sda        ),
        .ct_scl         (ct_scl        ),
        .ct_rstn        (ct_rstn       )
    ); 
//-----{LCD显示模块}end

//-----{用户输入处理}begin
    // 处理用户输入的存储器地址
    always @(posedge clk) begin
        if (!resetn) begin
            mem_addr <= 32'd0;
        end
        else if (input_valid) begin
            mem_addr <= input_value;
        end
    end
    
    // 寄存器编号转换：display_number从5开始显示寄存器
    assign rf_addr = display_number - 6'd5;
//-----{用户输入处理}end

//-----{显示信息处理}begin
    // 处理要显示的信息
    always @(posedge clk) begin
        if (display_number >6'd4 && display_number <6'd37 ) begin
            // 显示32个通用寄存器的值（显示编号5~36）
            display_valid <= 1'b1;
            display_name[39:16] <= "REG";                                  // 显示"REG"
            display_name[15: 8] <= {4'b0011,3'b000,rf_addr[4]};          // 寄存器编号高位
            display_name[7 : 0] <= {4'b0011,rf_addr[3:0]};               // 寄存器编号低位
            display_value       <= rf_data;                               // 寄存器值
        end
        else begin
            case(display_number)
                6'd1 : begin    // 显示PC值
                    display_valid <= 1'b1;
                    display_name  <= "   PC";
                    display_value <= cpu_pc;
                end
                6'd2 : begin    // 显示当前指令
                    display_valid <= 1'b1;
                    display_name  <= " INST";
                    display_value <= cpu_inst;
                end
                6'd3 : begin    // 显示要观察的存储器地址
                    display_valid <= 1'b1;
                    display_name  <= "MADDR";
                    display_value <= mem_addr;
                end
                6'd4 : begin    // 显示存储器地址对应的数据
                    display_valid <= 1'b1;
                    display_name  <= "MDATA";
                    display_value <= mem_data;
                end
                default : begin
                    display_valid <= 1'b0;
                end
            endcase
        end
    end
//-----{显示信息处理}end

endmodule
