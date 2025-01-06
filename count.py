def calculate_sequence(n):
    # 初始化前两个数
    a0, a1 = 1, 1
    
    print(f"a0 = {a0:d} (0x{a0:08X})")
    print(f"a1 = {a1:d} (0x{a1:08X})")
    
    # 计算后续的数
    for i in range(2, n):
        # an+2 = 3an + 2an+1
        a2 = 3 * a0 + 2 * a1
        print(f"a{i} = {a2:d} (0x{a2:08X})")
        
        # 更新数列
        a0, a1 = a1, a2

# 计算前10项
print("计算数列的前10项：")
calculate_sequence(10)