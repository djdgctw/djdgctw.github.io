---
title: SpinalHDL Stream 小抄：5 个提升流水线可读性的技巧
date: 2025-02-10 21:30:00
updated: 2025-02-18 08:00:00
categories:
  - FPGA
tags:
  - SpinalHDL
  - Scala
  - 流水线
  - 笔记
cover: https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=1400&q=80&ixlib=rb-4.1.0
description: 记录在视频链路项目里使用 SpinalHDL Stream 接口时积累的模式，从命名到仿真都覆盖。
---

SpinalHDL 的 `Stream`/`Flow` 是数据路径的基石，语法简单但很容易写成“神秘黑盒”。这篇整理了几个最常用的技巧。

## 1. 约定式命名

```scala
val pixIn  = slave Stream(Pixel())
val pixOut = master Stream(Pixel())
```

把 `Stream` 当作“业务数据 + 握手”的整体来命名，避免 `data`, `valid` 分家导致重复连线。

## 2. `>>` 与 `<<` 的用法

```scala
pixOut << pixIn.throwWhen(dropLine)
```

`<<` 会自动帮我们连接 `valid/ready`. 当需要对 `payload` 做操作时，记得使用 `.translateWith`，否则 `valid` 和 `payload` 的时序会错位。

## 3. 管线化方法

```scala
val stage2 = pixIn.m2sPipe()
val stage3 = stage2.queue(4)
```

- `m2sPipe`: 只寄存 `payload`
- `s2mPipe`: 只寄存反压
- `queue`: 带深度的 FIFO，可选 `pipeline`, `flow`, `stream` 模式

组合使用能够更严格地控制延迟。

## 4. 调试：用 `StreamMonitor`

```scala
StreamMonitor(pixOut){ packet =>
  assert(packet.payload.alpha <= 255)
}
```

搭配 `SimTimeout`, `SimClockDomain` 可以快速定位 handshake carding。尤其在视频项目里，一旦 `ready` 被拉低，整帧都会“褪色”，必须第一时间定位。

## 5. 与 AXI4-Stream 的互操作

SpinalHDL 提供 `Axi4Stream` 封装，实际上就是 `Stream(Fragment(Bits()))`。常见的桥接写法：

```scala
val axis = master Axi4Stream(axiConfig)
val pix  = slave Stream(Fragment(Pixel()))

axis.payload.fragment := pix.payload.fragment.asBits
axis.last              := pix.last
pix.ready              := axis.ready
```

## Checklist

- [x] 统一使用 `Stream` 命名
- [x] 加上 `queue`/`pipe` 注释延迟
- [ ] 整理一个可复用的 `StreamBus` trait

希望这份小抄能帮你写出更优雅的流水线模块。
