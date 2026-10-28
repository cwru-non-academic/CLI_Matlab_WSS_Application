function summary = runCliCi(purpose)
%RUNCLICI Execute the production app against its committed wrapper submodule.
root = fileparts(fileparts(mfilename('fullpath')));
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
dotnetenv('core', Version='8');
addpath(fullfile(root, 'src'), fullfile(root, 'conformance'));
switch char(purpose)
    case 'general'
        % Test the default production entry before adding wrapper source paths.
        wss_cli.main({'--conformance', '--command', 'status', '--command', 'quit'});
        files = [dir(fullfile(root, 'src', '**', '*.m')); dir(fullfile(root, 'tests', '**', '*.m')); ...
            dir(fullfile(root, 'conformance', '*.m')); dir(fullfile(root, 'ci', '*.m'))];
        for k = 1:numel(files)
            file = fullfile(files(k).folder, files(k).name);
            findings = checkcode(file, '-id');
            if ~isempty(findings), error('wss_cli_ci:Analyzer', 'Code Analyzer findings in %s: %s', file, jsonencode(findings)); end
        end
        previous = getenv('WSS_MATLAB_WRAPPER_ROOT');
        envCleanup = onCleanup(@() setenv('WSS_MATLAB_WRAPPER_ROOT', previous));
        setenv('WSS_MATLAB_WRAPPER_ROOT', '');
        tests = runtests(fullfile(root, 'tests'));
        assertSuccess(tests);
        scenarios = runCliConformance();
        summary = struct('purpose', purpose, 'matlab', version, 'testsPassed', sum([tests.Passed]), ...
            'scenariosPassed', sum([scenarios.Passed]));
    case 'compatibility'
        summary = checkCliCompatibility();
        summary.purpose = purpose;
        summary.matlab = version;
    otherwise
        error('wss_cli_ci:Purpose', 'Select general or compatibility.');
end
directory = fullfile(root, 'artifacts', 'ci');
if ~isfolder(directory), mkdir(directory); end
writeFile(fullfile(directory, [char(purpose) '.json']), jsonencode(summary));
writeFile(fullfile(directory, 'matlab-root.txt'), matlabroot);
disp(summary);
end

function writeFile(path, text)
file = fopen(path, 'w', 'n', 'UTF-8');
if file < 0, error('wss_cli_ci:Evidence', 'Cannot write CI evidence.'); end
cleanup = onCleanup(@() fclose(file));
fprintf(file, '%s', text);
end
