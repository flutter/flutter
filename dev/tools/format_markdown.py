#!/usr/bin/env python3
"""Markdown formatter for Flutter - Step 1 demonstration"""

import sys
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: python dev/tools/format_markdown.py file1.md [file2.md ...]")
        sys.exit(1)
    
    files = sys.argv[1:]
    cmd = ["python3", "-m", "mdformat"] + files
    
    try:
        result = subprocess.run(cmd)
        sys.exit(result.returncode)
    except FileNotFoundError:
        print("Error: mdformat not found. Install with: pip install mdformat")
        sys.exit(1)

if __name__ == '__main__':
    main()
