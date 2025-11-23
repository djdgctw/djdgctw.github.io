---
title: 关于 djdgctw
date: 2025-11-23 10:43:31
updated: 2025-11-23 11:30:00
type: about
comments: true
description: 记录我在 FPGA / 视频接口 / 嵌入式系统方向的折腾与踩坑。
---

你好，我是 **djdgctw**，一个在高速接口与图像处理之间反复横跳的硬件工程师。白天写 FPGA/SoC，晚上写博客，把实验室的碎碎念整理成可复现的笔记。

## 现在关注的方向

- **HDMI / DP 视频链路**：协议、编码、板级信号完整性
- **KV260 & Zynq**：从 Linux 驱动到 PL 端 pipeline
- **SpinalHDL / Chisel**：用现代语言写出可维护的 RTL

## 能力矩阵

| 模块 | 工具链 | 备注 |
| --- | --- | --- |
| 视频处理 | Vivado HLS · SpinalHDL | ISP、色彩空间转换、OSD |
| 接口协议 | Verilog · SystemVerilog | HDMI、LVDS、MIPI D-PHY |
| 嵌入式 | PetaLinux · Yocto | 设备树、驱动、调试脚本 |

## 常用设备

- R&S RTM3K 示波器 / Tektronix TDR
- Digilent ZedBoard、KV260、定制 MiniLED Driver 板
- Ansible + Tmuxp 维护的一套远程实验室

## 写作原则

1. 所有命令都经过真机验证，能复现才上线
2. 图表必须有来源和单位，方便同行 review
3. 优先用中文写作，但附带核心术语的英文原文

<div id="roadmap"></div>

## Roadmap

1. **HDMI 1.4 系列**：HDCP、EDID、InfoFrame、调试脚本
2. **Mini LED 视频链路**：多路并行驱动 + 色彩管理
3. **SpinalHDL 实战**：整理一套 Stream/Flow cookbook

## 联系方式

- GitHub: [@djdgctw](https://github.com/djdgctw)
- Email: fpga@djdgctw.dev
- 如果你也在折腾视频接口，欢迎留言或者提 issue。
