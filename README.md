<div align="center">

# 🚀 MIPS单周期CPU设计实现

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Language](https://img.shields.io/badge/language-Verilog-orange)

一个基于MIPS指令集的单周期CPU实现，专注于特殊数列计算
</div>

## 🌟 特性一览

<table>
<tr>
    <td>✨ MIPS基本指令集</td>
    <td>🔄 32位数据通路</td>
    <td>📊 32个通用寄存器</td>
</tr>
<tr>
    <td>🧮 独立乘法器模块</td>
    <td>🔍 完整调试接口</td>
    <td>📱 LCD显示支持</td>
</tr>
</table>

## 🎯 数列计算实现

### 📐 数学定义
> 这是一个特殊的递推数列，具有以下特点：
```math
a₀ = 1, a₁ = 1
aₙ₊₁ = 2aₙ + 1 + 3aₙ₋₁
```

### 📈 数列前几项
```
1 → 1 → 5 → 13 → 41 → 121 ...
```

### 💻 核心代码实现
```mips
# 初始化
addiu $2,$0,#1    ┌─ $2 = 1 (a₀)
addiu $3,$0,#1    └─ $3 = 1 (a₁)

# 计算循环
addiu $1,$0,#2    ┌─ 准备常数2
mul   $12,$1,$3   └─ $12 = 2aₙ
addiu $1,$0,#3    ┌─ 准备常数3
mul   $11,$1,$2   └─ $11 = 3aₙ₋₁
addu  $7,$11,$12  ─── 计算新项
or    $2,$3,$0    ┌─ 更新寄存器
or    $3,$7,$0    └─ 保存结果
j     08H         ─── 继续循环
```

## 🛠️ 使用指南

### 📋 前置需求
- Vivado 2019.2
- ModelSim SE-64 10.5
- Xilinx 7系列FPGA

### ⚡ 快速开始

1. **克隆仓库**
```bash
git clone https://github.com/MuQY1818/MIPS-single-cycle-CPU.git
cd MIPS-single-cycle-CPU
```

2. **运行仿真**
```tcl
vsim -novopt tb
run -all
```

3. **查看波形**
```tcl
add wave -position insertpoint sim:/tb/*
```

## 🔧 调试功能

<details>
<summary>展开查看详细信息</summary>

- 🔍 寄存器实时监控
- 📊 波形完整记录
- 📱 LCD结果显示
- 🔄 状态实时更新

</details>

## ⚠️ 注意事项

- ⏰ 确保时钟配置正确
- 📈 注意数值溢出风险
- 🔌 LCD模块需额外配置
- 🕒 关注乘法器时序

## 🤝 贡献指南

1. Fork 本仓库
2. 创建新分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📝 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 👥 联系方式

<p align="center">
  <a href="mailto:weijuebu@gmail.com">
    <img src="https://img.shields.io/badge/Email-weijuebu%40gmail.com-blue?style=flat-square&logo=gmail">
  </a>
</p>

## 🌟 致谢

感谢 LOONGSON 团队提供的基础框架和参考设计。

<div align="center">

### 🌈 欢迎 Star & Fork

</div>
