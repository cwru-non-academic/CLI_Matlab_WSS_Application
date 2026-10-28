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
        fprintf(['help | start | stop | status | stim <finger|chN> <value>\n' ...
            'analog <finger|chN> <pw> [amp] [ipi]\n' ...
            'reload-core | reload-params [path] | save-params | quit\n']);
    case 'start'
        requireCount(parts, 1, 1); controller.StartStimulation();
    case 'stop'
        requireCount(parts, 1, 1); controller.StopStimulation();
    case 'status'
        requireCount(parts, 1, 1);
        fprintf('Ready=%d Started=%d ModeValid=%d BasicSupported=%d Ticks=%d\n', ...
            controller.Ready(), controller.Started(), controller.isModeValid(), ...
            controller.BasicSupported, controller.TickCount);
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
