#!/usr/bin/env python3
"""Markdown formatter for Flutter - Step 1 demonstration"""

import sys
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: python dev/tools/format_markdown.py file1.md [file2.md ...]")
        sys.exit(1)
    
    files = sys.argv[1:]
    cmd = [sys.executable, "-m", "mdformat"] + files

    # The FileNotFoundError handler was removed as it was misleading.
    # If mdformat is not installed, the subprocess will exit with a non-zero
    # status code and print an error to stderr. This is propagated.
    result = subprocess.run(cmd)
    sys.exit(result.returncode)


if __name__ == '__main__':
    main()
