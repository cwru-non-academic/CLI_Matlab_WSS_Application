# Independent native test selection

The trusted MATLAB wrapper bootstrap owns `Invoke-SelectedMatlabTests.ps1` for
both wrapper and CLI roles. Supply this repository as the independently selected
`TestRoot` at its exact `TestSha`, with `TestRepository` and `TestSelectionId` from
the authenticated frozen Core plan. `tests/test-contract.json` selects only the
fixed `tests` and `conformance` native MATLAB source directories. Product and
wrapper roots/SHAs and the canonical payload are separate fixed inputs.

`runCliConformance` accepts an optional third `productRoot` argument;
`checkCliCompatibility` accepts an optional second `productRoot` argument. These
prevent selected tests from adding their own `src` to the path. Native tests use
`WSS_MATLAB_PRODUCT_ROOT` for product-owned Config and the existing explicit
`WSS_MATLAB_WRAPPER_ROOT` for the fixed wrapper. Defaults remain unchanged for
ordinary CI. No selected `ci`, `.github`, product source, or release validator is
executed. Existing mandatory product CI, canonical, runtime, projection, and
receipt checks remain required; the independently selected suite is additive.

See the wrapper repository's `docs/SELECTED-TESTS.md` for evidence and invocation.
