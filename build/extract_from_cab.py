#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Extracts a single file from a CAB archive."""

import os
import shutil
import subprocess
import sys
import tempfile

def run_quiet(*args):
  """Run 'expand' suppressing noisy output. Returns returncode from process."""
  popen = subprocess.Popen(args, stdout=subprocess.PIPE)
  out, _ = popen.communicate()
  if popen.returncode:
    # expand emits errors to stdout, so if we fail, then print that out.
    print out
  return popen.returncode

def main():
  if len(sys.argv) != 4:
    print 'Usage: extract_from_cab.py cab_path archived_file output_dir'
    return 1

  [cab_path, archived_file, output_dir] = sys.argv[1:]

  # Expand.exe does its work in a fixed-named temporary directory created within
  # the given output directory. This is a problem for concurrent extractions, so
  # create a unique temp dir within the desired output directory to work around
  # this limitation.
  temp_dir = tempfile.mkdtemp(dir=output_dir)

  try:
    # Invoke the Windows expand utility to extract the file.
    level = run_quiet('expand', cab_path, '-F:' + archived_file, temp_dir)
    if level == 0:
      # Move the output file into place, preserving expand.exe's behavior of
      # paving over any preexisting file.
      output_file = os.path.join(output_dir, archived_file)
      try:
        os.remove(output_file)
      except OSError:
        pass
      os.rename(os.path.join(temp_dir, archived_file), output_file)
  finally:
    shutil.rmtree(temp_dir, True)

  if level != 0:
    return level

  # The expand utility preserves the modification date and time of the archived
  # file. Touch the extracted file. This helps build systems that compare the
  # modification times of input and output files to determine whether to do an
  # action.
  os.utime(os.path.join(output_dir, archived_file), None)
  return 0


if __name__ == '__main__':
  sys.exit(main())
