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
end
