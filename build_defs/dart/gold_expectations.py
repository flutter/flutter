#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The part of Flutter Gold's expectations that one library's tests compare with.

Gold's response (build_defs/repositories/gold.bzl) cut down to the tests
whose names begin with a library's: flutter_goldens names a golden
`<directory of the test>.<file>`. flutter_test.bzl's
gold_library_expectations runs this once per test directory, and every test
file there that compares goldens gets the result as
FLUTTER_GOLD_EXPECTATIONS.

The cut is what keeps the cache: Gold's response changes whenever anyone
triages an image of any test, and a test that received all of it would run
again each time.
"""

import argparse
import json
import sys


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument(
      '--expectations', required=True, help="Gold's /json/v2/expectations response."
  )
  parser.add_argument(
      '--library',
      required=True,
      help="The name of the tests' directory, which begins their goldens' names."
  )
  parser.add_argument('--out', required=True, help='The file to write.')
  args = parser.parse_args()

  with open(args.expectations, encoding='utf-8') as expectations:
    primary = json.load(expectations).get('primary')
  if not isinstance(primary, dict):
    print(
        '%s is not a response of Flutter Gold: no "primary" object' % args.expectations,
        file=sys.stderr
    )
    return 1
  prefix = args.library + '.'
  tests = {name: digests for name, digests in primary.items() if name.startswith(prefix)}

  with open(args.out, 'w', encoding='utf-8') as out:
    json.dump({'primary': tests}, out, sort_keys=True, separators=(',', ':'))
    out.write('\n')
  return 0


if __name__ == '__main__':
  sys.exit(main())
