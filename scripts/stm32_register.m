function stm32_register()
%STM32_REGISTER Register ST third-party tools with the STM32 Blockset.
%   Non-interactive equivalent of the stm32setup wizard validation steps.

    t = stm32cube.hwsetup.stm32Tools;

    try
        warn = t.updateSTM32CubeMXPath('E:\STM32Cubemx');
        fprintf('CubeMX            : OK  %s\n', warn);
    catch e
        fprintf('CubeMX            : ERR %s\n', e.message);
    end

    try
        warn = t.updateSTM32CubeProgrammerPath('E:\ST\STM32CubeProgrammer\bin');
        fprintf('CubeProgrammer    : OK  %s\n', warn);
    catch e
        fprintf('CubeProgrammer    : ERR %s\n', e.message);
    end

    try
        t.updateSTM32CubeCLTPath('E:\ST\stm32cubeclt\STM32CubeCLT_1.22.0');
        fprintf('CubeCLT           : OK\n');
    catch e
        fprintf('CubeCLT           : ERR %s\n', e.message);
    end

    try
        stm32cube.hwsetup.stm32Tools.setInstalledCubeRepositoryLocation('E:\STM32Cubemx\Repository');
        fprintf('FW repository     : OK\n');
    catch e
        fprintf('FW repository     : ERR %s\n', e.message);
    end

    fprintf('GNU Tools dir     : %s\n', stm32cube.utils.getGnuArmToolsDir);

    disp('--- MW_STM32 preferences ---');
    if ispref('MW_STM32')
        disp(getpref('MW_STM32'));
    else
        disp('(none)');
    end
end
