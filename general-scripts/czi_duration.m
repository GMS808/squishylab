function duration_sec = czi_duration(fname, sceneIdx)
% Get duration (s) of a CZI time series without Bio-Formats, via Python aicspylibczi.
% Requires: Python3 with 'aicspylibczi' and 'lxml' (or stdlib ElementTree).
% pip install aicspylibczi lxml

if nargin < 2, sceneIdx = 0; end

% Ensure MATLAB sees your Python
% pyenv('Version','/usr/bin/python3');  % <-- set if needed

aics = py.importlib.import_module('aicspylibczi');
ET   = py.importlib.import_module('xml.etree.ElementTree');

czi = aics.CziFile(fname);

% Discover time range for this scene (from binary dims, not just metadata)
dims_list = cell(czi.get_dims_shape());     % list of Py dicts
% Find the dict whose 'S' range covers this scene
match_i = [];
for i = 1:numel(dims_list)
    d = dims_list{i};
    if d.has_key(py.str('S'))
        Sr = cell(d.get(py.str('S'))); % Python tuple -> {start,end}
        if sceneIdx >= Sr{1} && sceneIdx < Sr{2}
            match_i = i; break;
        end
    end
end
if isempty(match_i)
    warning('Scene %d not found.', sceneIdx); duration_sec = NaN; return;
end
d = dims_list{match_i};

% Time index range [T0, T1) for this scene
if ~d.has_key(py.str('T'))
    warning('No time dimension for scene %d.', sceneIdx); duration_sec = 0; return;
end
Tr = cell(d.get(py.str('T')));
T0 = double(Tr{1}); T1 = double(Tr{2});  % half-open interval

times = nan(T1-T0,1);

% Read subblock metadata at each time and parse AcquisitionTime (ISO8601)
for t = T0:(T1-1)
    xml = czi.read_subblock_metadata(true, pyargs('S',sceneIdx,'T',int32(t)));
    % xml is an Element; stringify & regex out AcquisitionTime or TimeStamp
    xml_bytes = ET.tostring(xml, pyargs('encoding','utf-8'));
    xml_str   = char(py.bytes.decode(xml_bytes,"utf-8"));

    % Try AcquisitionTime="..." (ISO 8601), fallback to TimeStamp="..."
    tok = regexp(xml_str,'AcquisitionTime="([^"]+)"','tokens','once');
    if isempty(tok)
        tok = regexp(xml_str,'TimeStamp="([^"]+)"','tokens','once');
    end
    if isempty(tok)
        continue
    end
    % Robust ISO8601 parse (timezone aware). Adjust format if needed.
    try
        dt = datetime(tok{1},'InputFormat',"yyyy-MM-dd'T'HH:mm:ss.SSSSSSSXXX",'TimeZone','UTC');
    catch
        % Fallback with fewer fractional seconds
        dt = datetime(tok{1},'InputFormat',"yyyy-MM-dd'T'HH:mm:ss.SSSXXX",'TimeZone','UTC');
    end
    times(t-T0+1) = posixtime(dt);
end

good = ~isnan(times);
if ~any(good)
    warning('No timestamps found in subblock metadata for scene %d.', sceneIdx);
    duration_sec = NaN;
else
    duration_sec = max(times(good)) - min(times(good));
end
end
