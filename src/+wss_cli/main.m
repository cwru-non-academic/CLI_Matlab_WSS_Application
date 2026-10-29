function code = main(argv)
%MAIN Run the MATLAB application CLI; errors propagate for matlab -batch.
% Pass {'--command','status','--command','quit'} for finite batch operation.
if nargin < 1, argv = {}; end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
options = wss_cli.parseOptions(argv, root);
code = 0;
if options.Help
    fprintf(['WSS MATLAB CLI\n' ...
        '--transport serial|ble|test|conformance (default: serial)\n' ...
        '--ble-auto | --ble-device-name NAME | --ble-device-id ID\n' ...
        '--serial NAME --config DIR --cs-libs DIR --log-file FILE\n' ...
        '--max-retries N --tick MS --test | --conformance\n' ...
        'Conformance without --command runs shared checks and exits.\n' ...
        '--wrapper-root DIR (explicit local development override)\n' ...
        '--command "COMMAND" (repeatable; finite batch mode) --help\n' ...
        '--serial-smoke (construct/dispose only; no port opened)\n' ...
        'Value options also accept --name=value, as in the C# CLI.\n']);
    return;
end
if batchStartupOptionUsed && isempty(options.Commands) && ~options.SerialSmoke && ~options.ConformanceMode
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
    if options.SerialSmoke
        smokeOptions = options;
        smokeOptions.Transport = 'serial';
        if ispc, smokeOptions.SerialPort = 'COM1'; else, smokeOptions.SerialPort = '/dev/ttyWssSmoke'; end
        transport = wss.createTransport(wss_cli.createConfig(smokeOptions));
        smokeCleanup = onCleanup(@() transport.Dispose());
        fprintf('Serial transport constructed and disposed successfully.\n');
        path(oldPath);
        return;
    end
    if options.ConformanceMode && isempty(options.Commands)
        conformanceCleanup = onCleanup(@() path(oldPath));
        addpath(fullfile(root, 'conformance'));
        results = runCliConformance(options.WrapperRoot, options.CsLibDir);
        if ~all([results.Passed]), error('wss_cli:Conformance', 'Core conformance failed.'); end
        fprintf('Conformance: %d/%d passed\n', sum([results.Passed]), numel(results));
        return;
    end
    config = wss_cli.createConfig(options);
    controller = wss_cli.createController(config);
catch failure
    path(oldPath);
    rethrow(failure);
end
% A single cleanup boundary keeps wrapper classes on path until disposal.
controllerCleanup = onCleanup(@() shutdownThenRestore(controller, oldPath));
controller.Initialize();
fprintf('WSS controller initialized; waiting for asynchronous setup.\n');
fprintf('Transport: %s\n', config.Transport);
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
