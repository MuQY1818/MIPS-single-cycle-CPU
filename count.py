def calculate_sequence(n):
    # 初始化前两个数
    a0, a1 = 1, 1
    
    print(f"a0 = {a0:d} (0x{a0:08X})")
    print(f"a1 = {a1:d} (0x{a1:08X})")
    
    # 从1开始计数，与MIPS实现保持一致
    for i in range(1, n-1):
        if i % 2 == 1:  # 奇数情况
            # 2an+1 + 3an
            temp_2a1 = 2 * a1    # mul $12,$1,$3
            temp_3a0 = 3 * a0    # mul $11,$1,$2
            a2 = temp_2a1 + temp_3a0  # addu $7,$11,$12
        else:  # 偶数情况
            # 3an+1 + 2an
            temp_3a1 = 3 * a1    # mul $12,$1,$3
            temp_2a0 = 2 * a0    # mul $11,$1,$2
            a2 = temp_3a1 + temp_2a0  # addu $7,$11,$12
            
        print(f"a{i+1} = {a2:d} (0x{a2:08X})")
        
        # 更新数列
        a0, a1 = a1, a2

# 计算前10项
print("计算数列的前15项：")
calculate_sequence(15)