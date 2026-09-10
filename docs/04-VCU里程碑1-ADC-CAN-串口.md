# VCU 里程碑 1：ADC + CAN + 2kHz 空环 + 串口

在已验证工具链（阶段0/1）基础上，用模型化方式实现简化 VCU 的第一块功能：
**2kHz 周期读取 8 路 ADC → 通过 CAN 发出（0x500）→ 通过 USART1 打印；同时接收 CAN（0x200）。**

## 1. 硬件/引脚（VCU_F103.ioc）
| 功能 | 引脚 | 配置 |
|---|---|---|
| ADC1 IN0-IN7 | PA0-PA7 | Regular 8 ranks + DMA1_Ch1 循环 |
| CAN1 | PA11=RX / PA12=TX | 500kbps（Prescaler=9, BS1=6TQ, BS2=1TQ） |
| USART1 | PA9=TX / PA10=RX | 115200 |
| TIM1_CH1 (蜂鸣器 PWM) | PA8 | 25kHz（PSC=0, ARR=2879） |
| 数字输入 ×8 | PB0,PB1,PB5-PB10 | GPIO_Input |
| 数字输出 ×4 | PB12-PB15 | GPIO_Output |
| 心跳灯 | PC13 | GPIO_Output |
| SWD | PA13/PA14 | Serial Wire |
| HAL 时基 | — | TIM2（非 SysTick） |

## 2. `.ioc` 关键格式（本里程碑踩坑总结）
1. **ADC 引脚信号**：`PA0-WKUP.Signal=ADCx_IN0`（不是 `ADC1_IN0`），并加 `SH.ADCx_IN0.0=ADC1_IN0,IN0` / `SH.ADCx_IN0.ConfNb=1`。
2. **ADC 转换数**：Blockset 读取 `ADC1.NbrOfConversion`。仅有 `NbrOfConversionFlag` 会默认按 1 处理 → 必须显式写 `ADC1.NbrOfConversion=8`，并加入 `ADC1.IPParameters`。
3. **CAN IP 名（F1）**：IP 名为 `CAN`（不是 `CAN1`）；引脚 `PA11.Mode=CAN_Activate` + `Signal=CAN_RX`、`PA12...=CAN_TX`；参数前缀 `CAN.`（`CAN.Prescaler/BS1/BS2`）。
4. **驱动层选择**：`ProjectManager.functionlistsort` 的 `LL/HAL` 标记决定生成的驱动。
   - **CAN 必须是 `HAL`**（Blockset 的 `stm_can_hal.h` 使用 `CAN_HandleTypeDef`/`HAL_CAN_*`）。
   - GPIO 用 `LL`；ADC 用 `LL`（`stm_adc_ll.h`）。
   - 否则 `stm32f1xx_hal_conf.h` 不会启用对应 HAL 模块，报 `CAN_HandleTypeDef undeclared`。

## 3. 模型（models/VCU_M1.slx）
基础率 **0.0005s（2kHz）**，固定步长。

```
ADC(ADC1, Regular, Trigger and read, 8 conv)
  └─> Data Type Conversion (uint8)
        ├─> CAN Write (CAN1, Standard 11-bit, ID=0x500, DLC=8, Raw data)
        └─> UART Write (USART1)
CAN Read (CAN1, FIFO 0, Unpacked) ─> Terminator
Pulse(2s/50%) ─> Digital Port Write (GPIOC,[13])   % 心跳
```

块路径（`stm32blockslib`）：`Analog to Digital Converter` / `CAN Write` / `CAN Read` / `UART//USART Write` / `Digital Port Write`。

> 注意：`add_block` 传**数值**参数可能报"参数名无效"；改为先 `add_block`（不带参数）再 `set_param(...,'名称','字符串值')`。CAN 块没有 `DataType` 参数。

## 4. 构建
```matlab
cd E:\stm32_simulink\models
slbuild('VCU_M1')     % 或 run('E:\stm32_simulink\scripts\vcu_build.m')
```
实测占用：
```
RAM:   2104 B / 20 KB (10.27%)
FLASH: 13112 B / 64 KB (20.01%)
Download verified successfully
```

## 5. 验证
- USART1（115200）持续输出 8 路 ADC 转换值。
- CAN 分析仪/对端节点可见 **0x500** 报文（8 字节）。
- PC13 心跳灯 1Hz 闪烁。
- 逻辑分析仪测 ADC/环周期约 500µs。

## 6. 已知限制 / 后续
- 本里程碑 CAN Read 结果暂 Terminator（仅验证通路）；下一里程碑接入解析并打印。
- 尚未做定点化（当前直接 uint16→uint8）；算法阶段（KF/DYC/Slip/Distribution）再引入 Fixed-Point。
- TIM1 PWM 蜂鸣器块尚未加入模型（`.ioc` 已配置）。
