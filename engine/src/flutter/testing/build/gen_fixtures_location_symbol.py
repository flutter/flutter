#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import sys
import os


def main():
  parser = argparse.ArgumentParser(
      description='Create the symbol specifying the location of test fixtures.')

  parser.add_argument('--fixtures_location_file', type=str, required=True)
  parser.add_argument('--fixtures_location', type=str, required=True)

  args = parser.parse_args()

  with open(args.fixtures_location_file, 'w') as file:
    file.write('namespace testing {const char* GetFixturesPath() {return "%s";}}'
      % args.fixtures_location)


if __name__ == '__main__':
  sys.exit(main())
