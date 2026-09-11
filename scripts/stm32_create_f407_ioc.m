function stm32_create_f407_ioc()
%STM32_CREATE_F407_IOC Create a baseline STM32CubeMX project for STM32F407VGTx.

    projdir = fileparts(fileparts(mfilename('fullpath')));
    outdir  = fullfile(projdir,'00_HW','F407VGT6');
    if ~isfolder(outdir), mkdir(outdir); end
    iocPath = fullfile(outdir,'VCU_F407.ioc');

    cli = stm32cube.tools.cubeMXCli('E:\STM32Cubemx');
    cli.setProjectWorkingDir(outdir);

    [status, msg] = cli.createNewCubeMXProject(iocPath, 'STM32F407VGTx', false, false, 'GNU Tools for STM32');
    fprintf('status = %d\n', status);
    if ~isempty(msg), disp(msg); end
end
