#!/usr/bin/python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script can either source a file and dump the enironment changes done by
# it, or just simply dump the current environment as JSON into a file.

import json
import optparse
import os
import pipes
import subprocess
import sys


def main():
  parser = optparse.OptionParser()
  parser.add_option('-f', '--output-json',
                    help='File to dump the environment as JSON into.')
  parser.add_option(
      '-d', '--dump-mode', action='store_true',
      help='Dump the environment to sys.stdout and exit immediately.')

  parser.disable_interspersed_args()
  options, args = parser.parse_args()
  if options.dump_mode:
    if args or options.output_json:
      parser.error('Cannot specify args or --output-json with --dump-mode.')
    json.dump(dict(os.environ), sys.stdout)
  else:
    if not options.output_json:
      parser.error('Requires --output-json option.')

    envsetup_cmd = ' '.join(map(pipes.quote, args))
    full_cmd = [
        'bash', '-c',
        '. %s > /dev/null; %s -d' % (envsetup_cmd, os.path.abspath(__file__))
    ]
    try:
      output = subprocess.check_output(full_cmd)
    except Exception as e:
      sys.exit('Error running %s and dumping environment.' % envsetup_cmd)

    env_diff = {}
    new_env = json.loads(output)
    for k, val in new_env.items():
      if k == '_' or (k in os.environ and os.environ[k] == val):
        continue
      env_diff[k] = val
    with open(options.output_json, 'w') as f:
      json.dump(env_diff, f)


if __name__ == '__main__':
  sys.exit(main())
