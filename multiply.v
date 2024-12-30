`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: multiply.v
//   > ���ܣ�32λ�з������˷���
//   > �ص㣺
//   >   - ֧��32λ�з��������
//   >   - ������λ�ӷ��㷨
//   >   - ����߼�ʵ�֣����������
//   >   - ���64λ���
//*************************************************************************
module multiply(
    input         clk,         // ʱ���źţ���ģ��δʹ�ã�
    input         mult_begin,  // �˷���ʼ�ź�
    input  [31:0] mult_op1,   // ����1
    input  [31:0] mult_op2,   // ����2
    output [63:0] product,    // �˻����
    output        mult_end    // �˷�����ź�
);
    // ��һ����ȡ����ֵ
    // ��ȡ�������ķ���λ��1Ϊ����0Ϊ����
    wire        op1_sign = mult_op1[31];
    wire        op2_sign = mult_op2[31];
    // ����Ǹ�����ͨ��ȡ����1��ȡ����ֵ
    wire [31:0] op1_absolute = op1_sign ? (~mult_op1+1) : mult_op1;
    wire [31:0] op2_absolute = op2_sign ? (~mult_op2+1) : mult_op2;

    // �ڶ�����ִ���޷������˷�
    wire [63:0] product_temp;  // ��ʱ�洢�˻����
    reg  [63:0] temp;         // �����ۼӵ���ʱ����
    integer i;                // ѭ��������

    // ��λ�ӷ�ʵ�ֳ˷�
    always @(*) begin
        temp = 64'd0;  // ��ʼ�����Ϊ0
        // ��������2��ÿһλ
        for(i = 0; i < 32; i = i + 1) begin
            if(op2_absolute[i])  // �����ǰλΪ1
                // ������1����iλ��ӵ������
                // {32'd0,op1_absolute}��32λ��չ��64λ�Է�ֹ���
                temp = temp + ({32'd0,op1_absolute} << i);
        end
    end
    
    assign product_temp = temp;
    
    // ��������ȷ�����ս���ķ���
    // �������������������ͬ�����Ϊ�������Ų�ͬ�����Ϊ��
    wire product_sign = op1_sign ^ op2_sign;
    
    // ���ݷ��ž����Ƿ���Ҫ�Խ��ȡ��
    // ������Ӧ��Ϊ�����������ʱ���ȡ����1
    assign product = product_sign ? (~product_temp+1) : product_temp;

    // ����������߼�ʵ�֣��˷�������һ�����������
    assign mult_end = mult_begin;  

endmodule
