# WSS MATLAB CLI Application

Run WSS from a MATLAB console. This application supplies command parsing and
runtime configuration; its pinned
[MATLAB integration library](https://github.com/cwru-non-academic/Matlab_WSS_Integration_Lib#readme)
supplies the controller and Core payload.
See the [WSS documentation](https://cwru-non-academic.github.io/WSS_Documentation/)
for architecture, configuration and shared stimulation concepts.

## Set up

You need Git, a .NET SDK capable of building `netstandard2.0`, and MATLAB with a
compatible .NET runtime. MATLAB R2026b with .NET 8 is a working combination.
Select that runtime in a fresh MATLAB process before loading .NET assemblies;
consult MathWorks' [runtime documentation](https://www.mathworks.com/help/matlab/ref/dotnetenv.html)
for your installed release.

```powershell
git clone --recursive https://github.com/cwru-non-academic/CLI_Matlab_WSS_Application.git
cd CLI_Matlab_WSS_Application
dotnet build external/wss-matlab-wrapper/managed/Wss.Matlab.Managed.csproj -c Release
```

For an existing clone, run `git submodule update --init --recursive` before the
build. Keep the wrapper's `Cs_Libraries/` runtime and backend directories intact.

## Run without hardware

From the application root, in MATLAB:

```matlab
dotnetenv("core", Version="8");
addpath('src');
wss_cli.main({'--test'});
```

`--test` uses the simulated transport. At the prompt, type `status`, `help`, then
`quit` to close the controller and return to MATLAB. Setup is asynchronous, so
an immediate `status` can report `Ready=0`. Use `--conformance` instead of `--test`
to select the in-memory behavior-test emulator; the two flags are mutually exclusive.

For a finite terminal invocation with no hardware connection:

```powershell
matlab -batch "dotnetenv('core',Version='8'); addpath('src'); wss_cli.main({'--test','--command','status','--command','quit'});"
```

For help without initializing the controller:

```matlab
addpath('src');
wss_cli.main({'--help'});
```

## Configuration and device use

The application reads `Config/` and writes logs under `logs/`, independent of
MATLAB's current directory. Review your configuration using the
[shared configuration reference](https://cwru-non-academic.github.io/WSS_Documentation/apiDocs/conceptual/config-files-reference.html).
Omitting `--test` and `--conformance` selects serial; pass `--serial` with a
specific port when intentionally connecting a device:

```matlab
wss_cli.main({'--serial', 'COM3', '--config', fullfile(pwd, 'Config')});
```

Replace `COM3` with your platform's port name. Without `--serial`, serial mode
can automatically select a port.

Commands include `help`, `status`, `start`, `stop`, `stim`, `analog`,
`reload-core`, `reload-params`, `save-params`, and `quit`/`exit`; use `help` for
argument syntax. Options include `--config`, `--cs-libs`, `--log-file`,
`--max-retries`, `--tick`, and repeatable `--command` values. `--wrapper-root`
explicitly selects a local development wrapper without changing the submodule pin.

The application cleans up on normal exit and errors and restores its temporary
MATLAB path additions. Batch command failures propagate as errors to
`matlab -batch`. Runtime and assembly loading lasts for the MATLAB process.

## Development checks

After setup, select the runtime and run from the application root:

```matlab
addpath('src');
assertSuccess(runtests('tests'));
addpath('conformance');
results = runCliConformance();
```

These use the pinned wrapper and production controller factory. See
[ci/README.md](ci/README.md) for CI commands and the
[library README](https://github.com/cwru-non-academic/Matlab_WSS_Integration_Lib#readme)
for reusable integration and managed checks.
