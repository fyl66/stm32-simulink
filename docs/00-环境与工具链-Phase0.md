# 阶段 0：环境与工具链（STM32 Microcontroller Blockset）

目标：让 MATLAB/Simulink 能调用 STM32CubeMX 生成底层代码、用 GNU 工具链编译、用 STM32CubeProgrammer 通过 ST-LINK 烧录。

---

## 1. 前置与授权核对

### 1.1 所需产品
- MATLAB + Simulink
- **STM32 Microcontroller Blockset**（`stm32b`）
- **Embedded Coder**（`toolbox\coder`）
- **Simulink Coder**（`toolbox\simulinkcoder`）
- MATLAB Coder（随 Embedded Coder 流程使用）

### 1.2 授权核对（关键！）

> **坑**：用产品名调用 `license('test',...)` 会得到错误的 0。

正确做法——使用**真实许可功能名**：

```matlab
names = {'Embedded Coder','Simulink Coder','MATLAB Coder','STM32 Microcontroller Blockset'};
for i = 1:numel(names)
    bc = matlab.internal.product.getBaseCodeFromProductName(names{i});
    fi = matlab.internal.licensing.getFeatureInfo(bc);
    fprintf('%-32s feature=%-22s test=%d lic=%s exp=%s\n', ...
        names{i}, fi.feature, license('test',fi.feature), fi.license_number, fi.expdate);
end
```

对照表：

| 产品 | 真实功能名（feature） |
|---|---|
| Embedded Coder | `rtw_embedded_coder` |
| Simulink Coder | `real-time_workshop` |
| MATLAB Coder | `matlab_coder` |
| STM32 Microcontroller Blockset | `stm32_blockset` |

期望全部 `test=1`。若某项为 0，见 `docs/02` 的"授权功能名陷阱"。

---

## 2. 工具版本矩阵

Blockset 推荐版本（R2026a）：

| 工具 | 推荐版本 | 最低版本 |
|---|---|---|
| STM32CubeMX | 6.12.0 | 6.2.0 |
| STM32CubeProgrammer | 2.17.0 | — |
| STM32CubeCLT | 1.17.0 | — |
| GNU Tools for STM32 | 13.2.1 | — |

本仓库实测使用的版本（均可用，但有版本告警）：

| 工具 | 本机版本 | 路径 |
|---|---|---|
| STM32CubeMX | 6.18.1-RC2 | `E:\STM32Cubemx` |
| STM32CubeProgrammer | 2.23.0 | `E:\ST\STM32CubeProgrammer\bin` |
| STM32CubeCLT | 1.22.0 | `E:\ST\stm32cubeclt\STM32CubeCLT_1.22.0` |
| GNU Tools for STM32 | 13.2.1 | `C:\ProgramData\MATLAB\R2026a\stm32b\3P.instrset\gnuarm-stm32.instrset\win` |

> Blockset 对版本是"≥要求即可，不等只告警"。但 **CubeMX 版本差异风险最高**（脚本化代码生成、`.mxproject` 解析）。若代码生成阶段报错，回退安装 CubeMX **6.12.0**。

---

## 3. 注册工具到 Blockset

用脚本完成（等价于 `stm32setup` 向导的 Validate 步骤）：

```matlab
run('E:\stm32_simulink\scripts\stm32_register.m')
```

脚本核心：

```matlab
t = stm32cube.hwsetup.stm32Tools;
t.updateSTM32CubeMXPath('E:\STM32Cubemx');                 % 传"安装目录"
t.updateSTM32CubeProgrammerPath('E:\ST\STM32CubeProgrammer\bin');  % 传 bin 目录
t.updateSTM32CubeCLTPath('E:\ST\stm32cubeclt\STM32CubeCLT_1.22.0');% 含 SVD 的目录
stm32cube.hwsetup.stm32Tools.setInstalledCubeRepositoryLocation('E:\STM32Cubemx\Repository');
```

要点：
- `updateSTM32CubeMXPath` 接收**目录**（目录下需有 `STM32CubeMX.exe` 与 `jre\`）。
- `updateSTM32CubeProgrammerPath` 接收**包含 `STM32_Programmer_CLI.exe` 的目录**。
- `updateSTM32CubeCLTPath` 接收**包含 `STMicroelectronics_CMSIS_SVD\STM32F401.svd` 的目录**。
- 版本校验只告警不阻断；写入 `MW_STM32` 首选项。

验证：

```matlab
getpref('MW_STM32')                       % 查看已注册项
stm32cube.utils.getGnuArmToolsDir         % GNU 工具链目录
```

---

## 4. 安装 STM32Cube 固件包（F1 V1.8.6）

Blockset 要求 F1 固件包 **`STM32Cube_FW_F1 V1.8.6`**（H7 为 V1.11.2）。

```matlab
run('E:\stm32_simulink\scripts\stm32_install_fw.m')
```

内部：

```matlab
[status,msg] = stm32cube.hwsetup.stm32Tools.installSTM32CubeFirmware('F1','1.8.6');
```

### 4.1 坑：CubeMX 默认装到 C 盘仓库

`swmgr install` 会装到 **CubeMX 自己的仓库路径**（默认 `C:\Users\<user>\STM32Cube\Repository`），而不是 MATLAB 首选项里的路径。

处理：把已下载的固件目录迁移到目标仓库，并同步 CubeMX 的 `updater.ini`：

```text
# C:\Users\<user>\.stm32cubemx\plugins\updater\updater.ini
[Path]
RepositoryPath=E:/STM32Cubemx/Repository/
```

（迁移后 `STM32Cube_FW_F1_V1.8.6` 应位于 `E:\STM32Cubemx\Repository\`。）

验证：

```matlab
[d,v] = stm32cube.hwsetup.stm32Tools.getSTM32CubeFirmwarePackageDetails('F1');
disp(d); disp(v);   % 期望 d=...\STM32Cube_FW_F1_V1.8.6, v=1.8.6
```

---

## 5. 安装 CMSIS / CMSIS-DSP / CMSIS-NN

Blockset 代码生成要求三者已安装**并注册**。CMSIS 常被预装但**未注册**，DSP/NN 常缺失。

```matlab
run('E:\stm32_simulink\scripts\stm32_install_cmsis.m')
```

内部：

```matlab
xmlFolder = fullfile(matlabroot,'toolbox','stm32b','stm32shared','thirdpartytools','instrset');
for k = {'cmsis','cmsis_dsp','cmsis_nn'}
    shared3pcmsis.download3pCMSISFolder(k{1}, xmlFolder);
    shared3pcmsis.install3pCMSISFolder (k{1}, xmlFolder);
    shared3pcmsis.register3pCMSISFolder(k{1}, xmlFolder);
end
```

验证（返回非空即已注册）：

```matlab
shared3pcmsis.get3pCMSISInstallFolder('cmsis')
shared3pcmsis.get3pCMSISInstallFolder('cmsis_dsp')
shared3pcmsis.get3pCMSISInstallFolder('cmsis_nn')
```

下载源（MathWorks 托管）：
- CMSIS 5.9.0、CMSIS-DSP 1.14.3、CMSIS-NN 6.0.0（见各 `common.xml`）。

---

## 6. 阶段 0 完成判据

- `getpref('MW_STM32')` 含 `STM32CubeMX` / `STM32CubeProgrammer` / `STM32CubeCLT` / `STM32CubeFW`。
- `getSTM32CubeFirmwarePackageDetails('F1')` 返回 V1.8.6 路径。
- `get3pCMSISInstallFolder('cmsis'/'cmsis_dsp'/'cmsis_nn')` 均非空。
- `STM32_Programmer_CLI.exe -l st-link` 能列出 ST-LINK 探针。
