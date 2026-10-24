# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Assembles a directory of GN's build directory from the files placed in it.

A GN action may read a directory of the build directory that several targets
fill (gen/dart-pkg/sky_engine: the package assembled by dart_pkg.py and the
libraries copied beside it). Under Bazel each target places its own files
(BuildDirectoryInfo); this script lays what the action's deps place under
that directory into one directory artifact, at their paths below it, for
the action to read as GN's script reads the build directory.

Usage: stage_build_directory.py OUT (SOURCE DESTINATION)...

  OUT          the directory to assemble (created empty by Bazel).
  SOURCE       a file, or a directory, placed in the build directory.
  DESTINATION  its path below OUT; `.` for a directory whose contents are
               OUT's own (a placed directory above the one read, entered at
               the path below it).

Symlinks are resolved on the way (a sandboxed tree artifact's files are
symlinks), so the result holds regular files.
"""

import os
import shutil
import sys


def main(argv):
  out = argv[1]
  pairs = argv[2:]
  if len(pairs) % 2:
    sys.stderr.write('stage_build_directory.py: SOURCE DESTINATION pairs expected\n')
    return 1
  os.makedirs(out, exist_ok=True)
  for source, destination in zip(pairs[0::2], pairs[1::2]):
    target = os.path.normpath(os.path.join(out, destination))
    if os.path.isdir(source):
      shutil.copytree(source, target, symlinks=False, dirs_exist_ok=True)
    else:
      os.makedirs(os.path.dirname(target), exist_ok=True)
      shutil.copyfile(source, target)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
