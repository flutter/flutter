#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Clang tools on Windows are still a bit busted. The tooling can't handle
backslashes in paths, doesn't understand how to read .rsp files, etc. In
addition, ninja generates compile commands prefixed with the ninja msvc helper,
which also confuses clang. This script generates a compile DB that should mostly
work until clang tooling can be improved upstream.
"""

import os
import re
import json
import shlex
import subprocess
import sys


_NINJA_MSVC_WRAPPER = re.compile('ninja -t msvc -e .+? -- ')
_RSP_RE = re.compile(r' (@(.+?\.rsp)) ')


def _ProcessEntry(e):
  # Strip off the ninja -t msvc wrapper.
  e['command'] = _NINJA_MSVC_WRAPPER.sub('', e['command'])

  # Prepend --driver-mode=cl to the command's arguments.
  # Escape backslashes so shlex doesn't try to interpret them.
  escaped_command = e['command'].replace('\\', '\\\\')
  split_command = shlex.split(escaped_command)
  e['command'] = ' '.join(
      split_command[:1] + ['--driver-mode=cl'] + split_command[1:])

  # Expand the contents of the response file, if any.
  # http://llvm.org/bugs/show_bug.cgi?id=21634
  try:
    match = _RSP_RE.search(e['command'])
    rsp_path = os.path.join(e['directory'], match.group(2))
    rsp_contents = file(rsp_path).read()
    e['command'] = ''.join([
        e['command'][:match.start(1)],
        rsp_contents,
        e['command'][match.end(1):]])
  except IOError:
    pass

  # TODO(dcheng): This should be implemented in Clang tooling.
  # http://llvm.org/bugs/show_bug.cgi?id=19687
  # Finally, use slashes instead of backslashes to avoid bad escaping by the
  # tooling. This should really only matter for command, but we do it for all
  # keys for consistency.
  e['directory'] = e['directory'].replace('\\', '/')
  e['command'] = e['command'].replace('\\', '/')
  e['file'] = e['file'].replace('\\', '/')

  return e


def main(argv):
  # First, generate the compile database.
  print 'Generating compile DB with ninja...'
  compile_db_as_json = subprocess.check_output(shlex.split(
      'ninja -C out/Debug -t compdb cc cxx objc objcxx'))

  compile_db = json.loads(compile_db_as_json)
  print 'Read in %d entries from the compile db' % len(compile_db)
  compile_db = [_ProcessEntry(e) for e in compile_db]
  original_length = len(compile_db)

  # Filter out NaCl stuff. The clang tooling chokes on them.
  compile_db = [e for e in compile_db if '_nacl.cc.pdb' not in e['command']
      and '_nacl_win64.cc.pdb' not in e['command']]
  print 'Filtered out %d entries...' % (original_length - len(compile_db))
  f = file('out/Debug/compile_commands.json', 'w')
  f.write(json.dumps(compile_db, indent=2))
  print 'Done!'


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
