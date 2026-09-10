# VCU 里程碑 2：定点算法 + Stateflow 三状态 + PWM + 完整 CAN

在 `VCU_M1`（ADC+CAN+2kHz 空环+串口）基础上，`models/VCU_M2.slx` 加入：

- **定点** ADC 标度（Fixed-Point Designer `fi`）
- 简化控制：车速一阶 KF + 扭矩分配（整数定点）
- **Stateflow 三状态机**（Start / Drive / Brake）
- **TIM1_CH1 蜂鸣器 PWM**（25kHz，占空比 50%）
- **CAN 收发（完整 ID 规划）**：TX 0x100（电机指令）/ 0x500（状态）/ 0x600（诊断）；RX 单块读取 FIFO0 后按 ID 分派 0x200/0x300/0x400
- USART1 调试帧（state + vx + throttle）

## 1. 模型结构（`models/VCU_M2.slx`，基础率 0.0005s / 2kHz）

```
ADC(ADC1,8ch) ─► scale_fp(fi) ─┬─► ctrl_fp(KF+分配) ─► pack_tq ─► CAN Write 0x100
                               ├─► pack_st ─► CAN Write 0x500
                               ├─► state_chart(Stateflow) ─► ctrl_fp/pack_st/pack_dbg
                               └─► pack_dbg ─┬─► UART Write
                                             └─► CAN Write 0x600
CAN Read(FIFO0) ─► rx_dispatch(按ID) ─► vx ─► ctrl_fp
Constant 50 ─► PWM Output(TIM1 CH1)
Pulse ─► Digital Port Write(GPIOC[13])
```

## 2. 定点化
- `scale_fp`：`fi` 实现，ADC(0~4095) → mV(`fi(...,1,16,0)`)：
  ```matlab
  v_mV = fi(zeros(8,1),1,16,0);
  k = fi(3300/4095,1,16,15);
  v_mV(i) = fi(adc(i),1,16,0)*k;
  ```
- `ctrl_fp`：为规避代码生成类型推断问题，用 **int16 整数定点**（Q0）实现 KF 与分配：
  ```matlab
  vx_est = vx_est + int16(0.3*(double(vx_meas)-double(vx_est)));
  ```
- 说明：MATLAB Function 块内 `fi` 的 `numerictype` 参数必须是**编译期常量**；`fi` 与整数混用时的类型推断易报错，简单起见控制用整数定点，标度用 `fi`。

## 3. Stateflow 三状态机（脚本创建）
用 Stateflow API 以脚本创建（`buildStateflowChart`）：
```matlab
ch = sfroot.find('-isa','Stateflow.Chart','-and','Path','VCU_M2/state_chart');
u = Stateflow.Data(ch); u.Name='throttle'; u.Scope='Input'; u.DataType='int16';
y = Stateflow.Data(ch); y.Name='state';    y.Scope='Output'; y.DataType='uint8';
s1 = Stateflow.State(ch); s1.Name='Start'; ...
t  = Stateflow.Transition(ch); t.Source=s1; t.Destination=s2;
t.LabelString = '[throttle > 50] {state = uint8(1);}';
```
转移：Start→Drive（throttle>50）、Drive→Brake（brake>50）、Brake→Drive（brake≤50 且 throttle>50）、Drive/Brake→Start（speed≤0 且 throttle≤50）。

> **坑**：`Stateflow.EMChart.Script` / `Chart` 属性需 **char 向量**（不是 string）。脚本里用 `char(join(stringArray,""))` 转换。

## 4. PWM 蜂鸣器
块：`stm32blockslib/PWM Output`；参数：
```matlab
set_param(blk,'TimerModule','TIM1','DutycycleUnits','Percentage', ...
    'EnableChannel1','on','EnableChannel2','off', ..., 'EnableFrequencyInput','off');
```
- 频率由 `.ioc` 的 TIM1 PSC/ARR 决定（我们配了 25kHz：PSC=0, ARR=2879）。
- 占空比从 `CH1` 输入端口给（0~100）。
- 若勾选 `EnableFrequencyInput`，其端口是 **ARR 周期计数值**（不是 Hz）。

## 5. CAN 完整 ID 规划
- TX：三个 `CAN Write`（Raw data, DLC=8, Dialog ID）= 0x100 / 0x500 / 0x600。
- RX：单个 `CAN Read`（FIFO0, Unpacked）输出 `Data`(1)/`Length`(2)/`Id`(3)，经 `rx_dispatch` 按 `Id` 分派 0x200(512)/0x300(768)/0x400(1024)。
- `CAN Read` 的 ID 过滤在 `.ioc` 的 CAN 滤波器配置（当前采用放行后软件分派）。

## 6. 构建结果
```
RAM:   2344 B / 20 KB (11.45%)
FLASH: 16996 B / 64 KB (25.93%)
Download verified successfully
```
构建：`run('E:\stm32_simulink\scripts\vcu_build2.m')`。

## 7. 本里程碑踩坑
1. **MATLAB Function 的 `fi` 类型推断**：`ctrl_fp` 用 `fi` 报"无法确定大小/数据类型" → 控制改用 int16 整数定点。
2. **`Stateflow.*.Script` 需 char**：传 string 数组报"值必须为字符向量"。
3. **`add_block` 传数值参数报错**：改 `add_block` + `set_param(...,'字符串')`。
4. **PWM 频率不在块上**：由 `.ioc` 的 TIM1 PSC/ARR 决定。

## 8. 后续
- 用 Fixed-Point Designer 对 `ctrl_fp` 做正式的定点类型标注（`fiaccel`/`buildInstrumentedMex`）。
- CAN 接收滤波器在 `.ioc` 精细化（0x200→FIFO0、0x300/0x400→FIFO1）。
- 接入真实对端节点联调，验证 0x100 电机指令与 0x200 反馈闭环。
