#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
  Invokes git diff [args...] and inserts file:line in front of each line of diff
  output where possible.

  This is useful from an IDE that allows you to double-click lines that begin
  with file:line to open and jump to that point in the file.

Synopsis:
  %prog [git diff args...]

Examples:
  %prog
  %prog HEAD
"""

import subprocess
import sys


def GitShell(args, ignore_return=False):
  """A shell invocation suitable for communicating with git. Returns
  output as list of lines, raises exception on error.
  """
  job = subprocess.Popen(args,
                         shell=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
  (out, err) = job.communicate()
  if job.returncode != 0 and not ignore_return:
    print out
    raise Exception("Error %d running command %s" % (
        job.returncode, args))
  return out.split('\n')


def PrintGitDiff(extra_args):
  """Outputs git diff extra_args with file:line inserted into relevant lines."""
  current_file = '';
  line_num = 0;
  lines = GitShell('git diff %s' % ' '.join(extra_args))
  for line in lines:
    # Pass-through lines:
    #  diff --git a/file.c b/file.c
    #  index 0e38c2d..8cd69ae 100644
    #  --- a/file.c
    if (line.startswith('diff ') or
        line.startswith('index ') or
        line.startswith('--- ')):
      print line
      continue

    # Get the filename from the +++ line:
    #  +++ b/file.c
    if line.startswith('+++ '):
      # Filename might be /dev/null or a/file or b/file.
      # Skip the first two characters unless it starts with /.
      current_file = line[4:] if line[4] == '/' else line[6:]
      print line
      continue

    # Update line number from the @@ lines:
    #  @@ -41,9 +41,9 @@ def MyFunc():
    #            ^^
    if line.startswith('@@ '):
      _, old_nr, new_nr, _ = line.split(' ', 3)
      line_num = int(new_nr.split(',')[0])
      print line
      continue
    print current_file + ':' + repr(line_num) + ':' + line

    # Increment line number for lines that start with ' ' or '+':
    #  @@ -41,4 +41,4 @@ def MyFunc():
    #  file.c:41: // existing code
    #  file.c:42: // existing code
    #  file.c:43:-// deleted code
    #  file.c:43:-// deleted code
    #  file.c:43:+// inserted code
    #  file.c:44:+// inserted code
    if line.startswith(' ') or line.startswith('+'):
      line_num += 1


def main():
  PrintGitDiff(sys.argv[1:])


if __name__ == '__main__':
  main()
