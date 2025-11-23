---
title: 关于 djdgctw
date: 2025-11-23 10:43:31
updated: 2025-11-23 14:45:00
type: about
comments: true
description: 记录我在 FPGA / 视频接口 / 嵌入式系统方向的折腾与踩坑。
---

你好，我是 **djdgctw**，一名在 FPGA、视频链路和嵌入式系统之间穿梭的工程师兼 B 站 UP（账号：对酒当歌晚长亭）。我相信“能复现的经验才配上线”，所以这里的笔记都踩过坑、跑过真机。

## 现在关注的方向

- **HDMI / DP 视频链路**：协议细节、TMDS/DP 编码与板级 SI
- **KV260 & Zynq**：Linux 侧驱动、PL pipeline、视频缓冲
- **SpinalHDL / Chisel**：用现代语言写出可维护的 RTL

## 能力矩阵

| 模块 | 工具链 | 备注 |
| --- | --- | --- |
| 视频处理 | Vivado HLS · SpinalHDL | ISP、色彩空间转换、OSD |
| 接口协议 | Verilog · SystemVerilog | HDMI、LVDS、MIPI D-PHY |
| 嵌入式 | PetaLinux · Yocto | 设备树、驱动、调试脚本 |

## 常用设备

- R&S RTM3K 示波器 / Tektronix TDR
- Digilent ZedBoard、KV260、自研 MiniLED Driver 板
- Ansible + Tmuxp 维护的远程实验室

## 写作原则

1. 所有命令都在真机验证，能复现才记录
2. 图表必须注明来源与单位，方便同行 review
3. 以中文为主，但保留关键术语的英文原文

<div id="roadmap"></div>

## Roadmap

1. **HDMI 1.4 系列**：补完 HDCP、EDID、InfoFrame、调试脚本
2. **Mini LED 视频链路**：多路并行驱动 + 色彩管理实践
3. **SpinalHDL 实战**：Stream/Flow Cookbook 与项目脚手架

## 联系方式

- GitHub: [@djdgctw](https://github.com/djdgctw)
- Email: fpga@djdgctw.dev
