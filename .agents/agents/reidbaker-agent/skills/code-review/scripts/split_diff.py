#!/usr/bin/env python3
import argparse
import json
import os
import re
import sys


def extract_diff_from_json(json_data, key=None):
    if key:
        return json_data.get(key, "")
    if isinstance(json_data, str):
        return json_data
    # Try common keys
    for k in ["diff", "patch", "content"]:
        if k in json_data:
            return json_data[k]
    raise ValueError("Could not find diff in JSON data")


def split_diff(diff_content, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    # Regex to split by file in unified diff (looks for 'diff --git ')
    files = re.split(r"^(?=diff --git )", diff_content, flags=re.MULTILINE)

    if len(files) <= 1:
        # Try another marker if 'diff --git' not found (e.g. '--- a/')
        files = re.split(r"^(?=--- )", diff_content, flags=re.MULTILINE)

    summary = []
    count = 0
    for i, file_diff in enumerate(files):
        if not file_diff.strip():
            continue
        # Try to find file name
        match = re.search(r"^diff --git a/(.*?) b/", file_diff, re.MULTILINE)
        if not match:
            match = re.search(r"^--- a/(.*?)$", file_diff, re.MULTILINE)

        if match:
            file_name = match.group(1).strip()
            safe_name = file_name.replace("/", "_")
        else:
            safe_name = f"chunk_{i}.diff"
            file_name = safe_name

        file_path = os.path.join(output_dir, safe_name)
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(file_diff)

        summary.append(f"- {file_name} -> {safe_name}")
        count += 1

    return summary


def main():
    parser = argparse.ArgumentParser(
        description="Extract and split diffs for code review."
    )
    parser.add_argument(
        "input",
        nargs="?",
        type=argparse.FileType("r", encoding="utf-8"),
        default=sys.stdin,
        help="Input file (default: stdin)",
    )
    parser.add_argument(
        "--json", action="store_true", help="Input is JSON encoded"
    )
    parser.add_argument(
        "--json-key", help="Key in JSON containing the diff string"
    )
    parser.add_argument(
        "--output-dir", required=True, help="Directory to write chunks to"
    )

    args = parser.parse_args()

    content = args.input.read()

    if args.json:
        try:
            json_data = json.loads(content)
            diff_content = extract_diff_from_json(json_data, args.json_key)
        except json.JSONDecodeError:
            print("Error: Input is not valid JSON", file=sys.stderr)
            sys.exit(1)
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        diff_content = content

    summary = split_diff(diff_content, args.output_dir)

    print(f"Successfully split diff into {len(summary)} files in {args.output_dir}")
    print("\n".join(summary))


if __name__ == "__main__":
    main()
