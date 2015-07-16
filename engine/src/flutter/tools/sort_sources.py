#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Given a GYP/GN filename, sort C-ish source files in that file.

Shows a diff and prompts for confirmation before doing the deed.
Works great with tools/git/for-all-touched-files.py.

Limitations:

1) Comments used as section headers

If a comment (1+ lines starting with #) appears in a source list without a
preceding blank line, the tool assumes that the comment is about the next
line. For example, given the following source list,

  sources = [
    "b.cc",
    # Comment.
    "a.cc",
    "c.cc",
  ]

the tool will produce the following output:

  sources = [
    # Comment.
    "a.cc",
    "b.cc",
    "c.cc",
  ]

This is not correct if the comment is for starting a new section like:

  sources = [
    "b.cc",
    # These are for Linux.
    "a.cc",
    "c.cc",
  ]

The tool cannot disambiguate the two types of comments. The problem can be
worked around by inserting a blank line before the comment because the tool
interprets a blank line as the end of a source list.

2) Sources commented out

Sometimes sources are commented out with their positions kept in the
alphabetical order, but what if the list is not sorted correctly? For
example, given the following source list,

  sources = [
    "a.cc",
    # "b.cc",
    "d.cc",
    "c.cc",
  ]

the tool will produce the following output:

  sources = [
    "a.cc",
    "c.cc",
    # "b.cc",
    "d.cc",
  ]

This is because the tool assumes that the comment (# "b.cc",) is about the
next line ("d.cc",). This kind of errors should be fixed manually, or the
commented-out code should be deleted.

3) " and ' are used both used in the same source list (GYP only problem)

If both " and ' are used in the same source list, sources quoted with " will
appear first in the output. The problem is rare enough so the tool does not
attempt to normalize them. Hence this kind of errors should be fixed
manually.

4) Spaces and tabs used in the same source list

Similarly, if spaces and tabs are both used in the same source list, sources
indented with tabs will appear first in the output. This kind of errors
should be fixed manually.

"""

import difflib
import optparse
import re
import sys

from yes_no import YesNo

SUFFIXES = ['c', 'cc', 'cpp', 'h', 'mm', 'rc', 'rc.version', 'ico', 'def',
            'release']
SOURCE_PATTERN = re.compile(r'^\s+[\'"].*\.(%s)[\'"],$' %
                            '|'.join([re.escape(x) for x in SUFFIXES]))
COMMENT_PATTERN = re.compile(r'^\s+#')


def SortSources(original_lines):
  """Sort source file names in |original_lines|.

  Args:
    original_lines: Lines of the original content as a list of strings.

  Returns:
    Lines of the sorted content as a list of strings.

  The algorithm is fairly naive. The code tries to find a list of C-ish
  source file names by a simple regex, then sort them. The code does not try
  to understand the syntax of the build files. See the file comment above for
  details.
  """

  output_lines = []
  comments = []
  sources = []
  for line in original_lines:
    if re.search(COMMENT_PATTERN, line):
      comments.append(line)
    elif re.search(SOURCE_PATTERN, line):
      # Associate the line with the preceding comments.
      sources.append([line, comments])
      comments = []
    else:
      # |sources| should be flushed first, to handle comments at the end of a
      # source list correctly.
      if sources:
        for source_line, source_comments in sorted(sources):
          output_lines.extend(source_comments)
          output_lines.append(source_line)
        sources = []
      if comments:
        output_lines.extend(comments)
        comments = []
      output_lines.append(line)
  return output_lines


def ProcessFile(filename, should_confirm):
  """Process the input file and rewrite if needed.

  Args:
    filename: Path to the input file.
    should_confirm: If true, diff and confirmation prompt are shown.
  """

  original_lines = []
  with open(filename, 'r') as input_file:
    for line in input_file:
      original_lines.append(line)

  new_lines = SortSources(original_lines)
  if original_lines == new_lines:
    print '%s: no change' % filename
    return

  if should_confirm:
    diff = difflib.unified_diff(original_lines, new_lines)
    sys.stdout.writelines(diff)
    if not YesNo('Use new file (y/N)'):
      return

  with open(filename, 'w') as output_file:
    output_file.writelines(new_lines)


def main():
  parser = optparse.OptionParser(usage='%prog filename1 filename2 ...')
  parser.add_option('-f', '--force', action='store_false', default=True,
                    dest='should_confirm',
                    help='Turn off confirmation prompt.')
  opts, filenames = parser.parse_args()

  if len(filenames) < 1:
    parser.print_help()
    return 1

  for filename in filenames:
    ProcessFile(filename, opts.should_confirm)


if __name__ == '__main__':
  sys.exit(main())
