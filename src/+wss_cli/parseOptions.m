function options = parseOptions(argv, repoRoot)
%PARSEOPTIONS Parse application arguments without loading the wrapper or .NET.
if nargin < 1, argv = {}; end
if nargin < 2, repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath')))); end
if isstring(argv), argv = cellstr(argv); end
if ~iscell(argv), error('wss_cli:Arguments', 'Pass a cell array or string array of arguments.'); end
options = struct('Help', false, 'ConfigPath', fullfile(repoRoot, 'Config'), ...
    'WrapperRoot', fullfile(repoRoot, 'external', 'wss-matlab-wrapper'), ...
    'CsLibDir', fullfile(repoRoot, 'external', 'wss-matlab-wrapper', 'Cs_Libraries'), ...
    'LogPath', fullfile(repoRoot, 'logs', ['wss_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss')) '.log']), ...
    'SerialPort', '', 'Transport', '', 'BleAutoSelect', false, ...
    'BleDeviceName', '', 'BleDeviceId', '', 'SerialSmoke', false, 'MaxSetupTries', 5, 'TickIntervalMs', 10, ...
    'TestMode', false, 'ConformanceMode', false, 'Commands', {{}});
k = 1;
explicitLibraries = false;
while k <= numel(argv)
    flag = char(argv{k});
    separator = strfind(flag, '=');
    inline = ~isempty(separator);
    value = '';
    if inline
        value = flag(separator(1) + 1:end);
        flag = flag(1:separator(1) - 1);
    end
    flag = lower(flag);
    if inline && ismember(flag, {'--help', '-h', '/?', '--test', '--conformance', '--ble-auto', '--serial-smoke'})
        error('wss_cli:UnexpectedValue', '%s does not accept a value.', flag);
    end
    switch flag
        case {'--help', '-h', '/?'}
            options.Help = true;
        case '--ble-auto'
            options.BleAutoSelect = true;
        case '--serial-smoke'
            options.SerialSmoke = true;
        case '--test'
            options.TestMode = true;
        case '--conformance'
            options.ConformanceMode = true;
        case {'--transport', '--ble-device-name', '--ble-device-id', '--serial', '--config', '--cs-libs', '--log-file', '--max-retries', '--tick', '--command', '--wrapper-root'}
            if ~inline
                if k == numel(argv), error('wss_cli:MissingValue', 'Missing value after %s.', flag); end
                k = k + 1; value = char(argv{k});
            end
            switch flag
                case '--transport'
                    if isempty(value), error('wss_cli:UnsupportedTransport', 'Transport must not be empty.'); end
                    options.Transport = lower(value);
                case '--ble-device-name', options.BleDeviceName = value;
                case '--ble-device-id', options.BleDeviceId = value;
                case '--serial', options.SerialPort = value;
                case '--config', options.ConfigPath = absolutePath(value);
                case '--cs-libs', options.CsLibDir = absolutePath(value); explicitLibraries = true;
                case '--wrapper-root', options.WrapperRoot = absolutePath(value);
                case '--log-file', options.LogPath = absolutePath(value);
                case '--command', options.Commands{end + 1} = value;
                otherwise
                    number = str2double(value);
                    if ~isfinite(number) || number < 1 || number ~= fix(number) || number > double(intmax('int32'))
                        error('wss_cli:PositiveInteger', '%s requires a positive Int32 value.', flag);
                    end
                    if strcmp(flag, '--tick'), options.TickIntervalMs = number;
                    else, options.MaxSetupTries = number; end
            end
        otherwise
            error('wss_cli:UnknownOption', 'Unknown option: %s.', flag);
    end
    k = k + 1;
end
if options.TestMode && options.ConformanceMode
    error('wss_cli:ConflictingTransport', 'Select --test or --conformance, not both.');
end
if ~isempty(options.Transport) && ~ismember(options.Transport, {'serial', 'ble', 'test', 'conformance'})
    error('wss_cli:UnsupportedTransport', 'Expected serial, ble, test, or conformance.');
end
alias = '';
if options.TestMode, alias = 'test'; end
if options.ConformanceMode, alias = 'conformance'; end
if ~isempty(alias)
    if ~isempty(options.Transport) && ~strcmp(options.Transport, alias)
        error('wss_cli:ConflictingTransport', 'Transport conflicts with --test or --conformance.');
    end
    options.Transport = alias;
end
if isempty(options.Transport), options.Transport = 'serial'; end
options.TestMode = strcmp(options.Transport, 'test');
options.ConformanceMode = strcmp(options.Transport, 'conformance');
if ~explicitLibraries, options.CsLibDir = fullfile(options.WrapperRoot, 'Cs_Libraries'); end
end

function value = absolutePath(value)
if isempty(value), error('wss_cli:EmptyPath', 'Paths must not be empty.'); end
if isempty(regexp(value, '^([A-Za-z]:[\\/]|[\\/]{2}|/)', 'once'))
    value = fullfile(pwd, value);
end
end
