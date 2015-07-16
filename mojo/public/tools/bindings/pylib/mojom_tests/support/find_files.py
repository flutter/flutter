# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import fnmatch
from os import walk
from os.path import join
import sys


def FindFiles(top, pattern, **kwargs):
  """Finds files under |top| matching the glob pattern |pattern|, returning a
  list of paths."""
  matches = []
  for dirpath, _, filenames in walk(top, **kwargs):
    for filename in fnmatch.filter(filenames, pattern):
      matches.append(join(dirpath, filename))
  return matches


def main(argv):
  if len(argv) != 3:
    print "usage: %s path pattern" % argv[0]
    return 1

  for filename in FindFiles(argv[1], argv[2]):
    print filename
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
