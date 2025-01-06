`timescale 1ns / 1ps
module tb;
    // ʱ�Ӻ͸�λ�ź�
    reg clk;                  // CPU��ʱ��
    reg clk0;                // �Ĵ����ļ�ʱ��
    reg resetn;              // ��λ�źţ��͵�ƽ��Ч
    
    // ���Խӿ��ź�
    reg [4:0] rf_addr;       // �Ĵ����Ѷ���ַ
    reg [31:0] mem_addr;     // �洢������ַ

    // CPU����״̬�ź�
    wire [31:0] rf_data;     // �Ĵ�������
    wire [31:0] mem_data;    // �洢������
    wire [31:0] cpu_pc;      // ��ǰPCֵ
    wire [31:0] cpu_inst;    // ��ǰָ��

    // ����������CPU
    single_cycle_cpu uut (
        .clk0     (clk0     ),  // �Ĵ����ļ�ʱ��
        .clk      (clk      ),  // CPU��ʱ��
        .resetn   (resetn   ),  // ��λ�ź�
        .rf_addr  (rf_addr  ),  // �Ĵ�������ַ
        .mem_addr (mem_addr ),  // �洢������ַ
        .rf_data  (rf_data  ),  // �Ĵ�������
        .mem_data (mem_data ),  // �洢������
        .cpu_pc   (cpu_pc   ),  // ���������
        .cpu_inst (cpu_inst )   // ��ǰָ��
    );

    // ��ʼ���͸�λ����
    initial begin
        // ��ʼ���ź�
        clk = 0;
        clk0 = 0;
        resetn = 0;
        rf_addr = 0;
        mem_addr = 0;

        // ��λ��ʱ
        #100;
        resetn = 1;
        
        // �ȴ��������
        #2000;
        
        // ��֤������
        check_result(5'd5, 32'd9,  "a2");  // ����2��
        #200;
        check_result(5'd5, 32'd24, "a3");  // ����3��
        #200;
        check_result(5'd5, 32'd75, "a4");  // ����4��
        
        // �������
        #100;
        $display("�������");
        $finish;
    end

    // ��ؼĴ�����ָ��ִ��
    initial begin
        // ֻ����һ����Ҫ��monitor���
        $monitor("Time=%3d PC=%h Inst=%h | i=$4=%d | $5=%d(��ż) | an=$2=%d an+1=$3=%d | $11=%d(�˻�1) $12=%d(�˻�2) | $7=%d(��)",
                 $time,                     // ����ʱ��
                 cpu_pc,                    // ���������
                 cpu_inst,                  // ��ǰָ��
                 uut.rf_module.rf[4],      // $4 - ������i
                 uut.rf_module.rf[5],      // $5 - ��ż�жϽ��
                 uut.rf_module.rf[2],      // $2 - an
                 uut.rf_module.rf[3],      // $3 - an+1
                 uut.rf_module.rf[11],     // $11 - ��һ���˻�
                 uut.rf_module.rf[12],     // $12 - �ڶ����˻�
                 uut.rf_module.rf[7]       // $7 - ��
                );
    end

    // ֻ�ڹؼ��¼�ʱ��ʾ��ϸ��Ϣ
    always @(posedge clk) begin
        if (cpu_inst[31:26] == 6'b011100 && cpu_inst[5:0] == 6'b000010) begin  // MULָ��
            $display("\n�˷�����: %d * %d = %d", 
                     uut.alu_operand1, uut.alu_operand2, uut.alu_result);
        end
        else if (cpu_inst[31:26] == 6'b000100) begin  // BEQָ��
            $display("\n��֧�ж�(BEQ): $5=%d, Ŀ���ַ=%h", 
                     uut.rf_module.rf[5], uut.jbr_target);
        end
    end

    // ���ALU�������
    initial begin
        $monitor("ALU: op1=%d op2=%d result=%d | MUL: control=%b end=%b", 
                 uut.alu_operand1,         // ALU������1
                 uut.alu_operand2,         // ALU������2
                 uut.alu_result,           // ALU���
                 uut.alu_control,          // ALU�����ź�
                 uut.alu_end               // ALU������ɱ�־
                );
    end

    // ʱ���ź�����
    always #50 clk = ~clk;    // ��ʱ������100ns
    always #5  clk0 = ~clk0;  // �Ĵ����ļ�ʱ������10ns

    // ����������
    task check_result;
        input [4:0] addr;         // Ҫ���ļĴ�����ַ
        input [31:0] expected;    // ����ֵ
        input [8*10:1] stage;     // ���׶�˵��
        begin
            rf_addr = addr;
            #10;
            if (rf_data === expected) begin
                $display("�� %s �������ȷ: $%0d = %0d", stage, addr, rf_data);
            end else begin
                $display("�� %s ��������: $%0d = %0d, ����ֵΪ %0d", stage, addr, rf_data, expected);
            end
        end
    endtask

endmodule

