# Ordinary CLI CI

`CLI CI` runs on pull requests to `main` and `dev`, plus manual dispatch. Check
contexts match C#: `CLI general conformance`, with distinct
`CLI platform compatibility (Windows)`, `(Ubuntu)`, and `(macOS)` jobs.

General conformance builds the committed public wrapper submodule, executes the
default production CLI without a sibling override, MATLAB argument/runtime tests
and Core's canonical catalog through the CLI factory. On its Windows runner it
also uses the real MATLAB Engine interrupt harness with a blocking input double.
Compatibility jobs separately verify application path ownership and serial/BLE
runtime/backend/native ABI loading; they do not relabel a general conformance
run as three platform checks. macOS explicitly reports Core's unsupported BLE
backend. No physical device connection or stimulation is performed.

The wrapper and CLI are public. Public recursive submodule checkout needs no
GitHub App token, new credentials or expanded permissions. Every consumer test
uses the committed gitlink, not a floating branch or local sibling checkout.

MathWorks [Setup MATLAB Notes](https://github.com/matlab-actions/setup-matlab#notes)
exclude external .NET/Engine interfaces from public-project and batch-token
licensing. Existing separately licensed self-hosted runners are required.
`WSS_MATLAB_WINDOWS_RUNNER`, `WSS_MATLAB_UBUNTU_RUNNER`, and
`WSS_MATLAB_MACOS_RUNNER` select JSON runner-label arrays, as documented in the
wrapper's `ci/README.md`. Without them each exact check fails clearly on its
GitHub-hosted fallback. MATLAB absence or unavailable licensing also fails; no
skip or managed-only substitute produces a pass.

Runners require MATLAB R2026b on PATH, .NET SDK/runtime 8, PowerShell and build
dependencies. The Windows general runner additionally needs an existing supported
Python executable (`PYTHON_EXECUTABLE` optionally overrides `python`). The Engine
harness imports MATLAB's bundled API directly; it installs no packages. The actual
MATLAB run records its root for the Engine step.

Only Windows execution is locally verified; Ubuntu/macOS execution remains
pending. No runner registrations, license grants, credentials, rulesets or App
permissions are changed here. Ordinary CI is separate from automated Core
propagation, which remains disabled until the owner authorizes it later.

Local commands: build `external/wss-matlab-wrapper/managed/Wss.Matlab.Managed.csproj`,
then in MATLAB `addpath('ci'); runCliCi('general'); runCliCi('compatibility');`.
Evidence is written under ignored `artifacts/ci/`.
