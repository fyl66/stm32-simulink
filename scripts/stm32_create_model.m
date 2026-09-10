function stm32_create_model()
%STM32_CREATE_MODEL Build the F103_Blink Simulink model and configure the target.

    projdir = fileparts(fileparts(mfilename('fullpath')));
    ioc     = fullfile(projdir,'00_HW','F103C8T6','F103C8T6.ioc');
    m       = 'F103_Blink';
    slx     = fullfile(projdir,[m '.slx']);

    if bdIsLoaded(m)
        close_system(m,0);
    end
    if isfile(slx)
        delete(slx);
    end

    new_system(m);
    load_system('stm32blockslib');

    set_param(m,'SolverType','Fixed-step');
    set_param(m,'Solver','FixedStepDiscrete');
    set_param(m,'FixedStep','0.01');
    set_param(m,'StopTime','inf');
    set_param(m,'SystemTargetFile','ert.tlc');

    add_block('simulink/Sources/Pulse Generator',[m '/Pulse'], ...
        'Amplitude','1','Period','2','PulseWidth','50','SampleTime','0.01', ...
        'Position',[40 100 80 140]);

    add_block('simulink/Signal Routing/Mux',[m '/Mux'], ...
        'Inputs','5','Position',[140 60 145 180]);

    add_block('stm32blockslib/Digital Port Write',[m '/GPIOA'], ...
        'PortName','GPIOA','PinNumber','[0 1 2 3 4]', ...
        'ReadOperation','off','IOAsArray','on', ...
        'Position',[220 50 320 190]);

    add_block('stm32blockslib/Digital Port Write',[m '/GPIOC'], ...
        'PortName','GPIOC','PinNumber','[13]', ...
        'ReadOperation','off','IOAsArray','on', ...
        'Position',[220 240 320 300]);

    al(m,'Pulse/1','GPIOC/1');
    for k = 1:5
        al(m,'Pulse/1',sprintf('Mux/%d',k));
    end
    al(m,'Mux/1','GPIOA/1');

    % --- Target configuration ---
    set_param(m,'HardwareBoard','STM32F1xx Based');
    set_param(m,'Toolchain','GNU Tools for STM32');

    codertarget.data.setParameterValue(m,'STM32CubeMX.ProjectFile',ioc);
    codertarget.data.setParameterValue(m,'Runtime.BuildAction','Build, load and run');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ConnectivityMode','st-link');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ConnectionPort','SWD');
    codertarget.data.setParameterValue(m,'STM32CubeMX.Frequency','4000');
    codertarget.data.setParameterValue(m,'STM32CubeMX.Mode','Normal');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ResetMode','Software reset');
    codertarget.data.setParameterValue(m,'STM32CubeMX.AutoDetectBoard',1);

    save_system(m,slx);
    fprintf('Saved %s\n', slx);
    fprintf('HardwareBoard = %s\n', get_param(m,'HardwareBoard'));
    fprintf('Toolchain     = %s\n', get_param(m,'Toolchain'));
    fprintf('ProjectFile   = %s\n', codertarget.data.getParameterValue(m,'STM32CubeMX.ProjectFile'));
    fprintf('BuildAction   = %s\n', codertarget.data.getParameterValue(m,'Runtime.BuildAction'));
    close_system(m,0);
end

function al(m,a,b)
    % Add line with orthogonal (right-angle) autorouting.
    add_line(m,a,b,'autorouting','on');
end
