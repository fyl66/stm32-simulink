# AGENTS.md — 项目规则（STM32 + Simulink）

本文件定义本仓库的硬性约定。任何人在此仓库（或让 AI 助手）工作前必须遵守。

## 1. 路径与环境

- **工程路径必须是纯 ASCII**，不得包含中文、空格或特殊字符。
  - 反例：`E:\桌面\FYL\...`（GNU 工具链会乱码，报 `main.h: No such file or directory`）。
  - 正例：`E:\stm32_simulink`。
- MATLAB 安装路径若含空格（如 `Program Files`），Blockset 会告警；能工作但非最佳。
- 所有脚本内部路径应相对脚本自身定位：
  `projdir = fileparts(fileparts(mfilename('fullpath')))`，禁止硬编码绝对路径。

## 2. 版本与授权

- 授权核对使用**真实许可功能名**：
  - Embedded Coder → `rtw_embedded_coder`
  - Simulink Coder → `real-time_workshop`
  - STM32 Blockset → `stm32_blockset`
- **禁止**用产品名做判断（`license('test','Embedded_Coder')` 会误报 0）。
- 记录并核对工具版本（见 `docs/00`）。若偏离 Blockset 推荐版本（CubeMX 6.12.0 / CubeProgrammer 2.17.0 / CubeCLT 1.17.0），需在提交信息或文档中注明。

## 3. 源文件与生成物

- **纳入版本控制（源）**：`*.ioc`、`*.slx`、`scripts/`、`docs/`、`README.md`、`AGENTS.md`、`.gitignore`。
- **不纳入（生成物）**：`slprj/`、`*_ert_rtw/`、`*.elf|*.bin|*.hex|*.map`、CubeMX 生成的 `Core/`、`Drivers/`、`STM32CubeIDE/`、`*.mxproject`、`*.mat`、`script`、`*.slxc`。
- 克隆仓库后，由 `.ioc` + `.slx` 重新生成代码；**不要手动修改**生成目录中的文件。

## 4. `.ioc`（CubeMX 工程）约定

- **时基源（Timebase Source）不能是 SysTick**，必须改为 TIM2 等；否则 Blockset 报 `STM32CubeMXTimebaseSourceSystick`。
- `ProjectManager.NoMain=true`（由 Blockset 生成 `main`）。
- GPIO 输出引脚需与模型 `Digital Port Write` 块一致。
- 修改 `.ioc` 后，必须同步模型中的 `STM32CubeMX.DeviceId` 与 `STM32CubeMX.Family`（见第 5 条）。
- **驱动层选择（`functionlistsort` 的 LL/HAL）必须匹配 Blockset 驱动**：CAN=`HAL`（`stm_can_hal.h`）、GPIO=`LL`、ADC=`LL`（`stm_adc_ll.h`）。选错会导致 `CAN_HandleTypeDef undeclared`。
- **多通道 ADC 必须显式写 `ADC1.NbrOfConversion=N`**，否则报 `ADCNoOfConvMismatch`。
- 改动 `.ioc` 后若 HAL 配置未更新，删除生成的 `Core/`、`Drivers/`、`STM32CubeIDE/`、`.mxproject`、`*.mat`、`script` 再重建。

## 5. 模型（`.slx`）目标配置

程序化设置 `STM32CubeMX.ProjectFile` **不会**自动解析 `.ioc`，必须显式写入：

```matlab
codertarget.data.setParameterValue(m,'STM32CubeMX.ProjectFile', iocPath);
codertarget.data.setParameterValue(m,'STM32CubeMX.DeviceId',   'STM32F103C8Tx');
codertarget.data.setParameterValue(m,'STM32CubeMX.Family',     'STM32F1');
codertarget.data.setParameterValue(m,'Runtime.BuildAction',    'Build, load and run');
```

否则设备检测返回 `No STM32 MCU connected`。

## 6. 构建

- 标准构建命令：
  ```matlab
  cd('E:\stm32_simulink'); slbuild('F103_Blink');
  ```
- 非交互（`matlab -batch`）构建时，`codertarget.target.configureModelIfRequired` 可能弹出 `questdlg` 导致失败。**仅在无头构建期间**临时放置一个自动应答的 `questdlg.m`，构建完成后**必须删除**（已加入 `.gitignore`）。
- 构建失败先看 `diary` 日志（`stm32_build.m` 会写到 `%TEMP%\stm32_build_diary.txt`）。

## 7. 修改 MATLAB 工具箱的限制

- 原则上**不修改** MathWorks 工具箱文件。
- 若因第三方工具版本兼容必须修改（如 `getConnectedDevicesList`），必须：
  1. 备份原文件（`.p` → `.p.orig`）；
  2. 在 `docs/patches/` 记录补丁全文、原因、影响范围与**回退步骤**；
  3. 在提交信息中注明。
- 已知补丁：`docs/patches/getConnectedDevicesList-2.23.patch.md`。

## 8. 提交规范

- 提交信息使用 `<type>: <描述>`，type ∈ `feat|fix|docs|chore|refactor`。
- **禁止提交**任何令牌、PAT、密钥、账号密码；`.ioc`/脚本中不得内嵌敏感信息。
- 提交前确认 `git status` 中无生成物、无本机绝对路径（`E:\桌面\...`）。

## 9. 命名与目录

- 模型文件：`<功能>.slx`（如 `F103_Blink.slx`）。
- 硬件目录：`00_HW/<MCU>/<MCU>.ioc`。
- 新增芯片/板卡：复制 `docs/03-新项目复刻清单.md` 逐项执行。

## 9b. 模型连线规范

- 连线必须**横平竖直**，禁止斜线直接连接。
- 脚本中一律使用 `add_line(m,a,b,'autorouting','on')`（本仓库封装为 `al(m,a,b)`），由 Simulink 自动正交布线。
- 布局上让信号从左到右、从上到下流动，减少交叉。

## 9c. 模型布局规范

- 用网格定位 `gpos(col,row,w,h)`（列间距 100、行间距 120），禁止手写零散坐标。
- 块尺寸建议：STM32 外设块 `240×160`、MATLAB Function `240×140`、Stateflow 图块 `300×240`。
- 块内/块名的文字不得与相邻块或框线重叠；生成后用 `scripts/check_layout.m` 检查（块重叠应为 0、斜线应为 0）。
- Stateflow：状态框 ≥ `240×120`、横向间距 ≥ 360；**动作放在状态的 `en:` 入口动作**，转移标签只写条件（避免标签过长互相重叠）。

## 10. 已知硬件注意

- LED 等外设请串联限流电阻（330Ω~1kΩ），避免超过 GPIO 灌电流。
