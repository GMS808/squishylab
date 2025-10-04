function make_times_from_rate(video, varargin)
% MAKE_TIMES_FROM_RATE  Create per-frame times when TIFFs have no timestamps.
% Looks in data/<video>/tiffs_gray (or tiffs), counts frames, and writes:
%   data/<video>/video metadata/tiff_times.csv   (frame, rel_ms)
%   data/<video>/fov1_times.mat                  (variable: time, in seconds)
%
% Usage examples:
%   make_times_from_rate('fullframe_19ms-57','dt_ms',19)      % use 19 ms per frame
%   make_times_from_rate('fullframe_19ms-57','fps',52.63)     % use fps
%   make_times_from_rate('fullframe_19ms-57')                 % try to parse "19ms" from folder name

p = inputParser;
p.addRequired('video', @(s)ischar(s)||isstring(s));
p.addParameter('fps', [], @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('dt_ms', [], @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.parse(video, varargin{:});
fps   = p.Results.fps;
dt_ms = p.Results.dt_ms;

root  = fullfile('data', char(video));
inDir = fullfile(root,'tiffs_gray');
if ~isfolder(inDir), inDir = fullfile(root,'tiffs'); end
assert(isfolder(inDir), 'No tiffs_gray/ or tiffs/ under %s', root);

dd = dir(fullfile(inDir,'*.tif*'));
assert(~isempty(dd), 'No TIFFs found in %s', inDir);
n = numel(dd);

% If neither fps nor dt_ms given, try to parse e.g. "..._19ms-57"
if isempty(fps) && isempty(dt_ms)
    m = regexp(char(video), '([0-9]*\.?[0-9]+)\s*ms', 'tokens', 'once');
    if ~isempty(m)
        dt_ms = str2double(m{1});
        fprintf('Parsed dt = %.6g ms from video name.\n', dt_ms);
    else
        error('Provide ''dt_ms'' or ''fps'' (e.g., make_times_from_rate(''%s'',''dt_ms'',19))', video);
    end
end

if isempty(dt_ms)
    dt_ms = 1000 / fps;
else
    fps = 1000 / dt_ms;
end
fprintf('Using dt = %.6g ms (fps = %.6g)\n', dt_ms, fps);

% Build times: start at t=0
rel_ms = (0:n-1)' * dt_ms;          % milliseconds
time   = rel_ms / 1000;             % seconds

% Write CSV
outDir = fullfile(root,'video metadata');
if ~isfolder(outDir), mkdir(outDir); end
T = table((1:n)', rel_ms, 'VariableNames', {'frame','rel_ms'});
csvPath = fullfile(outDir,'tiff_times.csv');
writetable(T, csvPath);

% Save MAT (legacy)
matPath = fullfile(root,'fov1_times.mat');
save(matPath, 'time');

fprintf('Wrote %s and %s\n', csvPath, matPath);
end
