function stm32_install_fw()
%STM32_INSTALL_FW Download STM32Cube_FW_F1 V1.8.6 into the configured repo.

    fprintf('Repository: %s\n', stm32cube.hwsetup.stm32Tools.getInstalledCubeRepositoryLocation);

    fprintf('Installing STM32Cube_FW_F1 V1.8.6 ...\n');
    [status, msg] = stm32cube.hwsetup.stm32Tools.installSTM32CubeFirmware('F1', '1.8.6');
    fprintf('status = %d\n', status);
    if ~isempty(msg)
        disp(msg);
    end

    fprintf('--- Repository contents ---\n');
    d = dir('E:\STM32Cubemx\Repository');
    for i = 1:numel(d)
        if ~strcmp(d(i).name, '.') && ~strcmp(d(i).name, '..')
            fprintf('  %s\n', d(i).name);
        end
    end
end
