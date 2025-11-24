---
title: HDMI1.4协议阅读笔记
date: 2025-11-24 14:30:00
tags:
  - HDMI
categories:
  - 接口协议
description: HDMI1.4协议阅读笔记
cover: img/02_HDMI/HDMI框架图.png
top_img: /img/01_cocotb/env-hero.png
---
# HDMI传输系统综述

一个HDMI传输系统包括发送端（source）和接收端（sink）。HDMI线缆包括以下连接：
- 由四个差分对组成的主数据通路，包括三个数据通道和一个时钟通道。
- VESA DDC，实际上就是一个I2C bus，用于配置和状态信息的传输
- CEC（optional），消费电子控制
- HEAC，家庭影院系统中音频回传功能
- HPD，热插拔检测
![HDMI框架图](/img/02_HDMI/HDMI框架图.png)
HDMI物理层的实现不在此次赘述，下面直接进入HDMI的数据链路层。

## HDMI信号编码

HDMI一共有三种传输模式：Control Period传输control data；Data Island Period传输packet data；Video Data Period传输video data。

同步信号HSYNC和VSYNC会在特定的行、列位置拉起，用于source和sink之间的同步。可以看到实际传输的帧大小是要大于视频大小（720*480p），包括额外插入了一些行，并且行的长度也得到了扩展，这些扩展的区域被称为blank区（包括Vblank和Hblank），blank区由Control Period和Data Island Period交替填充，其中在Data Island Period会传输音频数据和其他辅助数据（例如像素格式等）。实际传输Video Data Period的区域称为active区，传输我们最终会在显示器上看到的视频图像数据。
![显示时序图](/img/02_HDMI/02.png)
在HDMI clock channel上每一拍时钟（又称为一个TMDS Clock），每个data channel上都会传输10bit的character。这10bit的character，对于不同的数据，由不同的编码方式得到：
- control data：2 bit -> 10 bit编码
- packet data：4 bit -> 10 bit编码（TERC4编码）
- video data：8 bit -> 10 bit编码（TMDS编码）

换句话说，每个TMDS Clock，在每个data channel上，会传输2bit的control data，或者4bit的packet data，或者10bit的control data。
![信号传输框架](/img/02_HDMI/03.png)
### Control data
- 在channel 0的2bit数据代表HSYNC和VSYNC
- channel 1和channel 2上的4bit数据组合构成CTL0-3，其代表的具体信息在后文介绍。

### Packet data
- channel 0上的4bit数据包含HSYNC、VSYNC以及packet header，packet header用于sink判断当前packet的类型（音频包、辅助信息包等）
- channel 1和channel 2上传输实际packet信息，如音频包会在这两个channel上传输音频信号采样值。

### Video data
- channel 0到channel 2上总共24bit，均为视频像素数据。

## Data Island Period 和 Video Data Period 的传输规则

### Data Island Period
- 紧贴Data Island Period传输的前后，分别有一个Data Island Guard Band（称为Leading Guard Band和Trailing Guard Band），长度均为2个TMDS Clock。
- 在Leading Data Island Guard Band前面，有一个Data Island Preamble，长度为8个TMDS Clock。
- 由于HDMI1.4协议规定，每次发Control Period必须连续发至少12个TMDS Clock。由于Data Island Preamble被视为一种特殊的Control Period，因此在Data Island Preamble前面会有至少连续4 TMDS Clock的Control Period。
- 在两个Data Island Guard Band包围起来的中间区域，会发送实际的packet data。每一个packet需要32个TMDS Clock，可以连续发送最少1个，最多18个packet。因此每一个Data Island Period的最小长度为1×32 + 2×2 = 36 TMDS Clock（头尾的两个Guard Band也是Data Island Period的一部分）。

### Video Data Period
- 与Data Island Period类似，有一个长度为2 TMDS Clock的Video Data Guard Band，但仅存在于Video Data Period传输最开始（也即只有Leading Guard Band）。
- 同样有一个长度为8 TMDS Clock的Video Data Preamble。
- Video Data Preamble前面同样会有至少连续4 TMDS Clock的Control Period。
- Data Island Period和Video Data Period不能紧贴，无论哪一个在前，在前者传输完成后必须传输一段Control Period，才能传输后者。
![TMDS Period AND Encode](/img/02_HDMI/04.png)
## Control Period

Control Period在channel 0上传输HSYNC和VSYNC，在channel 1-2上传输CTL0-3。HDMI1.4协议下，CTL0-3主要用于Video Data Preamble和Data Island Preamble传输，以及被sink用作为Character Synchronization（也用于HDCP1.4 EESS信号传输）。
![](/img/02_HDMI/05.png)
### Preamble
Channel 0上的HSYNC和VSYNC在Preamble期间按实际情况正常传输
![](/img/02_HDMI/06.png)
### Character Synchronization
- TMDS Character是指每次编码后，每个TMDS Clock传输的10 bit值。
- 经过编码后，Video Data Period和Data Island Period的每个character会包含5次或者更少的1->0或0->1跳转，而Control Period会包含7次或更多的跳转。
- 基于此，source端的每次Control Period需要持续12个TMDS Clocks，而sink端的解码器应该能识别到这样连续的Contral Period传输，从而同步到Character边界。Sink端的检测算法实现由其自行决定，不在HDMI1.4协议中做要求。
![](/img/02_HDMI/07.png)
- 每隔一定时间间隔（至少50毫秒一次），source端还被要求要发一个持续时间更长（32 TMDS Clocks）的Control Period，被称为Extended Control Period。
![](/img/02_HDMI/08.png)
### Control Period Encoding
![](/img/02_HDMI/09.png)
## Data Island Period

对于Data Island Period（包括对应的Guard Band）的传输：
- 下面指代的是[3:0]长度的那个信号
- channel 0中的D0和D1分别传输HSYNC 和VSYNC
- D2传输Packet Header（在Guard Band区域固定传输1）
- D3在Leading Guard Band后的第一个TMDS Clock传输0，在其他TMDS Clock（包括Guard Band）传输
- channel 1和channel 2的总计8bit用于传输Packet Data（Guard Band区域会传输固定的10 bits character）

### Data Island Guard Band
- Data Island Guard Band时，channel 1和channel 2被直接编码为实际HDMI Lane上固定的10 bit Character，其值如下图，其中channel0由编译规则决定，NA实际上是不确定的意思
![Data Island Guard Band时,channel1,2编码后固定值](/img/02_HDMI/10.png)
- channel 0上，D2和D3被固定为1，因此，依据HSYNC和VSYNC的取值，channel 0上D[3:0]可能的取值为0xC，0xD，0xE，0xF，并通过TERC4编码为10bit character

### Data Island Packet（数据岛包）结构说明
在 HDMI Data Island Period 中，所有音频包和 InfoFrame 辅助数据都以 **Packet** 的形式传输。  
每一个 Packet 占用 **32 个 TMDS Clocks**，由以下两大部分组成：

1. **Packet Header（包头）**  
2. **Packet Body（包含 4 个 Subpacket 的包体）**

每个部分都包含对应的 **BCH 纠错位（ECC）**。

#### 1. Packet Header（24bit 数据 + 8bit BCH 校验）
Packet Header 共 24bit，由 3 个 Header Bytes（HB0、HB1、HB2）组成。  
根据 HDMI 规范，需为 Header 添加 **8bit 的 BCH(32,24) 校验位**，构成 **32bit 的 BCH Block4**。
**该 BCH Block4 通过 Channel 0 的 D2 线上传输。**
#### 2. Packet Body（4 个 Subpacket）
Packet Body 包含 **4 个 Subpacket**，每个 Subpacket 包含：
- **56 bits 数据**
- **8 bits BCH(64,56) 校验位**
每个 Subpacket 构成一个 BCH Block（Block0–Block3）。  
**这些 BCH Blocks 通过 Channel 1 和 Channel 2 传输。**
#### 3. Subpacket 到 Packet Bytes（PBx）的映射
每个 Subpacket 的 56bit 等于 **7 个字节**：SB0, SB1, SB2, SB3, SB4, SB5, SB6
4 个 Subpacket 共 **28 个字节**，HDMI 将它们顺序拼接为：PB0 ~ PB27
- 映射关系如下：
| Subpacket | 包含字节 | 映射到 PB 范围 |
|-----------|----------|----------------|
| Subpacket0 | SB0–SB6 | PB0 – PB6 |
| Subpacket1 | SB0–SB6 | PB7 – PB13 |
| Subpacket2 | SB0–SB6 | PB14 – PB20 |
| Subpacket3 | SB0–SB6 | PB21 – PB27 |
- 这种连续映射方式方便 Sink 对 Packet Body 进行线性解析，也符合 BCH Block 数据布局要求，解码时根据这个解码。

关系图如下
![Data Island Guard Band时,channel1,2编码后固定值](/img/02_HDMI/11.png)

### 纠错位计算（ECC）

HDMI 的 Data Island Packet 使用 BCH 纠错码来保护 Header 与 Subpacket 的数据完整性。

- **BCH(64,56)** 用于 56bit Subpacket 数据  
- **BCH(32,24)** 用于 24bit Packet Header 数据

纠错位由标准的 BCH 生成多项式计算得到。  
具体的 BCH 计算细节不在此处展开。

![Packet纠错位](/img/02_HDMI/12.png)


### Packet Header 和 Packet Body 的定义

Packet Header（HB0、HB1、HB2）以及 Packet Body（Subpacket 结构）在 HDMI1.4 数据岛章节中有详细定义。  
后续文章会继续展开具体结构和类型意义。


### Data Island Period 编码：TERC4（后面修）

Data Island 中的所有 4bit 数据必须通过 **TERC4 编码** 转换为 10bit TMDS 字符。  
TERC4 是 HDMI 定义的固定编码表，被用于 Packet Data、Guard Band 等区域。
Data Island Period
│
├── Guard Band (TERC4)
├── Preamble (TERC4)
│
└── Packet
     ├── Header (4bit nibbles → TERC4)
     └── Body   (4bit nibbles → TERC4)

![TERC4编码示意](/img/02_HDMI/13.png)

### Video Data Period
Video Data Period 是 HDMI 用于传输实际像素 RGB 数据的区域。
#### 1. Video Data Period Signal
在 Video Data Period 内：
- Video Data 的 Guard Band 用于告知 Sink：即将进入 Video Data Period
- **Guard Band（前导 GB）**：3 个通道会发送固定的 TMDS 字符，固定字符如下
![Video Data Period Signal](/img/02_HDMI/14.png)
- **Active Video 区域**：三通道传输 RGB，每个通道 8bit
#### 3. Pixel Data(像素数据)(后面修)

Active Video 区域内：

- Channel 0 → Blue（8bit）
- Channel 1 → Green（8bit）
- Channel 2 → Red（8bit）

像素数据经 TMDS 编码后以 10bit character 输出。

（具体 Pixel 格式与 InfoFrame 中 AVI 信息相关，将在后续章节展开。）

---

### Video Data Period 编码：TMDS（8bit → 10bit）

TMDS 编码的目标：
- 减少跳变次数（减少 EM 噪声）
- 保持直流平衡（长期传输中 1/0 数量保持平均）
TMDS 编码包含两个步骤：
#### Step 1：8bit → 9bit（最小化跳变）
第一步8->9bits的编码：9bits code的LSb等于输入的8bits的LSB，随后的7bit，每一bit的计算都基于如下公式: output[n] = input[n] OR output[n-1]，或output[n] = input[n] NOR output[n-1]。具体计算选择XOR（异或）还是XNOR（同或），取决于哪种模式编码得到的9bits code中的跳变更少（算法使用的判断条件如下流程图所示）。9bits code的MSb用于指示当前编码使用的是OR还是NOR。
##### 解析
在 HDMI 的 TMDS（Transition Minimized Differential Signaling）编码中，为了减少信号跳变、降低电磁干扰（EMI），对原始 8bit 数据进行编码时会尝试两种方式：**XOR** 和 **XNOR**，并选择其中**跳变次数更少**的一种。最终输出为 9bit 编码结果，其中最高位（MSB）用于指示所选的编码方式。

假设输入 8bit 是：
```python
input = 1100_1010
         ↑    ↑
       MSB    LSB
第 1 步：生成 9bit 的输出（先试 XOR）
① output[0] = input[0]（LSB 对齐）
假设最右边是 bit0：
input:   i7 i6 i5 i4 i3 i2 i1 i0
                         ↑
output0 = i0
例如：
output[0] = 0
② 从 output[1] 开始依次计算：
output[n] = input[n] XOR output[n-1]
举例：
output[1] = input[1] XOR output[0]
output[2] = input[2] XOR output[1]
output[3] = input[3] XOR output[2]
...
一直到 output[7]
这样就得到 一个 8bit 序列（递推生成）
③ 第 9bit（MSB）标记：
MSB = 0  (代表使用 XOR)
第 2 步：再试一次 XNOR
同样步骤：
output[n] = input[n] XNOR output[n-1]
这样得到另一套 9bit 序列。
第 3 步：比较两套 9bit 的跳变次数
例如你算出来：
XOR 方式：出现 5 次跳变
XNOR 方式：出现 2 次跳变
👉 选择跳变少的 XNOR
并把 9bit 的 MSB 设置为：
MSB = 1   （代表选择了 XNOR）
```

#### Step 2：9bit → 10bit（保持直流平衡）
- 第二步9->10bits的编码：实现数据流的直流平衡。添加一个第10bit的最高位，以指示是否对数据进行按位取反。编码器基于目前已传输的数据流中0和1的数量差异，以及当前character已编码的低8bits的0和1的数量差异，决定是否进行取反。
- 这里的取反是根据前面发了很久的数据，计算出来现在是0多还是1多，然后决定是否取反这样
- 所有的编码流程如下图所示。整个编码会产生460种不同的10 bits characters。在编码器正确工作的情况下，不应在Video Data Period产生其他的characters。
![TMDS编码流程1](/img/02_HDMI/15.png)
![TMDS编码流程2](/img/02_HDMI/16.png)
#### TMDS 字符集
TMDS 编码共生成约 **460 种有效的 10bit 字符**。  
Video Data Period 内不应出现非 TMDS 编码字符；  
Guard Band、Control Period、Data Island 使用不同字符集，Sink 可根据字符类型识别当前 Period。


