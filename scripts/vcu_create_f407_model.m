function vcu_create_f407_model()
%VCU_CREATE_F407_MODEL Create models/VCU_F407.slx (full VCU, FreeRTOS multi-rate).
%   Base 1kHz : ADC + control(KF/DYC/Distribution) + Stateflow + CAN1 RX/TX
%   100Hz IO  : PC0-3 in -> PE0-3 out
%   10Hz  dbg : UART1
%   1Hz   LED : PD0/PD1 heartbeat (active-low)
%   Layout: fixed sizes per block type + strict grid (left->right).

    projdir = fileparts(fileparts(mfilename('fullpath')));
    ioc     = fullfile(projdir,'00_HW','F407VGT6','VCU_F407','VCU_F407.ioc');
    m       = 'VCU_F407';
    slx     = fullfile(projdir,'models',[m '.slx']);

    if bdIsLoaded(m), close_system(m,0); end
    if isfile(slx), delete(slx); end

    new_system(m);
    load_system('stm32blockslib');
    blks = find_system('stm32blockslib','SearchDepth',1,'Type','Block');
    pick = @(kw) blks{find(contains(blks,kw),1)};
    mf = 'simulink/User-Defined Functions/MATLAB Function';

    set_param(m,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
        'FixedStep','0.001','StopTime','inf','SystemTargetFile','ert.tlc', ...
        'EnableMultiTasking','on','PositivePriorityOrder','on');

    % ================= 1 kHz base-rate subsystem =================
    % grid: col pitch 340 (280+60), row pitch 260 (180+80)
    add_block('simulink/Ports & Subsystems/Subsystem',[m '/ctrl1k'],'Position',[40 40 2500 720]);
    set_param([m '/ctrl1k'],'TreatAsAtomicUnit','on','SystemSampleTime','0.001');
    sub_del([m '/ctrl1k']);
    add_block(pick('Analog to Digital'), [m '/ctrl1k/ADC1_BLK'], 'Position',[40 40 320 220]);
    add_block(pick('CAN Read'),          [m '/ctrl1k/CAN_RX'],   'Position',[40 320 320 500]);
    add_block(mf,[m '/ctrl1k/scale_fp'], 'Position',[420 60 660 190]);
    add_block(mf,[m '/ctrl1k/rx_dispatch'],'Position',[420 340 660 470]);
    add_block(mf,[m '/ctrl1k/ctrl_fp'],  'Position',[800 60 1040 190]);
    add_block('sflib/Chart',[m '/ctrl1k/state_chart'],'Position',[800 340 2000 700]);
    add_block(mf,[m '/ctrl1k/pack_all'], 'Position',[1720 60 2000 240]);
    add_block(pick('CAN Write'),[m '/ctrl1k/CAN_TX_0x100'],'Position',[2100 40 2380 220]);
    add_block(pick('CAN Write'),[m '/ctrl1k/CAN_TX_0x500'],'Position',[2100 300 2380 480]);
    add_block('simulink/Sinks/Out1',[m '/ctrl1k/dbg'],'Port','1','Position',[2100 560 2160 600]);

    set_param([m '/ctrl1k/ADC1_BLK'],'ADCModule','ADC1','ConversionGroup','Regular', ...
        'TriggerMode','Trigger and read','NumberOfConversions','8');
    set_param([m '/ctrl1k/CAN_RX'],'CANModule','CAN1','ReadSource','FIFO 0','OperationReadMode','Data','OutputTypeReadMode','Unpacked');
    set_param([m '/ctrl1k/CAN_TX_0x100'],'CANModule','CAN1','DataFormatWriteMode','Raw data','IdentifierVia','Dialog','Identifier','256','IdentifierType','Standard (11-bit identifier)','DataLengthVia','Dialog','DataLength','8');
    set_param([m '/ctrl1k/CAN_TX_0x500'],'CANModule','CAN1','DataFormatWriteMode','Raw data','IdentifierVia','Dialog','Identifier','1280','IdentifierType','Standard (11-bit identifier)','DataLengthVia','Dialog','DataLength','8');

    mf_scale(m,'/ctrl1k/scale_fp');
    mf_ctrl (m,'/ctrl1k/ctrl_fp');
    mf_rx   (m,'/ctrl1k/rx_dispatch');
    mf_pack (m,'/ctrl1k/pack_all');
    sf_chart(m,'/ctrl1k/state_chart');

    al([m '/ctrl1k'],'ADC1_BLK/1','scale_fp/1');
    al([m '/ctrl1k'],'CAN_RX/1','rx_dispatch/1');
    al([m '/ctrl1k'],'CAN_RX/3','rx_dispatch/2');
    al([m '/ctrl1k'],'scale_fp/1','ctrl_fp/1');
    al([m '/ctrl1k'],'rx_dispatch/1','ctrl_fp/2');
    al([m '/ctrl1k'],'state_chart/1','ctrl_fp/3');
    al([m '/ctrl1k'],'scale_fp/2','state_chart/1');
    al([m '/ctrl1k'],'scale_fp/3','state_chart/2');
    al([m '/ctrl1k'],'rx_dispatch/1','state_chart/3');
    al([m '/ctrl1k'],'ctrl_fp/1','pack_all/1');
    al([m '/ctrl1k'],'scale_fp/1','pack_all/2');
    al([m '/ctrl1k'],'state_chart/1','pack_all/3');
    al([m '/ctrl1k'],'rx_dispatch/1','pack_all/4');
    al([m '/ctrl1k'],'scale_fp/2','pack_all/5');
    al([m '/ctrl1k'],'pack_all/1','CAN_TX_0x100/1');
    al([m '/ctrl1k'],'pack_all/2','CAN_TX_0x500/1');
    al([m '/ctrl1k'],'pack_all/3','dbg/1');

    % ================= 100 Hz IO subsystem =================
    add_block('simulink/Ports & Subsystems/Subsystem',[m '/io100'],'Position',[2800 40 3560 300]);
    set_param([m '/io100'],'TreatAsAtomicUnit','on','SystemSampleTime','0.01');
    sub_del([m '/io100']);
    add_block(pick('Digital Port Read'), [m '/io100/DIN'], 'PortName','GPIOC','PinNumber','[0 1 2 3]','ReadOperation','on','IOAsArray','on','Position',[40 40 320 220]);
    add_block(pick('Digital Port Write'),[m '/io100/DOUT'],'PortName','GPIOE','PinNumber','[0 1 2 3]','ReadOperation','off','IOAsArray','on','Position',[420 40 700 220]);
    al([m '/io100'],'DIN/1','DOUT/1');

    % ================= 10 Hz debug subsystem =================
    add_block('simulink/Ports & Subsystems/Subsystem',[m '/dbg10'],'Position',[2800 360 3560 620]);
    set_param([m '/dbg10'],'TreatAsAtomicUnit','on','SystemSampleTime','0.1');
    sub_del([m '/dbg10']);
    add_block('simulink/Sources/In1',[m '/dbg10/din'],'Port','1','Position',[40 120 100 160]);
    add_block(pick('USART Write'),[m '/dbg10/UART_TX'],'UARTModule','USART1','Position',[200 40 480 220]);
    al([m '/dbg10'],'din/1','UART_TX/1');

    % ================= 1 Hz LED subsystem =================
    add_block('simulink/Ports & Subsystems/Subsystem',[m '/led1s'],'Position',[2800 680 3560 940]);
    set_param([m '/led1s'],'TreatAsAtomicUnit','on','SystemSampleTime','1.0');
    sub_del([m '/led1s']);
    add_block(mf,[m '/led1s/F'],'Position',[40 60 280 190]);
    add_block(pick('Digital Port Write'),[m '/led1s/LED'],'PortName','GPIOD','PinNumber','[0 1]','ReadOperation','off','IOAsArray','on','Position',[380 40 660 220]);
    al([m '/led1s'],'F/1','LED/1');
    setEmScript(m,'/led1s/F', [ ...
        "function y = led_toggle()" newline "%#codegen" newline ...
        "persistent s" newline "if isempty(s)" newline "    s = false;" newline "end" newline ...
        "s = ~s;" newline "y = [s; s];" newline "end"]);

    % ================= cross-rate: ctrl1k dbg -> dbg10 =================
    add_block('simulink/Signal Attributes/Rate Transition',[m '/RT_dbg'],'Position',[2620 380 2680 420]);
    al(m,'ctrl1k/1','RT_dbg/1');
    al(m,'RT_dbg/1','dbg10/1');

    % ================= Target configuration =================
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

% ---------- helpers ----------
function sub_del(sys)
    try, delete_line(sys,'In1/1','Out1/1'); catch, end
    try, delete_block([sys '/In1']); delete_block([sys '/Out1']); catch, end
end
function al(sys,a,b)
    add_line(sys,a,b,'autorouting','on');
end
function setEmScript(model, blkPath, script)
    rt = sfroot;
    ch = rt.find('-isa','Stateflow.EMChart','-and','Path',[model blkPath]);
    if isempty(ch), error('EMChart not found: %s%s', model, blkPath); end
    if isstring(script), script = char(join(script,"")); end
    ch.Script = script;
end
function mf_scale(m,p)
    setEmScript(m,p, ["function [v_mV, throttle, brake] = vcu_scale(adc)" newline "%#codegen" newline ...
        "v_mV = fi(zeros(8,1),1,16,0);" newline "k = fi(3300/4095,1,16,15);" newline ...
        "for i = 1:8" newline "    v_mV(i) = fi(adc(i),1,16,0)*k;" newline "end" newline ...
        "throttle = v_mV(1);" newline "brake = v_mV(3);" newline "end"]);
end
function mf_ctrl(m,p)
    setEmScript(m,p, ["function torque = vcu_ctrl(v_mV, vx_meas, state)" newline "%#codegen" newline ...
        "persistent vx_est" newline "if isempty(vx_est)" newline "    vx_est = int16(0);" newline "end" newline ...
        "vx_est = vx_est + int16(0.3*(double(vx_meas)-double(vx_est)));" newline ...
        "torque = int16(zeros(4,1));" newline "if state == 1" newline "    b = v_mV(1);" newline ...
        "    torque(1)=b; torque(2)=b; torque(3)=b; torque(4)=b;" newline "elseif state == 3" newline ...
        "    b = v_mV(3);" newline "    torque(1)=-b; torque(2)=-b; torque(3)=-b; torque(4)=-b;" newline ...
        "end" newline "end"]);
end
function mf_rx(m,p)
    setEmScript(m,p, ["function [vx, bms, sens] = vcu_rx(Data, Id)" newline "%#codegen" newline ...
        "vx = int16(0); bms = int16(0); sens = int16(0);" newline "if Id == uint32(512)" newline ...
        "    vx = int16(bitshift(uint16(Data(1)),8) + uint16(Data(2)));" newline "elseif Id == uint32(768)" newline ...
        "    bms = int16(bitshift(uint16(Data(1)),8) + uint16(Data(2)));" newline "elseif Id == uint32(1024)" newline ...
        "    sens = int16(bitshift(uint16(Data(1)),8) + uint16(Data(2)));" newline "end" newline "end"]);
end
function mf_pack(m,p)
    setEmScript(m,p, ["function [d_tq, d_st, d_dbg] = vcu_pack(tq, v_mV, state, vx, throttle)" newline "%#codegen" newline ...
        "d_tq = zeros(8,1,'uint8');" newline "for i=1:4" newline "    u = uint16(tq(i));" newline ...
        "    d_tq(2*i-1) = uint8(bitshift(u,-8));" newline "    d_tq(2*i)   = uint8(bitand(u,255));" newline "end" newline ...
        "d_st = zeros(8,1,'uint8');" newline "d_st(1) = uint8(state);" newline "for i=1:3" newline ...
        "    u = uint16(v_mV(i));" newline "    d_st(2*i) = uint8(bitshift(u,-8));" newline "    d_st(2*i+1) = uint8(bitand(u,255));" newline "end" newline ...
        "d_dbg = zeros(8,1,'uint8');" newline "d_dbg(1)=uint8(state);" newline ...
        "u=uint16(vx); d_dbg(2)=uint8(bitshift(u,-8)); d_dbg(3)=uint8(bitand(u,255));" newline ...
        "u=uint16(throttle); d_dbg(4)=uint8(bitshift(u,-8)); d_dbg(5)=uint8(bitand(u,255));" newline "end"]);
end
function sf_chart(model, blkPath)
    rt = sfroot;
    ch = rt.find('-isa','Stateflow.Chart','-and','Path',[model blkPath]);
    if isempty(ch), error('Chart not found: %s%s', model, blkPath); end
    delete(ch.find('-isa','Stateflow.State')); delete(ch.find('-isa','Stateflow.Transition'));
    u1=Stateflow.Data(ch); u1.Name='throttle'; u1.Scope='Input'; u1.DataType='int16';
    u2=Stateflow.Data(ch); u2.Name='brake';    u2.Scope='Input'; u2.DataType='int16';
    u3=Stateflow.Data(ch); u3.Name='speed';    u3.Scope='Input'; u3.DataType='int16';
    y1=Stateflow.Data(ch); y1.Name='state';    y1.Scope='Output'; y1.DataType='uint8';
    s1=Stateflow.State(ch); s1.Name='Start'; s1.LabelString=sprintf('Start\nen: state = uint8(0);'); s1.Position=[40 100 320 340];
    s2=Stateflow.State(ch); s2.Name='Drive'; s2.LabelString=sprintf('Drive\nen: state = uint8(1);'); s2.Position=[480 100 760 340];
    s3=Stateflow.State(ch); s3.Name='Brake'; s3.LabelString=sprintf('Brake\nen: state = uint8(3);'); s3.Position=[920 100 1200 340];
    t0=Stateflow.Transition(ch); t0.Destination=s1;
    t12=Stateflow.Transition(ch); t12.Source=s1; t12.Destination=s2; t12.LabelString='[throttle>50]';
    t21=Stateflow.Transition(ch); t21.Source=s2; t21.Destination=s1; t21.LabelString='[speed<=0]'; t21.MidPoint=[400 540];
    t23=Stateflow.Transition(ch); t23.Source=s2; t23.Destination=s3; t23.LabelString='[brake>50]';
    t32=Stateflow.Transition(ch); t32.Source=s3; t32.Destination=s2; t32.LabelString='[throttle>50]'; t32.MidPoint=[840 500];
    t31=Stateflow.Transition(ch); t31.Source=s3; t31.Destination=s1; t31.LabelString='[speed<=0]'; t31.MidPoint=[640 600];
end

