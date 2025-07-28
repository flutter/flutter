#!/usr/bin/env python3
"""
Markdown formatter for Flutter repository.
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path

EXCLUDE_DIRS = {".git", ".dart_tool", "build", "node_modules", "ios", "android", "web", "windows", "macos", "linux"}

def find_markdown_files(root_dir):
    markdown_files = []
    for root, dirs, files in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        for file in files:
            if file.endswith((".md", ".markdown")):
                markdown_files.append(os.path.join(root, file))
    return sorted(markdown_files)

def format_files(files, check_only=False):
    if not files:
        print("No markdown files found.")
        return True
    
    # Process files in smaller batches
    batch_size = 10
    all_success = True
    
    for i in range(0, len(files), batch_size):
        batch = files[i:i + batch_size]
        
        cmd = ["python3", "-m", "mdformat"]
        if check_only:
            cmd.append("--check")
        cmd.extend(batch)
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ Batch {i//batch_size + 1}/{(len(files)-1)//batch_size + 1}: OK ({len(batch)} files)")
            else:
                all_success = False
                print(f"❌ Batch {i//batch_size + 1}/{(len(files)-1)//batch_size + 1}: Issues found")
                if result.stdout:
                    print(f"  Output: {result.stdout[:200]}...")
                if result.stderr:
                    print(f"  Error: {result.stderr[:200]}...")
                    
        except Exception as e:
            print(f"❌ Error processing batch {i//batch_size + 1}: {e}")
            all_success = False
    
    return all_success

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("files", nargs="*")
    args = parser.parse_args()
    
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent.parent
    
    if args.files:
        files_to_format = args.files
    else:
        files_to_format = find_markdown_files(str(repo_root))
        print(f"Found {len(files_to_format)} markdown files")
    
    success = format_files(files_to_format, check_only=args.check)
    
    if success:
        print("✅ All files processed successfully!")
    else:
        print("❌ Some files had issues")
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
