function vcu_create_model()
%VCU_CREATE_MODEL Create models/VCU_M1.slx (ADC + CAN + 2kHz loop + UART).

    projdir = fileparts(fileparts(mfilename('fullpath')));
    ioc     = fullfile(projdir,'00_HW','F103C8T6','VCU_F103.ioc');
    m       = 'VCU_M1';
    slx     = fullfile(projdir,'models',[m '.slx']);

    if bdIsLoaded(m), close_system(m,0); end
    if isfile(slx), delete(slx); end

    new_system(m);
    load_system('stm32blockslib');
    blks = find_system('stm32blockslib','SearchDepth',1,'Type','Block');
    pick = @(kw) blks{find(contains(blks,kw),1)};

    % ---- Solver: 2 kHz ----
    set_param(m,'SolverType','Fixed-step');
    set_param(m,'Solver','FixedStepDiscrete');
    set_param(m,'FixedStep','0.0005');
    set_param(m,'StopTime','inf');
    set_param(m,'SystemTargetFile','ert.tlc');

    % ---- Add blocks (no params) ----
    add_block(pick('Analog to Digital'),          [m '/ADC'],          'Position',[60 100 160 200]);
    add_block('simulink/Commonly Used Blocks/Data Type Conversion',[m '/ADC_u8'],'Position',[220 130 270 170]);
    add_block(pick('CAN Write'),                  [m '/CAN_TX_0x500'], 'Position',[340 90 440 150]);
    add_block(pick('USART Write'),                [m '/UART_DBG'],     'Position',[340 190 440 250]);
    add_block(pick('CAN Read'),                   [m '/CAN_RX_0x200'], 'Position',[340 300 440 360]);
    add_block('simulink/Sinks/Terminator',        [m '/Term'],         'Position',[500 320 520 340]);
    add_block('simulink/Sources/Pulse Generator', [m '/HB'],           'Position',[60 400 100 440]);
    add_block(pick('Digital Port Write'),         [m '/Heartbeat'],    'Position',[160 390 260 450]);

    % ---- Configure blocks ----
    set_param([m '/ADC'],'ADCModule','ADC1','ConversionGroup','Regular', ...
        'TriggerMode','Trigger and read','NumberOfConversions','8');
    set_param([m '/ADC_u8'],'OutDataTypeStr','uint8');
    set_param([m '/CAN_TX_0x500'],'CANModule','CAN1','DataFormatWriteMode','Raw data', ...
        'IdentifierVia','Dialog','Identifier','1280', ...
        'IdentifierType','Standard (11-bit identifier)', ...
        'DataLengthVia','Dialog','DataLength','8');
    set_param([m '/UART_DBG'],'UARTModule','USART1');
    set_param([m '/CAN_RX_0x200'],'CANModule','CAN1','ReadSource','FIFO 0', ...
        'OperationReadMode','Data','OutputTypeReadMode','Unpacked');
    set_param([m '/HB'],'Amplitude','1','Period','2','PulseWidth','50','SampleTime','0.0005');
    set_param([m '/Heartbeat'],'PortName','GPIOC','PinNumber','[13]', ...
        'ReadOperation','off','IOAsArray','on');

    % ---- Connections ----
    add_line(m,'ADC/1','ADC_u8/1');
    add_line(m,'ADC_u8/1','CAN_TX_0x500/1');
    add_line(m,'ADC_u8/1','UART_DBG/1');
    add_line(m,'CAN_RX_0x200/1','Term/1');
    add_line(m,'HB/1','Heartbeat/1');

    % ---- Target configuration ----
    set_param(m,'HardwareBoard','STM32F1xx Based');
    set_param(m,'Toolchain','GNU Tools for STM32');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ProjectFile',ioc);
    codertarget.data.setParameterValue(m,'STM32CubeMX.DeviceId','STM32F103C8Tx');
    codertarget.data.setParameterValue(m,'STM32CubeMX.Family','STM32F1');
    codertarget.data.setParameterValue(m,'Runtime.BuildAction','Build, load and run');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ConnectivityMode','st-link');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ConnectionPort','SWD');
    codertarget.data.setParameterValue(m,'STM32CubeMX.Frequency','4000');
    codertarget.data.setParameterValue(m,'STM32CubeMX.Mode','Normal');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ResetMode','Software reset');
    codertarget.data.setParameterValue(m,'STM32CubeMX.AutoDetectBoard',1);

    save_system(m,slx);
    fprintf('Saved %s\n', slx);
    fprintf('ProjectFile = %s\n', codertarget.data.getParameterValue(m,'STM32CubeMX.ProjectFile'));
    close_system(m,0);
end
