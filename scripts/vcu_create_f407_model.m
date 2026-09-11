function vcu_create_f407_model()
%VCU_CREATE_F407_MODEL Create models/VCU_F407.slx (M1: FreeRTOS minimal).
%   Base rate 1kHz (control task) + 1Hz sub-rate (LED heartbeat on PD0/PD1).
%   Active-low LEDs (anode->3V3).

    projdir = fileparts(fileparts(mfilename('fullpath')));
    ioc     = fullfile(projdir,'00_HW','F407VGT6','VCU_F407','VCU_F407.ioc');
    m       = 'VCU_F407';
    slx     = fullfile(projdir,'models',[m '.slx']);

    if bdIsLoaded(m), close_system(m,0); end
    if isfile(slx), delete(slx); end

    new_system(m);
    load_system('stm32blockslib');

    set_param(m,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
        'FixedStep','0.001','StopTime','inf','SystemTargetFile','ert.tlc', ...
        'EnableMultiTasking','on','PositivePriorityOrder','on');

    % ---- 1kHz base-rate subsystem (control placeholder) ----
    add_block('simulink/Ports & Subsystems/Subsystem',[m '/ctrl1k'],'Position',gpos(1,1,300,160));
    set_param([m '/ctrl1k'],'TreatAsAtomicUnit','on','SystemSampleTime','0.001');
    delete_line_if_any([m '/ctrl1k']);
    add_block('simulink/Sources/Constant',[m '/ctrl1k/C'],'Value','1','Position',[40 60 80 90]);
    add_block('simulink/Discrete/Unit Delay',[m '/ctrl1k/D'],'SampleTime','0.001','Position',[140 55 190 95]);
    add_block('simulink/Sinks/Terminator',[m '/ctrl1k/T'],'Position',[250 60 270 80]);
    add_line([m '/ctrl1k'],'C/1','D/1');
    add_line([m '/ctrl1k'],'D/1','T/1');

    % ---- 1Hz sub-rate subsystem (LED heartbeat) ----
    add_block('simulink/Ports & Subsystems/Subsystem',[m '/led1s'],'Position',gpos(1,2,300,160));
    set_param([m '/led1s'],'TreatAsAtomicUnit','on','SystemSampleTime','1.0');
    delete_line_if_any([m '/led1s']);
    add_block('simulink/User-Defined Functions/MATLAB Function',[m '/led1s/F'],'Position',[40 45 140 105]);
    add_block('stm32blockslib/Digital Port Write',[m '/led1s/LED'], ...
        'PortName','GPIOD','PinNumber','[0 1]','ReadOperation','off','IOAsArray','on', ...
        'Position',[180 40 290 120]);
    add_line([m '/led1s'],'F/1','LED/1');
    setEmScript(m,'/led1s/F', [ ...
        "function y = led_toggle()" newline ...
        "%#codegen" newline ...
        "persistent s" newline ...
        "if isempty(s)" newline ...
        "    s = false;" newline ...
        "end" newline ...
        "s = ~s;" newline ...
        "y = [s; s];" newline ...
        "end"]);

    % ---- Target configuration ----
    set_param(m,'HardwareBoard','STM32F4xx Based');
    set_param(m,'Toolchain','GNU Tools for STM32');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ProjectFile',ioc);
    codertarget.data.setParameterValue(m,'STM32CubeMX.DeviceId','STM32F407VGTx');
    codertarget.data.setParameterValue(m,'STM32CubeMX.Family','STM32F4');
    codertarget.data.setParameterValue(m,'Runtime.BuildAction','Build, load and run');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ConnectivityMode','st-link');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ConnectionPort','SWD');
    codertarget.data.setParameterValue(m,'STM32CubeMX.Frequency','4000');
    codertarget.data.setParameterValue(m,'STM32CubeMX.Mode','Normal');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ResetMode','Software reset');
    codertarget.data.setParameterValue(m,'STM32CubeMX.AutoDetectBoard',1);
    codertarget.data.setParameterValue(m,'RTOS','FreeRTOS');
    codertarget.data.setParameterValue(m,'RTOSBaseRateTaskPriority','5');

    save_system(m,slx);
    fprintf('Saved %s\n', slx);
    close_system(m,0);
end

function delete_line_if_any(sys)
    % Remove default lines inside a freshly added Subsystem (In1->Out1)
    try
        delete_line(sys,'In1/1','Out1/1');
    catch
    end
    try
        delete_block([sys '/In1']);
        delete_block([sys '/Out1']);
    catch
    end
end

function p = gpos(col,row,w,h)
    W=240; H=160; SX=100; SY=120;
    x = 40 + (col-1)*(W+SX);
    y = 40 + (row-1)*(H+SY);
    p = [x y x+w y+h];
end

function setEmScript(model, blkPath, script)
    rt = sfroot;
    ch = rt.find('-isa','Stateflow.EMChart','-and','Path',[model blkPath]);
    if isempty(ch)
        error('EMChart not found: %s%s', model, blkPath);
    end
    if isstring(script)
        script = char(join(script,""));
    end
    ch.Script = script;
end
