function render_model(modelPath, outfile)
%RENDER_MODEL Render a Simulink model to a PNG for visual inspection.

    [~,name] = fileparts(modelPath);
    if bdIsLoaded(name), close_system(name,0); end
    load_system(modelPath);
    try
        print(['-s' name], '-dpng', '-r120', outfile);
        fprintf('Rendered %s\n', outfile);
    catch e
        fprintf('RENDER_ERR: %s\n', e.message);
    end
    close_system(name,0);
end
