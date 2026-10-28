# Public MATLAB CI experiment

This draft PR tests the production MATLAB CLI directly against its existing published wrapper submodule fdc7584e77d62b4d3a56ff608e7a1ced1afd2dcf. Main/dev, the wrapper pin, production code, DLL payloads, and shared assertions are unchanged.

## Preceding wrapper evidence

- Iteration 1: official public-project setup ran both existing native wrapper runtime tests successfully on Windows: https://github.com/cwru-non-academic/Matlab_WSS_Integration_Lib/actions/runs/40745512339
- Iteration 2: full wrapper suite passed (5 native tests, 10 canonical Core scenarios), plus distinct Windows/Ubuntu/macOS compatibility checks: https://github.com/cwru-non-academic/Matlab_WSS_Integration_Lib/actions/runs/40746403298
- macOS serial checks passed; BLE remains explicitly unsupported-by-Core in this payload. Compatibility is load-only, without hardware operations.

## Iteration 3: Native CLI general and platform checks

- Change: replace this branch's self-hosted precondition with official `matlab-actions/setup-matlab@v3` / `run-command@v3`, R2026b and .NET 8. Run existing native `runCliCi('general')` and separate Windows, Ubuntu, macOS `runCliCi('compatibility')` jobs with canonical names. Build the committed wrapper host and upload existing JSON evidence.
- Reason: test the actual application and pinned-library consumer path through the same direct MATLAB-to-DLL route that passed wrapper CI. Remove the Python Engine workflow step so hosted CI uses MATLAB-native entrypoints throughout.
- Coverage boundary: existing native tests and canonical scenarios stay unchanged. The supplemental Python Engine cancellation harness remains in the repository for licensed local diagnostics but is no longer invoked in this workflow; this run therefore does not claim programmatic Engine cancellation coverage.
- Constraints: no user license token, account login, paid runner, hardware operation, changed MathWorks enforcement, or replacement Core implementation. Four jobs, each bounded to 30 minutes. Technical execution does not by itself resolve broad MathWorks support/licensing wording.
- Result: pending GitHub Actions run.
