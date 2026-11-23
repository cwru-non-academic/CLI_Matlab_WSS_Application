# WSS MATLAB CLI Application

Application-owned MATLAB console UI. The reusable MATLAB wrapper is a separate
repository, consumed as a pinned submodule at `external/wss-matlab-wrapper`.
This mirrors the Python application/wrapper split and leaves the wrapper usable
by other CLIs and GUIs.

## First stimulation

The Windows example uses MATLAB R2026b with .NET 8 CoreCLR. Install Git and the .NET 8 SDK to build the managed host. Use MATLAB and .NET of the same host architecture. See [Checks](#checks) for the other platform and release combinations exercised by CI.

From PowerShell:

```powershell
git clone --recurse-submodules https://github.com/cwru-non-academic/CLI_Matlab_WSS_Application.git
cd CLI_Matlab_WSS_Application
dotnet build external/wss-matlab-wrapper/managed/Wss.Matlab.Managed.csproj -c Release
```

If you already cloned without the wrapper, run `git submodule update --init --recursive` from the repo root and build again.

### Set the runtime and prepare the profile

In a fresh MATLAB process, set **Current Folder** to `CLI_Matlab_WSS_Application`. In the **Command Window**, select the CLR before your first .NET call, then run the simulated check:

```matlab
dotnetenv("core", Version="8");
addpath(fullfile(pwd, "src"));
wss_cli.main({'--conformance'});
```

The result reports passed cases and control returns to MATLAB. Restart MATLAB before changing the CLR or swapping the loaded WSS DLLs.

Follow the [hardware overview](https://cwru-non-academic.github.io/WSS_Documentation/hardwareDocs/wsshardware.html) for the physical setup and the [bench verification handoff](https://github.com/cwru-non-academic/WSS_Documentation/blob/main/apiDocs/conceptual/start-here-using-an-application.md#bench-verification) for the approved profile and measurement procedure. Use a bench setup with no person connected.

Copy the three `Config/*.json` files to a writable directory named `Config-bench` in the repo root and apply the bench profile to that copy. In `stimConfig.json`, check that `maxWSS` is 1 and that `firmware` and the first `wssTargets` entry match the device. The example uses H03 and `0x81`. It has example calibration on `ch1` and zeroed calibration on `ch2`/`ch3`. Use the approved `stimParams.json` for `ch1` and retain the associated `modelConfig.json`.

To make the working copy from the MATLAB Command Window:

```matlab
configDir = fullfile(pwd, 'Config-bench');
if ~isfolder(configDir), mkdir(configDir); end
copyfile(fullfile(pwd, 'Config', '*.json'), configDir);
```

Apply the approved settings in `Config-bench` before running a live command.

### Connect from the MATLAB Command Window

For serial, locate the device in **Device Manager → Ports (COM & LPT)**. For BLE, enable Bluetooth and use the exact advertised name of the NUS device. Run one of the following launch commands:

```matlab
configDir = fullfile(pwd, 'Config-bench');
port = input('WSS serial port: ', 's');
wss_cli.main({'--transport', 'serial', '--serial', port, '--config', configDir});
```

```matlab
configDir = fullfile(pwd, 'Config-bench');
name = input('WSS BLE name: ', 's');
wss_cli.main({'--transport', 'ble', '--ble-device-name', name, '--config', configDir});
```

### Send a command, verify output, and stop

1. At the application's `>` prompt, run `status`. Setup is asynchronous. When `Started` is true, continue to the next step. If `Ready` is true and `Started` is false, run `start` and check `status` again until `Started` is true.
2. Enter `stim ch1 <magnitude>`, replacing `<magnitude>` with the normalized input from your bench profile. Confirm output on the mapped channel using the bench procedure.
3. Enter `stop` and verify output has ceased. Enter `quit` to exit.

If the app never starts, check the selected device, port access, firmware and receiver address. If it starts but the bench measurement shows no output, check that the loaded calibration and model apply to the channel you are testing.

MATLAB displays true as `1` in `status`. The startup output shows the resolved `Host log`, which includes setup and tick errors. To rehearse without a device, copy the application JSONs to a disposable directory and call `wss_cli.main({'--test', '--config', practiceDir})` with `practiceDir` set to that directory. Use the same prompt commands.

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

## Additional launch options and commands

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

| Command | Use |
| --- | --- |
| `status` | Show Ready, Started, model support, ticks and the latest error. |
| `start`, `stop` | Request a broadcast start or stop. |
| `stim <channel> <magnitude>` | Send a finite normalized input from 0 to 1 through the active model and channel calibration. For one device use `ch1`, `ch2`, or `ch3`. The aliases `thumb`, `index`, and `middle` select the same channels. |
| `analog <channel> <pw> [amp] [ipi]` | Send a direct request. Pulse width is in µs, amplitude is in the mA domain, and interval is in ms. Omitted amplitude and interval default to 3 and 10. Use the direct values supplied by your bench procedure. |
| `reload-core`, `reload-params [path]`, `save-params` | Reload or persist the host profile. See [Coordinated configuration reload](#coordinated-configuration-reload) for paths. |
| `help`, `quit`, `exit` | Show help or close the CLI and return to MATLAB. |

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
setenv('WSS_MATLAB_WRAPPER_ROOT', fullfile(pwd, 'external', 'wss-matlab-wrapper'));
assertSuccess(runtests('tests'));
addpath('conformance');
results = runCliConformance(fullfile(pwd, 'external', 'wss-matlab-wrapper'));
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
