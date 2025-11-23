---
title: KV260 视频链路实验记录：从 ISP 到 HDMI
date: 2025-02-20 09:30:00
updated: 2025-02-20 09:30:00
categories:
  - Lab Notes
tags:
  - KV260
  - 视频链路
  - HDMI
  - 实验记录
cover: https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1400&q=80&ixlib=rb-4.1.0
description: 用 KV260 打通 RAW Sensor → ISP → 视频缓存 → HDMI 输出的链路，并记录调试步骤与可复用的脚本。
---

> 笔记以“模块目标 + 关键寄存器 + 验证方法”记录，方便复现或移植到其他平台。

## 1. 整体架构

```text
MIPI/RAW Sensor
    ↓ (AXI Stream)
Image Signal Processor (Demosaic + Gamma)
    ↓
AXI VDMA (Write)
    ↓
DDR 圆形缓冲
    ↓
AXI VDMA (Read)
    ↓
Video Mixer (OSD + Scaling)
    ↓
HDMI TX Subsystem
```

核心是把 ISP 与 HDMI TX 解耦，通过 VDMA 做帧缓存，调试时可以单独验证每个 Stage。

## 2. Sensor & ISP

- 选择 `imx219` 作为 RAW 输入，MIPI 配置脚本使用 `i2cset` 写寄存器，注意 `0x0157` 需设置为正确的 `line_length_pck`。
- ISP 只开启 Demosaic + Gamma，关闭变焦模块以减少延迟。
- 用 `v4l2-ctl --stream-mmap --stream-to=/dev/null --stream-count=200` 先确认 Sensor 输出稳定。

## 3. VDMA 的关键寄存器

| 寄存器 | 作用 | 经验值 |
| --- | --- | --- |
| `MM2S_VSIZE` | 行数 | 1080 |
| `MM2S_HSIZE` | 单行字节数 | 3840 (1920×2B) |
| `FRMDLY_STRIDE` | 行间距 | 4096, 对齐 4KB |

Tips：KV260 上 DDR 通常配置为 32bit AXI，总线利用率不够时，可以把 `HSIZE` 扩充到 4096 字节来做突发。

## 4. 调试脚本

```bash
# 写通 Sensor → ISP → VDMA
sudo modprobe xlnx-isp
sudo modprobe xilinx-vdma

media-ctl -d /dev/media0 -l "'mipi_csi2 0':1 -> 'xilinx-video 0':0 [1]"
media-ctl -d /dev/media0 -V "'mipi_csi2 0':1 [fmt:SRGGB10_1X10/1920x1080@1/30]"

vdma_ctl write start --width 1920 --height 1080 --fmt rgb
```

## 5. HDMI 输出

- HDMI TX Subsystem 选择 148.5 MHz, Color Depth 8bit，勾选内置 InfoFrame 生成器。
- 如果屏幕黑屏，优先检查 `HPD` 是否拉高、EDID 读取是否成功（`cat /sys/kernel/debug/dri/0/i915_edid_raw`）。
- 用 `xilinx-axidma` 工具注入彩条数据，可以验证链路是否正确。

## 6. 待办

- [ ] 增加 HDR 元数据通路
- [ ] 编写自动化 bring-up 脚本，整合到 `make video-demo`
- [ ] 测试两路 PIP 输出

有问题欢迎在评论区一起讨论。
