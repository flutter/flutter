#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
import urllib2

import suppressions


def main():
  supp = suppressions.GetSuppressions()

  all_supps = []
  for supps in supp.values():
    all_supps += [s.description for s in supps]
  sys.stdout.write(urllib2.urlopen(
      'http://chromium-build-logs.appspot.com/unused_suppressions',
      '\n'.join(all_supps)).read())
  return 0

if __name__ == "__main__":
  sys.exit(main())
