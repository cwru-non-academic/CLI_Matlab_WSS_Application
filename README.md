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

## Interactive commands

The coordinated reload behavior below requires a wrapper revision containing
`WssConfigurationSnapshot` host reload support. Keep the application's pinned
wrapper current through the normal verified promotion path. Older wrapper
revisions may retain only the selected parameter file and may not reconstruct
Core on reload.

Enter these commands at the application's `>` prompt after startup; they are
separate from startup options such as `--test`. Command names and finger/channel
aliases are case-insensitive. In the syntax below, `<...>` is required and
`[...]` is optional; do not type the brackets.

| Command | What it does and inputs | Example at the prompt |
| --- | --- | --- |
| `help` | Show interactive command syntax, units and defaults. | `help` |
| `status` | Query controller state and available API support. See the state explanation below. | `status` |
| `start` | Request a broadcast start for the configured devices; takes no channel or magnitude. | `start` |
| `stop` | Request a broadcast stop; takes no channel argument. | `stop` |
| `stim <finger\|chN> <magnitude>` | Update one logical channel using the active model and stimulation parameters. Intended magnitude input is a finite number from `0.0` to `1.0`. | `stim ch1 1.0` |
| `analog <finger\|chN> <pw> [amp] [ipi]` | Update one channel directly, bypassing model/parameter mapping. Pulse width is in microseconds, amplitude is in the mA domain (mapped to device scale), and inter-pulse interval is in milliseconds. Use integers; omitted `amp` is `3`, omitted `ipi` is `10`. | `analog ch1 50 1 10` |
| `reload-core` | Reload the active `stimConfig.json` through the host reset path, retaining current calibration/model values. Reconstructs Core, including receiver addressing. | `reload-core` |
| `reload-params [path]` | Reload all three startup-default JSON files. A directory selects all three standard filenames. An explicit file selects calibration only, with startup-default Core/model files. | `reload-params ./Config/stimParams.json` |
| `save-params` | Write active stimulation parameters to their current JSON file. This is host-side persistence, not a device configuration save. | `save-params` |
| `quit` or `exit` | Leave the console and clean up the controller. | `quit` |

### Channels, values and state

`chN` selects a 1-based logical channel. Finger aliases map to `thumb` = `ch1`,
`index` = `ch2`, `middle` = `ch3`, `ring` = `ch4`, and `pinky`/`little` = `ch5`.
Use a channel available in your configuration; recognizing a name does not make
that channel available. For example, a one-device configuration has three
logical channels, so `ring` and `pinky` are outside its range.

`stim ch1 1.0` supplies normalized input **1.0**, not 1 mA. The active P/PD model
and per-channel `stimParams.json` settings determine the resulting pulse width
and amplitude. `stim thumb 0.25` supplies 0.25 to the same channel. The intended
input interval is `0.0` through `1.0`; this is not a claim that the command parser
rejects every value outside that interval. Model mapping can change the output,
so even input `0` is not a substitute for the broadcast `stop` command.

`analog ch1 50` uses pulse width 50, amplitude 3 and IPI 10. To choose an IPI,
supply the amplitude too: `analog ch1 50 1 20`. These are syntax examples, not
recommended settings for a person or device. Direct analog values do not use
the normalized calibration mapping. The CLI does not impose a universal
calibrated operating range; use settings appropriate to your firmware, device
and calibration. A successfully parsed request does not establish valid physical
output. Stimulation commands update runtime values; `save-params` does not turn
an analog request into new calibration settings.

Setup continues asynchronously. `Ready` describes the Core state in which a
start can be accepted, while `Started` describes started/streaming state;
`Ready` need not remain true while streaming. `ModeValid` reports model-mode
support, and `BasicSupported` reports availability of the optional Basic API.
These flags and printed request messages do not prove physical stimulation.
MATLAB also prints tick count, a captured tick error when present, and the latest process-wide Core error when present.

### Parsing and paths

Magnitude must be a finite real number. Analog arguments must additionally
be integer-valued within the signed 32-bit range (`-2147483648` through
`2147483647`); this conversion range is not a device operating range. Invalid
numeric values and incorrect argument counts raise command errors. `stim`
requires exactly two arguments; `analog` accepts two through four. Commands
without arguments reject extra tokens, except that `help` does not check count.
Interactive errors are displayed; errors in `--command` batch execution propagate.

`reload-params` takes the entire remaining path, including spaces; optional double
quotes are stripped. For example:

```text
reload-params "C:/WSS Practice/Config/stimParams.json"
```

Channel aliases must be a recognized finger name or `chN` with positive integer
`N`; malformed aliases are rejected by the wrapper.

Relative explicit reload paths are relative to the process working directory.
The original startup defaults remain anchored even if the working directory
changes. `reload-params` without an argument always returns to all three startup
files (`stimConfig.json`, `stimParams.json`, `modelConfig.json`), not the last
selected profile. For an explicit calibration file, the other two files come
from startup defaults, not that file's siblings.

Reload stages and validates files before changing the active stack. A Core
configuration change uses the existing reset path, which stops/zeros output and
disconnects the old stack before initialization of the replacement. Unchanged
Core permits calibration/model updates without reconnecting. `reload-core`
retains applied calibration/model values; `reload-params` rereads them. Wait for
`Started` before sending new stimulation commands after reconstruction.
`save-params` writes to the selected calibration file. Use a disposable
configuration copy when learning commands.

### Practice without hardware

After completing setup, use a fresh supported MATLAB session and select
the CLR as described above. From the repository root, copy the configuration and
start the simulated interactive session:

```matlab
addpath('src');
practiceConfig = tempname;
mkdir(practiceConfig);
copyfile(fullfile(pwd, 'Config', '*.json'), practiceConfig);
wss_cli.main({'--test', '--config', practiceConfig, ...
    '--log-file', fullfile(practiceConfig, 'practice.log')});
```

For finite batch execution, pass each prompt line as a separate `--command`
argument. `--conformance` without commands runs diagnostics and exits; with
commands it uses the emulator for those commands.

In that simulated session, try these commands one at a time. Inspect `status`
and let setup progress before requesting a start. These commands demonstrate
syntax; the configured model and parameters still control the simulated values.

```text
help
status
stim ch1 1.0
stim thumb 0.25
analog ch1 50 1 10
start
status
stop
reload-core
reload-params
save-params
quit
```

The copy isolates configuration writes, not just the log file. Serial/BLE startup
selects live transports; keep `--test` for this exercise. A simulated session
does not validate physical communication or output.

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
