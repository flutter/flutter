#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os.path
import sys

def main():
  parser = argparse.ArgumentParser(
      description="GYP helper script for mapping mojoms => generated outputs.")
  parser.add_argument("--basedir", required=True)
  parser.add_argument("mojom", nargs="*")

  args = parser.parse_args()

  for mojom in args.mojom:
    full = os.path.join("<(SHARED_INTERMEDIATE_DIR)", args.basedir, mojom)
    base, ext = os.path.splitext(full)
    assert ext == ".mojom", mojom
    # Fix filename escaping issues on Windows.
    base = base.replace("\\", "/")
    print base + ".mojom.cc"
    print base + ".mojom.h"
    print base + ".mojom-internal.h"
    print base + ".mojom.js"
    print base + "_mojom.py"

  return 0

if __name__ == "__main__":
  sys.exit(main())
