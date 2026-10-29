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

function testBleArgumentsReachActualCoreTransportWithoutConnecting(testCase)
appRoot = fileparts(fileparts(mfilename('fullpath')));
wrapperRoot = getenv('WSS_MATLAB_WRAPPER_ROOT');
if isempty(wrapperRoot), wrapperRoot = fullfile(appRoot, 'external', 'wss-matlab-wrapper'); end
oldPath = path;
cleanupPath = onCleanup(@() path(oldPath));
addpath(fullfile(wrapperRoot, 'src'));
selectors = {{'--ble-auto'}, {'--ble-device-name=WSS unit'}, {'--ble-device-id=device-id'}};
for k = 1:numel(selectors)
    options = wss_cli.parseOptions([{'--wrapper-root', wrapperRoot, '--transport=ble'}, selectors{k}], appRoot);
    config = wss_cli.createConfig(options);
    if ismac && ~isfile(fullfile(config.CsLibDir, 'backends', 'macos', 'WSS.Transport.BLE.MacOS.dll'))
        verifyError(testCase, @() wss.createTransport(config), 'wss:MissingBleBackend');
        fprintf('Legacy payload: explicit macOS BLE rejection verified; no backend available.\n');
        return;
    end
    transport = wss.createTransport(config);
    cleanup = onCleanup(@() transport.Dispose());
    verifyEqual(testCase, char(transport.GetType().FullName), 'Wss.Transports.BleNusTransport');
    verifyFalse(testCase, transport.IsConnected);
    % This boundary assertion protects argv -> wrapper -> Core option mapping.
    field = transport.GetType().GetField('_options', ...
        bitor(System.Reflection.BindingFlags.NonPublic, System.Reflection.BindingFlags.Instance));
    actual = field.GetValue(transport);
    verifyEqual(testCase, logical(actual.AutoSelectDevice), config.BleAutoSelect);
    verifyEqual(testCase, char(actual.DeviceName), config.BleDeviceName);
    verifyEqual(testCase, char(actual.DeviceId), config.BleDeviceId);
    clear cleanup;
end
verifyError(testCase, @() wss_cli.createConfig(wss_cli.parseOptions({'--transport=ble'})), ...
    'wss:BleSelectorRequired');
end

function testSerialSmokeAndNamedTransportUseProductionEntry(testCase)
wrapperRoot = getenv('WSS_MATLAB_WRAPPER_ROOT');
if isempty(wrapperRoot)
    wrapperRoot = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external', 'wss-matlab-wrapper'); %#ok<NASGU> Used by evalc.
end
text = evalc("code = wss_cli.main({'--wrapper-root', wrapperRoot, '--serial-smoke'});");
verifyEqual(testCase, code, 0);
verifySubstring(testCase, text, 'Serial transport constructed and disposed');
text = evalc("code = wss_cli.main({'--wrapper-root', wrapperRoot, '--transport=conformance', '--command=status', '--command=quit'});");
verifyEqual(testCase, code, 0);
verifySubstring(testCase, text, 'Transport: conformance');
verifySubstring(testCase, text, 'The prompt is active: use status');
text = evalc("code = wss_cli.main({'--wrapper-root', wrapperRoot, '--transport=conformance'});");
verifyEqual(testCase, code, 0);
verifySubstring(testCase, text, 'Conformance: 10/10 passed');
end

function testConformanceRejectsMissingSelectedPayload(testCase)
wrapperRoot = getenv('WSS_MATLAB_WRAPPER_ROOT');
if isempty(wrapperRoot)
    wrapperRoot = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external', 'wss-matlab-wrapper');
end
verifyError(testCase, @() wss_cli.main({'--wrapper-root', wrapperRoot, ...
    '--conformance', '--cs-libs', tempname}), 'wss:MissingCore');
end
