function process_tiffs()
% Processes all TIFFs under data/*/input_tiffs/ into data/*/processed_tiffs/.
% - Supports single & multi-page TIFFs
% - Preserves integer classes; rescales floats to uint16

rootDir = fullfile('data');
dsets   = dir(rootDir);
dsets   = dsets([dsets.isdir] & ~startsWith({dsets.name},'.'));

for d = 1:numel(dsets)
    dsName = dsets(d).name;
    inDir  = fullfile(rootDir, dsName, 'input_tiffs');
    outDir = fullfile(rootDir, dsName, 'processed_tiffs');

    if ~exist(inDir,'dir')
        continue
    end
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end

    files = dir(fullfile(inDir,'*.tif*'));
    if isempty(files)
        fprintf('%s: no TIFFs found.\n', dsName);
        continue
    end

    fprintf('Processing %-22s  (%d file(s))\n', dsName, numel(files));

    for k = 1:numel(files)
        inPath = fullfile(files(k).folder, files(k).name);
        info   = imfinfo(inPath);
        nPages = numel(info);

        for p = 1:nPages
            I = imread(inPath, p);

            % Normalize datatype for writing
            if isa(I,'uint8') || isa(I,'uint16') || isa(I,'uint32')
                J = I;                     % keep integer range as-is
            else
                J = im2uint16(mat2gray(I));% float/int -> uint16 safely
            end

            outName = sprintf('%s_f%05d_p%03d.tif', dsName, k, p);
            outPath = fullfile(outDir, outName);

            % Ensure parent dir exists (robust)
            if ~exist(fileparts(outPath),'dir')
                mkdir(fileparts(outPath));
            end

            imwrite(J, outPath, 'Compression','none');
        end
    end
end

fprintf('Done.\n');
end
