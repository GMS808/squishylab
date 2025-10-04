function fix_rgb_grayscale(videoName, varargin)
% FIX_RGB_GRAYSCALE  Convert TIFFs under data/<videoName>/tiffs (or input_tiffs) to robust grayscale.
% Writes to data/<videoName>/tiffs_gray/ and data/<videoName>/tiff_frame_metadata.csv.
%
% Usage:
%   fix_rgb_grayscale('fullframe_19ms-57');
%   fix_rgb_grayscale('fullframe_19ms-57','InDir', fullfile('data','fullframe_19ms-57','input_tiffs'));
%   fix_rgb_grayscale('fullframe_19ms-57','Percentiles',[0.5 99.5],'Channel','auto');
%
% Name-Value:
%   'Percentiles' : [lo hi] robust stretch percentiles (default [0.5 99.5])
%   'Channel'     : 'auto' | 'luma' | 'R' | 'G' | 'B' | 'single'  (default 'auto')
%   'Overwrite'   : true/false (default true)
%   'InDir'       : explicit path to the folder containing source TIFFs

p = inputParser;
p.addRequired('videoName', @(s)ischar(s)||isstring(s));
p.addParameter('Percentiles', [0.5 99.5], @(v)isnumeric(v)&&numel(v)==2);
p.addParameter('Channel', 'auto', @(s)ischar(s)||isstring(s));
p.addParameter('Overwrite', true, @(x)islogical(x));
p.addParameter('InDir', '', @(s)ischar(s)||isstring(s));   % NEW
p.parse(videoName, varargin{:});
percent   = p.Results.Percentiles;
chanMode  = lower(string(p.Results.Channel));
overwrite = p.Results.Overwrite;
inDirOpt  = char(p.Results.InDir);

rootDir = fullfile('data', char(videoName));
if ~isempty(inDirOpt)
    inDir = inDirOpt;
else
    % prefer .../tiffs; fallback to .../input_tiffs; else search child/*/tiffs
    cand = { fullfile(rootDir,'tiffs'), fullfile(rootDir,'input_tiffs') };
    inDir = '';
    for c = cand
        if exist(c{1},'dir'), inDir = c{1}; break; end
    end
    if isempty(inDir)
        kids = dir(rootDir); kids = kids([kids.isdir] & ~startsWith({kids.name},'.'));
        for k = 1:numel(kids)
            tpath = fullfile(kids(k).folder, kids(k).name, 'tiffs');
            if exist(tpath,'dir'), inDir = tpath; break; end
        end
    end
    if isempty(inDir)
        error('Missing input dir: expected %s/tiffs or %s/input_tiffs (or child/*/tiffs).', rootDir, rootDir);
    end
end

outDir = fullfile(rootDir, 'tiffs_gray');
if ~exist(outDir,'dir'), mkdir(outDir); end

files = dir(fullfile(inDir,'*.tif*'));
if isempty(files), warning('No TIFFs in %s', inDir); return; end

rows = {};
fprintf('Converting %d TIFF(s): %s -> %s\n', numel(files), inDir, outDir);

for k = 1:numel(files)
    inPath = fullfile(files(k).folder, files(k).name);
    info   = imfinfo(inPath);
    nPages = numel(info);
    [~, base] = fileparts(inPath);

    for pno = 1:nPages
        I = imread(inPath, pno);
        origClass = class(I);
        colorType = info(1).ColorType;
        bitDepth  = info(1).BitDepth;

        % ---- RGB → gray (safe) ----
        Id = double(I);
        method = "mono";
        if ndims(I)==3 && size(I,3)==3
            switch chanMode
                case "r",  G = Id(:,:,1); method="R";
                case "g",  G = Id(:,:,2); method="G";
                case "b",  G = Id(:,:,3); method="B";
                case "luma", G = 0.2126*Id(:,:,1)+0.7152*Id(:,:,2)+0.0722*Id(:,:,3); method="luma";
                case "single", G = Id(:,:,2); method="single(G)";
                otherwise
                    Ic = reshape(Id,[],3);
                    if max(std(Ic,0,1)) < 1e-6
                        G = Id(:,:,2); method="monoRGB→G";
                    else
                        G = 0.2126*Id(:,:,1)+0.7152*Id(:,:,2)+0.0722*Id(:,:,3); method="auto→luma";
                    end
            end
        else
            G = Id;
        end

        % ---- robust stretch to 16-bit ----
        mn = min(G(:)); mx = max(G(:));
        lohi = prctile(G(:), percent);
        if ~isfinite(lohi(1)) || lohi(1)==lohi(2), lohi = [mn mx]; end
        if lohi(1)==lohi(2)
            J = zeros(size(G),'uint16');
        else
            Jr = (G - lohi(1)) / (lohi(2) - lohi(1));
            Jr = max(0, min(1, Jr));
            J = uint16(Jr * 65535);
        end

        outName = sprintf('%s_p%03d_gray.tif', base, pno);
        outPath = fullfile(outDir, outName);
        if overwrite || ~exist(outPath,'file')
            imwrite(J, outPath, 'Compression','none');
        end

        rows(end+1,:) = {inPath, outPath, pno, colorType, origClass, bitDepth, mn, mx, lohi(1), lohi(2), char(method)}; %#ok<AGROW>
    end
end

T = cell2table(rows, 'VariableNames', ...
 {'source_path','output_path','page','color_type','orig_class','bit_depth','min_val','max_val','low_clip','high_clip','method'});
writetable(T, fullfile(rootDir,'tiff_frame_metadata.csv'));
fprintf('Wrote: %s\n', fullfile(rootDir,'tiff_frame_metadata.csv'));
end
