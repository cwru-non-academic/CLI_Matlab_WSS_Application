function keepRunning = executeCommand(controller, line)
%EXECUTECOMMAND Route application console commands through the public wrapper.
keepRunning = true;
parts = regexp(strtrim(char(line)), '\s+', 'split');
if isempty(parts) || isempty(parts{1}), return; end
command = lower(parts{1});
switch command
    case {'quit', 'exit'}
        requireCount(parts, 1, 1); keepRunning = false;
    case 'help'
        fprintf([ ...
            'Commands (type at the > prompt; brackets denote optional arguments):\n' ...
            '  help                 Show this command reference.\n' ...
            '  status               Query Ready/Started/ModeValid/BasicSupported.\n' ...
            '  start                Request broadcast start for configured devices.\n' ...
            '  stop                 Request broadcast stop (not channel-specific).\n' ...
            '  stim <finger|chN> <magnitude>  Apply active model and channel parameters.\n' ...
            '    Intended input: finite 0.0..1.0, not mA. Example: stim ch1 1.0\n' ...
            '  analog <finger|chN> <pw> [amp] [ipi]  Direct values; bypass model/params.\n' ...
            '    Integers: pw in us, amp in mA domain (default 3), ipi in ms (default 10).\n' ...
            '    Example: analog ch1 50 1 10. Omitted amp/ipi: analog ch1 50\n' ...
            '  reload-core          Reload active Core JSON through host reset; retain model/params.\n' ...
            '  reload-params [path]  Reload all default JSONs, a directory profile, or one params file.\n' ...
            '  save-params          Write active params JSON to its current host file.\n' ...
            '  quit|exit            Leave the console and clean up the controller.\n' ...
            'Aliases: thumb=ch1, index=ch2, middle=ch3, ring=ch4, pinky/little=ch5.\n' ...
            'Use channels available in your configuration. Setup is asynchronous.\n' ...
            'Examples are for simulation with --test and a disposable config copy.\n' ...
            'Values depend on firmware/calibration; requests do not prove physical output.\n' ...
            'See README Interactive commands for input limits, paths and examples.\n' ...
            'status also reports ticks and captured errors when present.\n' ...
            'Analog values must be signed 32-bit integers; magnitudes finite real numbers.\n' ...
            'reload-params accepts paths with spaces and optional double quotes.\n']);
    case 'start'
        requireCount(parts, 1, 1); controller.StartStimulation();
    case 'stop'
        requireCount(parts, 1, 1); controller.StopStimulation();
    case 'status'
        requireCount(parts, 1, 1);
        tickError = controller.LastTickError;
        if isempty(tickError)
            try
                ready = controller.Ready();
                started = controller.Started();
                modeValid = controller.isModeValid();
            catch failure
                % A background tick can fail between the initial read and query.
                tickError = controller.LastTickError;
                if isempty(tickError), rethrow(failure); end
            end
        end
        if isempty(tickError)
            fprintf('Ready=%d Started=%d ModeValid=%d BasicSupported=%d Ticks=%d\n', ...
                ready, started, modeValid, controller.BasicSupported, controller.TickCount);
        else
            fprintf('Ready=unknown Started=unknown ModeValid=unknown BasicSupported=%d Ticks=%d\n', ...
                controller.BasicSupported, controller.TickCount);
            fprintf('Tick error: %s\n', tickError);
        end
        if ~isempty(controller.LastCoreError)
            fprintf('Latest Core error (process-wide): %s\n', controller.LastCoreError);
        end
    case 'stim'
        requireCount(parts, 3, 3); controller.StimWithMode(parts{2}, number(parts{3}));
    case 'analog'
        requireCount(parts, 3, 5);
        amp = 3; ipi = 10;
        if numel(parts) >= 4, amp = number(parts{4}); end
        if numel(parts) >= 5, ipi = number(parts{5}); end
        controller.StimulateAnalog(parts{2}, number(parts{3}), amp, ipi);
    case 'reload-core'
        requireCount(parts, 1, 1); controller.LoadCoreConfigFile();
    case 'reload-params'
        % Keep the entire path suffix to support spaces, with optional quotes.
        path = strtrim(char(line)); path = strtrim(path(numel(parts{1}) + 1:end));
        if numel(path) >= 2 && path(1) == '"' && path(end) == '"', path = path(2:end-1); end
        if isempty(path), controller.LoadParamsJson(); else, controller.LoadParamsJson(path); end
    case 'save-params'
        requireCount(parts, 1, 1); controller.SaveParamsJson();
    otherwise
        error('wss_cli:UnknownCommand', 'Unknown command: %s. Type help.', command);
end
end

function requireCount(parts, minimum, maximum)
if numel(parts) < minimum || numel(parts) > maximum
    error('wss_cli:CommandArguments', 'Incorrect argument count for %s. Type help.', parts{1});
end
end

function value = number(text)
value = str2double(text);
if ~isfinite(value) || ~isreal(value)
    error('wss_cli:NumericArgument', 'Expected a finite real number: %s.', text);
end
end
