function result = checkCliCompatibility(wrapperRoot)
%CHECKCLICOMPATIBILITY Verify consumer path resolution and wrapper runtime assets.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1, wrapperRoot = fullfile(root, 'external', 'wss-matlab-wrapper'); end
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
addpath(fullfile(root, 'src'), fullfile(wrapperRoot, 'src'), fullfile(wrapperRoot, 'conformance'));
options = wss_cli.parseOptions({'--wrapper-root', wrapperRoot}, root);
assert(strcmp(options.ConfigPath, fullfile(root, 'Config')), 'CLI config ownership changed.');
assert(strcmp(options.CsLibDir, fullfile(wrapperRoot, 'Cs_Libraries')), 'CLI did not select wrapper-owned DLLs.');
assert(wss_cli.main({'--help'}) == 0, 'CLI help failed.');
result = checkCompatibility(options.CsLibDir);
end
