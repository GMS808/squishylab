function import_all_czis()
% Walks data/<experiment>/, finds *.czi, exports TIFFs + per-frame timestamps.
% Requires Bio-Formats (bfGetReader, bfGetPlane) on the MATLAB path.

projectRoot = fileparts(mfilename('fullpath'));
dataRoot    = fullfile(projectRoot, '..');  % if scripts/ ; adjust if needed
% If this file is at project root instead of scripts/, use:
% dataRoot = fullfile(projectRoot, 'data');

% --- Resolve data root whether we're in scripts/ or root
if endsWith(projectRoot, [filesep 'scripts'])
    dataRoot = fullfile(fileparts(projectRoot), 'data');
else
    dataRoot = fullfile(projectRoot, 'data');
end

exps = dir(dataRoot);
exps = exps([exps.isdir] & ~startsWith({exps.name}, '.'));

for k = 1:numel(exps)
    expFolder = fullfile(dataRoot, exps(k).name);
    czi = dir(fullfile(expFolder, '*.czi'));
    if isempty(czi), fprintf('No CZI in %s\n', exps(k).name); continue; end
    cziPath = fullfile(expFolder, czi(1).name);

    tiffFolder = fullfile(expFolder, 'tiffs');
    if ~exist(tiffFolder,'dir'), mkdir(tiffFolder); end

    fprintf('Importing %s ...\n', czi(1).name);

    % ---- Open with Bio-Formats
    r = bfGetReader(cziPath);
    seriesIdx = 0;                     % use first series; change if needed
    r.setSeries(seriesIdx);
    ome = r.getMetadataStore();

    sizeZ = r.getSizeZ();
    sizeC = r.getSizeC();
    sizeT = r.getSizeT();

    % Preferred per-plane elapsed time in seconds:
    DeltaT = nan(sizeT,1);
    for t = 0:sizeT-1
        p = ome.getPlaneDeltaT(seriesIdx, t);
        if ~isempty(p), DeltaT(t+1) = p.value().doubleValue(); end
    end
    % Fallback: acquisition time or uniform grid
    if all(isnan(DeltaT))
        acq = nan(sizeT,1);
        for t = 0:sizeT-1
            p = ome.getPlaneAcquisitionTime(seriesIdx, t);
            if ~isempty(p), acq(t+1) = p.getValue(); end  % usually ms
        end
        if ~all(isnan(acq))
            acq = acq - acq(1);
            DeltaT = acq / 1000; % ms → s
        else
            DeltaT = (0:sizeT-1)'; % last resort
        end
    end

    % Choose a default Z (mid-slice); export all channels
    zIdx = max(0, round((sizeZ-1)/2));
    chanList = 0:sizeC-1;

    rows = {};
    frameCount = 0;

    for t = 0:sizeT-1
        for c = chanList
            plane = t*sizeZ*sizeC + c*sizeZ + zIdx;  % (Z,C,T) flattened
            I = bfGetPlane(r, plane+1);              % 1-based for bfGetPlane
            frameCount = frameCount + 1;
            fn = sprintf('frame_t%06d_c%02d.tif', t+1, c+1);
            imwrite(I, fullfile(tiffFolder, fn));
            rows(end+1,:) = {frameCount, fn, DeltaT(t+1), zIdx+1, c+1}; %#ok<AGROW>
        end
    end
    r.close();

    % Write per-frame CSV
    tiffTbl = cell2table(rows, 'VariableNames', {'Frame','FileName','Time_s','Z','C'});
    writetable(tiffTbl, fullfile(expFolder,'tiffs_metadata.csv'));

    fprintf('✓ Done: %s (%d frames written)\n', exps(k).name, height(tiffTbl));
end
end
