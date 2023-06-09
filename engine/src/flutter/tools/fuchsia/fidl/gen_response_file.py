#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
from pathlib import Path


def main():
  parser = argparse.ArgumentParser(
      description="Generate response file for FIDL frontend. "
      "Arguments not mentioned here are forwarded as is to fidlc."
  )
  parser.add_argument(
      "--out-response-file",
      help="The path for for the response file to generate",
      type=Path,
      required=True
  )
  parser.add_argument(
      "--out-libraries",
      help="The path for for the libraries file to generate",
      type=Path,
      required=True
  )
  parser.add_argument(
      "--sources", help="List of FIDL source files", nargs="+", required=True
  )
  parser.add_argument(
      "--dep-libraries", help="List of dependent libraries", nargs="*"
  )
  args, args_to_forward = parser.parse_known_args()

  # Each line contains a library's source files separated by spaces.
  # We use a dict instead of a set to maintain insertion order.
  dep_lines = {}
  for path in args.dep_libraries or []:
    with open(path) as f:
      for line in f:
        dep_lines[line.rstrip()] = True
  libraries = list(dep_lines)
  libraries.append(" ".join(sorted(args.sources)))

  args.out_libraries.parent.mkdir(parents=True, exist_ok=True)
  with open(args.out_libraries, "w") as f:
    print("\n".join(libraries), file=f)

  args.out_response_file.parent.mkdir(parents=True, exist_ok=True)
  with open(args.out_response_file, "w") as f:
    fidlc_args = args_to_forward + ["--files " + line for line in libraries]
    print(" ".join(fidlc_args), file=f)


if __name__ == "__main__":
  main()
