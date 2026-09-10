function stm32_validate_ioc()
%STM32_VALIDATE_IOC Load and resave the F103C8T6 .ioc through CubeMX to validate.

    ioc = 'E:\桌面\FYL\vibecoding\stm32_simulink\00_HW\F103C8T6\F103C8T6.ioc';

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
