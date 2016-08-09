#!/usr/bin/env python
#
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import collections
import copy
import json
import os
import pipes
import re
import subprocess
import sys

import bb_utils

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from pylib import constants


CHROMIUM_COVERAGE_BUCKET = 'chromium-code-coverage'

_BotConfig = collections.namedtuple(
    'BotConfig', ['bot_id', 'host_obj', 'test_obj'])

HostConfig = collections.namedtuple(
    'HostConfig',
    ['script', 'host_steps', 'extra_args', 'extra_gyp_defines', 'target_arch'])

TestConfig = collections.namedtuple('Tests', ['script', 'tests', 'extra_args'])


def BotConfig(bot_id, host_object, test_object=None):
  return _BotConfig(bot_id, host_object, test_object)


def DictDiff(d1, d2):
  diff = []
  for key in sorted(set(d1.keys() + d2.keys())):
    if key in d1 and d1[key] != d2.get(key):
      diff.append('- %s=%s' % (key, pipes.quote(d1[key])))
    if key in d2 and d2[key] != d1.get(key):
      diff.append('+ %s=%s' % (key, pipes.quote(d2[key])))
  return '\n'.join(diff)


def GetEnvironment(host_obj, testing, extra_env_vars=None):
  init_env = dict(os.environ)
  init_env['GYP_GENERATORS'] = 'ninja'
  if extra_env_vars:
    init_env.update(extra_env_vars)
  envsetup_cmd = '. build/android/envsetup.sh'
  if testing:
    # Skip envsetup to avoid presubmit dependence on android deps.
    print 'Testing mode - skipping "%s"' % envsetup_cmd
    envsetup_cmd = ':'
  else:
    print 'Running %s' % envsetup_cmd
  proc = subprocess.Popen(['bash', '-exc',
    envsetup_cmd + ' >&2; python build/android/buildbot/env_to_json.py'],
    stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    cwd=bb_utils.CHROME_SRC, env=init_env)
  json_env, envsetup_output = proc.communicate()
  if proc.returncode != 0:
    print >> sys.stderr, 'FATAL Failure in envsetup.'
    print >> sys.stderr, envsetup_output
    sys.exit(1)
  env = json.loads(json_env)
  env['GYP_DEFINES'] = env.get('GYP_DEFINES', '') + \
      ' OS=android fastbuild=1 use_goma=1 gomadir=%s' % bb_utils.GOMA_DIR
  if host_obj.target_arch:
    env['GYP_DEFINES'] += ' target_arch=%s' % host_obj.target_arch
  extra_gyp = host_obj.extra_gyp_defines
  if extra_gyp:
    env['GYP_DEFINES'] += ' %s' % extra_gyp
    if re.search('(asan|clang)=1', extra_gyp):
      env.pop('CXX_target', None)

  # Bots checkout chrome in /b/build/slave/<name>/build/src
  build_internal_android = os.path.abspath(os.path.join(
      bb_utils.CHROME_SRC, '..', '..', '..', '..', '..', 'build_internal',
      'scripts', 'slave', 'android'))
  if os.path.exists(build_internal_android):
    env['PATH'] = os.pathsep.join([build_internal_android, env['PATH']])
  return env


def GetCommands(options, bot_config):
  """Get a formatted list of commands.

  Args:
    options: Options object.
    bot_config: A BotConfig named tuple.
    host_step_script: Host step script.
    device_step_script: Device step script.
  Returns:
    list of Command objects.
  """
  property_args = bb_utils.EncodeProperties(options)
  commands = [[bot_config.host_obj.script,
               '--steps=%s' % ','.join(bot_config.host_obj.host_steps)] +
              property_args + (bot_config.host_obj.extra_args or [])]

  test_obj = bot_config.test_obj
  if test_obj:
    run_test_cmd = [test_obj.script] + property_args
    for test in test_obj.tests:
      run_test_cmd.extend(['-f', test])
    if test_obj.extra_args:
      run_test_cmd.extend(test_obj.extra_args)
    commands.append(run_test_cmd)
  return commands


def GetBotStepMap():
  compile_step = ['compile']
  chrome_proxy_tests = ['chrome_proxy']
  python_unittests = ['python_unittests']
  std_host_tests = ['check_webview_licenses']
  std_build_steps = ['compile', 'zip_build']
  std_test_steps = ['extract_build']
  std_tests = ['ui', 'unit']
  telemetry_tests = ['telemetry_perf_unittests']
  telemetry_tests_user_build = ['telemetry_unittests',
                                'telemetry_perf_unittests']
  trial_tests = [
      'base_junit_tests',
      'components_browsertests',
      'gfx_unittests',
      'gl_unittests',
  ]
  flakiness_server = (
      '--flakiness-server=%s' % constants.UPSTREAM_FLAKINESS_SERVER)
  experimental = ['--experimental']
  bisect_chrome_output_dir = os.path.abspath(
      os.path.join(os.path.dirname(__file__), os.pardir, os.pardir, os.pardir,
                   os.pardir, 'bisect', 'src', 'out'))
  B = BotConfig
  H = (lambda steps, extra_args=None, extra_gyp=None, target_arch=None:
       HostConfig('build/android/buildbot/bb_host_steps.py', steps, extra_args,
                  extra_gyp, target_arch))
  T = (lambda tests, extra_args=None:
       TestConfig('build/android/buildbot/bb_device_steps.py', tests,
                  extra_args))

  bot_configs = [
      # Main builders
      B('main-builder-dbg', H(std_build_steps + std_host_tests)),
      B('main-builder-rel', H(std_build_steps)),
      B('main-clang-builder',
        H(compile_step, extra_gyp='clang=1 component=shared_library')),
      B('main-clobber', H(compile_step)),
      B('main-tests-rel', H(std_test_steps),
        T(std_tests + telemetry_tests + chrome_proxy_tests,
          ['--cleanup', flakiness_server])),
      B('main-tests', H(std_test_steps),
        T(std_tests, ['--cleanup', flakiness_server])),

      # Other waterfalls
      B('asan-builder-tests', H(compile_step,
                                extra_gyp='asan=1 component=shared_library'),
        T(std_tests, ['--asan', '--asan-symbolize'])),
      B('blink-try-builder', H(compile_step)),
      B('chromedriver-fyi-tests-dbg', H(std_test_steps),
        T(['chromedriver'],
          ['--install=ChromeShell', '--install=ChromeDriverWebViewShell',
           '--skip-wipe', '--disable-location', '--cleanup'])),
      B('fyi-x86-builder-dbg',
        H(compile_step + std_host_tests, experimental, target_arch='ia32')),
      B('fyi-builder-dbg',
        H(std_build_steps + std_host_tests, experimental,
          extra_gyp='emma_coverage=1')),
      B('x86-builder-dbg',
        H(compile_step + std_host_tests, target_arch='ia32')),
      B('fyi-builder-rel', H(std_build_steps, experimental)),
      B('fyi-tests', H(std_test_steps),
        T(std_tests + python_unittests,
                      ['--experimental', flakiness_server,
                      '--coverage-bucket', CHROMIUM_COVERAGE_BUCKET,
                      '--cleanup'])),
      B('user-build-fyi-tests-dbg', H(std_test_steps),
        T(sorted(telemetry_tests_user_build + trial_tests))),
      B('fyi-component-builder-tests-dbg',
        H(compile_step, extra_gyp='component=shared_library'),
        T(std_tests, ['--experimental', flakiness_server])),
      B('gpu-builder-tests-dbg',
        H(compile_step),
        T(['gpu'], ['--install=ContentShell'])),
      # Pass empty T([]) so that logcat monitor and device status check are run.
      B('perf-bisect-builder-tests-dbg',
        H(['bisect_perf_regression']),
        T([], ['--chrome-output-dir', bisect_chrome_output_dir])),
      B('perf-tests-rel', H(std_test_steps),
        T([], ['--install=ChromeShell', '--cleanup'])),
      B('webkit-latest-webkit-tests', H(std_test_steps),
        T(['webkit_layout', 'webkit'], ['--cleanup', '--auto-reconnect'])),
      B('webkit-latest-contentshell', H(compile_step),
        T(['webkit_layout'], ['--auto-reconnect'])),
      B('builder-unit-tests', H(compile_step), T(['unit'])),

      # Generic builder config (for substring match).
      B('builder', H(std_build_steps)),
  ]

  bot_map = dict((config.bot_id, config) for config in bot_configs)

  # These bots have identical configuration to ones defined earlier.
  copy_map = [
      ('lkgr-clobber', 'main-clobber'),
      ('try-builder-dbg', 'main-builder-dbg'),
      ('try-builder-rel', 'main-builder-rel'),
      ('try-clang-builder', 'main-clang-builder'),
      ('try-fyi-builder-dbg', 'fyi-builder-dbg'),
      ('try-x86-builder-dbg', 'x86-builder-dbg'),
      ('try-tests-rel', 'main-tests-rel'),
      ('try-tests', 'main-tests'),
      ('try-fyi-tests', 'fyi-tests'),
      ('webkit-latest-tests', 'main-tests'),
  ]
  for to_id, from_id in copy_map:
    assert to_id not in bot_map
    # pylint: disable=W0212
    bot_map[to_id] = copy.deepcopy(bot_map[from_id])._replace(bot_id=to_id)

    # Trybots do not upload to flakiness dashboard. They should be otherwise
    # identical in configuration to their trunk building counterparts.
    test_obj = bot_map[to_id].test_obj
    if to_id.startswith('try') and test_obj:
      extra_args = test_obj.extra_args
      if extra_args and flakiness_server in extra_args:
        extra_args.remove(flakiness_server)
  return bot_map


# Return an object from the map, looking first for an exact id match.
# If this fails, look for an id which is a substring of the specified id.
# Choose the longest of all substring matches.
# pylint: disable=W0622
def GetBestMatch(id_map, id):
  config = id_map.get(id)
  if not config:
    substring_matches = [x for x in id_map.iterkeys() if x in id]
    if substring_matches:
      max_id = max(substring_matches, key=len)
      print 'Using config from id="%s" (substring match).' % max_id
      config = id_map[max_id]
  return config


def GetRunBotOptParser():
  parser = bb_utils.GetParser()
  parser.add_option('--bot-id', help='Specify bot id directly.')
  parser.add_option('--testing', action='store_true',
                    help='For testing: print, but do not run commands')

  return parser


def GetBotConfig(options, bot_step_map):
  bot_id = options.bot_id or options.factory_properties.get('android_bot_id')
  if not bot_id:
    print (sys.stderr,
           'A bot id must be specified through option or factory_props.')
    return

  bot_config = GetBestMatch(bot_step_map, bot_id)
  if not bot_config:
    print 'Error: config for id="%s" cannot be inferred.' % bot_id
  return bot_config


def RunBotCommands(options, commands, env):
  print 'Environment changes:'
  print DictDiff(dict(os.environ), env)

  for command in commands:
    print bb_utils.CommandToString(command)
    sys.stdout.flush()
    if options.testing:
      env['BUILDBOT_TESTING'] = '1'
    return_code = subprocess.call(command, cwd=bb_utils.CHROME_SRC, env=env)
    if return_code != 0:
      return return_code


def main(argv):
  proc = subprocess.Popen(
      ['/bin/hostname', '-f'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  hostname_stdout, hostname_stderr = proc.communicate()
  if proc.returncode == 0:
    print 'Running on: ' + hostname_stdout
  else:
    print >> sys.stderr, 'WARNING: failed to run hostname'
    print >> sys.stderr, hostname_stdout
    print >> sys.stderr, hostname_stderr
    sys.exit(1)

  parser = GetRunBotOptParser()
  options, args = parser.parse_args(argv[1:])
  if args:
    parser.error('Unused args: %s' % args)

  bot_config = GetBotConfig(options, GetBotStepMap())
  if not bot_config:
    sys.exit(1)

  print 'Using config:', bot_config

  commands = GetCommands(options, bot_config)
  for command in commands:
    print 'Will run: ', bb_utils.CommandToString(command)
  print

  env = GetEnvironment(bot_config.host_obj, options.testing)
  return RunBotCommands(options, commands, env)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
