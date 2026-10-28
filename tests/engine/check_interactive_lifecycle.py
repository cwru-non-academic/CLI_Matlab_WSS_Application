"""Verify production CLI lifecycle with a blocking input double and real MATLAB interrupt.

Uses the MATLAB-bundled Engine API directly; no pip installation is required.
Only ConformanceMode is used. The fixture folder shadows input only inside the
isolated MATLAB process. This is a console-double check, not a native UI check.
"""

from __future__ import annotations

import argparse
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import time


def wait_file(path: Path, future, timeout: float = 30) -> None:
    deadline = time.monotonic() + timeout
    while not path.is_file():
        if future.done():
            future.result()
            raise RuntimeError(f"CLI returned before reaching {path.name}")
        if time.monotonic() >= deadline:
            future.cancel()
            raise TimeoutError(f"CLI did not reach {path.name}")
        time.sleep(0.02)


def quote(value: Path) -> str:
    return "'" + str(value).replace("'", "''") + "'"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--matlab-root", type=Path, required=True)
    parser.add_argument("--wrapper-root", type=Path, required=True)
    args = parser.parse_args()
    app = Path(__file__).resolve().parents[2]
    root = args.matlab_root.resolve()
    wrapper = args.wrapper_root.resolve()
    sys.dont_write_bytecode = True
    # Preserve DLL search handles for the lifetime of the Engine process.
    handles = [os.add_dll_directory(str(root / "bin/win64")),
               os.add_dll_directory(str(root / "extern/bin/win64"))]
    sys.path[:0] = [str(root / "extern/engines/python/dist"),
                   str(root / "extern/engines/python/dist/matlab/engine/win64"),
                   str(root / "extern/bin/win64")]
    import matlab.engine

    engine = matlab.engine.start_matlab("-nodesktop -noFigureWindows")
    output = io.StringIO()
    reports = []
    try:
        engine.eval("dotnetenv('core',Version='8');", nargout=0)
        engine.addpath(str(app / "src"), str(wrapper / "src"), str(Path(__file__).parent), nargout=0)
        with tempfile.TemporaryDirectory(prefix="wss-matlab-input-") as temp:
            for mode in ("quit", "interrupt", "quit"):
                directory = Path(temp) / f"case-{len(reports)}-{mode}"
                directory.mkdir()
                config = directory / "Config"
                config.mkdir()
                for source in (app / "Config").glob("*.json"):
                    (config / source.name).write_bytes(source.read_bytes())
                log = directory / "host.log"
                engine.setenv("WSS_MATLAB_INPUT_GATE", str(directory), nargout=0)
                expression = ("wss_cli.main({'--wrapper-root'," + quote(wrapper)
                              + ",'--config'," + quote(config) + ",'--log-file'," + quote(log)
                              + ",'--conformance','--tick','1'});")
                future = engine.eval(expression, nargout=0, background=True, stdout=output, stderr=output)
                wait_file(directory / "waiting.json", future)
                time.sleep(0.3)
                if mode == "quit":
                    (directory / "release.txt").write_text("quit", encoding="utf-8")
                    future.result(timeout=30)
                    ticks = json.loads((directory / "released.json").read_text(encoding="utf-8"))
                    if ticks["after"] <= ticks["before"]:
                        raise AssertionError("Managed ticking stopped at the console input boundary")
                else:
                    if not future.cancel():
                        raise AssertionError("MATLAB Engine did not accept the interrupt")
                    try:
                        future.result(timeout=30)
                    except matlab.engine.InterruptedError:
                        pass
                    except matlab.engine.CancelledError:
                        pass
                    if not future.cancelled():
                        raise AssertionError("MATLAB execution was not marked cancelled")
                    ticks = {"interrupt": "accepted"}
                # main owns and deletes the actual controller before restoring
                # wrapper paths. A retained fixture handle must be invalid now.
                engine.eval("assert(~isvalid(wss_test_controller));", nargout=0)
                if "Disposed" not in log.read_text(encoding="utf-8"):
                    raise AssertionError("CLI unwind did not dispose the managed host")
                reports.append({"mode": mode, "passed": True, **ticks})
                print(json.dumps(reports[-1]), flush=True)
    finally:
        engine.quit()
        del handles
    print(json.dumps({"checks": reports, "native_input_ui": "not exercised"}), flush=True)


if __name__ == "__main__":
    main()
