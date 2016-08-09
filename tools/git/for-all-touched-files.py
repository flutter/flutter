#!/usr/bin/env python
# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
  Invokes the specified (quoted) command for all files modified
  between the current git branch and the specified branch or commit.

  The special token [[FILENAME]] (or whatever you choose using the -t
  flag) is replaced with each of the filenames of new or modified files.

  Deleted files are not included.  Neither are untracked files.

Synopsis:
  %prog [-b BRANCH] [-d] [-x EXTENSIONS|-c|-g] [-t TOKEN] QUOTED_COMMAND

Examples:
  %prog -x gyp,gypi "tools/format_xml.py [[FILENAME]]"
  %prog -c "tools/sort-headers.py [[FILENAME]]"
  %prog -g "tools/sort_sources.py [[FILENAME]]"
  %prog -t "~~BINGO~~" "echo I modified ~~BINGO~~"
"""

import optparse
import os
import subprocess
import sys


# List of C++-like source file extensions.
_CPP_EXTENSIONS = ('h', 'hh', 'hpp', 'c', 'cc', 'cpp', 'cxx', 'mm',)
# List of build file extensions.
_BUILD_EXTENSIONS = ('gyp', 'gypi', 'gn',)


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


def FilenamesFromGit(branch_name, extensions):
  """Provides a list of all new and modified files listed by [git diff
  branch_name] where branch_name can be blank to get a diff of the
  workspace.

  Excludes deleted files.

  If extensions is not an empty list, include only files with one of
  the extensions on the list.
  """
  lines = GitShell('git diff --stat=600,500 %s' % branch_name)
  filenames = []
  for line in lines:
    line = line.lstrip()
    # Avoid summary line, and files that have been deleted (no plus).
    if line.find('|') != -1 and line.find('+') != -1:
      filename = line.split()[0]
      if filename:
        filename = filename.rstrip()
        ext = filename.rsplit('.')[-1]
        if not extensions or ext in extensions:
          filenames.append(filename)
  return filenames


def ForAllTouchedFiles(branch_name, extensions, token, command):
  """For each new or modified file output by [git diff branch_name],
  run command with token replaced with the filename. If extensions is
  not empty, do this only for files with one of the extensions in that
  list.
  """
  filenames = FilenamesFromGit(branch_name, extensions)
  for filename in filenames:
    os.system(command.replace(token, filename))


def main():
  parser = optparse.OptionParser(usage=__doc__)
  parser.add_option('-x', '--extensions', default='', dest='extensions',
                    help='Limits to files with given extensions '
                    '(comma-separated).')
  parser.add_option('-c', '--cpp', default=False, action='store_true',
                    dest='cpp_only',
                    help='Runs your command only on C++-like source files.')
  # -g stands for GYP and GN.
  parser.add_option('-g', '--build', default=False, action='store_true',
                    dest='build_only',
                    help='Runs your command only on build files.')
  parser.add_option('-t', '--token', default='[[FILENAME]]', dest='token',
                    help='Sets the token to be replaced for each file '
                    'in your command (default [[FILENAME]]).')
  parser.add_option('-b', '--branch', default='origin/master', dest='branch',
                    help='Sets what to diff to (default origin/master). Set '
                    'to empty to diff workspace against HEAD.')
  opts, args = parser.parse_args()

  if not args:
    parser.print_help()
    sys.exit(1)

  if opts.cpp_only and opts.build_only:
    parser.error("--cpp and --build are mutually exclusive")

  extensions = opts.extensions
  if opts.cpp_only:
    extensions = _CPP_EXTENSIONS
  if opts.build_only:
    extensions = _BUILD_EXTENSIONS

  ForAllTouchedFiles(opts.branch, extensions, opts.token, args[0])


if __name__ == '__main__':
  main()
