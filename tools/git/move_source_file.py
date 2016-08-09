#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Moves C++ files to a new location, updating any include paths that point
to them, and re-ordering headers as needed.  If multiple source files are
specified, the destination must be a directory.  Updates include guards in
moved header files.  Assumes Chromium coding style.

Attempts to update paths used in .gyp(i) files, but does not reorder
or restructure .gyp(i) files in any way.

Updates full-path references to files in // comments in source files.

Must run in a git checkout, as it relies on git grep for a fast way to
find files that reference the moved file.
"""


import optparse
import os
import re
import subprocess
import sys

import mffr

if __name__ == '__main__':
  # Need to add the directory containing sort-headers.py to the Python
  # classpath.
  sys.path.append(os.path.abspath(os.path.join(sys.path[0], '..')))
sort_headers = __import__('sort-headers')
import sort_sources


HANDLED_EXTENSIONS = ['.cc', '.mm', '.h', '.hh', '.cpp']


def IsHandledFile(path):
  return os.path.splitext(path)[1] in HANDLED_EXTENSIONS


def MakeDestinationPath(from_path, to_path):
  """Given the from and to paths, return a correct destination path.

  The initial destination path may either a full path or a directory.
  Also does basic sanity checks.
  """
  if not IsHandledFile(from_path):
    raise Exception('Only intended to move individual source files '
                    '(%s does not have a recognized extension).' %
                    from_path)

  # Remove '.', '..', etc.
  to_path = os.path.normpath(to_path)

  if os.path.isdir(to_path):
    to_path = os.path.join(to_path, os.path.basename(from_path))
  else:
    dest_extension = os.path.splitext(to_path)[1]
    if dest_extension not in HANDLED_EXTENSIONS:
      raise Exception('Destination must be either a full path with '
                      'a recognized extension or a directory.')
  return to_path


def MoveFile(from_path, to_path):
  """Performs a git mv command to move a file from |from_path| to |to_path|.
  """
  if not os.system('git mv %s %s' % (from_path, to_path)) == 0:
    raise Exception('Fatal: Failed to run git mv command.')


def UpdatePostMove(from_path, to_path):
  """Given a file that has moved from |from_path| to |to_path|,
  updates the moved file's include guard to match the new path and
  updates all references to the file in other source files. Also tries
  to update references in .gyp(i) files using a heuristic.
  """
  # Include paths always use forward slashes.
  from_path = from_path.replace('\\', '/')
  to_path = to_path.replace('\\', '/')

  if os.path.splitext(from_path)[1] in ['.h', '.hh']:
    UpdateIncludeGuard(from_path, to_path)

    # Update include/import references.
    files_with_changed_includes = mffr.MultiFileFindReplace(
        r'(#(include|import)\s*["<])%s([>"])' % re.escape(from_path),
        r'\1%s\3' % to_path,
        ['*.cc', '*.h', '*.m', '*.mm', '*.cpp'])

    # Reorder headers in files that changed.
    for changed_file in files_with_changed_includes:
      def AlwaysConfirm(a, b): return True
      sort_headers.FixFileWithConfirmFunction(changed_file, AlwaysConfirm, True)

  # Update comments; only supports // comments, which are primarily
  # used in our code.
  #
  # This work takes a bit of time. If this script starts feeling too
  # slow, one good way to speed it up is to make the comment handling
  # optional under a flag.
  mffr.MultiFileFindReplace(
      r'(//.*)%s' % re.escape(from_path),
      r'\1%s' % to_path,
      ['*.cc', '*.h', '*.m', '*.mm', '*.cpp'])

  # Update references in GYP and BUILD.gn files.
  #
  # GYP files are mostly located under the first level directory (ex.
  # chrome/chrome_browser.gypi), but sometimes they are located in
  # directories at a deeper level (ex. extensions/shell/app_shell.gypi). On
  # the other hand, BUILD.gn files can be placed in any directories.
  #
  # Paths in a GYP or BUILD.gn file are relative to the directory where the
  # file is placed.
  #
  # For instance, "chrome/browser/chromeos/device_uma.h" is listed as
  # "browser/chromeos/device_uma.h" in "chrome/chrome_browser_chromeos.gypi",
  # but it's listed as "device_uma.h" in "chrome/browser/chromeos/BUILD.gn".
  #
  # To handle this, the code here will visit directories from the top level
  # src directory to the directory of |from_path| and try to update GYP and
  # BUILD.gn files in each directory.
  #
  # The code only handles files moved/renamed within the same build file. If
  # files are moved beyond the same build file, the affected build files
  # should be fixed manually.
  def SplitByFirstComponent(path):
    """'foo/bar/baz' -> ('foo', 'bar/baz')
       'bar' -> ('bar', '')
       '' -> ('', '')
    """
    parts = re.split(r"[/\\]", path, 1)
    if len(parts) == 2:
      return (parts[0], parts[1])
    else:
      return (parts[0], '')

  visiting_directory = ''
  from_rest = from_path
  to_rest = to_path
  while True:
    files_with_changed_sources = mffr.MultiFileFindReplace(
        r'([\'"])%s([\'"])' % from_rest,
        r'\1%s\2' % to_rest,
        [os.path.join(visiting_directory, 'BUILD.gn'),
         os.path.join(visiting_directory, '*.gyp*')])
    for changed_file in files_with_changed_sources:
      sort_sources.ProcessFile(changed_file, should_confirm=False)
    from_first, from_rest = SplitByFirstComponent(from_rest)
    to_first, to_rest = SplitByFirstComponent(to_rest)
    visiting_directory = os.path.join(visiting_directory, from_first)
    if not from_rest or not to_rest:
        break


def MakeIncludeGuardName(path_from_root):
  """Returns an include guard name given a path from root."""
  guard = path_from_root.replace('/', '_')
  guard = guard.replace('\\', '_')
  guard = guard.replace('.', '_')
  guard += '_'
  return guard.upper()


def UpdateIncludeGuard(old_path, new_path):
  """Updates the include guard in a file now residing at |new_path|,
  previously residing at |old_path|, with an up-to-date include guard.

  Prints a warning if the update could not be completed successfully (e.g.,
  because the old include guard was not formatted correctly per Chromium style).
  """
  old_guard = MakeIncludeGuardName(old_path)
  new_guard = MakeIncludeGuardName(new_path)

  with open(new_path) as f:
    contents = f.read()

  new_contents = contents.replace(old_guard, new_guard)
  # The file should now have three instances of the new guard: two at the top
  # of the file plus one at the bottom for the comment on the #endif.
  if new_contents.count(new_guard) != 3:
    print ('WARNING: Could not successfully update include guard; perhaps '
           'old guard is not per style guide? You will have to update the '
           'include guard manually. (%s)' % new_path)

  with open(new_path, 'w') as f:
    f.write(new_contents)

def main():
  if not os.path.isdir('.git'):
    print 'Fatal: You must run from the root of a git checkout.'
    return 1

  parser = optparse.OptionParser(usage='%prog FROM_PATH... TO_PATH')
  parser.add_option('--already_moved', action='store_true',
                    dest='already_moved',
                    help='Causes the script to skip moving the file.')
  parser.add_option('--no_error_for_non_source_file', action='store_false',
                    default='True',
                    dest='error_for_non_source_file',
                    help='Causes the script to simply print a warning on '
                    'encountering a non-source file rather than raising an '
                    'error.')
  opts, args = parser.parse_args()

  if len(args) < 2:
    parser.print_help()
    return 1

  from_paths = args[:len(args)-1]
  orig_to_path = args[-1]

  if len(from_paths) > 1 and not os.path.isdir(orig_to_path):
    print 'Target %s is not a directory.' % orig_to_path
    print
    parser.print_help()
    return 1

  for from_path in from_paths:
    if not opts.error_for_non_source_file and not IsHandledFile(from_path):
      print '%s does not appear to be a source file, skipping' % (from_path)
      continue
    to_path = MakeDestinationPath(from_path, orig_to_path)
    if not opts.already_moved:
      MoveFile(from_path, to_path)
    UpdatePostMove(from_path, to_path)
  return 0


if __name__ == '__main__':
  sys.exit(main())
