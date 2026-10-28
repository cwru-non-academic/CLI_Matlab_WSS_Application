function line = input(varargin)
%INPUT Test-only blocking console double. Add this folder only in the harness.
% The application still calls input at its production boundary. The Python
% Engine harness releases or interrupts this wait without a physical device.
directory = getenv('WSS_MATLAB_INPUT_GATE');
if isempty(directory), error('wss_cli_test:MissingGate', 'Test gate directory is required.'); end
controller = evalin('caller', 'controller');
assignin('base', 'wss_test_controller', controller);
before = controller.TickCount;
write(fullfile(directory, 'waiting.json'), jsonencode(struct('ticks', before)));
release = fullfile(directory, 'release.txt');
while ~isfile(release), pause(0.01); end
after = controller.TickCount;
write(fullfile(directory, 'released.json'), jsonencode(struct('before', before, 'after', after)));
line = strtrim(fileread(release));
end

function write(file, text)
handle = fopen(file, 'w', 'n', 'UTF-8');
if handle < 0, error('wss_cli_test:Write', 'Cannot write test gate.'); end
cleanup = onCleanup(@() fclose(handle));
fprintf(handle, '%s', text);
end
