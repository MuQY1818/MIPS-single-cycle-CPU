`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: single_cycle_cpu.v
//   > ����: ������CPU����ģ��
//   > ����: ʵ��16��MIPSָ��ĵ�����CPU��������
//          1. R��ָ�ADDU, SUBU, SLT, AND, NOR, OR, XOR, SLL, SRL, MUL
//          2. I��ָ�ADDIU, LW, SW, LUI, BEQ, BNE
//          3. J��ָ�J
//   > �ص�: ָ��ROM������RAM�����첽��ȡ�����ڵ�����CPUʵ��
//*************************************************************************
`define STARTADDR 32'd0  // ������ʼ��ַ

module single_cycle_cpu(
    input  clk0,              // ʱ���ź�0
    input  clk,               // CPUʱ��
    input  resetn,            // ��λ�źţ��͵�ƽ��Ч

    // ���Խӿ�
    input  [ 4:0] rf_addr,    // �Ĵ����Ѷ���ַ
    input  [31:0] mem_addr,   // �洢������ַ
    output [31:0] rf_data,    // �Ĵ�������
    output [31:0] mem_data,   // �洢������
    output [31:0] cpu_pc,     // ��ǰPCֵ
    output [31:0] cpu_inst    // ��ǰָ��
    );

//-----{ȡָģ��}begin-----
    // PC�Ĵ�������һ��ָ���ַ����
    reg  [31:0] pc;           // ���������
    wire [31:0] next_pc;      // ��һ��ָ���ַ
    wire [31:0] seq_pc;       // ˳��ִ�е���һ��ָ���ַ
    wire [31:0] jbr_target;   // ��תĿ���ַ
    wire        jbr_taken;    // ��ת�ź�

    // ����˳��ִ�е���һ��ָ���ַ��PC = PC + 4
    assign seq_pc[31:2] = pc[31:2] + 1'b1;
    assign seq_pc[1:0]  = pc[1:0];
    
    // ������ת�ź�ѡ����һ��ָ���ַ
    assign next_pc = jbr_taken ? jbr_target : seq_pc;

    // PC�Ĵ�������
    always @(posedge clk) begin
        if (!resetn) begin
            pc <= `STARTADDR;  // ��λʱָ�������ʼ��ַ
        end
        else begin
            pc <= next_pc;     // ����Ϊ��һ��ָ���ַ
        end
    end

    // ָ��洢���ӿ�
    wire [31:0] inst_addr;    // ָ���ַ
    wire [31:0] inst;         // ��ǰָ��
    assign inst_addr = pc;    // ָ���ַ����PC��ֵ
    
    // ����ָ��洢��
    inst_rom inst_rom_module(
        .addr  (inst_addr[6:2]),  // ����ָ���ַ
        .inst  (inst          )   // ���ָ��
    );

    // ����˵���ǣ���������ĵ�ַ����ָ��洢����ȡ����Ӧ��ָ��
    
    // ���Խӿ����
    assign cpu_pc   = pc;
    assign cpu_inst = inst;
//-----{ȡָģ��}end-----

//-----{����ģ��}begin-----
    // ָ��ֽ�
    wire [5:0] op;       // ������
    wire [4:0] rs;       // Դ������1��ַ
    wire [4:0] rt;       // Դ������2��ַ
    wire [4:0] rd;       // Ŀ���������ַ
    wire [4:0] sa;       // ��λ��
    wire [5:0] funct;    // ������
    wire [15:0] imm;     // ������
    wire [15:0] offset;  // ��֧��תƫ����
    wire [25:0] target;  // ��תĿ���ַ

    // ָ��ֶ�
    assign op     = inst[31:26];
    assign rs     = inst[25:21];
    assign rt     = inst[20:16];
    assign rd     = inst[15:11];
    assign sa     = inst[10:6];
    assign funct  = inst[5:0];
    assign imm    = inst[15:0];
    assign offset = inst[15:0];
    assign target = inst[25:0];

    // ָ�������ж�
    wire op_zero;    // ������ȫ0
    wire sa_zero;    // sa��ȫ0
    assign op_zero = ~(|op);
    assign sa_zero = ~(|sa);
    
    // ָ����룬����֧�ֵ�ָ��
    wire inst_ADDU, inst_SUBU, inst_SLT, inst_AND;
    wire inst_NOR , inst_OR  , inst_XOR, inst_SLL;
    wire inst_SRL , inst_ADDIU, inst_BEQ, inst_BNE;
    wire inst_LW  , inst_SW   , inst_LUI, inst_J;
    wire inst_MUL;

    // R��ָ�����
    assign inst_ADDU = op_zero & sa_zero & (funct == 6'b100001);  // �޷��żӷ�
    assign inst_SUBU = op_zero & sa_zero & (funct == 6'b100011);  // �޷��ż���
    assign inst_SLT  = op_zero & sa_zero & (funct == 6'b101010);  // С������λ
    assign inst_AND  = op_zero & sa_zero & (funct == 6'b100100);  // ��λ��
    assign inst_NOR  = op_zero & sa_zero & (funct == 6'b100111);  // ��λ���
    assign inst_OR   = op_zero & sa_zero & (funct == 6'b100101);  // ��λ��
    assign inst_XOR  = op_zero & sa_zero & (funct == 6'b100110);  // ��λ���
    assign inst_SLL  = op_zero & (rs==5'd0) & (funct == 6'b000000);  // �߼�����
    assign inst_SRL  = op_zero & (rs==5'd0) & (funct == 6'b000010);  // �߼�����
    assign inst_MUL  = (op == 6'b011100) & sa_zero & (funct == 6'b000010);  // �˷�

    // I��ָ�����
    assign inst_ADDIU = (op == 6'b001001);  // �������޷��żӷ�
    assign inst_BEQ   = (op == 6'b000100);  // ��ȷ�֧
    assign inst_BNE   = (op == 6'b000101);  // ���ȷ�֧
    assign inst_LW    = (op == 6'b100011);  // ���ڴ����
    assign inst_SW    = (op == 6'b101011);  // �洢���ڴ�
    assign inst_LUI   = (op == 6'b001111);  // ���������ص��߰��ֽ�

    // J��ָ�����
    assign inst_J     = (op == 6'b000010);  // ��������ת

    // ��תָ���
    wire        j_taken;     // Jָ����ת�ź�
    wire [31:0] j_target;    // Jָ����תĿ��
    assign j_taken = inst_J;
    // Jָ����תĿ���ַ��PC={PC[31:28],target<<2}
    assign j_target = {pc[31:28], target, 2'b00};

    // ��ָ֧���
    wire        beq_taken;    // BEQָ����ת�ź�
    wire        bne_taken;    // BNEָ����ת�ź�
    wire [31:0] br_target;    // ��ָ֧����תĿ��
    assign beq_taken = (rs_value == rt_value);  // ���ʱ��ת
    assign bne_taken = ~beq_taken;              // ����ʱ��ת
    // ��֧��תĿ���ַ��PC=PC+offset<<2
    assign br_target[31:2] = pc[31:2] + {{14{offset[15]}}, offset};
    assign br_target[1:0]  = pc[1:0];

    // ��ת�źź�Ŀ���ַ������ȷ��
    assign jbr_taken = j_taken                // ��������ת
                    | inst_BEQ & beq_taken    // ��ȷ�֧��ת
                    | inst_BNE & bne_taken;   // ���ȷ�֧��ת
    assign jbr_target = j_taken ? j_target : br_target;

    // �Ĵ����ѽӿ��ź�
    wire rf_wen;          // �Ĵ���дʹ��
    wire [4:0] rf_waddr;  // �Ĵ���д��ַ
    wire [31:0] rf_wdata; // �Ĵ���д����
    wire [31:0] rs_value; // rs�Ĵ���ֵ
    wire [31:0] rt_value; // rt�Ĵ���ֵ

    // �����Ĵ�����ģ��
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
    
    // ALU�����ź�����
    wire inst_add, inst_sub, inst_slt, inst_sltu;
    wire inst_and, inst_nor, inst_or, inst_xor;
    wire inst_sll, inst_srl, inst_sra, inst_lui;
    
    // ��������ָ��
    assign inst_add  = inst_ADDU | inst_ADDIU | inst_LW | inst_SW;
    assign inst_sub  = inst_SUBU;
    assign inst_slt  = inst_SLT;
    assign inst_sltu = 1'b0;      // δʵ��
    
    // �߼�����ָ��
    assign inst_and = inst_AND;
    assign inst_nor = inst_NOR;
    assign inst_or  = inst_OR;
    assign inst_xor = inst_XOR;
    
    // ��λָ��
    assign inst_sll = inst_SLL;
    assign inst_srl = inst_SRL;
    assign inst_sra = 1'b0;       // δʵ��
    assign inst_lui = inst_LUI;

    // ����������
    wire [31:0] sext_imm;         // ������չ���������
    wire inst_shf_sa;             // ʹ��sa����Ϊƫ������ָ��
    wire inst_imm_sign;           // ��Ҫ������������չ��ָ��
    assign sext_imm     = {{16{imm[15]}}, imm};
    assign inst_shf_sa  = inst_SLL | inst_SRL;
    assign inst_imm_sign = inst_ADDIU | inst_LUI | inst_LW | inst_SW;
    
    // ALU�����ź�
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;
    wire [12:0] alu_control;
    
    // ALU��һ��������ѡ��
    assign alu_operand1 = inst_shf_sa ? {27'd0,sa} : rs_value;
    
    // ALU�ڶ���������ѡ��
    assign alu_operand2 = inst_imm_sign ? sext_imm : rt_value;
    
    // ALU�����ź�
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
//-----{����ģ��}end-----

//-----{ִ��ģ��}begin-----
    wire [31:0] alu_result;  // ALU������
    wire alu_end;            // ALU��������ź�
    
    // ����ALUģ��
    alu alu_module(
        .clk         (clk0        ),
        .alu_control (alu_control ),
        .alu_src1    (alu_operand1),
        .alu_src2    (alu_operand2),
        .alu_result  (alu_result  ),
        .alu_end     (alu_end     )
    );
//-----{ִ��ģ��}end-----

//-----{�ô�ģ��}begin-----
    wire [3:0]  dm_wen;     // ���ݴ洢��дʹ��
    wire [31:0] dm_addr;    // ���ݴ洢����д��ַ
    wire [31:0] dm_wdata;   // ���ݴ洢��д����
    wire [31:0] dm_rdata;   // ���ݴ洢��������
    
    // ���ݴ洢��дʹ���źţ�SWָ����Ч��CPU���ڸ�λ״̬
    assign dm_wen   = {4{inst_SW}} & {4{resetn}};
    assign dm_addr  = alu_result;               // ��д��ַΪALU����ֵ
    assign dm_wdata = rt_value;                 // д����Ϊrt�Ĵ���ֵ
    
    // �������ݴ洢��ģ��
    data_ram data_ram_module(
        .clk        (clk          ),
        .wen        (dm_wen       ),
        .addr       (dm_addr[6:2] ),
        .wdata      (dm_wdata     ),
        .rdata      (dm_rdata     ),
        .test_addr  (mem_addr[6:2]),
        .test_data  (mem_data     )
    );
//-----{�ô�ģ��}end-----

//-----{д��ģ��}begin-----
    wire inst_wdest_rt;   // �Ĵ���д�ص�ַΪrt��ָ��
    wire inst_wdest_rd;   // �Ĵ���д�ص�ַΪrd��ָ��
    
    // д�ص�ַѡ���ź�
    assign inst_wdest_rt = inst_ADDIU | inst_LW | inst_LUI;
    assign inst_wdest_rd = inst_ADDU | inst_SUBU | inst_SLT | inst_AND | inst_NOR
                        | inst_OR   | inst_XOR  | inst_SLL | inst_SRL;
    
    // �Ĵ���дʹ���ź�
    assign rf_wen = (inst_wdest_rt | inst_wdest_rd | (inst_MUL&alu_end)) & resetn;
    
    // �Ĵ���д�ص�ַѡ��ʹ��rd��ָ���˷�ָ��ѡrd������ѡrt
    assign rf_waddr = (inst_wdest_rd | (inst_MUL&alu_end)) ? rd : rt;
    
    // �Ĵ���д������ѡ��LWָ��д�ش洢�����ݣ�����ָ��д��ALU���
    assign rf_wdata = inst_LW ? dm_rdata : alu_result;
//-----{д��ģ��}end-----

endmodule
