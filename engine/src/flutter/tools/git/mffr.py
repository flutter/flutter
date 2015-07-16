#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Usage: mffr.py [-d] [-g *.h] [-g *.cc] REGEXP REPLACEMENT

This tool performs a fast find-and-replace operation on files in
the current git repository.

The -d flag selects a default set of globs (C++ and Objective-C/C++
source files). The -g flag adds a single glob to the list and may
be used multiple times. If neither -d nor -g is specified, the tool
searches all files (*.*).

REGEXP uses full Python regexp syntax. REPLACEMENT can use
back-references.
"""

import optparse
import re
import subprocess
import sys


# We need to use shell=True with subprocess on Windows so that it
# finds 'git' from the path, but can lead to undesired behavior on
# Linux.
_USE_SHELL = (sys.platform == 'win32')


def MultiFileFindReplace(original, replacement, file_globs):
  """Implements fast multi-file find and replace.

  Given an |original| string and a |replacement| string, find matching
  files by running git grep on |original| in files matching any
  pattern in |file_globs|.

  Once files are found, |re.sub| is run to replace |original| with
  |replacement|.  |replacement| may use capture group back-references.

  Args:
    original: '(#(include|import)\s*["<])chrome/browser/ui/browser.h([>"])'
    replacement: '\1chrome/browser/ui/browser/browser.h\3'
    file_globs: ['*.cc', '*.h', '*.m', '*.mm']

  Returns the list of files modified.

  Raises an exception on error.
  """
  # Posix extended regular expressions do not reliably support the "\s"
  # shorthand.
  posix_ere_original = re.sub(r"\\s", "[[:space:]]", original)
  if sys.platform == 'win32':
    posix_ere_original = posix_ere_original.replace('"', '""')
  out, err = subprocess.Popen(
      ['git', 'grep', '-E', '--name-only', posix_ere_original,
       '--'] + file_globs,
      stdout=subprocess.PIPE,
      shell=_USE_SHELL).communicate()
  referees = out.splitlines()

  for referee in referees:
    with open(referee) as f:
      original_contents = f.read()
    contents = re.sub(original, replacement, original_contents)
    if contents == original_contents:
      raise Exception('No change in file %s although matched in grep' %
                      referee)
    with open(referee, 'wb') as f:
      f.write(contents)

  return referees


def main():
  parser = optparse.OptionParser(usage='''
(1) %prog <options> REGEXP REPLACEMENT
REGEXP uses full Python regexp syntax. REPLACEMENT can use back-references.

(2) %prog <options> -i <file>
<file> should contain a list (in Python syntax) of
[REGEXP, REPLACEMENT, [GLOBS]] lists, e.g.:
[
  [r"(foo|bar)", r"\1baz", ["*.cc", "*.h"]],
  ["54", "42"],
]
As shown above, [GLOBS] can be omitted for a given search-replace list, in which
case the corresponding search-replace will use the globs specified on the
command line.''')
  parser.add_option('-d', action='store_true',
                    dest='use_default_glob',
                    help='Perform the change on C++ and Objective-C(++) source '
                    'and header files.')
  parser.add_option('-f', action='store_true',
                    dest='force_unsafe_run',
                    help='Perform the run even if there are uncommitted local '
                    'changes.')
  parser.add_option('-g', action='append',
                    type='string',
                    default=[],
                    metavar="<glob>",
                    dest='user_supplied_globs',
                    help='Perform the change on the specified glob. Can be '
                    'specified multiple times, in which case the globs are '
                    'unioned.')
  parser.add_option('-i', "--input_file",
                    type='string',
                    action='store',
                    default='',
                    metavar="<file>",
                    dest='input_filename',
                    help='Read arguments from <file> rather than the command '
                    'line. NOTE: To be sure of regular expressions being '
                    'interpreted correctly, use raw strings.')
  opts, args = parser.parse_args()
  if opts.use_default_glob and opts.user_supplied_globs:
    print '"-d" and "-g" cannot be used together'
    parser.print_help()
    return 1

  from_file = opts.input_filename != ""
  if (from_file and len(args) != 0) or (not from_file and len(args) != 2):
    parser.print_help()
    return 1

  if not opts.force_unsafe_run:
    out, err = subprocess.Popen(['git', 'status', '--porcelain'],
                                stdout=subprocess.PIPE,
                                shell=_USE_SHELL).communicate()
    if out:
      print 'ERROR: This tool does not print any confirmation prompts,'
      print 'so you should only run it with a clean staging area and cache'
      print 'so that reverting a bad find/replace is as easy as running'
      print '  git checkout -- .'
      print ''
      print 'To override this safeguard, pass the -f flag.'
      return 1

  global_file_globs = ['*.*']
  if opts.use_default_glob:
    global_file_globs = ['*.cc', '*.h', '*.m', '*.mm']
  elif opts.user_supplied_globs:
    global_file_globs = opts.user_supplied_globs

  # Construct list of search-replace tasks.
  search_replace_tasks = []
  if opts.input_filename == '':
    original = args[0]
    replacement = args[1]
    search_replace_tasks.append([original, replacement, global_file_globs])
  else:
    f = open(opts.input_filename)
    search_replace_tasks = eval("".join(f.readlines()))
    for task in search_replace_tasks:
      if len(task) == 2:
        task.append(global_file_globs)
    f.close()

  for (original, replacement, file_globs) in search_replace_tasks:
    print 'File globs:  %s' % file_globs
    print 'Original:    %s' % original
    print 'Replacement: %s' % replacement
    MultiFileFindReplace(original, replacement, file_globs)
  return 0


if __name__ == '__main__':
  sys.exit(main())
