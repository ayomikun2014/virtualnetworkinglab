"""Test runner for the simulation engine.

The engine's imports are rooted at `simulation_engine/` (`from app.core...`,
`from tests.fixtures...`), so pytest must run with that directory as both the
working directory and on sys.path. This wrapper guarantees that regardless of
where it is invoked from:

    python simulation_engine/run_tests.py [pytest args...]
"""

import os
import sys

ENGINE_DIR = os.path.dirname(os.path.abspath(__file__))

if __name__ == "__main__":
    os.chdir(ENGINE_DIR)
    sys.path.insert(0, ENGINE_DIR)

    import pytest

    sys.exit(pytest.main(sys.argv[1:] or ["tests", "-q"]))
