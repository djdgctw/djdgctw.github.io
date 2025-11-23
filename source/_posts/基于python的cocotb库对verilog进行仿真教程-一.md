---
title: 基于 Python 的 Cocotb 库对 Verilog 进行仿真教程（一）
date: 2025-11-23 13:24:27
tags:
  - cocotb
  - verilog
description: 基于 Verilator 与 Cocotb 对 Verilog 模块进行协同仿真的基础流程与原理讲解。
cover: /img/01_cocotb/03.png
---

## 项目地址

👉 <https://github.com/djdgctw/first_cocotb_testbench>

本教程对应仓库的 `01_base` 示例，是 Verilator × Cocotb 入门的最小可运行工程。


## 1. 跑通 01_base 基础流程

环境要求：

1. Ubuntu（或 WSL2）  
2. Verilator（apt 或源码编译均可）  
3. Python（conda / 系统 Python 均可）  
4. `pip install cocotb`

克隆仓库后进入：

```bash
cd first_cocotb_testbench/01_base
````

项目结构如下：

![01\_base项目结构示意图](/img/01_cocotb/01.png)


## 2. 示例流程讲解

在 `01_base` 目录下执行：

```bash
make run-logged SIM=verilator
```

该命令会：

* 调用 cocotb 的 Makefile 体系
* 使用 Verilator 对 `src/dff.sv` 进行编译
* 运行 Python 侧的 testbench
* 将运行日志与波形存入 `logs/` 目录（含 `report.log` 与波形文件）

Makefile 关键逻辑如下：

![makefile部分代码](/img/01_cocotb/02.png)


## 3. 原理讲解

本示例由 Verilog 设计文件 `dff.sv` 与 Python Cocotb 测试文件 `test_dff.py` 组成，二者通过 cocotb 的 VPI/PLI 接口建立交互。

### 3.1 Verilog 代码讲解（被测模块 DUT）

以下是示例中最小 D 触发器：

```verilog
`timescale 1us/1ns

module dff (
    output logic [3:0] q,
    input  logic       clk,
    input  logic [3:0] d
);

always @(posedge clk) begin
    q <= d;
end

endmodule
```

解释：

* 上升沿采样：每个 `posedge clk`，`q` 都会更新为 `d`
* 延迟语义：行为等价于 “q = d 上一拍的值”
### 3.2 Cocotb Python 测试代码讲解

以下为本示例中的核心测试函数：

```python
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
import logging

@cocotb.test()
async def test_dff_simple(dut):
    """验证 d 能正确传递到 q"""

    # 创建日志器
    logger = logging.getLogger("my_testbench")
    logger.setLevel(logging.DEBUG)

    # 创建 10us 周期的时钟
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # 进行 10 轮随机激励
    for i in range(10):
        val = random.randint(0, 7)
        dut.d.value = val  # 写入 DUT 输入

        await FallingEdge(dut.clk)  # 等待一个时钟下降沿

        logger.info(f"周期 {i}: d={dut.d.value}, q={dut.q.value}")

        # 断言检查（若错误会自动中止测试）
        assert dut.q.value == val, \
            f"第 {i} 次检查失败：期望 {val}，实际 {dut.q.value}"
```

重点：

* `@cocotb.test()`：声明 Python 测试用例
* `Clock(...)`：在 Python 侧创建时钟并驱动 DUT
* `await FallingEdge(...)`：事件驱动式仿真
* `.value` 是 cocotb 写入和读取信号的标准方式
* 断言错误会直接标红报告


### 3.3 Makefile 核心部分解释

```Makefile
# testbench 作为 Python 模块路径
export PYTHONPATH := $(PWD)/testbench:$(PYTHONPATH)

# 指定被测模块语言
TOPLEVEL_LANG = verilog

# DUT 的源文件
VERILOG_SOURCES = $(PWD)/src/dff.sv

# 顶层模块名
TOPLEVEL = dff

# Cocotb 的 Python 测试模块名（不带 .py）
MODULE = test_dff

# 默认使用 Verilator
SIM ?= verilator

# 引入 cocotb 的标准 Makefile
include $(shell cocotb-config --makefiles)/Makefile.sim
```

简要说明：

* `TOPLEVEL` 必须与 Verilog 中的模块名一致
* `MODULE=test_dff` 指定 Python 测试入口
* `VERILOG_SOURCES` 决定参与仿真的 RTL 文件
* `cocotb-config` 自动选择正确的仿真器后端

> **换模块时，只需改：**
> `src/*.sv`、`TOPLEVEL`、`MODULE`
> 其余逻辑无需修改。

## 4. 小结

本篇示例展示了 Cocotb 最小可运行工程的结构和原理，包括：

* Verilator + Cocotb 的协同仿真流程
* Verilog DUT 的构成
* Python 异步 testbench 的写法
* Makefile 如何将两者串联

在后面篇章中我将逐渐更新：
- 如何利用python强大的功能将verilog仿真结果转化为可观看的图片
- 如何使得cocotb通过modelsim支持vivado中使用了ip核的仿真


