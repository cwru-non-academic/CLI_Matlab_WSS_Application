function results = runCliConformance(wrapperRoot)
%RUNCLICONFORMANCE Run Core catalog through the app's production factory.
% A local wrapper override is explicit until a published implementation can
% be pinned in the submodule. The submodule gitlink is never changed here.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1, wrapperRoot = fullfile(root, 'external', 'wss-matlab-wrapper'); end
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
addpath(fullfile(root, 'src'), fullfile(wrapperRoot, 'src'), fullfile(wrapperRoot, 'conformance'));
results = runConformance(@wss_cli.createController, fullfile(wrapperRoot, 'Cs_Libraries'));
end
