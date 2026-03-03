# -*- coding: utf-8 -*-

"""
The CI/CD test script for ATB.

TODO: AK3 and build test.
"""

from test_run_env import TestRunEnv
import os
import sys
import unittest


ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)


def main() -> int:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestRunEnv)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
