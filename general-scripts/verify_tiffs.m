function verify_tiffs()
% Lists each dataset under data/, counts TIFFs in input_tiffs/.

rootDir = fullfile('data');
dsets   = dir(rootDir);
dsets   = dsets([dsets.isdir] & ~startsWith({dsets.name},'.'));

fprintf('Scanning %s …\n\n', rootDir);
grand = 0;
for i = 1:numel(dsets)
    ds = dsets(i).name;
    inDir = fullfile(rootDir, ds, 'input_tiffs');
    if exist(inDir,'dir')
        files = dir(fullfile(inDir,'*.tif*'));
        grand = grand + numel(files);
        fprintf('%-22s  %4d TIFF(s) in input_tiffs/\n', ds, numel(files));
    end
end
fprintf('\nTotal input TIFFs found: %d\n', grand);
end
