#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A simple script to make building/testing Mojo components easier."""

import argparse
from copy import deepcopy
import logging
from multiprocessing import cpu_count
import os
import subprocess
import sys

from get_test_list import GetTestList
from mopy.config import Config
from mopy.paths import Paths
from mopy.gn import GNArgsForConfig, ParseGNConfig, CommandLineForGNArgs
from mopy.log import InitLogging


_logger = logging.getLogger()
_verbose_count = 0


def _args_to_config(args):
  # Default to host OS.
  target_os = None
  if args.android:
    target_os = Config.OS_ANDROID
  elif args.ios:
    target_os = Config.OS_IOS

  target_cpu = args.target_cpu

  additional_args = {}

  if 'clang' in args:
    additional_args['is_clang'] = args.clang

  if 'asan' in args and args.asan:
    additional_args['sanitizer'] = Config.SANITIZER_ASAN

  # Additional non-standard config entries:

  if 'goma' in args:
    goma_dir = os.environ.get('GOMA_DIR')
    goma_home_dir = os.path.join(os.getenv('HOME', ''), 'goma')
    if args.goma and goma_dir:
      additional_args['use_goma'] = True
      additional_args['goma_dir'] = goma_dir
    elif args.goma and os.path.exists(goma_home_dir):
      additional_args['use_goma'] = True
      additional_args['goma_dir'] = goma_home_dir
    else:
      additional_args['use_goma'] = False
      additional_args['goma_dir'] = None

  if 'nacl' in args:
    additional_args['use_nacl'] = args.nacl

  if not ('asan' in args and args.asan):
    go_dir = os.path.join(Paths().src_root, 'third_party', 'go', 'tool')
    if args.android:
      additional_args['mojo_use_go'] = True
      additional_args['go_build_tool'] = os.path.join(
          go_dir, 'android_arm', 'bin', 'go')
    elif target_os is None and Config.GetHostOS() == Config.OS_LINUX:
      additional_args['mojo_use_go'] = True
      additional_args['go_build_tool'] = os.path.join(
          go_dir, 'linux_amd64', 'bin', 'go')

  if 'dry_run' in args:
    additional_args['dry_run'] = args.dry_run

  if 'builder_name' in args:
    additional_args['builder_name'] = args.builder_name
  if 'build_number' in args:
    additional_args['build_number'] = args.build_number
  if 'master_name' in args:
    additional_args['master_name'] = args.master_name
  if 'test_results_server' in args:
    additional_args['test_results_server'] = args.test_results_server

  if 'gn_args' in args:
    additional_args['gn_args'] = args.gn_args

  is_debug = args.debug and not args.official

  return Config(target_os=target_os, target_cpu=target_cpu,
                is_debug=is_debug, is_official_build=args.official,
                dcheck_always_on=args.dcheck_always_on,
                is_simulator=args.simulator, **additional_args)


def _get_out_dir(config):
  """Gets the build output directory (e.g., out/Debug), relative to src, for the
  given config."""

  paths = Paths(config)
  return paths.SrcRelPath(paths.build_dir)


def _sync(config):  # pylint: disable=W0613
  """Runs gclient sync for the given config."""

  _logger.debug('_sync()')
  return subprocess.call(['gclient', 'sync'])


def _gn(config):
  """Runs gn gen for the given config."""

  _logger.debug('_gn()')

  command = ['gn', 'gen', '--check']

  gn_args = CommandLineForGNArgs(GNArgsForConfig(config))
  out_dir = _get_out_dir(config)
  command.append(out_dir)
  command.append('--args=%s' % ' '.join(gn_args))

  print 'Running %s %s ...' % (command[0],
                               ' '.join('\'%s\'' % x for x in command[1:]))
  return subprocess.call(command)


def _build(config):
  """Builds for the given config."""

  _logger.debug('_build()')

  out_dir = _get_out_dir(config)
  gn_args = ParseGNConfig(out_dir)
  print 'Building in %s ...' % out_dir
  if gn_args.get('use_goma'):
    # Use the configured goma directory.
    local_goma_dir = gn_args.get('goma_dir')
    print 'Ensuring goma (in %s) started ...' % local_goma_dir
    command = ['python',
               os.path.join(local_goma_dir, 'goma_ctl.py'),
               'ensure_start']
    exit_code = subprocess.call(command)
    if exit_code:
      return exit_code

    # Goma allows us to run many more jobs in parallel, say 32 per core/thread
    # (= 1024 on a 16-core, 32-thread Z620). Limit the load average to 4 per
    # core/thread (= 128 on said Z620).
    jobs = cpu_count() * 32
    limit = cpu_count() * 4
    return subprocess.call(['ninja', '-j', str(jobs), '-l', str(limit),
                            '-C', out_dir])
  else:
    return subprocess.call(['ninja', '-C', out_dir])


def _run_tests(config, test_types):
  """Runs the tests of the given type(s) for the given config."""

  assert isinstance(test_types, list)
  config = deepcopy(config)
  config.values['test_types'] = test_types

  test_list = GetTestList(config, verbose_count=_verbose_count)
  dry_run = config.values.get('dry_run')
  final_exit_code = 0
  failure_list = []
  for entry in test_list:
    print 'Running: %s' % entry['name']
    print 'Command: %s' % ' '.join(entry['command'])
    if dry_run:
      continue

    _logger.info('Starting: %s' % ' '.join(entry['command']))
    exit_code = subprocess.call(entry['command'])
    _logger.info('Completed: %s' % ' '.join(entry['command']))
    if exit_code:
      if not final_exit_code:
        final_exit_code = exit_code
      failure_list.append(entry['name'])

  print 72 * '='
  print 'SUMMARY:',
  if dry_run:
    print 'Dry run: no tests run'
  elif not failure_list:
    assert not final_exit_code
    print 'All tests passed'
  else:
    assert final_exit_code
    print 'The following had failures:', ', '.join(failure_list)

  return final_exit_code


def _test(config):
  _logger.debug('_test()')
  return _run_tests(config, [Config.TEST_TYPE_DEFAULT])


def _perftest(config):
  _logger.debug('_perftest()')
  return _run_tests(config, [Config.TEST_TYPE_PERF])


def _pytest(config):
  _logger.debug('_pytest()')
  return _run_tests(config, ['python'])


def main():
  os.chdir(Paths().src_root)

  parser = argparse.ArgumentParser(description='A script to make building'
      '/testing Mojo components easier.')

  parent_parser = argparse.ArgumentParser(add_help=False)

  parent_parser.add_argument('--verbose',
                             help='Be verbose (multiple times for more)',
                             default=0, dest='verbose_count', action='count')

  parent_parser.add_argument('--asan', help='Use Address Sanitizer',
                             action='store_true')
  parent_parser.add_argument('--dcheck_always_on',
                             help='DCHECK and MOJO_DCHECK are fatal even in '
                             'release builds',
                             action='store_true')

  debug_group = parent_parser.add_mutually_exclusive_group()
  debug_group.add_argument('--debug', help='Debug build (default)',
                           default=True, action='store_true')
  debug_group.add_argument('--release', help='Release build', default=False,
                           dest='debug', action='store_false')
  # The official build is a release build suitable for distribution, with a
  # different package name.
  debug_group.add_argument('--official', help='Official build', default=False,
                           dest='official', action='store_true')

  os_group = parent_parser.add_mutually_exclusive_group()
  os_group.add_argument('--android', help='Build for Android',
                        action='store_true')
  os_group.add_argument('--ios', help='Build for iOS',
                        action='store_true')

  parent_parser.add_argument('--simulator',
                             help='Build for a simulator of the target',
                             action='store_true')

  parent_parser.add_argument('--target-cpu',
                             help='CPU architecture to build for.',
                             choices=['x64', 'x86', 'arm'])

  subparsers = parser.add_subparsers()

  sync_parser = subparsers.add_parser('sync', parents=[parent_parser],
      help='Sync using gclient (does not run gn).')
  sync_parser.set_defaults(func=_sync)

  gn_parser = subparsers.add_parser('gn', parents=[parent_parser],
                                    help='Run gn for mojo (does not sync).')
  gn_parser.set_defaults(func=_gn)
  gn_parser.add_argument('--args', help='Specify extra args',
                         default=None, dest='gn_args')
  # Note: no default, if nothing is specified on the command line GN decides.
  gn_parser.add_argument('--nacl', help='Add in NaCl', action='store_true',
                         default=argparse.SUPPRESS)
  gn_parser.add_argument('--no-nacl', help='Remove NaCl', action='store_false',
                         default=argparse.SUPPRESS, dest='nacl')

  clang_group = gn_parser.add_mutually_exclusive_group()
  clang_group.add_argument('--clang', help='Use Clang (default)', default=None,
                           action='store_true')
  clang_group.add_argument('--gcc', help='Use GCC',
                           dest='clang', action='store_false')
  goma_group = gn_parser.add_mutually_exclusive_group()
  goma_group.add_argument('--goma',
                          help='Use Goma (if $GOMA_DIR is set or $HOME/goma '
                               'exists; default)',
                          default=True,
                          action='store_true')
  goma_group.add_argument('--no-goma', help='Don\'t use Goma', default=False,
                          dest='goma', action='store_false')

  build_parser = subparsers.add_parser('build', parents=[parent_parser],
                                       help='Build')
  build_parser.set_defaults(func=_build)

  test_parser = subparsers.add_parser('test', parents=[parent_parser],
                                      help='Run unit tests (does not build).')
  test_parser.set_defaults(func=_test)
  test_parser.add_argument('--dry-run',
                           help='Print instead of executing commands',
                           default=False, action='store_true')

  perftest_parser = subparsers.add_parser('perftest', parents=[parent_parser],
      help='Run perf tests (does not build).')
  perftest_parser.set_defaults(func=_perftest)

  pytest_parser = subparsers.add_parser('pytest', parents=[parent_parser],
      help='Run Python unit tests (does not build).')
  pytest_parser.set_defaults(func=_pytest)

  args = parser.parse_args()
  global _verbose_count
  _verbose_count = args.verbose_count
  InitLogging(_verbose_count)

  if args.simulator and not args.ios:
    sys.exit("Currently, the simulator target is only configured for iOS")

  return args.func(_args_to_config(args))


if __name__ == '__main__':
  sys.exit(main())
