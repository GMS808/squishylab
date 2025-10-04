function extract_tiff_times(video)
% EXTRACT_TIFF_TIMES  Parse timestamps from TIFF metadata.
% Scans data/<video>/tiffs_gray/ (preferred) or data/<video>/tiffs/,
% writes: data/<video>/video metadata/tiff_times.csv
% and also saves data/<video>/fov1_times.mat (legacy compatibility).
%
% Usage:
%   extract_tiff_times('fullframe_19ms-57');

% ----- locate frame folder -----
root  = fullfile('data', video);
inDir = fullfile(root, 'tiffs_gray');
if ~isfolder(inDir)
    inDir = fullfile(root, 'tiffs');
end
assert(isfolder(inDir), 'No tiffs_gray/ or tiffs/ found under %s', root);

dd = dir(fullfile(inDir, '*.tif*'));
assert(~isempty(dd), 'No TIFFs found in %s', inDir);

files = natsortfiles(fullfile({dd.folder}, {dd.name}));

% ----- iterate & parse -----
rows = {};
t0 = NaT;  % first absolute timestamp (if available)

for i = 1:numel(files)
    p = files{i};
    info = imfinfo(p); % assumes single-page; extend if multipage needed
    dtstr = "";
    rel_ms = NaN;

    % Prefer ImageDescription if present
    desc = "";
    if isfield(info(1), 'ImageDescription') && ~isempty(info(1).ImageDescription)
        desc = string(info(1).ImageDescription);
    end

    % Common absolute timestamp keys
    m = regexp(desc, '(TimeStamp|Timestamp|AcquisitionTime)\s*[:=]\s*([^\s;]+)', 'tokens', 'once');
    if ~isempty(m)
        dtstr = string(m{2});
    end

    % Common relative time keys (ms)
    m2 = regexp(desc, '(RelativeTime|Time\s*\[ms\]|DeltaT|dt)\s*[:=]\s*([0-9\.]+)', 'tokens', 'once');
    if ~isempty(m2)
        rel_ms = str2double(m2{2});
    end

    % Fallback to TIFF DateTime (second resolution)
    if dtstr == "" && isfield(info(1), 'DateTime') && ~isempty(info(1).DateTime)
        dtstr = string(info(1).DateTime);  % format: yyyy:MM:dd HH:mm:ss
    end

    % Parse absolute time (try several formats)
    abs_dt = NaT;
    fmts = { ...
        'yyyy-MM-dd''T''HH:mm:ss.SSS', ...
        'yyyy-MM-dd''T''HH:mm:ss', ...
        'yyyy:MM:dd HH:mm:ss' ...
    };
    for f = 1:numel(fmts)
        try
            abs_dt = datetime(dtstr, 'InputFormat', fmts{f}, 'TimeZone', 'local');
            if ~isnat(abs_dt), break; end
        catch
        end
    end

    % Anchor relative on first absolute if needed
    if isnat(abs_dt) && ~isnan(rel_ms) && ~isnat(t0)
        abs_dt = t0 + milliseconds(rel_ms);
    end
    if isscalar(t0) && isnat(t0) && ~isnat(abs_dt)
        t0 = abs_dt;
    end
    if isnan(rel_ms) && ~isnat(abs_dt) && ~isnat(t0)
        rel_ms = milliseconds(abs_dt - t0);
    end

    rows(end+1,:) = {i, p, char(dtstr), abs_dt, rel_ms}; %#ok<AGROW>
end

% ----- write outputs -----
outDir = fullfile(root, 'video metadata');
if ~isfolder(outDir)
    mkdir(outDir);
end
T = cell2table(rows, 'VariableNames', {'frame','path','raw_dt','abs_time','rel_ms'});
writetable(T, fullfile(outDir, 'tiff_times.csv'));
save(fullfile(root, 'fov1_times.mat'), 'T');  % legacy consumer

fprintf('Wrote %s\n', fullfile(outDir, 'tiff_times.csv'));
end

% ================= helpers =================

function out = natsortfiles(paths)
% Natural-ish sort by zero-padding numeric runs inside filenames.
% Compatible with older MATLAB (no function-handle regex replacements).
if ischar(paths), paths = cellstr(paths); end
keys = cell(size(paths));
for i = 1:numel(paths)
    keys{i} = make_sort_key(paths{i});
end
[~, idx] = sort(keys);  % pure lexicographic on padded keys
out = paths(idx);
end

function key = make_sort_key(p)
% Build a key by interleaving text parts with zero-padded numbers
[~, name, ext] = fileparts(p);
s = [name ext];
numMatches = regexp(s, '\d+', 'match');
txtParts   = regexp(s, '\d+', 'split');

% Pad numbers to fixed width
PADW = 12;  % increase if you have insanely large frame numbers
key = '';
for k = 1:numel(numMatches)
    key = [key, txtParts{k}, sprintf(['%0',num2str(PADW),'d'], str2double(numMatches{k}))]; %#ok<AGROW>
end
if numel(txtParts) > numel(numMatches)
    key = [key, txtParts{end}]; %#ok<AGROW>
end
end
