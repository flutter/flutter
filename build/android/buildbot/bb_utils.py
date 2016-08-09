# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import optparse
import os
import pipes
import subprocess
import sys

import bb_annotations

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from pylib import constants


TESTING = 'BUILDBOT_TESTING' in os.environ

BB_BUILD_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), os.pardir, os.pardir, os.pardir,
    os.pardir, os.pardir, os.pardir, os.pardir))

CHROME_SRC = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', '..'))

# TODO: Figure out how to merge this with pylib.cmd_helper.OutDirectory().
CHROME_OUT_DIR = os.path.join(CHROME_SRC, 'out')

GOMA_DIR = os.environ.get('GOMA_DIR', os.path.join(BB_BUILD_DIR, 'goma'))

GSUTIL_PATH = os.path.join(BB_BUILD_DIR, 'third_party', 'gsutil', 'gsutil')

def CommandToString(command):
  """Returns quoted command that can be run in bash shell."""
  return ' '.join(map(pipes.quote, command))


def SpawnCmd(command, stdout=None, cwd=CHROME_SRC):
  """Spawn a process without waiting for termination."""
  print '>', CommandToString(command)
  sys.stdout.flush()
  if TESTING:
    class MockPopen(object):
      @staticmethod
      def wait():
        return 0
      @staticmethod
      def communicate():
        return '', ''
    return MockPopen()
  return subprocess.Popen(command, cwd=cwd, stdout=stdout)


def RunCmd(command, flunk_on_failure=True, halt_on_failure=False,
           warning_code=constants.WARNING_EXIT_CODE, stdout=None,
           cwd=CHROME_SRC):
  """Run a command relative to the chrome source root."""
  code = SpawnCmd(command, stdout, cwd).wait()
  print '<', CommandToString(command)
  if code != 0:
    print 'ERROR: process exited with code %d' % code
    if code != warning_code and flunk_on_failure:
      bb_annotations.PrintError()
    else:
      bb_annotations.PrintWarning()
    # Allow steps to have both halting (i.e. 1) and non-halting exit codes.
    if code != warning_code and halt_on_failure:
      print 'FATAL %d != %d' % (code, warning_code)
      sys.exit(1)
  return code


def GetParser():
  def ConvertJson(option, _, value, parser):
    setattr(parser.values, option.dest, json.loads(value))
  parser = optparse.OptionParser()
  parser.add_option('--build-properties', action='callback',
                    callback=ConvertJson, type='string', default={},
                    help='build properties in JSON format')
  parser.add_option('--factory-properties', action='callback',
                    callback=ConvertJson, type='string', default={},
                    help='factory properties in JSON format')
  return parser


def EncodeProperties(options):
  return ['--factory-properties=%s' % json.dumps(options.factory_properties),
          '--build-properties=%s' % json.dumps(options.build_properties)]


def RunSteps(steps, step_cmds, options):
  unknown_steps = set(steps) - set(step for step, _ in step_cmds)
  if unknown_steps:
    print >> sys.stderr, 'FATAL: Unknown steps %s' % list(unknown_steps)
    sys.exit(1)

  for step, cmd in step_cmds:
    if step in steps:
      cmd(options)
