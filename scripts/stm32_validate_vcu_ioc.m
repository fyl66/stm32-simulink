function stm32_validate_vcu_ioc()
%STM32_VALIDATE_VCU_IOC Load and resave VCU_F103.ioc through CubeMX.

    ioc = 'E:\stm32_simulink\00_HW\F103C8T6\VCU_F103.ioc';

    obj = stm32cube.iocParser(ioc);
    fprintf('DeviceId : %s\n', obj.DeviceId);
    fprintf('Family   : %s\n', obj.Family);

    cli = stm32cube.tools.cubeMXCli('E:\STM32Cubemx');
    cli.setCubeMXProject(ioc);
    [status, prjFolder, msg] = cli.resaveCubeMXProject('GNU Tools for STM32');
    fprintf('resave status = %d\n', status);
    fprintf('prjFolder     = %s\n', prjFolder);
    if ~isempty(msg)
        disp(msg);
    end
end
