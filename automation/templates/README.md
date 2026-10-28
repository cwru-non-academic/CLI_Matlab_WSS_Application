# Disabled workflow template

`cli-ci.yml.disabled` is outside `.github/workflows` and every job has a literal
false guard. It does not execute or configure CI. Context names match the C# CLI:
`CLI general conformance` and `CLI platform compatibility (Windows|Ubuntu|macOS)`.

Activation requires a published wrapper implementation, updated committed
gitlink, reviewed GitHub App access/secrets, licensed isolated MATLAB runners and
.NET 8, OS compatibility execution, action pin review and a separate decision to
enable CI. Only Windows has been validated locally. Skipped template jobs are not
validation evidence. Immutable-artifact preflight and propagation remain future
work; never substitute current committed DLLs for a candidate artifact.

The Windows general-conformance runner must also provide an existing supported
Python interpreter via `PYTHON_EXECUTABLE` and its installed MATLAB root via
`MATLAB_ROOT` for the Engine interrupt harness. No package installation is done
by that harness. OS compatibility jobs run the separate load-only checks.
