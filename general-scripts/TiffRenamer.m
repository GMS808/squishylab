function TiffRenamer(inDir, outDir, prefix)
% TIFFRENAMER  Copy/rename TIFFs from inDir -> outDir as <prefix>0001.tif, ...
% Example:
%   ds='fullframe_19ms-57';
%   TiffRenamer(fullfile('data',ds,'tiffs_gray'), fullfile('data',ds,'fov1'), 'fov1_');

if nargin < 3, prefix = 'fov1_'; end
if ~exist(inDir,'dir'), error('Input dir not found: %s', inDir); end
if ~exist(outDir,'dir'), mkdir(outDir); end

files = dir(fullfile(inDir,'*.tif*'));
if isempty(files), warning('No TIFFs in %s', inDir); return; end

for k = 1:numel(files)
    inPath  = fullfile(files(k).folder, files(k).name);
    I = imread(inPath);
    outName = sprintf('%s%04d.tif', prefix, k);
    outPath = fullfile(outDir, outName);
    imwrite(I, outPath, 'Compression','none');  % preserve values
end
fprintf('Renamed %d file(s) into %s\n', numel(files), outDir);
end
