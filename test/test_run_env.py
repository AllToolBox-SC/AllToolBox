import os
import sys
import unittest
import uuid

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_DIR = os.path.join(ROOT_DIR, "src")
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

try:
    from src.start import run
except Exception as exc:  # pragma: no cover - runtime dependency guard
    run = None
    IMPORT_ERROR = exc
else:
    IMPORT_ERROR = None


@unittest.skipUnless(os.name == "nt", "Windows-only run() behavior test")
@unittest.skipIf(run is None, f"Cannot import run from start.py: {IMPORT_ERROR}")
class TestRunEnv(unittest.TestCase):
    def test_environment_variable_persists_across_calls(self) -> None:
        key = f"ATB_TEST_{uuid.uuid4().hex[:8].upper()}"
        try:
            run(f"set {key}=1", check=True)
            result1 = run(f"echo %{key}%", capture_output=True, check=True)
            self.assertEqual(result1.stdout.strip(), "1")

            run(f"set {key}=2", check=True)
            result2 = run(f"echo %{key}%", capture_output=True, check=True)
            self.assertEqual(result2.stdout.strip(), "2")
        finally:
            run(f"set {key}=")


if __name__ == "__main__":
    unittest.main()
