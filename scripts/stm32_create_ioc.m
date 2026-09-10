function stm32_create_ioc()
%STM32_CREATE_IOC Create a baseline STM32CubeMX project for STM32F103C8Tx.

    outdir = 'E:\桌面\FYL\vibecoding\stm32_simulink\00_HW';
    iocPath = fullfile(outdir, 'F103C8T6.ioc');

    cli = stm32cube.tools.cubeMXCli('E:\STM32Cubemx');
    cli.setProjectWorkingDir(outdir);

    fprintf('Creating %s ...\n', iocPath);
    [status, msg] = cli.createNewCubeMXProject(iocPath, 'STM32F103C8Tx', false, false, 'GNU Tools for STM32');
    fprintf('status = %d\n', status);
    if ~isempty(msg)
        disp(msg);
    end

    fprintf('--- %s ---\n', outdir);
    d = dir(outdir);
    for i = 1:numel(d)
        if ~strcmp(d(i).name,'.') && ~strcmp(d(i).name,'..')
            fprintf('  %s\n', d(i).name);
        end
    end
end
