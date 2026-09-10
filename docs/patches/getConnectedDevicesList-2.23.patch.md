# 补丁：getConnectedDevicesList（兼容 CubeProgrammer ≥ 2.20）

## 背景

- 文件：`<MATLABROOT>\toolbox\stm32b\stm32shared\+stm32cube\+parameters\+internal\getConnectedDevicesList.m`
- 触发条件：使用 **STM32CubeProgrammer 2.23.0**（Blockset 推荐 2.17.0）。
- 现象：烧录前设备检测返回 `No STM32 MCU connected`，即使 `STM32_Programmer_CLI -c port=SWD` 能连上目标。

## 原因

该函数用 `contains(cubeMxParams.DeviceId, dName)` 过滤设备。
`dName` 来自 CubeProgrammer 输出的 `Device name` 拆分。
- CubeProgrammer 2.23 输出分组名：`STM32F101/F102/F103 Medium-density`
  → 拆分为 `{'F101','F102','F103 Medium-density'}` → 无法匹配 `STM32F103C8Tx`。
- Blockset 期望的是具体料号（如 `STM32F103C8Tx` → 拆分后含 `F103C8T`）。

## 补丁内容

在 `getConnectedDevicesList.m` 中，将：

```matlab
                    if contains(cubeMxParams.DeviceId,dName)
```

替换为：

```matlab
                    % PATCH (local): CubeProgrammer >= 2.20 reports grouped
                    % device names, e.g. "STM32F101/F102/F103 Medium-density".
                    % Strip trailing density text so family tokens like
                    % "F103" still match the project DeviceId.
                    dNameMatch = regexprep(dName,'\s+.*$','');
                    if any(contains(cubeMxParams.DeviceId,dNameMatch))
```

## 生效步骤（关键）

MATLAB 优先使用同名 **`.p`**，因此必须让 `.m` 生效：

```powershell
# 1) 备份并禁用 .p
Copy-Item getConnectedDevicesList.p getConnectedDevicesList.p.orig
Rename-Item getConnectedDevicesList.p getConnectedDevicesList.p.disabled
```

```matlab
% 2) 刷新路径缓存
rehash toolboxcache; rehash path;
```

（本仓库已按此完成；`.p.orig` 与 `.p.disabled` 仅存在于本机，不入库。）

## 验证

```matlab
cd('E:\stm32_simulink'); load_system('F103_Blink');
cs = getActiveConfigSet('F103_Blink');
[dl,dd] = stm32cube.parameters.internal.getConnectedDevicesList(cs);
disp(dl);   % 期望：{'<SN> (STM32F101/F102/F103)'}
```

## 回退

**方式一（回退补丁）**：

```powershell
Rename-Item getConnectedDevicesList.p.disabled getConnectedDevicesList.p
# 并把 .m 恢复为原始一行：if contains(cubeMxParams.DeviceId,dName)
```

```matlab
rehash toolboxcache; rehash path;
```

**方式二（推荐，彻底避免补丁）**：安装 **STM32CubeProgrammer 2.17.0**，注册后即可去掉本补丁。

## 影响范围与风险

- 仅影响 Blockset 的"已连接设备检测"逻辑；改动向后兼容（具体料号与分组名均可匹配）。
- 属对 MathWorks 工具箱文件的最小修改；MATLAB 升级/重装会还原，需重新评估。
