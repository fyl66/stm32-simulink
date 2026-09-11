# STM32 + Simulink（模型化开发 → 一键编译烧录）

本仓库记录 **使用 MATLAB/Simulink 的 STM32 Microcontroller Blockset 开发 STM32** 的完整、可复刻流程。
当前已完成 **阶段 0（环境/工具链）** 与 **阶段 1（F103C8T6 点灯：编译+烧录+运行）**。

## 硬件与软件

| 项目 | 内容 |
|---|---|
| 目标 MCU | STM32F103C8T6（蓝板，LQFP48 / 64KB Flash / 20KB RAM，HSE 8MHz） |
| 调试器 | ST-LINK（SWD：PA13=SWDIO，PA14=SWCLK） |
| 输出 | PA0 / PA1 / PA2 / PA3 / PA4 / PC13（低电平点亮，约 1Hz 交替） |
| MATLAB | R2026a（Update 5） |
| 产品 | STM32 Microcontroller Blockset 26.1；Embedded Coder / Simulink Coder / MATLAB Coder |

> 授权核对务必使用**真实许可功能名**：`rtw_embedded_coder`、`real-time_workshop`、`stm32_blockset`。
> 详见 [docs/02-踩坑与注意事项.md](docs/02-踩坑与注意事项.md#1-授权功能名陷阱)。

## 一键复刻（速览）

```powershell
# 1) 安装工具（本机实际使用版本，见 docs/00）
#    CubeMX / CubeProgrammer / CubeCLT / GNU Tools for STM32 13.2.1

# 2) 注册工具到 Blockset（MATLAB 中运行）
matlab -batch "run('E:\stm32_simulink\scripts\stm32_register.m')"

# 3) 安装固件包 + CMSIS 组件
matlab -batch "run('E:\stm32_simulink\scripts\stm32_install_fw.m')"
matlab -batch "run('E:\stm32_simulink\scripts\stm32_install_cmsis.m')"

# 4) 构建并烧录（在工程目录内）
cd E:\stm32_simulink
matlab -batch "slbuild('F103_Blink')"
```

> **工程路径必须为纯 ASCII**（例如 `E:\stm32_simulink`）。含中文或空格的路径会导致 GNU 工具链乱码、找不到 `main.h`。

## 目录结构

```
stm32_simulink/
├─ README.md                       # 本文件
├─ AGENTS.md                       # 项目规则（AI/协作规范）
├─ .gitignore
├─ F103_Blink.slx                  # Simulink 模型（源）
├─ 00_HW/
│   └─ F103C8T6/F103C8T6.ioc       # CubeMX 工程（源，外设/时钟/时基）
├─ scripts/                        # 可复刻的自动化脚本
│   ├─ stm32_register.m            # 注册 CubeMX/Programmer/CLT/仓库
│   ├─ stm32_install_fw.m          # 下载 F1 固件包
│   ├─ stm32_install_cmsis.m       # 下载/注册 CMSIS / CMSIS-DSP / CMSIS-NN
│   ├─ stm32_create_ioc.m          # 生成基线 .ioc
│   ├─ stm32_create_model.m        # 生成模型并配置目标
│   ├─ stm32_update_paths.m        # 迁移后更新模型内路径
│   ├─ stm32_validate_ioc.m        # CubeMX 加载回存校验
│   └─ stm32_build.m               # 构建+烧录（diary 记录）
└─ docs/
    ├─ 00-环境与工具链-Phase0.md
    ├─ 01-F103点灯-编译烧录-Phase1.md
    ├─ 02-踩坑与注意事项.md
    ├─ 03-新项目复刻清单.md
    └─ patches/getConnectedDevicesList-2.23.patch.md
```

## 构建产物（不入库，由 `.ioc`/`.slx` 重新生成）

`slprj/`、`F103_Blink_ert_rtw/`、`F103_Blink.elf/.bin/.hex`、CubeMX 生成的 `Core/`、`Drivers/`、`STM32CubeIDE/`。

## 文档导航

- [阶段 0：环境与工具链](docs/00-环境与工具链-Phase0.md)
- [阶段 1：F103 点灯（编译烧录）](docs/01-F103点灯-编译烧录-Phase1.md)
- [踩坑与注意事项](docs/02-踩坑与注意事项.md)
- [新项目复刻清单](docs/03-新项目复刻清单.md)
- [VCU 里程碑 1：ADC + CAN + 2kHz 空环 + 串口](docs/04-VCU里程碑1-ADC-CAN-串口.md)
- [VCU 里程碑 2：定点 + Stateflow + PWM + 完整 CAN](docs/05-VCU里程碑2-定点-Stateflow-CAN.md)
- [F407VGT6 + FreeRTOS 移植（RTOS 架构验证）](docs/06-F407-FreeRTOS-移植.md)

## 进行中：简化版 VCU（F103C8T6）

在点灯基础上，用同一套工具链做简化 VCU（参考 Chain 架构）：
- 硬件：`00_HW/F103C8T6/VCU_F103.ioc`（ADC1×8+DMA / CAN 500k / TIM1 PWM / USART1 / GPIO）
- 模型：
  - `models/VCU_M1.slx`：里程碑1（ADC → CAN 0x500 + USART1；CAN Read 0x200；2kHz 空环）
  - `models/VCU_M2.slx`：里程碑2（定点 ADC + KF/分配 + Stateflow 三状态 + PWM 蜂鸣器 + CAN TX 0x100/0x500/0x600、RX 按 ID 分派 0x200/0x300/0x400）
- 构建：`run('E:\stm32_simulink\scripts\vcu_build.m')`（M1）/ `vcu_build2.m`（M2）
- 实测：M1 RAM 2.1KB / FLASH 13.1KB；M2 RAM 2.3KB / FLASH 17.0KB
- 规划与踩坑：见 [docs/04](docs/04-VCU里程碑1-ADC-CAN-串口.md)、[docs/05](docs/05-VCU里程碑2-定点-Stateflow-CAN.md)。
