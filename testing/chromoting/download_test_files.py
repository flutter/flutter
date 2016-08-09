# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A script to download files required for Remoting integration tests from GCS.

  The script expects 2 parameters:

    input_files: a file containing the full path in GCS to each file that is to
                be downloaded.
    output_folder: the folder to which the specified files should be downloaded.

  This scripts expects that its execution is done on a machine where the
  credentials are correctly setup to obtain the required permissions for
  downloading files from the specified GCS buckets.
"""

import argparse
import ntpath
import os
import subprocess
import sys


def main():

  parser = argparse.ArgumentParser()
  parser.add_argument('-f', '--files',
                      help='File specifying files to be downloaded .')
  parser.add_argument(
      '-o', '--output_folder',
      help='Folder where specified files should be downloaded .')

  if len(sys.argv) < 3:
    parser.print_help()
    sys.exit(1)

  args = parser.parse_args()
  if not args.files or not args.output_folder:
    parser.print_help()
    sys.exit(1)

  # Loop through lines in input file specifying source file locations.
  with open(args.files) as f:
    for line in f:
      # Copy the file to the output folder, with same name as source file.
      output_file = os.path.join(args.output_folder, ntpath.basename(line))
      # Download specified file from GCS.
      cp_cmd = ['gsutil.py', 'cp', line, output_file]
      try:
        subprocess.check_call(cp_cmd)
      except subprocess.CalledProcessError, e:
        print e.output
        sys.exit(1)

if __name__ == '__main__':
  main()
