function stm32_probe2()
%STM32_PROBE2 Probe library block paths and target configuration API.

    try
        load_system('stm32blockslib');
        b = find_system('stm32blockslib','SearchDepth',1,'Type','Block');
        fprintf('--- stm32blockslib blocks ---\n');
        for i = 1:numel(b)
            fprintf('%s\n', b{i});
        end
    catch e
        fprintf('lib err: %s\n', e.message);
    end

    m = 'tmp_probe';
    if bdIsLoaded(m)
        close_system(m,0);
    end
    new_system(m);
    try
        set_param(m,'HardwareBoard','STM32F1xx Based');
        fprintf('set HardwareBoard OK\n');
    catch e
        fprintf('set HardwareBoard ERR: %s\n', e.message);
    end
    try
        d = codertarget.data.getData(m);
        fn = fieldnames(d);
        fprintf('--- codertarget data fields ---\n');
        for i = 1:numel(fn)
            fprintf('GROUP %s\n', fn{i});
            v = d.(fn{i});
            if isstruct(v)
                fn2 = fieldnames(v);
                for j = 1:numel(fn2)
                    fprintf('   %s\n', fn2{j});
                end
            end
        end
    catch e
        fprintf('data ERR: %s\n', e.message);
    end
    close_system(m,0);
end
