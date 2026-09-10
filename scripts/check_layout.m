function check_layout(modelPath)
%CHECK_LAYOUT Report block overlaps and diagonal line segments for a model.

    [~,name] = fileparts(modelPath);
    if bdIsLoaded(name), close_system(name,0); end
    h = load_system(modelPath);

    % --- top-level blocks ---
    blks = find_system(h,'SearchDepth',1,'Type','Block');
    P = zeros(numel(blks),4);
    for i = 1:numel(blks)
        P(i,:) = get_param(blks(i),'Position');
    end
    overlaps = 0;
    for i = 1:numel(blks)
        for j = i+1:numel(blks)
            if rectOverlap(P(i,:),P(j,:))
                overlaps = overlaps + 1;
                fprintf('  OVERLAP: %s  <->  %s\n', get_param(blks(i),'Name'), get_param(blks(j),'Name'));
            end
        end
    end

    % --- lines ---
    L = find_system(h,'FindAll','on','Type','line');
    diag = 0;
    for i = 1:numel(L)
        p = get_param(L(i),'Points');
        for k = 2:size(p,1)
            if p(k,1) ~= p(k-1,1) && p(k,2) ~= p(k-1,2)
                diag = diag + 1; break;
            end
        end
    end

    fprintf('%s : blocks=%d overlaps=%d lines=%d diagonal=%d\n', ...
        name, numel(blks), overlaps, numel(L), diag);
    close_system(name,0);
end

function tf = rectOverlap(a,b)
    tf = ~(a(3) <= b(1) || b(3) <= a(1) || a(4) <= b(2) || b(4) <= a(2));
end

