function testConformanceProfilesCli()
%TESTCONFORMANCEPROFILES Every missing or unexpected sentinel is rejected.
appRoot = getenv('WSS_MATLAB_PRODUCT_ROOT');
if isempty(appRoot), appRoot = fileparts(fileparts(mfilename('fullpath'))); end
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
addpath(fullfile(appRoot, 'ci'));
baseline = true(1, 6); types = true(1, 6); modern = true(1, 14);
assert(strcmp(classifyConformanceApiCli(baseline, types, modern), 'layered-v1'));
assert(strcmp(classifyConformanceApiCli(baseline, ~types, ~modern), 'legacy-v1'));
for k = 1:numel(baseline)
    value = baseline; value(k) = false;
    reject(@() classifyConformanceApiCli(value, types, modern));
    reject(@() classifyConformanceApiCli(value, ~types, ~modern));
end
for k = 1:numel(types)
    value = types; value(k) = false;
    reject(@() classifyConformanceApiCli(baseline, value, modern));
    reject(@() classifyConformanceApiCli(baseline, ~value, ~modern));
end
for k = 1:numel(modern)
    value = modern; value(k) = false;
    reject(@() classifyConformanceApiCli(baseline, types, value));
    reject(@() classifyConformanceApiCli(baseline, ~types, ~value));
end
end

function reject(action)
failed = false;
try
    action();
catch
    failed = true;
end
assert(failed, 'Partial API unexpectedly accepted.');
end
