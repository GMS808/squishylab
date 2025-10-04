function [] = mpretrack(basepath, fovn, featuresize, barrI, barrRg, barrCc, IdivRg, numframes, masscut, Imin, field)
% MPRETRACK  Pre-processing & feature finding over a sequence of TIFF frames.
%
% This version is path-agnostic and works directly inside a per-video folder:
%   data/<videoName>/
%       tiffs/           (raw frames)        <-- used if tiffs_gray/ missing
%       tiffs_gray/      (preferred frames)  <-- produced by fix_rgb_grayscale.m
%       Feature_finding/ (outputs written here)
%
% Usage (example):
%   base = fullfile('data','fullframe_19ms-57');
%   featsize=7; barrI=50; barrRg=10; barrCc=0.8; IdivRg=3; masscut=0; Imin=0; field=1;
%   numframes = numel(dir(fullfile(base,'tiffs_gray','*.tif')));
%   mpretrack(base, 1, featsize, barrI, barrRg, barrCc, IdivRg, numframes, masscut, Imin, field);
%
% Inputs (kept to match your legacy signature):
%   basepath    : path to the *video* folder (e.g., data/<videoName>)
%   fovn        : FOV index (integer tag in output names)
%   featuresize : approx feature size passed to feature2D (pixels)
%   barrI       : intensity barrier (passed through / stored for reference)
%   barrRg      : region/size barrier (stored for reference)
%   barrCc      : circularity/corr barrier (stored for reference)
%   IdivRg      : intensity normalization divisor (stored for reference)
%   numframes   : number of frames to process (will be clamped to available)
%   masscut     : mass threshold for feature2D
%   Imin        : min intensity for feature2D
%   field       : field index for feature2D
%
% Output:
%   Saves to <basepath>/Feature_finding/MT_<fovn>_Feat_Size_<featuresize>.mat
%   with variables: MT, params, framesDir, fileList, featuresFound, time

% -------- Normalize and locate frame directory --------
if nargin < 12
    error('mpretrack:NotEnoughInputs','Expected 12 inputs; got %d', nargin);
end
if ~endsWith(basepath, filesep), basepath = [basepath filesep]; end

framesDir = fullfile(basepath, 'tiffs_gray');
if ~exist(framesDir, 'dir')
    framesDir = fullfile(basepath, 'tiffs');
end
if ~exist(framesDir, 'dir')
    error('mpretrack:NoFramesDir', 'No tiffs_gray/ or tiffs/ found under %s', basepath);
end

dd = dir(fullfile(framesDir,'*.tif*'));
if isempty(dd)
    error('mpretrack:NoFrames', 'No TIFF files found in %s', framesDir);
end

fileList = natsortfiles(fullfile({dd.folder}, {dd.name}));
numAvailable = numel(fileList);
numframes = min(numframes, numAvailable);

% -------- Output folder & times vector --------
pathout = fullfile(basepath, 'Feature_finding');
if ~exist(pathout, 'dir'), mkdir(pathout); end

tfile = fullfile(basepath, sprintf('fov%d_times.mat', fovn));
if exist(tfile,'file')
    S = load(tfile);                     %#ok<NASGU>
else
    time = (1:numframes)';               %#ok<NASGU>
    save(tfile,'time');
end

% -------- Run feature finding --------
fprintf('mpretrack: frames=%d (of %d available) | featuresize=%g | video=%s\n', ...
    numframes, numAvailable, featuresize, stripTrailingSep(basepath));
tic;

MT = cell(numframes,1);      % one features table per frame (as returned by feature2D)
featuresFound = zeros(numframes,3); % [frameIndex, nFeatures, reserved]

for k = 1:numframes
    fpath = fileList{k};
    try
        img = imread(fpath);
    catch ME
        warning('mpretrack:ReadFail','Failed to read %s: %s', fpath, ME.message);
        MT{k} = [];
        continue;
    end

    % Call your existing detector (signature preserved)
    % M is expected to be an Nx? numeric array of features; nmax count
    try
        [M, nmax] = feature2D(img, 1, featuresize, masscut, Imin, field);
    catch ME
        warning('mpretrack:Feature2DFail','feature2D failed on %s: %s', fpath, ME.message);
        M = []; nmax = 0;
    end

    % (Intentionally *not* re-filtering by barrI/barrRg/barrCc here, to keep
    %  exactly what feature2D returns. If you want explicit gating, we can
    %  add a post-filter step using these thresholds.)
    MT{k} = M;
    featuresFound(k,1) = k;
    featuresFound(k,2) = nmax;
end

elapsedMin = toc/60;
fprintf('mpretrack: completed in %.2f min\n', elapsedMin);

% -------- Save outputs (legacy-friendly name) --------
params = struct('featuresize',featuresize, 'barrI',barrI, 'barrRg',barrRg, ...
                'barrCc',barrCc, 'IdivRg',IdivRg, 'masscut',masscut, ...
                'Imin',Imin, 'field',field, 'fovn',fovn);

saveName = fullfile(pathout, sprintf('MT_%d_Feat_Size_%g.mat', fovn, featuresize));
try
    save(saveName, 'MT', 'params', 'framesDir', 'fileList', 'featuresFound', '-v7.3');
catch
    % Fallback if -v7.3 not desired
    save(saveName, 'MT', 'params', 'framesDir', 'fileList', 'featuresFound');
end
fprintf('mpretrack: saved %s\n', saveName);

end % function mpretrack

% =================== helpers ===================

function out = natsortfiles(paths)
% Natural sort of file paths (…_2.tif before …_10.tif)
if ischar(paths), paths = cellstr(paths); end
[~, names] = cellfun(@fileparts, paths, 'uni', 0);
tokens = regexp(names, '(\d+)|(\D+)', 'match');
keys = cellfun(@(t) cellfun(@kpart,t,'uni',0), tokens, 'uni', 0);
[~, idx] = sortrows(keys);
out = paths(idx);
    function kp = kpart(tok)
        d = sscanf(tok,'%d');
        if ~isempty(d), kp = {1,d};
        else,           kp = {2,tok};
        end
    end
end

function s = stripTrailingSep(p)
% Pretty print a path without a trailing file separator
if isempty(p), s = p; return; end
if p(end)==filesep, s = p(1:end-1); else, s = p; end
end
