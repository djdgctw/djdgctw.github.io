---
title: 基于 Python 的 Cocotb 仿真环境配置：Verilator · Cocotb · GTKWave
date: 2025-11-23 14:30:00
tags:
  - cocotb
  - verilator
  - gtkwave
categories:
  - 工具链
description: 记录在 Ubuntu/WSL 上搭建 Cocotb + Verilator + GTKWave 仿真环境的全过程，方便快速复刻。
cover: /img/01_cocotb/03.png
top_img: /img/01_cocotb/env-hero.png
---

> “跑通 demo 之前，先把环境配稳定。” —— 把每一步都写清楚，后续实验就能快速复现。

## 1. Python & Cocotb 安装

### 1.1 Python 环境

```bash
# 推荐 Python 3.10+，conda / pyenv 均可
sudo apt update
sudo apt install python3 python3-pip python3-venv -y

python3 -m venv ~/.venvs/cocotb
source ~/.venvs/cocotb/bin/activate
```

### 1.2 安装 Cocotb 及常用依赖

```bash
pip install --upgrade pip wheel
pip install cocotb cocotb-bus pytest
```

> 如果使用 VS Code，记得把虚拟环境指向 `~/.venvs/cocotb`.

## 2. Verilator 安装

### 2.1 apt 安装（简单）

```bash
sudo apt install verilator -y
verilator --version
```

### 2.2 源码安装（需要最新版本时）

```bash
sudo apt install git perl python3 make autoconf g++ flex bison libfl2 libfl-dev \
  zlibc zlib1g zlib1g-dev -y

git clone https://github.com/verilator/verilator.git
cd verilator
git checkout v5.026   # 根据需要选择版本
autoconf
./configure
make -j$(nproc)
sudo make install
```

> 如果系统已有旧版本，可在 `~/.bashrc` 中将 `/usr/local/bin` 提到 `PATH` 前面，让新版本优先。

## 3. GTKWave 安装（波形查看）

```bash
sudo apt install gtkwave -y
```

常用启动方式：

```bash
gtkwave logs/dump.vcd &
```

配合 Verilator/Cocotb 生成的 `.vcd` 或 `.fst` 文件即可。

## 4. 仿真工程模板初始化

```bash
mkdir -p ~/workspace/cocotb-demo && cd $_
git clone https://github.com/djdgctw/first_cocotb_testbench.git
cd first_cocotb_testbench/01_base

# 检查环境变量
which verilator
python -c "import cocotb; print(cocotb.__version__)"

# 运行一次 demo
make run-logged SIM=verilator
```

若输出 `INFO: Running on Verilator ...` 并生成 `logs/report.log`，说明环境 OK。

## 5. 常见问题

| 现象 | 处理 |
| --- | --- |
| `verilator: command not found` | 检查 `PATH`，确认 `/usr/bin` 或 `/usr/local/bin` 被包含。 |
| `ImportError: No module named 'cocotb'` | 虚拟环境未激活或 pip 安装在系统 Python，重新 `source ~/.venvs/cocotb/bin/activate`。 |
| GTKWave 打不开中文路径 | 避免把波形文件放在含中文空格的路径，或使用 `LANG=en_US.UTF-8 gtkwave ...`。 |

## 6. 后续文章

- [基于 Python 的 Cocotb 库对 Verilog 进行仿真教程（一）](../基于python的cocotb库对verilog进行仿真教程-一)
- 即将更新：波形可视化、与 ModelSim/Vivado IP 协同的实践

做好环境之后，后续的 Cocotb 实验就只剩“写 testbench + make run”这两个动作，祝玩得开心。
