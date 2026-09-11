function vcu_build_f407()
%VCU_BUILD_F407 Build, download and run models/VCU_F407.slx.

    projdir  = fileparts(fileparts(mfilename('fullpath')));
    modeldir = fullfile(projdir,'models');
    cd(modeldir);

    diaryFile = fullfile(tempdir,'vcu_f407_diary.txt');
    if isfile(diaryFile), delete(diaryFile); end
    diary(diaryFile);

    try
        slbuild('VCU_F407');
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
