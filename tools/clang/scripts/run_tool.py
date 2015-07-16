#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Wrapper script to help run clang tools across Chromium code.

How to use this tool:
If you want to run the tool across all Chromium code:
run_tool.py <tool> <path/to/compiledb>

If you want to include all files mentioned in the compilation database:
run_tool.py <tool> <path/to/compiledb> --all

If you only want to run the tool across just chrome/browser and content/browser:
run_tool.py <tool> <path/to/compiledb> chrome/browser content/browser

Please see https://code.google.com/p/chromium/wiki/ClangToolRefactoring for more
information, which documents the entire automated refactoring flow in Chromium.

Why use this tool:
The clang tool implementation doesn't take advantage of multiple cores, and if
it fails mysteriously in the middle, all the generated replacements will be
lost.

Unfortunately, if the work is simply sharded across multiple cores by running
multiple RefactoringTools, problems arise when they attempt to rewrite a file at
the same time. To work around that, clang tools that are run using this tool
should output edits to stdout in the following format:

==== BEGIN EDITS ====
r:<file path>:<offset>:<length>:<replacement text>
r:<file path>:<offset>:<length>:<replacement text>
...etc...
==== END EDITS ====

Any generated edits are applied once the clang tool has finished running
across Chromium, regardless of whether some instances failed or not.
"""

import collections
import functools
import json
import multiprocessing
import os.path
import pipes
import subprocess
import sys


Edit = collections.namedtuple(
    'Edit', ('edit_type', 'offset', 'length', 'replacement'))


def _GetFilesFromGit(paths = None):
  """Gets the list of files in the git repository.

  Args:
    paths: Prefix filter for the returned paths. May contain multiple entries.
  """
  args = []
  if sys.platform == 'win32':
    args.append('git.bat')
  else:
    args.append('git')
  args.append('ls-files')
  if paths:
    args.extend(paths)
  command = subprocess.Popen(args, stdout=subprocess.PIPE)
  output, _ = command.communicate()
  return [os.path.realpath(p) for p in output.splitlines()]


def _GetFilesFromCompileDB(build_directory):
  """ Gets the list of files mentioned in the compilation database.

  Args:
    build_directory: Directory that contains the compile database.
  """
  compiledb_path = os.path.join(build_directory, 'compile_commands.json')
  with open(compiledb_path, 'rb') as compiledb_file:
    json_commands = json.load(compiledb_file)

  return [os.path.join(entry['directory'], entry['file'])
          for entry in json_commands]


def _ExtractEditsFromStdout(build_directory, stdout):
  """Extracts generated list of edits from the tool's stdout.

  The expected format is documented at the top of this file.

  Args:
    build_directory: Directory that contains the compile database. Used to
      normalize the filenames.
    stdout: The stdout from running the clang tool.

  Returns:
    A dictionary mapping filenames to the associated edits.
  """
  lines = stdout.splitlines()
  start_index = lines.index('==== BEGIN EDITS ====')
  end_index = lines.index('==== END EDITS ====')
  edits = collections.defaultdict(list)
  for line in lines[start_index + 1:end_index]:
    try:
      edit_type, path, offset, length, replacement = line.split(':::', 4)
      replacement = replacement.replace("\0", "\n");
      # Normalize the file path emitted by the clang tool.
      path = os.path.realpath(os.path.join(build_directory, path))
      edits[path].append(Edit(edit_type, int(offset), int(length), replacement))
    except ValueError:
      print 'Unable to parse edit: %s' % line
  return edits


def _ExecuteTool(toolname, build_directory, filename):
  """Executes the tool.

  This is defined outside the class so it can be pickled for the multiprocessing
  module.

  Args:
    toolname: Path to the tool to execute.
    build_directory: Directory that contains the compile database.
    filename: The file to run the tool over.

  Returns:
    A dictionary that must contain the key "status" and a boolean value
    associated with it.

    If status is True, then the generated edits are stored with the key "edits"
    in the dictionary.

    Otherwise, the filename and the output from stderr are associated with the
    keys "filename" and "stderr" respectively.
  """
  command = subprocess.Popen((toolname, '-p', build_directory, filename),
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
  stdout, stderr = command.communicate()
  if command.returncode != 0:
    return {'status': False, 'filename': filename, 'stderr': stderr}
  else:
    return {'status': True,
            'edits': _ExtractEditsFromStdout(build_directory, stdout)}


class _CompilerDispatcher(object):
  """Multiprocessing controller for running clang tools in parallel."""

  def __init__(self, toolname, build_directory, filenames):
    """Initializer method.

    Args:
      toolname: Path to the tool to execute.
      build_directory: Directory that contains the compile database.
      filenames: The files to run the tool over.
    """
    self.__toolname = toolname
    self.__build_directory = build_directory
    self.__filenames = filenames
    self.__success_count = 0
    self.__failed_count = 0
    self.__edit_count = 0
    self.__edits = collections.defaultdict(list)

  @property
  def edits(self):
    return self.__edits

  @property
  def failed_count(self):
    return self.__failed_count

  def Run(self):
    """Does the grunt work."""
    pool = multiprocessing.Pool()
    result_iterator = pool.imap_unordered(
        functools.partial(_ExecuteTool, self.__toolname,
                          self.__build_directory),
        self.__filenames)
    for result in result_iterator:
      self.__ProcessResult(result)
    sys.stdout.write('\n')
    sys.stdout.flush()

  def __ProcessResult(self, result):
    """Handles result processing.

    Args:
      result: The result dictionary returned by _ExecuteTool.
    """
    if result['status']:
      self.__success_count += 1
      for k, v in result['edits'].iteritems():
        self.__edits[k].extend(v)
        self.__edit_count += len(v)
    else:
      self.__failed_count += 1
      sys.stdout.write('\nFailed to process %s\n' % result['filename'])
      sys.stdout.write(result['stderr'])
      sys.stdout.write('\n')
    percentage = (
        float(self.__success_count + self.__failed_count) /
        len(self.__filenames)) * 100
    sys.stdout.write('Succeeded: %d, Failed: %d, Edits: %d [%.2f%%]\r' % (
        self.__success_count, self.__failed_count, self.__edit_count,
        percentage))
    sys.stdout.flush()


def _ApplyEdits(edits, clang_format_diff_path):
  """Apply the generated edits.

  Args:
    edits: A dict mapping filenames to Edit instances that apply to that file.
    clang_format_diff_path: Path to the clang-format-diff.py helper to help
      automatically reformat diffs to avoid style violations. Pass None if the
      clang-format step should be skipped.
  """
  edit_count = 0
  for k, v in edits.iteritems():
    # Sort the edits and iterate through them in reverse order. Sorting allows
    # duplicate edits to be quickly skipped, while reversing means that
    # subsequent edits don't need to have their offsets updated with each edit
    # applied.
    v.sort()
    last_edit = None
    with open(k, 'rb+') as f:
      contents = bytearray(f.read())
      for edit in reversed(v):
        if edit == last_edit:
          continue
        last_edit = edit
        contents[edit.offset:edit.offset + edit.length] = edit.replacement
        if not edit.replacement:
          _ExtendDeletionIfElementIsInList(contents, edit.offset)
        edit_count += 1
      f.seek(0)
      f.truncate()
      f.write(contents)
    if clang_format_diff_path:
      # TODO(dcheng): python3.3 exposes this publicly as shlex.quote, but Chrome
      # uses python2.7. Use the deprecated interface until Chrome uses a newer
      # Python.
      if subprocess.call('git diff -U0 %s | python %s -i -p1 -style=file ' % (
          pipes.quote(k), clang_format_diff_path), shell=True) != 0:
        print 'clang-format failed for %s' % k
  print 'Applied %d edits to %d files' % (edit_count, len(edits))


_WHITESPACE_BYTES = frozenset((ord('\t'), ord('\n'), ord('\r'), ord(' ')))


def _ExtendDeletionIfElementIsInList(contents, offset):
  """Extends the range of a deletion if the deleted element was part of a list.

  This rewriter helper makes it easy for refactoring tools to remove elements
  from a list. Even if a matcher callback knows that it is removing an element
  from a list, it may not have enough information to accurately remove the list
  element; for example, another matcher callback may end up removing an adjacent
  list element, or all the list elements may end up being removed.

  With this helper, refactoring tools can simply remove the list element and not
  worry about having to include the comma in the replacement.

  Args:
    contents: A bytearray with the deletion already applied.
    offset: The offset in the bytearray where the deleted range used to be.
  """
  char_before = char_after = None
  left_trim_count = 0
  for byte in reversed(contents[:offset]):
    left_trim_count += 1
    if byte in _WHITESPACE_BYTES:
      continue
    if byte in (ord(','), ord(':'), ord('('), ord('{')):
      char_before = chr(byte)
    break

  right_trim_count = 0
  for byte in contents[offset:]:
    right_trim_count += 1
    if byte in _WHITESPACE_BYTES:
      continue
    if byte == ord(','):
      char_after = chr(byte)
    break

  if char_before:
    if char_after:
      del contents[offset:offset + right_trim_count]
    elif char_before in (',', ':'):
      del contents[offset - left_trim_count:offset]


def main(argv):
  if len(argv) < 2:
    print 'Usage: run_tool.py <clang tool> <compile DB> <path 1> <path 2> ...'
    print '  <clang tool> is the clang tool that should be run.'
    print '  <compile db> is the directory that contains the compile database'
    print '  <path 1> <path2> ... can be used to filter what files are edited'
    return 1

  clang_format_diff_path = os.path.join(
      os.path.dirname(os.path.realpath(__file__)),
      '../../../third_party/llvm/tools/clang/tools/clang-format',
      'clang-format-diff.py')
  # TODO(dcheng): Allow this to be controlled with a flag as well.
  # TODO(dcheng): Shell escaping of args to git diff to clang-format is broken
  # on Windows.
  if not os.path.isfile(clang_format_diff_path) or sys.platform == 'win32':
    clang_format_diff_path = None

  if len(argv) == 3 and argv[2] == '--all':
    filenames = set(_GetFilesFromCompileDB(argv[1]))
    source_filenames = filenames
  else:
    filenames = set(_GetFilesFromGit(argv[2:]))
    # Filter out files that aren't C/C++/Obj-C/Obj-C++.
    extensions = frozenset(('.c', '.cc', '.m', '.mm'))
    source_filenames = [f for f in filenames
                        if os.path.splitext(f)[1] in extensions]
  dispatcher = _CompilerDispatcher(argv[0], argv[1], source_filenames)
  dispatcher.Run()
  # Filter out edits to files that aren't in the git repository, since it's not
  # useful to modify files that aren't under source control--typically, these
  # are generated files or files in a git submodule that's not part of Chromium.
  _ApplyEdits({k : v for k, v in dispatcher.edits.iteritems()
                    if os.path.realpath(k) in filenames},
              clang_format_diff_path)
  if dispatcher.failed_count != 0:
    return 2
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
