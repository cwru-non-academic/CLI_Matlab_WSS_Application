# WSS MATLAB CLI Application

Application-owned MATLAB console UI. The reusable MATLAB wrapper is a separate
repository, consumed as a pinned submodule at `external/wss-matlab-wrapper`.
This mirrors the Python application/wrapper split and leaves the wrapper usable
by other CLIs and GUIs.

## Layout

- `src/+wss_cli/`: parser, production `createController` factory and command routing.
- `Config/`: application-owned runtime JSON examples.
- `logs/`: ignored runtime host logs.
- `external/wss-matlab-wrapper/`: library submodule; owns managed helper and Core DLLs.
- `tests/`: MATLAB tests for application argument/path behavior.
- `conformance/`: consumer entry point into the wrapper's shared Core scenarios.

Reference: Python CLI revision `3a0c18cb388c1bdca155ea7ba0a10e0cb45c583f`.

## Published wrapper baseline

The submodule pins published wrapper revision
`fdc7584e77d62b4d3a56ff608e7a1ced1afd2dcf`, including the reusable implementation,
Core payload, managed host and exact MIT license. The default CLI uses this
committed submodule; no sibling checkout or local override is required.

The explicit `--wrapper-root` override remains available for deliberate local
development against a separate wrapper checkout. It never changes the gitlink.

## Setup and run

Clone the application and its pinned wrapper:

```powershell
git clone --recursive https://github.com/cwru-non-academic/CLI_Matlab_WSS_Application.git
cd CLI_Matlab_WSS_Application
dotnet build external/wss-matlab-wrapper/managed/Wss.Matlab.Managed.csproj -c Release
```

For optional local development against a sibling wrapper:

```powershell
dotnet build ../Matlab_WSS_Integration_Lib/managed/Wss.Matlab.Managed.csproj -c Release
```

In a fresh MATLAB session, select a supported CLR before loading .NET. Example
for a release supporting .NET 8 selection:

```matlab
dotnetenv("core", Version="8");
addpath('src');
wss_cli.main({'--conformance'});
```

Interactive use works in a MATLAB console/desktop session. For a finite terminal
invocation after installation (from this repository):

```powershell
matlab -batch "dotnetenv('core',Version='8'); addpath('src'); wss_cli.main({'--test','--command','status','--command','quit'});"
```

The app restores its temporary MATLAB path additions on return and never calls
`savepath`. Assembly/CLR loading lasts for the MATLAB process. Default config and
log paths are anchored to the application, DLL paths to the selected wrapper.
User path overrides are anchored when parsed. Default transport is serial, as in
Python; use `--test` or `--conformance` for development without hardware.

Options: `--serial`, `--config`, `--cs-libs`, `--log-file`, `--max-retries`, `--tick`,
`--test`, `--conformance`, `--command`, `--wrapper-root`, `--help`.
Commands: `help`, `start`, `stop`, `status`, `stim`, `analog`, `reload-core`,
`reload-params`, `save-params`, `quit`/`exit`. Quoted reload paths may contain spaces.
Initialization is asynchronous: creation of the managed stack does not mean it
has reached Ready. Batch command errors propagate to MATLAB's nonzero failure
exit; interactive command errors are shown without abandoning cleanup.

## Checks

```matlab
addpath('src');
setenv('WSS_MATLAB_WRAPPER_ROOT', fullfile(pwd, '..', 'Matlab_WSS_Integration_Lib'));
assertSuccess(runtests('tests'));
addpath('conformance');
results = runCliConformance(fullfile(pwd, '..', 'Matlab_WSS_Integration_Lib'));
```

The consumer conformance entry uses `wss_cli.createController`, not a substitute
managed/Python implementation. On MATLAB R2026b with .NET 8, all 10 consumer
catalog scenarios passed, and the MATLAB unit/runtime suite passed including
CLI quit and command-failure disposal. The Engine harness also passed blocking
input-double quit/interruption/quit, with real MATLAB cancellation and repeated
cleanup. Native console input/keyboard Ctrl+C remain manual checks. Windows
serial/BLE load-only compatibility passed separately; Ubuntu/macOS remain
unverified. No port was opened or physical device connected. The managed helper
has separate .NET-only checks in the wrapper.

Run the Windows Engine lifecycle harness with an existing supported Python:

```powershell
python tests/engine/check_interactive_lifecycle.py --matlab-root 'C:/Program Files/MATLAB/R2026b' --wrapper-root '../Matlab_WSS_Integration_Lib'
```

It uses the MATLAB-bundled Engine API directly and installs nothing. Its temporary
input shadow is confined to the isolated test process.

Future propagation is described in the wrapper's `docs/PROPAGATION.md` and this
repo's `automation/pipeline-contract.json`. Ordinary PR CI is documented in
`ci/README.md`; automated Core propagation and dispatch remain inactive.
