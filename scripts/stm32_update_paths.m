function stm32_update_paths()
%STM32_UPDATE_PATHS Point the model at the relocated CubeMX project file.

    projdir = fileparts(fileparts(mfilename('fullpath')));
    m = 'F103_Blink';
    load_system(fullfile(projdir,[m '.slx']));

    ioc = fullfile(projdir,'00_HW','F103C8T6','F103C8T6.ioc');
    codertarget.data.setParameterValue(m,'STM32CubeMX.ProjectFile',ioc);

    save_system(m);
    fprintf('ProjectFile = %s\n', codertarget.data.getParameterValue(m,'STM32CubeMX.ProjectFile'));
    close_system(m,0);
end
