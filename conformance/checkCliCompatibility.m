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
if ismac && strcmp(result.Ble, 'unsupported-by-Core')
    if isfile(fullfile(options.CsLibDir, 'backends', 'macos', 'WSS.Transport.BLE.MacOS.dll'))
        error('wss_cli:StaleCompatibilityHelper', ...
            'The selected wrapper helper cannot validate its macOS BLE payload.');
    end
    result.Ble = 'unsupported-by-legacy-payload';
    fprintf('CLI compatibility: the pinned legacy payload lacks macOS BLE; Core now provides it.\n');
end
% Exercise actual CLI option/config/transport routing on each platform job.
result.CliBleSelection = result.Ble;
if strcmp(result.Ble, 'passed')
    selections = {{'--ble-auto'}, {'--ble-device-name=ci-load-only'}, {'--ble-device-id=ci-load-only'}};
    for k = 1:numel(selections)
        parsed = wss_cli.parseOptions([{'--wrapper-root', wrapperRoot, '--transport=ble'}, selections{k}], root);
        config = wss_cli.createConfig(parsed);
        transport = wss.createTransport(config);
        transportCleanup = onCleanup(@() transport.Dispose());
        assert(strcmp(char(transport.GetType().FullName), 'Wss.Transports.BleNusTransport'), ...
            'CLI BLE selection did not reach Core BLE transport.');
        assert(~transport.IsConnected, 'Compatibility routing must not connect hardware.');
        field = transport.GetType().GetField('_options', ...
            bitor(System.Reflection.BindingFlags.NonPublic, System.Reflection.BindingFlags.Instance));
        actual = field.GetValue(transport);
        assert(logical(actual.AutoSelectDevice) == config.BleAutoSelect && ...
            strcmp(char(actual.DeviceName), config.BleDeviceName) && ...
            strcmp(char(actual.DeviceId), config.BleDeviceId), 'CLI BLE selectors changed before reaching Core.');
        clear transportCleanup;
    end
end
end
