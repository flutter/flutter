# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script enumerates the files in the given directory, writing an empty
# stamp file and a .d file listing the inputs required to make the stamp. This
# allows us to dynamically depend on the grit sources without enumerating the
# grit directory for every invocation of grit (which is what adding the source
# files to every .grd file's .d file would entail) or shelling out to grit
# synchronously during GN execution to get the list (which would be slow).
#
# Usage:
#    stamp_grit_sources.py <directory> <stamp-file> <.d-file>

import os
import sys

def GritSourceFiles(grit_root_dir):
  files = []
  for root, _, filenames in os.walk(grit_root_dir):
    grit_src = [os.path.join(root, f) for f in filenames
                if f.endswith('.py') and not f.endswith('_unittest.py')]
    files.extend(grit_src)
  files = [f.replace('\\', '/') for f in files]
  return sorted(files)


def WriteDepFile(dep_file, stamp_file, source_files):
  with open(dep_file, "w") as f:
    f.write(stamp_file)
    f.write(": ")
    f.write(' '.join(source_files))


def WriteStampFile(stamp_file):
  with open(stamp_file, "w"):
    pass


def main(argv):
  if len(argv) != 4:
    print "Error: expecting 3 args."
    return 1

  grit_root_dir = sys.argv[1]
  stamp_file = sys.argv[2]
  dep_file = sys.argv[3]

  WriteStampFile(stamp_file)
  WriteDepFile(dep_file, stamp_file, GritSourceFiles(grit_root_dir))
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
