# Ordinary CLI CI

`CLI CI` runs on pull requests to `main` and `dev`, plus manual dispatch. Check
contexts match C#: `CLI general conformance`, with distinct
`CLI platform compatibility (Windows)`, `(Ubuntu)`, and `(macOS)` jobs.

General conformance builds the committed public wrapper submodule, executes the
default production CLI without a sibling override, MATLAB argument/runtime tests
and the canonical suites for the verified payload profile through the CLI
factory. The native MATLAB action performs this validation; the separate local
Engine interrupt harness is not an ordinary workflow step.
Compatibility jobs separately verify application path ownership and serial/BLE
runtime/backend/native ABI loading; they do not relabel a general conformance
run as three platform checks. A declared macOS backend requires packaged native
ABI proof; only an explicitly identified legacy payload without that backend
reports unsupported BLE. No physical device connection or stimulation is performed.

The wrapper and CLI are public. Public recursive submodule checkout needs no
GitHub App token, new credentials or expanded permissions. Every consumer test
uses the committed gitlink, not a floating branch or local sibling checkout.

The [committed CLI workflow](../.github/workflows/cli-ci.yml) uses GitHub-hosted
Windows and Ubuntu runners and two required native Mac lanes: ARM64/R2026b on
`macos-15` and Intel/R2025b on `macos-15-intel`. The final macOS context requires
both architecture proofs. The native action installs .NET 8, builds the recorded
wrapper's managed host, and invokes official `setup-matlab@v3` and `run-command@v3`.
Intel R2025b is compatibility-only; canonical behavior remains on R2026b.
`WSS_MATLAB_*_RUNNER` variables and Python Engine setup are not workflow prerequisites.

Successful hosted execution is technical evidence, not a determination of
MathWorks support or licensing terms. Review the current
[Setup MATLAB notes](https://github.com/matlab-actions/setup-matlab#notes) and the
applicable license. No runner registration, license, credential, ruleset or App
permission is changed here. Ordinary CI is separate from Core propagation and
release acceptance; committed readiness declarations do not establish effective
live settings or candidate acceptance. See [propagation setup](../docs/PROPAGATION-SETUP.md).

Local commands: build `external/wss-matlab-wrapper/managed/Wss.Matlab.Managed.csproj`,
then in MATLAB `addpath('ci'); runCliCi('general'); runCliCi('compatibility');`.
Evidence is written under ignored `artifacts/ci/`.

## Native unit-test source contract

`native-test-contract.json` lists the exact test IDs discovered by MATLAB for
this product source. Update it alongside intentional test additions/removals.
The runner checks exact discovered and completed IDs, rejects duplicates, and
requires every result to pass without skips. Evidence includes these IDs and
results; counts alone cannot satisfy a new-source contract.

MATLAB binders retrieve the contract from the verified immutable product-owner
revision, independently of the tooling checkout. Historical sources without a
manifest are accepted only for a frozen reviewed tests-tree and native-runner
blob pair with an authenticated discovery inventory. Unknown historical pairs
fail closed. These compatibility entries are not moving branch or package pins.
Canonical Core scenarios, payload hashes and source/native evidence remain
mandatory and separate from this unit-test inventory.
