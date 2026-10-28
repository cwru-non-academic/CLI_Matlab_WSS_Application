function tests = TestCliRuntime
% Exercises application cleanup through its production entry point/emulator.
tests = functiontests(localfunctions);
end

function testQuitAndCommandFailureDisposeHost(testCase)
appRoot = fileparts(fileparts(mfilename('fullpath')));
wrapperRoot = getenv('WSS_MATLAB_WRAPPER_ROOT');
if isempty(wrapperRoot), wrapperRoot = fullfile(appRoot, 'external', 'wss-matlab-wrapper'); end
directory = tempname;
mkdir(directory);
copyfile(fullfile(appRoot, 'Config', '*.json'), directory);
cleanup = onCleanup(@() rmdir(directory, 's'));
quitLog = fullfile(directory, 'quit.log');
base = {'--wrapper-root', wrapperRoot, '--config', directory, '--conformance'};
verifyEqual(testCase, wss_cli.main([base, {'--log-file', quitLog, '--command', 'quit'}]), 0);
verifySubstring(testCase, fileread(quitLog), 'Disposed');
errorLog = fullfile(directory, 'error.log');
verifyError(testCase, @() wss_cli.main([base, {'--log-file', errorLog, '--command', 'unknown'}]), ...
    'wss_cli:UnknownCommand');
verifySubstring(testCase, fileread(errorLog), 'Disposed');
end
