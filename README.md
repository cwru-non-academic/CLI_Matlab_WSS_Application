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
`671ef5c27d35f0f82b15999b1779ed57d968fa2d`, including the reusable implementation,
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
No local override is needed for this feature. The Core binary payload is unchanged.
Windows/Linux BLE require the matching packaged backend and OS Bluetooth access;
macOS BLE requires the newer Core payload containing the MacOS backend/native
bridge. The currently pinned legacy payload lacks those macOS files and reports
an explicit missing-backend error. No physical BLE validation is claimed.

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
`sender` JSON setting. Quit/restart the CLI after editing addresses so Core creates
a client with the new map; `reload-core` alone does not rebuild the client.

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

## Propagation preparation

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

Approved MATLAB dev participation sets both readiness flags true and enables
`automation/pipeline-contract.json`, with effective
`WSS_MATLAB_PROPAGATION_ENABLED=true` in both MATLAB repositories. Deploy reviewed
configuration on main and dev and verify workflow registration, rulesets and
existing App access before the separately authorized Core rollout. Readiness
permits execution; it does not accept a candidate or dispatch a workflow. Keep
`auto_merge=false`, human dependency merges and all real candidate preflights.
The existing receipt verifier pin and its MATLAB exclusion remain unchanged;
release acceptance requires separate Core policy/verifier alignment.

The additional `Mac packaged BLE diagnostic (arm64)` PR job stages the verified
27-file preparation artifact from Core run `40815407554` in a disposable copy of
the committed wrapper. It requires actual Mac managed/native ABI loading and
checks that CLI auto/name/id selectors reach Core without connecting hardware.
It uses a separately pinned diagnostic tooling checkout, preserves the production
gitlink and payload, and emits diagnostic evidence rather than acceptance
receipts. Intel and physical BLE are separate validation requirements.
