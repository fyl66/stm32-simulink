function stm32_build()
%STM32_BUILD Build, download and run the F103_Blink model.

    projdir = fileparts(fileparts(mfilename('fullpath')));
    cd(projdir);

    diaryFile = fullfile(tempdir,'stm32_build_diary.txt');
    if isfile(diaryFile), delete(diaryFile); end
    diary(diaryFile);

    try
        slbuild('F103_Blink');
        disp('===== BUILD_OK =====');
    catch e
        fprintf('===== BUILD_ERR =====\n');
        fprintf('identifier: %s\n', e.identifier);
        disp(getReport(e,'extended','hyperlinks','off'));
        for i = 1:numel(e.cause)
            fprintf('cause %d: %s\n', i, e.cause{i}.message);
        end
    end

    diary off;
end
