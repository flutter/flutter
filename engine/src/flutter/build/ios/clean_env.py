#!/usr/bin/python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys

def Main(argv):
  """This is like 'env -i', but it uses a whitelist of env variables to allow
  through to the command being run.  It attempts to strip off Xcode-added
  values from PATH.
  """
  # Note: An attempt was made to do something like: env -i bash -lc '[command]'
  # but that fails to set the things set by login (USER, etc.), so instead
  # the only approach that seems to work is to have a whitelist.
  env_key_whitelist = (
    'HOME',
    'LOGNAME',
    # 'PATH' added below (but filtered).
    'PWD',
    'SHELL',
    'TEMP',
    'TMPDIR',
    'USER'
  )

  # Need something to run.
  # TODO(lliabraa): Make this output a usage string and exit (here and below).
  assert(len(argv) > 0)

  add_to_path = [];
  first_entry = argv[0];
  if first_entry.startswith('ADD_TO_PATH='):
    argv = argv[1:];
    add_to_path = first_entry.replace('ADD_TO_PATH=', '', 1).split(':')

  # Still need something to run.
  assert(len(argv) > 0)

  clean_env = {}

  # Pull over the whitelisted keys.
  for key in env_key_whitelist:
    val = os.environ.get(key, None)
    if not val is None:
      clean_env[key] = val

  # Collect the developer dir as set via Xcode, defaulting it.
  dev_prefix = os.environ.get('DEVELOPER_DIR', '/Developer/')
  if dev_prefix[-1:] != '/':
    dev_prefix += '/'

  # Now pull in PATH, but remove anything Xcode might have added.
  initial_path = os.environ.get('PATH', '')
  filtered_chunks = \
      [x for x in initial_path.split(':') if not x.startswith(dev_prefix)]
  if filtered_chunks:
    clean_env['PATH'] = ':'.join(add_to_path + filtered_chunks)

  # Add any KEY=VALUE args before the command to the cleaned environment.
  args = argv[:]
  while '=' in args[0]:
    (key, val) = args[0].split('=', 1)
    clean_env[key] = val
    args = args[1:]

  # Still need something to run.
  assert(len(args) > 0)

  # Off it goes...
  os.execvpe(args[0], args, clean_env)
  # Should never get here, so return a distinctive, non-zero status code.
  return 66

if __name__ == '__main__':
  sys.exit(Main(sys.argv[1:]))
