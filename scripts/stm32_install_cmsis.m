function stm32_install_cmsis()
%STM32_INSTALL_CMSIS Download, extract and register CMSIS / CMSIS-DSP / CMSIS-NN.

    xmlFolder = fullfile(matlabroot,'toolbox','stm32b','stm32shared','thirdpartytools','instrset');
    keys = {'cmsis','cmsis_dsp','cmsis_nn'};

    for i = 1:numel(keys)
        k = keys{i};
        fprintf('===== %s =====\n', k);

        try
            [st,msg] = shared3pcmsis.download3pCMSISFolder(k, xmlFolder);
            fprintf('  download : status=%d  %s\n', st, msg);
        catch e
            fprintf('  download : ERR %s\n', e.message);
        end

        try
            [st,msg] = shared3pcmsis.install3pCMSISFolder(k, xmlFolder);
            fprintf('  install  : status=%d  %s\n', st, msg);
        catch e
            fprintf('  install  : ERR %s\n', e.message);
        end

        try
            [st,msg] = shared3pcmsis.register3pCMSISFolder(k, xmlFolder);
            fprintf('  register : status=%d  %s\n', st, msg);
        catch e
            fprintf('  register : ERR %s\n', e.message);
        end

        try
            p = shared3pcmsis.get3pCMSISInstallFolder(k);
            fprintf('  folder   : [%s]\n', p);
        catch e
            fprintf('  query    : ERR %s\n', e.message);
        end
    end
end
