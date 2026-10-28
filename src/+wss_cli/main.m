function code = main(argv)
%MAIN Run the MATLAB application CLI; errors propagate for matlab -batch.
% Pass {'--command','status','--command','quit'} for finite batch operation.
if nargin < 1, argv = {}; end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
options = wss_cli.parseOptions(argv, root);
code = 0;
if options.Help
    fprintf(['WSS MATLAB CLI\n' ...
        '--serial NAME --config DIR --cs-libs DIR --log-file FILE\n' ...
        '--max-retries N --tick MS --test | --conformance\n' ...
        '--wrapper-root DIR (explicit local development override)\n' ...
        '--command "COMMAND" (repeatable; finite batch mode) --help\n']);
    return;
end
if batchStartupOptionUsed && isempty(options.Commands)
    error('wss_cli:BatchCommandsRequired', 'Use --command for noninteractive batch sessions.');
end
wrapperSrc = fullfile(options.WrapperRoot, 'src');
if ~isfile(fullfile(wrapperSrc, '+wss', 'StimulationController.m'))
    error('wss_cli:MissingWrapper', ['Wrapper source is unavailable in the pinned submodule. ' ...
        'Initialize the submodule after publishing a wrapper revision containing the implementation.']);
end
oldPath = path;
addpath(wrapperSrc);
try
    config = wss.WssConfig('ConfigPath', options.ConfigPath, 'CsLibDir', options.CsLibDir, ...
        'LogPath', options.LogPath, 'SerialPort', options.SerialPort, ...
        'MaxSetupTries', options.MaxSetupTries, 'TickIntervalMs', options.TickIntervalMs, ...
        'TestMode', options.TestMode, 'ConformanceMode', options.ConformanceMode);
    controller = wss_cli.createController(config);
catch failure
    path(oldPath);
    rethrow(failure);
end
% A single cleanup boundary keeps wrapper classes on path until disposal.
controllerCleanup = onCleanup(@() shutdownThenRestore(controller, oldPath));
controller.Initialize();
fprintf('WSS controller initialized; waiting for asynchronous setup.\n');
fprintf('Config: %s\nDLLs: %s\nHost log: %s\n', config.ConfigPath, config.CsLibDir, config.LogPath);
if ~isempty(options.Commands)
    for k = 1:numel(options.Commands)
        if ~wss_cli.executeCommand(controller, options.Commands{k}), break; end
    end
    return;
end
wss_cli.executeCommand(controller, 'help');
while true
    line = input('> ', 's');
    try
        if ~wss_cli.executeCommand(controller, line), break; end
    catch failure
        fprintf(2, 'Command failed: %s\n', failure.message);
        if ~isempty(controller.LastTickError), rethrow(failure); end
    end
end
end

function shutdownThenRestore(controller, oldPath)
restore = onCleanup(@() path(oldPath));
controller.Shutdown();
delete(controller);
end
