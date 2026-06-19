# ===============================================================
# EventLogs.py
# PowerShell loader
# ===============================================================

import subprocess
from pathlib import Path
import sys


def main():

    ps1_file = Path(__file__).with_name("EventLogs.ps1")

    if not ps1_file.exists():
        print(f"ERROR: not found {ps1_file}")
        sys.exit(1)


    result = subprocess.run(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ps1_file),
        ]
    )


    sys.exit(result.returncode)


if __name__ == "__main__":
    main()