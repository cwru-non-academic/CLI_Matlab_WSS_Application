function tests = TestCliOptions
tests = functiontests(localfunctions);
end

function testResolvesAppOwnedPaths(testCase)
root = fullfile(tempdir, 'wss cli example');
options = wss_cli.parseOptions({'--test', '--tick', '3', '--command', 'status'}, root);
verifyEqual(testCase, options.ConfigPath, fullfile(root, 'Config'));
verifyEqual(testCase, options.CsLibDir, fullfile(root, 'external', 'wss-matlab-wrapper', 'Cs_Libraries'));
verifyEqual(testCase, options.Commands, {'status'});
verifyEqual(testCase, options.TickIntervalMs, 3);
verifyTrue(testCase, options.TestMode);
end

function testRejectsBadArgumentsBeforeControllerCreation(testCase)
verifyError(testCase, @() wss_cli.parseOptions({'--tick', '0'}), 'wss_cli:PositiveInteger');
verifyError(testCase, @() wss_cli.parseOptions({'--config'}), 'wss_cli:MissingValue');
verifyError(testCase, @() wss_cli.parseOptions({'--unknown'}), 'wss_cli:UnknownOption');
verifyError(testCase, @() wss_cli.parseOptions({'--test', '--conformance'}), 'wss_cli:ConflictingTransport');
end

function testHelpDoesNotRequireInitializedSubmodule(testCase)
text = evalc("code = wss_cli.main({'--help'});");
verifyEqual(testCase, code, 0);
verifySubstring(testCase, text, 'WSS MATLAB CLI');
verifySubstring(testCase, text, '--transport serial|ble|test|conformance');
verifySubstring(testCase, text, '--ble-device-id');
end

function testCSharpSyntaxAndBleSelectors(testCase)
options = wss_cli.parseOptions({'--transport=BLE', '--ble-auto', '--ble-device-name=WSS unit', ...
    '--ble-device-id=device-id', '--serial=COM7', '--max-retries=7', '--tick=12'});
verifyEqual(testCase, options.Transport, 'ble');
verifyTrue(testCase, options.BleAutoSelect);
verifyEqual(testCase, options.BleDeviceName, 'WSS unit');
verifyEqual(testCase, options.BleDeviceId, 'device-id');
verifyEqual(testCase, options.SerialPort, 'COM7');
verifyEqual(testCase, options.MaxSetupTries, 7);
verifyEqual(testCase, options.TickIntervalMs, 12);
options = wss_cli.parseOptions({'--transport', 'conformance'});
verifyTrue(testCase, options.ConformanceMode);
verifyError(testCase, @() wss_cli.parseOptions({'--transport=ble', '--test'}), 'wss_cli:ConflictingTransport');
verifyError(testCase, @() wss_cli.parseOptions({'--transport=wifi'}), 'wss_cli:UnsupportedTransport');
verifyError(testCase, @() wss_cli.parseOptions({'--ble-auto=false'}), 'wss_cli:UnexpectedValue');
end

function testStatusReportsTickFailureWithoutGuardedStateCalls(testCase)
controller = struct('LastTickError', 'synthetic tick failure', ...
    'LastCoreError', 'synthetic Core error', 'BasicSupported', true, 'TickCount', 17, ...
    'Ready', @unsafeStateQuery, 'Started', @unsafeStateQuery, 'isModeValid', @unsafeStateQuery); %#ok<NASGU> Used by evalc.
text = evalc("keepRunning = wss_cli.executeCommand(controller, 'status');");
verifyTrue(testCase, keepRunning);
verifySubstring(testCase, text, 'Ready=unknown Started=unknown');
verifySubstring(testCase, text, 'Tick error: synthetic tick failure');
verifySubstring(testCase, text, 'Latest Core error (process-wide): synthetic Core error');
end

function unsafeStateQuery
error('test:UnexpectedStateQuery', 'Status queried guarded state after a known tick failure.');
end
