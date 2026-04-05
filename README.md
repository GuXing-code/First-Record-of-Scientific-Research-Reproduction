

# falunwen

一个基于MATLAB的无线通信系统仿真项目，用于复现论文中的相关技术与算法。

## 项目简介

本项目包含一个完整的无线通信系统仿真框架，涵盖了QPSK调制解调、信道估计、时域均衡、干扰消除等核心通信技术的MATLAB实现。适用于学习和研究无线通信系统中的各种信号处理算法。

## 主要功能

- **QPSK调制解调**：实现QPSK信号的调制与解调功能
- **信道估计**：提供信道估计算法，用于获取信道状态信息
- **时域均衡**：实现RLS DFE自适应均衡器
- **时间反转**：自适应时间反转技术
- **干扰消除**：连续干扰消除（SIC）技术
- **性能评估**：计算系统的误码率（BER）

## 文件说明

| 文件 | 功能 |
|------|------|
| run_main.m | 主程序入口 |
| qpsk_mod.m | QPSK调制 |
| qpsk_demod.m | QPSK解调 |
| channel_estimation.m | 信道估计 |
| rls_dfe_equalizer.m | RLS DFE均衡器 |
| adaptive_time_reversal.m | 自适应时间反转 |
| time_reversal.m | 时间反转技术 |
| calc_ber.m | 误码率计算 |
| true_equivalent_channel.m | 等效信道 |

## 使用方法

在MATLAB环境中直接运行 `run_main.m` 主程序即可启动仿真。

```matlab
% 在MATLAB命令窗口中运行
run_main
```

## 运行要求

- MATLAB R2016a 或更高版本
- 信号处理工具箱（Signal Processing Toolbox）

## 目录结构

```
falunwen/
└── paper reproduction/
    └── First/          # 主要仿真代码目录
```

## 技术背景

本项目实现了无线通信中的多项关键技术：
- LFM信号同步
- QPSK基带调制
- 自适应滤波与均衡
- 时域信号处理

具体可参考各子程序中的实现细节和算法描述。