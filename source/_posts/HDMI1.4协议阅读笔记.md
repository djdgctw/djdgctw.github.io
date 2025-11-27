---
title: HDMI1.4协议阅读笔记
date: 2025-11-24 14:30:00
tags:
  - HDMI
categories:
  - 接口协议
description: HDMI1.4协议阅读笔记
cover: img/02_HDMI/HDMI框架�?png
top_img: /img/01_cocotb/env-hero.png
---
# HDMI传输系统综述

一个 HDMI 传输系统由发送端（Source）和接收端（Sink）组成，线缆中主要包含：
- 四个差分对组成的主数据链路：三个 TMDS 数据通道 + 一个 TMDS 时钟通道
- VESA DDC（I²C），用于显示参数的配置与状态读取
- CEC（可选），消费电子控制总线
- HEAC，用于音频回传和以太网信号
- HPD，热插拔检测

![HDMI框架图](/img/02_HDMI/HDMI框架图.png)

本文聚焦在 HDMI1.4 的数据链路层――也就是 TMDS 链路在行场时序中的组织与编码方式。

## TMDS链路与时序总览

一帧视频在 TMDS 链路上会被拆分为三个传输区段：
1. **Control Period**：承上启下，告知即将到来的数据类型，并携带 HSYNC/VSYNC。
2. **Data Island Period**：传输音频样本与各种 InfoFrame 辅助数据。
3. **Video Data Period**：传输有效像素数据。

同步信号 HSYNC/VSYNC 在特定行、列被拉起，用于 Source 与 Sink 的帧时序对齐。实际线上传输的帧尺寸大于有效分辨率（例如 720×480p），因为在行首、行尾及场间插入了 **blank 区域**（包含 HBlank 与 VBlank）。这些 blank 区由 Control Period 与 Data Island Period 交替填充，而真正显示在屏幕上的区域被称为 **active 区**，即 Video Data Period。

![显示时序图](/img/02_HDMI/02.png)

### TMDS 时钟与编码粒度

在 TMDS clock 通道的每一次跳变（一个 TMDS Clock）中，每条数据通道都会输出一个 10bit 的字符。不同类型的数据使用不同的编码：

| 数据类型 | 原始位宽 | 编码方式 | 输出位宽 |
|----------|----------|----------|----------|
| Control data | 2 bit | 控制字符编码 | 10 bit |
| Packet data  | 4 bit | TERC4 编码 | 10 bit |
| Video data   | 8 bit | TMDS 8b/10b 编码 | 10 bit |
| Guard Band   | -     | 固定控制字符 | 10 bit |

因此“每个 TMDS Clock / 每条数据通道始终 10bit”这条规则贯穿整个链路，只是编码方式会跟随传输期而变化。

![信号传输框架](/img/02_HDMI/03.png)

## Control Period：承上启下

Control Period 是 HDMI 链路的“呼吸区”，它在 Video 与 Data Island 之间填充，用于：
- 传输 HSYNC / VSYNC（Channel0）
- 告知接下来是 Video 还是 Data Island（Channel1/2 上的 CTL0~CTL3）
- 提供字符同步、HDCP EESS 等控制信息

| 通道 | 承载内容 |
|------|----------|
| Channel 0 | HSYNC、VSYNC |
| Channel 1 | CTL0、CTL1 |
| Channel 2 | CTL2、CTL3 |

### Preamble：判定下一个周期

每个数据周期开始前都会插入长度为 8 个 TMDS Clock 的 Preamble，全部由相同的控制字符构成，用于提示下一阶段的类型。

![](/img/02_HDMI/05.png)

在 Preamble 期间 HSYNC、VSYNC 按原行场节奏继续输出，而 CTL0~CTL3 组合被限定为如下两种合法取值：

| CTL0 | CTL1 | CTL2 | CTL3 | 意义 |
|------|------|------|------|------|
| 1 | 0 | 0 | 0 | 下一个周期是 Video Data Period |
| 1 | 0 | 1 | 0 | 下一个周期是 Data Island Period |

![](/img/02_HDMI/06.png)

### Guard Band：真正的数据边界

Preamble 结束后紧接着会发送 Guard Band――两个特殊的 TMDS 字符，用以标记数据区的真实起点，同时告知 Sink 接下来到底是 Video 还是 Data Island。
- Video Guard Band 只出现在 Video Data Period 的起始位置
- Data Island Guard Band 位于 Data Island Period 的首尾（Leading/Trailing，均为 2 个 TMDS Clock）

> Preamble 用于“宣布类型”，Guard Band 用于“宣布开始”。

协议规定 CTL=1010 的控制字符只允许出现在 Preamble 中，否则接收端可能误以为 Data Island 即将到来。

### Character Synchronization

- TMDS character 指编码后的 10bit 单元。Video/Data Island 字符的跳变很少，而 Control 字符往往包含 >=5 次跳变。
- Source 必须让每次 Control Period 至少持续 2 个 TMDS Clock，让 Sink 可以凭借跳变密度确认字符边界。
- Source 还需至少每 50ms 插入一次持续 32 个 TMDS Clock 的 Extended Control Period，以便进一步稳固同步。

![](/img/02_HDMI/07.png)
![](/img/02_HDMI/08.png)

### Control Period Encoding

Control Period 使用固定表格完成 2bit→10bit 的编码，编码形式示意如下：

![](/img/02_HDMI/09.png)

## Data Island Period：音频与辅助数据

Data Island Period 不承载像素，而是负责所有 Packet 数据（如 Audio Sample、AVI/Vendor InfoFrame 等）。其组织规则如下：

- 前置 8 个 TMDS Clock 的 Data Island Preamble
- Leading / Trailing Guard Band 各 2 个 TMDS Clock
- 核心数据区由 1~8 个 Packet 组成（每个 Packet 固定 32 个 TMDS Clock）
- Preamble 之前必须有 ≥4 个 TMDS Clock 的普通 Control Period，保证字符同步
- Data Island 与 Video 周期间必须插入至少一个 Control Period，二者不可直接相邻

![TMDS Period AND Encode](/img/02_HDMI/04.png)

### Guard Band 期间的通道分工

在 Data Island Guard Band 内：
- Channel1/Channel2 被直接映射为固定的 10bit 字符（如下图所示）
- Channel0 中 D2/D3 固定为 1；根据 HSYNC/VSYNC 不同，会出现 0xC~0xF 四种 nibble，再经 TERC4 编码得到最终字符

![Data Island Guard Band通道编码](/img/02_HDMI/10.png)

与此同时：
- Channel0 的 D0、D1 仍承担 HSYNC、VSYNC
- Leading Guard Band 之后的第一个 TMDS Clock，Channel0 的 D3 置 0，其余时刻保持 1
- Channel1/Channel2 的 8bit 数据负责 Packet 内容（Guard Band 内除外）

### Packet 结构

每个 Packet = Header + Body，两部分都配有 BCH 校验位：

1. **Packet Header（HB0/HB1/HB2）**  
   - 原始 24bit 数据 + BCH(32,24) → 32bit  
   - 由 Channel0 的 D2 传输
2. **Packet Body（4 个 Subpacket）**  
   - 每个 Subpacket：56bit 数据 + BCH(64,56) → 64bit  
   - 共 4 个 Subpacket（Block0~Block3），通过 Channel1/Channel2 传输

Subpacket 会被线性映射为 PB0~PB27：

| Subpacket | 包含字节 | 映射到 PB |
|-----------|----------|-----------|
| Subpacket0 | SB0~SB6 | PB0~PB6 |
| Subpacket1 | SB0~SB6 | PB7~PB13 |
| Subpacket2 | SB0~SB6 | PB14~PB20 |
| Subpacket3 | SB0~SB6 | PB21~PB27 |

这种连续映射便于 Sink 逐字节解析 Packet Body，也满足 BCH Block 的数据布局要求。

![Packet映射示意](/img/02_HDMI/11.png)

### BCH 纠错

HDMI 通过 BCH 编码保证音频与 InfoFrame 数据的可靠性：
- Subpacket 使用 BCH(64,56)
- Packet Header 使用 BCH(32,24)

下图给出了各字段的 BCH 位置分布，具体多项式略。

![Packet纠错位](/img/02_HDMI/12.png)

### Data Island 的编码：TERC4

Data Island 所有 4bit 数据（Guard Band、Preamble、Packet 内容）都必须先过 **TERC4** 编码，再映射到 10bit TMDS 字符。

```
Data Island
 ├── Guard Band (TERC4 固定字符)
 ├── Preamble  (TERC4 固定字符)
 └── Packet
      ├── Header (4bit nibbles 逐个 TERC4)
      └── Body   (4bit nibbles 逐个 TERC4)
```

![TERC4编码示意](/img/02_HDMI/13.png)

## Video Data Period：像素传输

Video Data Period 是 TMDS 链路真正搬运 RGB 像素的阶段：
- Video Preamble（8 个 TMDS Clock） + Video Guard Band（2 个 TMDS Clock，仅出现在段首）
- Active Video 区域三条通道分别传输 Blue/Green/Red 的 8bit 数据
- 三条通道共完成一个像素的 24bit 传输，TMDS Clock = Pixel Clock
- 在 InfoFrame 中还会声明具体像素格式、色域等信息

![Video Data Period Signal](/img/02_HDMI/14.png)

## TMDS 编码流程（8bit→10bit）

TMDS（Transition Minimized Differential Signaling）的目标是**减少跳变**和**保持直流平衡**，整个过程可拆为两步：

### Step 1：8bit→9bit（最小化跳变）

编码器会分别尝试 XOR 与 XNOR 两种方式递推 8bit 数据：
1. output[0] 直接等于输入 LSB。
2. 对 n=1~7，计算 `output[n] = input[n] XOR output[n-1]`（或 XNOR 版本）。
3. 比较两套结果的跳变次数，选择跳变更少的那套。
4. 生成的 9bit 中，MSB 用来标记选择的是 XOR（0）还是 XNOR（1）。

示例：
```python
input  = 1100_1010
方案A = XOR  方式生成的 9bit
方案B = XNOR 方式生成的 9bit
# 统计两套结果的跳变次数，选择较小者
```

### Step 2：9bit→10bit（直流平衡）

第二步为了实现 DC Balance，会增加第 10bit（通常记为 `q_m[9]`），并根据“已发送 1/0 的累积差值”决定是否将前 9bit 取反。
- 如果当前字符 1 比 0 多且累积差值也偏正，则取反
- 如果累积差与当前字符趋势相反，则保持不变
- 第 10bit 记录此次是否进行了取反

完整流程如下图所示，该编码总共会产出 460 种合法的 10bit 字符。只要编码器运作正常，Video Data Period 中不会出现其他字符；Guard Band、Control Period、Data Island 则各自使用专用字符集合，Sink 可以据此区分当前所处的 Period。

![TMDS编码流程1](/img/02_HDMI/15.png)
![TMDS编码流程2](/img/02_HDMI/16.png)

## 编码方式速查

| 场景 | 触发条件 | Guard Band | 编码方式 |
|------|----------|------------|----------|
| Control Period | Video/Data Island 之间的空档 | 固定控制字符 | 2bit→10bit 控制编码 |
| Data Island | Blank 区承载音频/InfoFrame | Leading+Trailing（各 2 个 Clock） | TERC4（4bit→10bit） |
| Video Data | Active 区像素传输 | 仅 Leading（2 个 Clock） | TMDS（8bit→10bit） |

![编码图](/img/02_HDMI/17.png)

## 代码设计图
![编码图](/img/02_HDMI/18.png)
