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

The committed `external/wss-matlab-wrapper` Git submodule entry is the
runtime wrapper revision for this checkout. It includes the reusable
implementation, Core payload, managed host and MIT license. The default CLI
uses this committed submodule; no sibling checkout or local override is required.
Inspect the actual pin with `git ls-tree HEAD external/wss-matlab-wrapper`.

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

Options: `--transport serial|ble|test|conformance`, `--ble-auto`,
`--ble-device-name NAME`, `--ble-device-id ID`, `--serial-smoke`, `--serial`, `--config`, `--cs-libs`, `--log-file`, `--max-retries`, `--tick`,
`--test`, `--conformance`, `--command`, `--wrapper-root`, `--help`.
Value options accept either `--name value` or C#-style `--name=value`.
BLE selection requires automatic selection, an exact device name, or a device ID;
Core owns discovery, ID precedence, connection and protocol behavior. For example:

```matlab
wss_cli.main({'--transport=ble', '--ble-auto'});
wss_cli.main({'--transport=ble', '--ble-device-name=WSS'});
wss_cli.main({'--transport=ble', '--ble-device-id=DEVICE_ID'});
```

These live commands may scan/connect hardware. `--serial-smoke` only constructs
and disposes the serial transport. Do not combine conflicting transport aliases.
The pinned wrapper includes BLE transport selection and platform loading.
No local override is needed for this feature. This checkout's pinned payload
includes `backends/macos/WSS.Transport.BLE.MacOS.dll` and
`backends/macos/libwss_macos_ble.dylib`. BLE still requires the matching packaged
backend, a supported native runtime and OS Bluetooth access. The native
compatibility and ABI checks below do not establish physical BLE operation.

Commands: `help`, `start`, `stop`, `status`, `stim`, `analog`, `reload-core`,
`reload-params`, `save-params`, `quit`/`exit`. Quoted reload paths may contain spaces.
`--conformance` (or `--transport=conformance`) without `--command` runs the
shared deterministic catalog and exits, like the C# conformance entry. Supplying
commands uses the emulator for those commands.
Initialization is asynchronous: creation of the managed stack does not mean it
has reached Ready. The command prompt is active while setup continues: use
`status` to inspect readiness, tick count and captured Core errors, or `quit`
to exit. The printed host log contains Core diagnostics as well as host lifecycle
records. Core messages are labeled process-wide because other controllers in
the same MATLAB process can also emit them.
Batch command errors propagate to MATLAB's nonzero failure
exit; interactive command errors are shown without abandoning cleanup.

## Device addresses

`Config/stimConfig.json` explicitly exposes `broadcastTarget` (`0x8F`) and
`wssTargets` (`0x81`, `0x82`, `0x83`). These preserve Core's historical defaults;
configure receiver addresses to match your devices. For a first device at `0x80`,
change the first `wssTargets` entry to `0x80` (also used in the C# CLI example).
Firmware, stimulation parameters and calibration are separate settings.

The application always supplies its own Config directory. These fields configure
receiver addressing, not the low-level host sender byte. Core does not expose a
`sender` JSON setting. After editing addresses, use `reload-core` to reconstruct
the client with the new map, or quit and restart the CLI. See the coordinated
reload contract below for this checkout's pinned wrapper.

## Checks

```matlab
addpath('src');
setenv('WSS_MATLAB_WRAPPER_ROOT', fullfile(pwd, '..', 'Matlab_WSS_Integration_Lib'));
assertSuccess(runtests('tests'));
addpath('conformance');
results = runCliConformance(fullfile(pwd, '..', 'Matlab_WSS_Integration_Lib'));
```

[Normal CLI CI](.github/workflows/cli-ci.yml) runs the production
`wss_cli.createController` path, MATLAB Code Analyzer, the required native test
contract and the single-/multi-device conformance profiles through
[`runCliCi`](ci/runCliCi.m). The reusable
[native MATLAB action](.github/actions/native-matlab/action.yml) builds the managed
host before running the CLI's native MATLAB entry point. Standalone managed-host
lifecycle/ticking checks run separately in wrapper behavioral CI, only when the
action uses `role=wrapper` and `purpose=behavioral`.

Compatibility jobs cover Windows, Ubuntu and native macOS ARM64/R2026b and
Intel/R2025b. The macOS aggregate requires both native lanes and their evidence;
a single architecture is insufficient. General conformance uses R2026b. These
checks exercise emulator behavior, loading and transport selection, not physical
stimulation. Native console input/keyboard Ctrl+C remain manual checks. The
Windows Engine lifecycle harness is a separate local check, not a claim that
normal CI exercises a human-operated console.

Run the Windows Engine lifecycle harness with an existing supported Python:

```powershell
python tests/engine/check_interactive_lifecycle.py --matlab-root 'C:/Program Files/MATLAB/R2026b' --wrapper-root '../Matlab_WSS_Integration_Lib'
```

It uses the MATLAB-bundled Engine API directly and installs nothing. Its temporary
input shadow is confined to the isolated test process.

## Verified dependency propagation

The normal `CLI general conformance` check and separate Windows/Ubuntu/macOS
compatibility jobs reuse the native MATLAB action. Candidate preflights require
the same production paths and canonical cases, plus strict 27-file projection
and source-bound provenance. A legacy macOS unsupported result cannot satisfy
candidate Mac acceptance.

The read-only receipt workflow verifies the actual human dependency merge,
committed-state normal CI, frozen plan/tooling identities, original paired
preflights, fresh validation against the merged wrapper and exact parent gitlink.
It does not create, approve or merge PRs. Its tools checkout must pin an immutable
reviewed wrapper tooling revision, published before this CLI workflow is deployed.

The [pipeline contract](automation/pipeline-contract.json) enables DEV
participation and requires gitlink-only dependency PRs, human merge and
`auto_merge=false`. Readiness permits execution; it does not itself accept a
candidate, dispatch a workflow or authorize publication. Acceptance requires the
frozen Core plan, actual wrapper/application dependency merges, normal CI and
matching receipts. MATLAB wrapper and CLI participate in the DEV nine-target
acceptance contract; the old MATLAB exclusion is not the current DEV contract.
Historical DEV acceptance does not accept this MAIN source or establish a release.

On same-repository PRs, the native macOS lanes also run a separately pinned
preparation-payload BLE ABI diagnostic in a disposable copy on both architectures.
It preserves the production gitlink/payload and produces diagnostic evidence,
not acceptance receipts. It does not replace committed-state compatibility,
candidate preflights or physical BLE validation.

## Coordinated configuration reload

These commands use the coordinated reload support in the wrapper pinned by this
checkout. Older checkouts must be checked against their own wrapper source and
Core payload; updating Core alone does not add the host reset behavior.

Enter `reload-core`, `reload-params [path]`, or `save-params` at the interactive
prompt. Do not type the brackets. The commands call `LoadCoreConfigFile()`,
`LoadParamsJson()` / `LoadParamsJson(path)`, and `SaveParamsJson()` respectively.

- `reload-params` rereads all three startup-default files: `stimConfig.json`,
  `stimParams.json`, and `modelConfig.json`. It returns to those defaults even
  after selecting another profile.
- `reload-params ./Config/profile` selects all three standard filenames in that
  directory.
- `reload-params ./Config/customParams.json` selects that calibration file with
  the startup-default Core and model files, **not sibling files** next to the
  selected calibration file. All three JSON files are still read and validated.
- `reload-core` reads the active Core file, retains currently applied in-memory
  calibration/model values and paths (including unsaved edits), and reconstructs
  Core through the host reset path, including its receiver address map. It
  reconstructs even if Core values are unchanged. Before initialization this
  Core reset is a no-op.
- `save-params` writes active stimulation parameters to the selected calibration
  file. It does not save device configuration or persist the Core/model files.

The startup defaults come from the application's resolved configuration directory
(`Config/` in the app repository unless overridden at startup). Startup paths
remain anchored even if the process working directory changes. Relative explicit
reload paths are resolved against the process working directory.

Reload stages and validates files before changing the active stack. Any effective
Core configuration change uses the existing reset path: stop ticking, dispose the
old stack (Core zeros output and disconnects), construct the validated replacement,
and resume initialization/ticking. Unchanged Core permits calibration/model
updates without reconnecting. A reset does not replay previous stimulation values.
`reload-core` retains applied calibration/model values; `reload-params` rereads them.
Use `status` to check asynchronous setup and wait for `Started` before sending new
stimulation commands after reconstruction. A printed reload message does not
establish device readiness or physical output.

Invalid JSON leaves the active stack unchanged. Cleanup or construction failure
can leave the controller unavailable; inspect the reported error rather than
assuming the replacement is ready. Use a disposable configuration copy with the
simulated transport when practicing reloads or `save-params`.

The MATLAB command parser preserves the entire reload path suffix and accepts
optional double quotes, so file or directory paths may contain spaces. For example:
`reload-params "C:/WSS Practice/Config/stimParams.json"`.
