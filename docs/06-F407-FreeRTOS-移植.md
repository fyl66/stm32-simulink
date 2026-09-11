# F407VGT6 + FreeRTOS 移植（RTOS 架构验证）

在已验证工具链上，用 **STM32F407VGT6 + FreeRTOS（CMSIS_V2）** 验证多任务架构，并把简化版 Chain(VCU) 以 **MBD** 方式移植（几乎不手写 C）。

## 1. 硬件/引脚（F407VGT6 / LQFP100）
| 功能 | 引脚 | 说明 |
|---|---|---|
| LED（验证） | **PD0, PD1** | 低电平点亮（阳极接3V3） |
| CAN1 | **PB8(RX)/PB9(TX)** | AF9，500kbps（避开 PD0/PD1，它们是 CAN1 备用脚） |
| ADC1 ×8 | PA0–PA7 | IN0–IN7 + DMA2_Stream0 |
| 调试串口 | PA9(TX)/PA10(RX) | USART1 |
| 蜂鸣器 PWM | PA8 | TIM1_CH1（25kHz） |
| 数字输入 ×4 | PC0–PC3 | GPIO_Input |
| 数字输出 ×4 | PE0–PE3 | GPIO_Output |
| SWD | PA13/PA14 | Serial Wire |
| HSE | PH0/PH1 | 8MHz → 168MHz |

> F407 的 HSE 在 **PH0/PH1**，PD0/PD1 是普通 GPIO（也是 CAN1 备用 AF），因此 LED 与晶振不冲突。

## 2. RTOS 任务划分（速率 → 任务）
| 速率 | 任务 | 优先级 | 内容 |
|---|---|---|---|
| **1kHz（基准）** | 控制+通信 | 5 | KF/分配控制 + Stateflow + CAN1 收发 + ADC |
| 100Hz | IO | 4 | Digital Port Read(PC0-3) → Write(PE0-3) |
| 10Hz | 调试 | 3 | UART Write（Rate Transition 来自 1kHz） |
| 1Hz | 心跳 | 2 | LED PD0/PD1 翻转 |

生成代码 `-DNUMST=4`（1 基准 + 3 子速率任务），源文件 `mw_freertos_init.c/mw_thread.c/mw_timer.c/mw_semaphore.c` + CubeMX `freertos.c`。

## 3. `.ioc` 要点（F407VGT6）
- 时钟：HSE 8MHz → PLLM=8/PLLN=336/PLLP=2 → **168MHz**，PLLQ=7
- **HAL Timebase = TIM6**（**非 SysTick**，SysTick 归 FreeRTOS）
- **FreeRTOS（CMSIS_V2）**：`configUSE_PREEMPTION=1`、`configTIMER_TASK_PRIORITY=6`（> 基准 5）、`configTICK_RATE_HZ=1000`、`configMINIMAL_STACK_SIZE=128`、`configTOTAL_HEAP_SIZE=15360`
- **驱动层**：GPIO/DMA/ADC/TIM/USART = **LL**，CAN = **HAL**（`functionlistsort` 的标记）
- **ADC1**：8 ranks + DMA + `EOCSelection=ADC_EOC_SEQ_CONV`（"EOC flag at end of all conversions"）
- `NoMain=true`

## 4. 模型（`models/VCU_F407.slx`）
```
[1kHz ctrl1k]  ADC1(8) -> scale_fp(fi) -> ctrl_fp(KF/分配) + Stateflow(Start/Drive/Brake)
               CAN_RX -> rx_dispatch(按ID) ; pack_tq -> CAN_TX 0x100 ; pack_st -> CAN_TX 0x500
               pack_dbg -> dbg(Outport)
[100Hz io100]  Digital Port Read(PC0-3) -> Digital Port Write(PE0-3)
[10Hz dbg10]   Rate Transition(来自 ctrl1k) -> UART Write(USART1)
[1Hz led1s]    MATLAB Function 翻转 -> Digital Port Write(GPIOD,[0 1])
```
目标：`HardwareBoard=STM32F4xx Based`、`RTOS=FreeRTOS`、`RTOSBaseRateTaskPriority=5`、`EnableMultiTasking=on`、`PositivePriorityOrder=on`。

## 5. 构建结果
```
RAM:   21136 B / 128 KB (16.13%)
FLASH: 25080 B / 1 MB   (2.39%)
Download verified successfully
```
构建：`run('E:\stm32_simulink\scripts\vcu_build_f407.m')`；创建：`vcu_create_f407_model.m`。

## 6. 本里程碑踩坑
1. **驱动层**：GPIO/DMA/ADC/TIM/USART 必须 **LL**，CAN 必须 **HAL**，否则 `IncorrectDriverLayerSelected`。
2. **ADC EOC**：多通道需 `ADC1.EOCSelection=ADC_EOC_SEQ_CONV`，否则 `ADCEOCOnEachConversion`。
3. **FreeRTOS 基准率 ≥1ms**：本模型基准 1kHz（1ms）。
4. **块名冲突**：块名不能叫 `UART`（与 HAL 冲突），改名 `UART_TX`；`ADC` 建议改 `ADC1_BLK`。
5. **多速率**：跨速率用 **Rate Transition**；原子子系统设 `SystemSampleTime`；块内采样率需与子系统一致（继承或相同）。
6. **HAL Timebase 非 SysTick**（FreeRTOS 占用 SysTick）。

## 7. 与 F103 的差异
| 项 | F103（裸机多速率） | F407（FreeRTOS） |
|---|---|---|
| 调度 | SysTick 非抢占 | FreeRTOS 抢占 |
| 基准率 | 可 2kHz | ≤1kHz（≥1ms） |
| CAN | 单路 | 单路（可扩展到 CAN2） |
| FPU | 无 | 有（`-mfloat-abi=hard`） |
| External Mode | 可用 | **不可用** |
