#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A helper module to run Legion multi-machine tests.

Example usage with 1 task machine:
$ testing/legion/tools/legion.py run  \
  --controller-isolated out/Release/example_test_controller.isolated  \
  --dimension os Ubuntu-14.04  \
  --task-name test-task-name  \
  --task task_machine out/Release/example_task_machine.isolated

Example usage with 2 task machines with the same isolated file:
$ testing/legion/tools/legion.py run  \
  --controller-isolated out/Release/example_test_controller.isolated  \
  --dimension os Ubuntu-14.04  \
  --task-name test-task-name  \
  --task task_machine_1 out/Release/example_task_machine.isolated  \
  --task task_machine_2 out/Release/example_task_machine.isolated

Example usage with 2 task machines with different isolated file:
$ testing/legion/tools/legion.py run  \
  --controller-isolated out/Release/example_test_controller.isolated  \
  --dimension os Ubuntu-14.04  \
  --task-name test-task-name  \
  --task task_machine_1 out/Release/example_task_machine_1.isolated  \
  --task task_machine_2 out/Release/example_task_machine_2.isolated
"""

import argparse
import logging
import os
import subprocess
import sys


THIS_DIR = os.path.split(__file__)[0]
SWARMING_DIR = os.path.join(THIS_DIR, '..', '..', '..', 'tools',
                            'swarming_client')
ISOLATE_PY = os.path.join(SWARMING_DIR, 'isolate.py')
SWARMING_PY = os.path.join(SWARMING_DIR, 'swarming.py')
LOGGING_LEVELS = ['DEBUG', 'INFO', 'WARNING', 'ERROR']


class Error(Exception):
  pass


def GetArgs():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('action', choices=['run', 'trigger'],
                      help='The swarming action to perform.')
  parser.add_argument('-f', '--format-only', action='store_true',
                      help='If true the .isolated files are archived but '
                      'swarming is not called, only the command line is built.')
  parser.add_argument('--controller-isolated', required=True,
                      help='The isolated file for the test controller.')
  parser.add_argument('--isolate-server', help='Optional. The isolated server '
                      'to use.')
  parser.add_argument('--swarming-server', help='Optional. The swarming server '
                      'to use.')
  parser.add_argument('--task-name', help='Optional. The swarming task name '
                      'to use.')
  parser.add_argument('--dimension', action='append', dest='dimensions',
                      nargs=2, default=[], help='Dimensions to pass to '
                      'swarming.py. This is in the form of --dimension key '
                      'value. The minimum required is --dimension os <OS>')
  parser.add_argument('--task', action='append', dest='tasks',
                      nargs=2, default=[], help='List of task names used in '
                      'the test controller. This is in the form of --task name '
                      '.isolated and is passed to the controller as --name '
                      '<ISOLATED HASH>.')
  parser.add_argument('--controller-var', action='append',
                      dest='controller_vars', nargs=2, default=[],
                      help='Command line vars to pass to the controller. These '
                      'are in the form of --controller-var name value and are '
                      'passed to the controller as --name value.')
  parser.add_argument('-v', '--verbosity', default=0, action='count')
  return parser.parse_args()


def RunCommand(cmd, stream_stdout=False):
  """Runs the command line and streams stdout if requested."""
  kwargs = {
      'args': cmd,
      'stderr': subprocess.PIPE,
      }
  if not stream_stdout:
    kwargs['stdout'] = subprocess.PIPE

  p = subprocess.Popen(**kwargs)
  stdout, stderr = p.communicate()
  if p.returncode:
    raise Error(stderr)
  if not stream_stdout:
    logging.debug(stdout)
  return stdout


def Archive(isolated, isolate_server=None):
  """Calls isolate.py archive with the given args."""
  cmd = [
      sys.executable,
      ISOLATE_PY,
      'archive',
      '--isolated', isolated,
      ]
  if isolate_server:
    cmd.extend(['--isolate-server', isolate_server])
  print ' '.join(cmd)
  return RunCommand(cmd).split()[0] # The isolated hash


def GetSwarmingCommandLine(args):
  """Builds and returns the command line for swarming.py run|trigger."""
  cmd = [
      sys.executable,
      SWARMING_PY,
      args.action,
      args.controller_isolated,
      ]
  if args.isolate_server:
    cmd.extend(['--isolate-server', args.isolate_server])
  if args.swarming_server:
    cmd.extend(['--swarming', args.swarming_server])
  if args.task_name:
    cmd.extend(['--task-name', args.task_name])
  # swarming.py dimensions
  for name, value in args.dimensions:
    cmd.extend(['--dimension', name, value])

  cmd.append('--')

  # Specify the output dir
  cmd.extend(['--output-dir', '${ISOLATED_OUTDIR}'])
  # Task name/hash values
  for name, isolated in args.tasks:
    cmd.extend(['--' + name, Archive(isolated, args.isolate_server)])
  # Test controller args
  for name, value in args.controller_vars:
    cmd.extend(['--' + name, value])
  print ' '.join(cmd)
  return cmd


def main():
  args = GetArgs()
  logging.basicConfig(
      format='%(asctime)s %(filename)s:%(lineno)s %(levelname)s] %(message)s',
      datefmt='%H:%M:%S',
      level=LOGGING_LEVELS[len(LOGGING_LEVELS)-args.verbosity-1])
  cmd = GetSwarmingCommandLine(args)
  if not args.format_only:
    RunCommand(cmd, True)
  return 0


if __name__ == '__main__':
  sys.exit(main())
