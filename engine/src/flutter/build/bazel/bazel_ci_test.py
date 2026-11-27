#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests of bazel_ci.py: the match of tools/gn flags against the builds table, the files.

Run from this directory: `python3 bazel_ci_test.py`; CI runs it as
//engine/src/flutter/build/bazel:bazel_ci_test.
"""

import collections
import contextlib
import io
import json
import os
import re
import stat
import sys
import tempfile
import unittest
import unittest.mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bazel_ci  # pylint: disable=wrong-import-position

HOST_DEBUG_UNOPT = {
    'file': 'linux_unopt.json',
    'name': 'ci/host_debug_unopt',
    'gn': [
        '--target-dir', 'ci/host_debug_unopt', '--runtime-mode', 'debug', '--unoptimized',
        '--prebuilt-dart-sdk', '--asan', '--dart-debug', '--rbe', '--no-goma'
    ],
    'build_directory': 'ci/host_debug_unopt',
    'config': 'ci_host_debug_unopt',
    'unsupported': [],
    'install': '//engine/src/flutter/ci/builders:ci_host_debug_unopt',
    'ninja_targets': ['flutter/tools/font_subset', 'flutter:unittests', 'sky_engine'],
    'ninja_targets_not_built': [],
    'ninja_targets_tested': [],
    'tests': {
        'suite': '//engine/src/flutter/ci/builders:ci_host_debug_unopt_tests',
        'types': {
            'dart': ['//engine/src/flutter/testing/dart:dart'],
            'engine': [
                '//engine/src/flutter/fml:fml_unittests', '//engine/src/flutter/flow:flow_unittests'
            ],
        },
        'binaries': [],
        'scripts': ['//engine/src/flutter:gn_test'],
        'missing': ['the benchmarks type'],
    },
}

# The same directory, other flags (linux_unopt.json's host_debug_no_prebuilt_dart_sdk
# shares ci/host_debug with linux_host_engine.json's ci/host_debug).
HOST_DEBUG = {
    **HOST_DEBUG_UNOPT,
    'file': 'linux_host_engine.json',
    'name': 'ci/host_debug',
    'gn': [
        '--target-dir', 'ci/host_debug', '--runtime-mode', 'debug', '--no-lto', '--rbe', '--no-goma'
    ],
    'build_directory': 'ci/host_debug',
    'config': 'ci_host_debug',
    'install': '//engine/src/flutter/ci/builders:ci_host_debug',
}
HOST_DEBUG_NO_PREBUILT = {
    **HOST_DEBUG,
    'file': 'linux_unopt.json',
    'name': 'ci/host_debug_no_prebuilt_dart_sdk',
    'gn': [
        '--target-dir', 'ci/host_debug', '--runtime-mode', 'debug', '--no-prebuilt-dart-sdk',
        '--rbe'
    ],
    'config': 'host_debug_no_prebuilt_dart_sdk',
    'install': '//engine/src/flutter/ci/builders:host_debug_no_prebuilt_dart_sdk',
}
UNSUPPORTED = {
    **HOST_DEBUG,
    'name': 'ci/host_debug_fancy',
    'gn': ['--target-dir', 'ci/host_debug_fancy', '--fancy'],
    'build_directory': 'ci/host_debug_fancy',
    'config': None,
    'unsupported': ["--fancy (not in the converter's table of tools/gn flags)"],
    'install': None,
}
BUILDS = [HOST_DEBUG_UNOPT, HOST_DEBUG, HOST_DEBUG_NO_PREBUILT, UNSUPPORTED]


class NormalizedFlagsTest(unittest.TestCase):

  def test_infrastructure_flags_and_engine_version_drop_out(self):
    self.assertEqual(
        bazel_ci.normalized_flags([
            '--bazel', '--target-dir', 'ci/x', '--rbe', '--no-goma', '--no-rbe',
            '--rbe-server-address=unix:///tmp/rbe/reproxy.sock', '--gn-args=engine_version="abc"',
            '--android-cpu=arm64', '--no-bazel-rbe', '--xcode-symlinks'
        ]), ['--target-dir', 'ci/x', '--android-cpu', 'arm64']
    )

  def test_the_rbe_flags_are_read_and_the_last_wins(self):
    self.assertIsNone(bazel_ci.rbe_flag(['--bazel', '--target-dir', 'ci/x', '--no-goma']))
    self.assertIs(bazel_ci.rbe_flag(['--bazel', '--target-dir', 'ci/x', '--no-rbe']), False)
    self.assertIs(bazel_ci.rbe_flag(['--rbe', '--bazel']), True)
    self.assertIs(bazel_ci.rbe_flag(['--bazel', '--no-bazel-rbe']), False)
    self.assertIs(bazel_ci.rbe_flag(['--bazel', '--bazel-rbe']), True)
    self.assertIs(bazel_ci.rbe_flag(['--no-bazel-rbe', '--bazel-rbe']), True)
    self.assertIs(bazel_ci.rbe_flag(['--bazel-rbe', '--no-bazel-rbe']), False)

  def test_the_recipes_no_rbe_takes_a_build_off_rbe(self):
    # A builder file's build on RBE: --no-rbe for the recipe (no reclient
    # proxy around ninja), then --bazel-rbe for the build.
    build = ['--target-dir', 'ci/x', '--no-rbe', '--xcode-symlinks', '--bazel', '--bazel-rbe']
    self.assertIs(bazel_ci.rbe_flag(build), True)
    # An official build: the recipe appends these to the same flags.
    official = build + ['--no-goma', '--no-rbe', '--gn-args=engine_version="abc"']
    self.assertIs(bazel_ci.rbe_flag(official), False)
    # A prod build of a Mac: the file's postsubmit_overrides, upstream's
    # --no-rbe and no --bazel-rbe.
    self.assertIs(bazel_ci.rbe_flag(['--target-dir', 'ci/x', '--no-rbe', '--bazel']), False)
    # The say is not among the flags a build is matched by.
    self.assertEqual(bazel_ci.normalized_flags(official), ['--target-dir', 'ci/x'])

  def test_other_gn_args_stay(self):
    self.assertEqual(
        bazel_ci.normalized_flags(['--gn-args=dart_dynamic_modules=true']),
        ['--gn-args', 'dart_dynamic_modules=true']
    )


class MatchBuildTest(unittest.TestCase):

  def test_matches_the_recipes_flags(self):
    # The recipe appends the infrastructure flags of an official build.
    build = bazel_ci.match_build(
        BUILDS, HOST_DEBUG_UNOPT['gn'] + ['--bazel', '--no-goma', '--no-rbe']
    )
    self.assertEqual(build, {**HOST_DEBUG_UNOPT, 'options': []})

  def test_the_recipes_no_lto_turns_lto_off(self):
    # cocoon's no_lto property on a presubmit's engine builds:
    # the recipe appends --no-lto to flags that lack it.
    build = bazel_ci.match_build(BUILDS, HOST_DEBUG_UNOPT['gn'] + ['--bazel', '--no-lto'])
    self.assertEqual(build['name'], HOST_DEBUG_UNOPT['name'])
    self.assertEqual(build['options'], ['--//engine/src/flutter/build/bazel:lto=false'])
    # A build whose own flags have it matches as it is.
    self.assertEqual(bazel_ci.match_build(BUILDS, HOST_DEBUG['gn'] + ['--bazel'])['options'], [])
    # A ThinLTO build the same: its --thin-lto stays among the flags, and says
    # nothing once LTO is off (tools/gn: use_thin_lto under enable_lto alone).
    thin = {
        **HOST_DEBUG,
        'file': 'linux_host_desktop_engine.json',
        'name': 'ci/host_release_desktop',
        'gn': [
            '--runtime-mode', 'release', '--thin-lto', '--target-dir', 'ci/host_release_desktop'
        ],
        'build_directory': 'ci/host_release_desktop',
        'config': 'ci_host_release_desktop',
    }
    build = bazel_ci.match_build(BUILDS + [thin], thin['gn'] + ['--bazel', '--no-lto'])
    self.assertEqual(build['name'], thin['name'])
    self.assertEqual(build['options'], ['--//engine/src/flutter/build/bazel:lto=false'])
    self.assertEqual(bazel_ci.match_build(BUILDS + [thin], thin['gn'] + ['--bazel'])['options'], [])

  def test_tells_two_builds_of_one_directory_apart(self):
    self.assertEqual(
        bazel_ci.match_build(BUILDS, HOST_DEBUG['gn'] + ['--bazel'])['name'], HOST_DEBUG['name']
    )
    self.assertEqual(
        bazel_ci.match_build(BUILDS, HOST_DEBUG_NO_PREBUILT['gn'] + ['--bazel'])['name'],
        HOST_DEBUG_NO_PREBUILT['name']
    )

  def test_no_match_names_the_directorys_builds(self):
    with self.assertRaises(bazel_ci.BazelCiError) as raised:
      bazel_ci.match_build(
          BUILDS, ['--bazel', '--target-dir', 'ci/host_debug', '--runtime-mode', 'debug']
      )
    message = str(raised.exception)
    self.assertIn('no build of the builder files', message)
    self.assertIn("linux_host_engine.json's ci/host_debug:", message)
    self.assertIn("linux_unopt.json's ci/host_debug_no_prebuilt_dart_sdk:", message)

  def test_no_configuration_is_refused_with_the_reason(self):
    with self.assertRaises(bazel_ci.BazelCiError) as raised:
      bazel_ci.match_build(BUILDS, UNSUPPORTED['gn'])
    self.assertIn('has no Bazel configuration: --fancy', str(raised.exception))


def shutil_usage(total):
  """A shutil.disk_usage result of `total` bytes."""
  return collections.namedtuple('usage', 'total used free')(total, 0, total)


class BuildDirectoryTest(unittest.TestCase):

  def setUp(self):
    self.tmp = tempfile.TemporaryDirectory()
    self.engine_src = os.path.join(self.tmp.name, 'checkout', 'engine', 'src')
    os.makedirs(self.engine_src)

  def tearDown(self):
    self.tmp.cleanup()

  def test_ninja_file_runs_the_install_once_for_every_target(self):
    out_dir = os.path.join(self.engine_src, 'out', 'ci', 'host_debug_unopt')
    text = bazel_ci.ninja_file(self.engine_src, HOST_DEBUG_UNOPT, out_dir, '/tools/bazelisk')
    # The edge runs the install through this module (which closes the
    # inherited descriptors: the Bazel server would hold ninja's pipe open
    # otherwise), from the description beside the file.
    self.assertIn(
        f'\n  command = {sys.executable} {os.path.abspath(bazel_ci.__file__)} install {out_dir}\n',
        text
    )
    self.assertIn(
        '  description = bazel run --config=ci_host_debug_unopt '
        f'//engine/src/flutter/ci/builders:ci_host_debug_unopt -- {out_dir}\n', text
    )
    self.assertIn('  pool = console\n', text)
    self.assertIn('\nbuild bazel_install.stamp: bazel_install\n', text)
    # ninja's escape of the colon in a GN label.
    self.assertIn('\nbuild flutter$:unittests: phony bazel_install.stamp\n', text)
    self.assertIn('\nbuild flutter/tools/font_subset: phony bazel_install.stamp\n', text)
    self.assertIn('\nbuild sky_engine: phony bazel_install.stamp\n', text)
    self.assertTrue(text.endswith('\ndefault bazel_install.stamp\n'))

  def test_install_command_from_the_description(self):
    out_dir = os.path.join(self.engine_src, 'out', 'ci', 'host_debug_unopt')
    bazel_ci.write_build_directory(self.engine_src, HOST_DEBUG_UNOPT, out_dir, '/tools/bazelisk')
    root = os.path.join(self.tmp.name, 'checkout')
    description = bazel_ci.read_build_directory(out_dir)
    self.assertEqual(
        bazel_ci.install_command(description), [
            '/tools/bazelisk', f'--output_user_root={root}/.bazel_ci/output', 'run', '--config=ci',
            f'--disk_cache={root}/.bazel_ci/disk_cache',
            '--experimental_disk_cache_gc_max_size=40G', '--config=ci_host_debug_unopt',
            '//engine/src/flutter/ci/builders:ci_host_debug_unopt', '--', out_dir
        ]
    )
    self.assertEqual(description['environment'], {'BAZELISK_HOME': f'{root}/.bazel_ci/bazelisk'})

  def test_the_builds_options_reach_both_commands(self):
    # The recipe's --no-lto on a build whose flags lack it: LTO off in the
    # install and in the tests.
    build = bazel_ci.match_build(BUILDS, HOST_DEBUG_UNOPT['gn'] + ['--no-lto'])
    self.assertEqual(build['options'], ['--//engine/src/flutter/build/bazel:lto=false'])
    out_dir = os.path.join(self.engine_src, 'out', 'ci', 'host_debug_unopt')
    bazel_ci.write_build_directory(self.engine_src, build, out_dir, '/tools/bazelisk')
    description = bazel_ci.read_build_directory(out_dir)
    self.assertEqual(description['options'], ['--//engine/src/flutter/build/bazel:lto=false'])
    command = bazel_ci.install_command(description)
    self.assertEqual(
        command[command.index('--config=ci_host_debug_unopt'):], [
            '--config=ci_host_debug_unopt', '--//engine/src/flutter/build/bazel:lto=false',
            '//engine/src/flutter/ci/builders:ci_host_debug_unopt', '--', out_dir
        ]
    )
    text = bazel_ci.ninja_file(self.engine_src, build, out_dir, '/tools/bazelisk')
    self.assertIn(
        '  description = bazel run --config=ci_host_debug_unopt '
        '--//engine/src/flutter/build/bazel:lto=false '
        f'//engine/src/flutter/ci/builders:ci_host_debug_unopt -- {out_dir}\n', text
    )

  def test_install_of_a_gn_directory_is_an_error(self):
    out_dir = os.path.join(self.engine_src, 'out', 'host_debug')
    os.makedirs(out_dir)
    self.assertEqual(bazel_ci.run_install(out_dir), 1)
    self.assertEqual(bazel_ci.main(['bazel_ci.py']), 2)

  def test_a_bots_state_is_in_the_tasks_temporary_directory(self):
    # The recipe clobbers the builder cache (the checkout) at the start of
    # every build: Bazel's state goes where swarming cleans up after the
    # task, the disk cache with it -- the root .bazelrc's is in the home
    # directory, which on a bot outlives the task and nothing bounds -- and
    # the repo contents cache, which is in the home directory too, is off.
    root = os.path.join(self.tmp.name, 'checkout')
    out_dir = os.path.join(self.engine_src, 'out', 'ci', 'host_debug_unopt')
    caches = ['--disk_cache=/b/s/w/ir/tmp/t/bazel_ci/disk_cache', '--repo_contents_cache=']
    with unittest.mock.patch.dict(
        os.environ,
        {'LUCI_CONTEXT': '/b/s/w/ir/tmp/t/luci_context.json', 'TMPDIR': '/b/s/w/ir/tmp/t'}):
      bazel_ci.write_build_directory(
          self.engine_src, HOST_DEBUG_UNOPT, out_dir, '/tools/bazelisk', rbe=True
      )
      description = bazel_ci.read_build_directory(out_dir)
      rbe = bazel_ci.rbe_config()
      if sys.platform.startswith('linux'):
        self.assertEqual(rbe, ['--config=rbe', bazel_ci.WRAP_RBE_FLAG])
      elif sys.platform == 'darwin':
        self.assertEqual(rbe, ['--config=rbe_mac', bazel_ci.WRAP_RBE_FLAG])
      else:
        self.assertEqual(rbe, [])
      self.assertEqual(bazel_ci.bot_cache_options(self.engine_src), caches)
      self.assertEqual(
          description['build_options'],
          bazel_ci.rbe_options(True) + bazel_ci.bot_sandbox_options() + caches
      )
      self.assertIn(
          description['build_options'], [rbe + caches, rbe + ['--sandbox_base=/dev/shm'] + caches]
      )
      # RBE is what the build's flags say (rbe_flag), on Linux and on a Mac
      # each with its own config, never elsewhere. A bot's build whose flags
      # say no, or nothing, runs on the bot: nothing but the flags makes it
      # remote, and the environment has no say.
      self.assertEqual(bazel_ci.rbe_options(True), rbe)
      self.assertEqual(bazel_ci.rbe_options(False), [])
      self.assertEqual(bazel_ci.rbe_options(), [])
      with unittest.mock.patch.dict(os.environ, {'FLUTTER_BAZEL_RBE': '1'}):
        self.assertEqual(bazel_ci.rbe_options(), [])
      for say in (False, None):
        bazel_ci.write_build_directory(
            self.engine_src, HOST_DEBUG_UNOPT, out_dir, '/tools/bazelisk', rbe=say
        )
        local = bazel_ci.read_build_directory(out_dir)['build_options']
        # Off RBE the caches are the task's all the same: such a build takes
        # nothing from the builds the bot ran before it.
        self.assertEqual(local, bazel_ci.bot_sandbox_options() + caches)
        self.assertFalse([option for option in local if 'rbe' in option])
    self.assertEqual(
        description['startup_options'],
        ['--output_user_root=/b/s/w/ir/tmp/t/bazel_ci/output', '--max_idle_secs=300']
    )
    # A developer's build has no RBE unless asked (--bazel-rbe), and then a
    # Linux host's is build:rbe_dev: build:rbe with the links on the machine.
    with unittest.mock.patch.dict(os.environ):
      os.environ.pop('LUCI_CONTEXT', None)
      developer_rbe = bazel_ci.rbe_config()
      if sys.platform.startswith('linux'):
        self.assertEqual(developer_rbe, ['--config=rbe_dev', bazel_ci.WRAP_RBE_FLAG])
      else:
        self.assertEqual(developer_rbe, rbe)
      options = bazel_ci.build_options(self.engine_src)
      self.assertNotIn('--config=rbe', options)
      self.assertNotIn('--config=rbe_dev', options)
      self.assertEqual(
          bazel_ci.build_options(self.engine_src, rbe=True)[:len(developer_rbe)], developer_rbe
      )
    self.assertEqual(
        description['environment'], {'BAZELISK_HOME': '/b/s/w/ir/tmp/t/bazel_ci/bazelisk'}
    )
    # The sandboxes go to the tmpfs when it is there and large enough.
    with unittest.mock.patch.object(bazel_ci.os.path, 'isdir', return_value=True), \
        unittest.mock.patch.object(bazel_ci.shutil, 'disk_usage') as usage:
      usage.return_value = shutil_usage(64 * 1024**3)
      self.assertEqual(bazel_ci.bot_sandbox_options(), ['--sandbox_base=/dev/shm'])
      usage.return_value = shutil_usage(8 * 1024**3)
      self.assertEqual(bazel_ci.bot_sandbox_options(), [])
    with unittest.mock.patch.object(bazel_ci.os.path, 'isdir', return_value=False):
      self.assertEqual(bazel_ci.bot_sandbox_options(), [])
    with unittest.mock.patch.dict(os.environ,
                                  {'LUCI_CONTEXT': '/b/s/w/ir/tmp/t/luci_context.json'}):
      os.environ.pop('TMPDIR', None)
      self.assertEqual(bazel_ci.bazel_home(self.engine_src), '/b/s/w/ir/tmp/t/bazel_ci')
    with unittest.mock.patch.dict(os.environ, {'BAZEL_CI_HOME': '/elsewhere'}):
      self.assertEqual(bazel_ci.bazel_home(self.engine_src), '/elsewhere')
    # A developer: under the checkout, with the disk cache.
    with unittest.mock.patch.dict(os.environ):
      os.environ.pop('LUCI_CONTEXT', None)
      os.environ.pop('BAZEL_CI_HOME', None)
      self.assertEqual(bazel_ci.bazel_home(self.engine_src), f'{root}/.bazel_ci')
      self.assertEqual(
          bazel_ci.build_options(self.engine_src)[0], f'--disk_cache={root}/.bazel_ci/disk_cache'
      )

  def test_shell_quoting_of_a_path_with_a_space(self):
    self.assertEqual(bazel_ci.shell_quote('/a b/c'), "'/a b/c'")
    self.assertEqual(bazel_ci.shell_quote('/a/b'), '/a/b')
    self.assertEqual(bazel_ci.shell_quote("it's"), "'it'\\''s'")

  def test_writes_and_reads_back_the_description(self):
    out_dir = os.path.join(self.engine_src, 'out', 'ci', 'host_debug_unopt')
    written = bazel_ci.write_build_directory(
        self.engine_src, HOST_DEBUG_UNOPT, out_dir, '/tools/bazelisk'
    )
    self.assertEqual([os.path.basename(p) for p in written], ['build.ninja', 'bazel.json'])
    description = bazel_ci.read_build_directory(out_dir)
    self.assertEqual(description['config'], 'ci_host_debug_unopt')
    self.assertEqual(description['tests'], HOST_DEBUG_UNOPT['tests'])
    self.assertEqual(description['repo_root'], os.path.join(self.tmp.name, 'checkout'))
    self.assertEqual(description['bazelisk'], '/tools/bazelisk')
    with open(os.path.join(out_dir, 'bazel.json'), encoding='utf-8') as written_json:
      self.assertEqual(json.load(written_json), description)

  def test_writing_the_directory_again_removes_the_stamp(self):
    # A persistent build directory (the bots', a developer's): ninja would
    # otherwise find the stamp up to date and run no install.
    out_dir = os.path.join(self.engine_src, 'out', 'ci', 'host_debug_unopt')
    bazel_ci.write_build_directory(self.engine_src, HOST_DEBUG_UNOPT, out_dir, '/tools/bazelisk')
    stamp = os.path.join(out_dir, 'bazel_install.stamp')
    with open(stamp, 'w', encoding='utf-8'):
      pass
    bazel_ci.write_build_directory(self.engine_src, HOST_DEBUG_UNOPT, out_dir, '/tools/bazelisk')
    self.assertFalse(os.path.exists(stamp))
    self.assertTrue(os.path.exists(os.path.join(out_dir, 'build.ninja')))

  def test_a_gn_directory_has_no_description(self):
    out_dir = os.path.join(self.engine_src, 'out', 'host_debug_unopt')
    os.makedirs(out_dir)
    self.assertIsNone(bazel_ci.read_build_directory(out_dir))


class TestSuitesTest(unittest.TestCase):

  def test_the_types_suites_in_order_without_repeats(self):
    description = {'file': 'f', 'name': 'n', 'tests': HOST_DEBUG_UNOPT['tests']}
    self.assertEqual(
        bazel_ci.test_suites(description, ['engine', 'dart', 'engine']), [
            '//engine/src/flutter/fml:fml_unittests', '//engine/src/flutter/flow:flow_unittests',
            '//engine/src/flutter/testing/dart:dart'
        ]
    )

  def test_binaries_are_the_steps_test_executables(self):
    tests = {
        **HOST_DEBUG_UNOPT['tests'],
        'binaries': ['//engine/src/flutter/tools/licenses_cpp:licenses_cpp_testrunner']
    }
    description = {'file': 'f', 'name': 'n', 'tests': tests}
    self.assertEqual(
        bazel_ci.test_suites(description, ['binaries']),
        ['//engine/src/flutter/tools/licenses_cpp:licenses_cpp_testrunner']
    )

  def test_a_type_the_build_does_not_run_is_an_error(self):
    description = {'file': 'f', 'name': 'n', 'tests': HOST_DEBUG_UNOPT['tests']}
    with self.assertRaises(bazel_ci.BazelCiError) as raised:
      bazel_ci.test_suites(description, ['engine', 'java'])
    self.assertIn('runs no java tests under Bazel (its types: dart, engine)', str(raised.exception))

  def test_the_wrap_rbe_env_file_carries_the_bots_metadata_server(self):
    # On a bot with LUCI's emulated metadata server: the three names and the
    # switch to GCE credentials; nothing off a bot, nothing without it.
    environ = {
        'LUCI_CONTEXT': '/b/s/w/ir/tmp/t/luci_context.json',
        'GCE_METADATA_HOST': '127.0.0.1:38553',
        'GCE_METADATA_IP': '127.0.0.1:38553',
        'GCE_METADATA_ROOT': '127.0.0.1:38553',
    }
    with tempfile.TemporaryDirectory() as home:
      with unittest.mock.patch.dict(os.environ, environ):
        path = bazel_ci.write_wrap_rbe_env(home=home, environ=environ)
      self.assertEqual(
          path, os.path.join(home, '.cache', 'flutter_engine_bazel', 'wrap_rbe_env.json')
      )
      with open(path, encoding='utf-8') as env_file:
        self.assertEqual(
            json.load(env_file), {
                'GCE_METADATA_HOST': '127.0.0.1:38553',
                'GCE_METADATA_IP': '127.0.0.1:38553',
                'GCE_METADATA_ROOT': '127.0.0.1:38553',
                'RBE_use_gce_credentials': 'true',
                'RBE_use_application_default_credentials': 'false',
            }
        )
      with unittest.mock.patch.dict(os.environ, environ):
        self.assertIsNone(bazel_ci.write_wrap_rbe_env(home=home, environ={'LUCI_CONTEXT': 'x'}))
      with unittest.mock.patch.dict(os.environ):
        os.environ.pop('LUCI_CONTEXT', None)
        self.assertIsNone(bazel_ci.write_wrap_rbe_env(home=home, environ=environ))

  def test_the_engines_tests_run_on_the_machine(self):
    # TEST_OPTIONS keeps the engine's suites off the RBE workers (a display,
    # a GPU, a device), before whatever the step adds and the suites.
    description = {
        'file': 'f',
        'name': 'n',
        'tests': HOST_DEBUG_UNOPT['tests'],
        'bazelisk': '/tools/bazelisk',
        'startup_options': [],
        'build_options': ['--config=rbe'],
        'config': 'ci_host_debug_unopt',
        'repo_root': '/checkout',
        'environment': {},
    }
    with unittest.mock.patch.object(bazel_ci.subprocess, 'run') as run:
      run.return_value.returncode = 3
      self.assertEqual(
          bazel_ci.run_tests(description, ['engine'], extra_arguments=['--runs_per_test=2']), 3
      )
    command = run.call_args.args[0]
    self.assertEqual(
        command[command.index('--config=ci_host_debug_unopt') + 1:], [
            '--strategy=TestRunner=sandboxed,local', '--runs_per_test=2',
            '//engine/src/flutter/fml:fml_unittests', '//engine/src/flutter/flow:flow_unittests'
        ]
    )
    self.assertEqual(run.call_args.kwargs['cwd'], '/checkout')


def summary_event(label, status, failed=(), passed=()):
  """A testSummary line of --build_event_json_file (path conversion off)."""
  return json.dumps({
      'id': {'testSummary': {'label': label, 'configuration': {'id': 'c0'}}},
      'testSummary': {
          'overallStatus': status,
          'failed': [{'uri': 'file://' + path} for path in failed],
          'passed': [{'uri': 'file://' + path} for path in passed],
      },
  })


class FailedTestLogsTest(unittest.TestCase):
  """The failed runs' logs: Bazel's account of them, and their copies."""

  def setUp(self):
    self.scratch = tempfile.TemporaryDirectory()
    self.addCleanup(self.scratch.cleanup)
    self.root = self.scratch.name
    self.testlogs = os.path.join(self.root, 'execroot', '_main', 'bazel-out', 'k8-dbg', 'testlogs')
    self.logs_dir = os.path.join(self.root, 'flutter_logs_dir')
    self.events = os.path.join(self.root, 'events.json')

  def log(self, relative, text='log\n'):
    """A test log as Bazel leaves it: read-only."""
    path = os.path.join(self.testlogs, *relative.split('/'))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as log:
      log.write(text)
    os.chmod(path, 0o555)
    return path

  def write_events(self, *lines):
    with open(self.events, 'w', encoding='utf-8') as events:
      events.write(''.join(line + '\n' for line in lines))

  def test_the_logs_are_those_of_the_runs_bazel_says_failed(self):
    passed = self.log('engine/a/passes/test.log')
    failed = self.log('engine/a/fails/test.log')
    shard = self.log('engine/a/sharded/shard_2_of_3/test.log')
    attempt = self.log('engine/a/flaky/test_attempts/attempt_1.log')
    retried = self.log('engine/a/flaky/test.log')
    self.write_events(
        json.dumps({'id': {'started': {}}, 'started': {'uuid': 'u'}}),
        json.dumps({'id': {'progress': {'opaqueCount': 1}}, 'progress': {'stderr': 'FAILED'}}),
        summary_event('//engine/a:passes', 'PASSED', passed=[passed]),
        summary_event('//engine/a:fails', 'FAILED', failed=[failed]),
        '{"id": {"testSummary": {"label": "//engine/a:cut", "confi',
        summary_event('//engine/a:sharded', 'FAILED', failed=[shard], passed=[passed]),
        summary_event('//engine/a:flaky', 'FLAKY', failed=[attempt], passed=[retried]),
        json.dumps({
            'id': {'testSummary': {'label': '//engine/a:remote'}},
            'testSummary': {
                'overallStatus': 'FAILED', 'failed': [{'uri': 'bytestream://cas/blobs/1/2'}]
            },
        }),
        json.dumps({'id': {'testSummary': {'label': '//engine/a:unbuilt'}}, 'testSummary': {}}),
        '[]',
        summary_event('//engine/a:fails', 'FAILED', failed=[failed]),
    )
    self.assertEqual(bazel_ci.failed_test_logs(self.events), [failed, shard, attempt])

  def test_a_path_with_a_space_comes_back_from_its_uri(self):
    failed = self.log('engine/a b/fails/test.log')
    self.write_events(
        json.dumps({
            'id': {'testSummary': {'label': '//engine/a b:fails'}},
            'testSummary': {
                'overallStatus': 'FAILED',
                'failed': [{'uri': 'file://' + failed.replace(' ', '%20')}]
            },
        })
    )
    self.assertEqual(bazel_ci.failed_test_logs(self.events), [failed])

  def test_no_events_file_names_no_log(self):
    self.assertEqual(bazel_ci.failed_test_logs(os.path.join(self.root, 'absent.json')), [])
    self.assertEqual(
        bazel_ci.copy_failed_test_logs(os.path.join(self.root, 'absent.json'), self.logs_dir), 0
    )
    self.assertFalse(os.path.exists(self.logs_dir))

  def test_a_copy_is_named_after_the_logs_place_under_testlogs(self):
    out = '/b/x/execroot/_main/bazel-out/linux_x64_debug-dbg/testlogs/'
    self.assertEqual(
        bazel_ci.test_log_name(out + 'engine/src/flutter/fml/fml_unittests/test.log'),
        'engine_src_flutter_fml_fml_unittests.test.log'
    )
    self.assertEqual(
        bazel_ci.test_log_name(out + 'engine/a/sharded/shard_2_of_3/test.log'),
        'engine_a_sharded_shard_2_of_3.test.log'
    )
    self.assertEqual(
        bazel_ci.test_log_name(out + 'engine/a/flaky/test_attempts/attempt_1.log'),
        'engine_a_flaky_test_attempts_attempt_1.test.log'
    )
    self.assertEqual(
        bazel_ci.test_log_name('/elsewhere/fails/test.log'), 'elsewhere_fails.test.log'
    )

  def test_copies_the_failed_runs_logs_and_no_other(self):
    passed = self.log('engine/a/passes/test.log', 'passes\n')
    failed = self.log('engine/a/fails/test.log', 'fails\n')
    self.write_events(
        summary_event('//engine/a:passes', 'PASSED', passed=[passed]),
        summary_event('//engine/a:fails', 'FAILED', failed=[failed]),
    )
    stderr = io.StringIO()
    with contextlib.redirect_stderr(stderr):
      self.assertEqual(bazel_ci.copy_failed_test_logs(self.events, self.logs_dir), 1)
    self.assertEqual(os.listdir(self.logs_dir), ['engine_a_fails.test.log'])
    with open(os.path.join(self.logs_dir, 'engine_a_fails.test.log'), encoding='utf-8') as copy:
      self.assertEqual(copy.read(), 'fails\n')
    self.assertIn('1 test log(s) copied to ' + self.logs_dir, stderr.getvalue())

  def test_a_later_attempt_writes_over_an_earlier_ones_copy(self):
    # The recipe runs a failed step up to three times into one logs
    # directory. With a cache Bazel's logs are read-only: a copy with their
    # mode is one the next attempt could not write (PermissionError, which
    # failed attempts whose tests had all passed).
    failed = self.log('engine/a/fails/test.log', 'first\n')
    self.write_events(summary_event('//engine/a:fails', 'FAILED', failed=[failed]))
    copy = os.path.join(self.logs_dir, 'engine_a_fails.test.log')
    with contextlib.redirect_stderr(io.StringIO()):
      self.assertEqual(bazel_ci.copy_failed_test_logs(self.events, self.logs_dir), 1)
      self.assertTrue(os.stat(copy).st_mode & stat.S_IWUSR)
      # What an earlier version left behind: a copy no one can write.
      os.chmod(copy, 0o555)
      os.chmod(failed, 0o755)
      with open(failed, 'w', encoding='utf-8') as log:
        log.write('second\n')
      os.chmod(failed, 0o555)
      self.assertEqual(bazel_ci.copy_failed_test_logs(self.events, self.logs_dir), 1)
    with open(copy, encoding='utf-8') as log:
      self.assertEqual(log.read(), 'second\n')
    self.assertTrue(os.stat(copy).st_mode & stat.S_IWUSR)

  def test_a_log_that_cannot_be_copied_is_reported_not_raised(self):
    failed = self.log('engine/a/fails/test.log')
    gone = os.path.join(self.testlogs, 'engine', 'a', 'gone', 'test.log')
    self.write_events(
        summary_event('//engine/a:gone', 'FAILED', failed=[gone]),
        summary_event('//engine/a:fails', 'FAILED', failed=[failed]),
    )
    stderr = io.StringIO()
    with contextlib.redirect_stderr(stderr):
      self.assertEqual(bazel_ci.copy_failed_test_logs(self.events, self.logs_dir), 1)
    self.assertEqual(os.listdir(self.logs_dir), ['engine_a_fails.test.log'])
    self.assertIn(gone + ' not copied', stderr.getvalue())

  def description(self):
    return {
        'file': 'f',
        'name': 'n',
        'tests': HOST_DEBUG_UNOPT['tests'],
        'bazelisk': '/tools/bazelisk',
        'startup_options': [],
        'build_options': [],
        'config': 'ci_host_debug_unopt',
        'repo_root': self.root,
        'environment': {},
    }

  def test_a_run_with_a_logs_directory_copies_from_its_events(self):
    failed = self.log('engine/src/flutter/fml/fml_unittests/test.log', 'fails\n')
    seen = {}

    def bazel(command, **_):
      # The test command: writes its events where it was told to.
      option = [word for word in command if word.startswith('--build_event_json_file=')]
      seen['events'] = option[0].split('=', 1)[1]
      seen['command'] = command
      with open(seen['events'], 'w', encoding='utf-8') as events:
        events.write(
            summary_event('//engine/src/flutter/fml:fml_unittests', 'FAILED', failed=[failed]) +
            '\n'
        )
      return unittest.mock.Mock(returncode=3)

    with unittest.mock.patch.object(bazel_ci.subprocess, 'run', side_effect=bazel) as run, \
        contextlib.redirect_stderr(io.StringIO()):
      status = bazel_ci.run_tests(
          self.description(), ['engine'],
          logs_dir=self.logs_dir,
          extra_arguments=['--runs_per_test=2']
      )
    self.assertEqual(status, 3)
    self.assertEqual(run.call_count, 1)
    command = seen['command']
    self.assertEqual(
        command[command.index('--config=ci_host_debug_unopt') + 1:], [
            '--strategy=TestRunner=sandboxed,local', '--build_event_json_file=' + seen['events'],
            '--build_event_json_file_path_conversion=false', '--runs_per_test=2',
            '//engine/src/flutter/fml:fml_unittests', '//engine/src/flutter/flow:flow_unittests'
        ]
    )
    self.assertEqual(os.listdir(self.logs_dir), ['engine_src_flutter_fml_fml_unittests.test.log'])
    self.assertFalse(os.path.exists(seen['events']))

  def test_the_exit_status_is_bazels_whatever_becomes_of_the_copy(self):
    stderr = io.StringIO()
    no_copy = unittest.mock.patch.object(
        bazel_ci, 'copy_failed_test_logs', side_effect=RuntimeError('no copy')
    )
    with no_copy, unittest.mock.patch.object(bazel_ci.subprocess, 'run') as run, \
        contextlib.redirect_stderr(stderr):
      run.return_value.returncode = 0
      self.assertEqual(
          bazel_ci.run_tests(self.description(), ['engine'], logs_dir=self.logs_dir), 0
      )
    self.assertIn('RuntimeError: no copy', stderr.getvalue())

  def test_without_a_logs_directory_the_command_asks_for_no_events(self):
    with unittest.mock.patch.object(bazel_ci.subprocess, 'run') as run, \
        contextlib.redirect_stderr(io.StringIO()):
      run.return_value.returncode = 0
      self.assertEqual(bazel_ci.run_tests(self.description(), ['engine']), 0)
    self.assertFalse([word for word in run.call_args.args[0] if 'build_event' in word])


class RealTableTest(unittest.TestCase):
  """The checked-in table: every configured Linux build matches its own flags."""

  def test_the_tables_builds_match_their_own_flags(self):
    # build/bazel/ -> build/ -> flutter/ -> engine/src.
    this = os.path.abspath(__file__)
    engine_src = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(this))))
    if not os.path.isfile(bazel_ci.builds_table(engine_src)):
      self.skipTest('no builds.json beside the module')
    builds = bazel_ci.load_builds(engine_src, 'linux')
    checked = 0
    for build in builds:
      if build['config'] is None or build['install'] is None:
        continue
      # CI's ci/wasm_release and local_engine.json's linux/wasm_release are
      # one build under two names: the match is the first of them.
      matched = bazel_ci.match_build(builds, build['gn'] + ['--bazel'])
      self.assertEqual((matched['config'], matched['install']), (build['config'], build['install']),
                       build['name'])
      checked += 1
    self.assertGreater(checked, 10)

  def test_every_bazel_build_says_where_it_runs(self):
    # ... and with what the recipe appends to an official build's flags,
    # every one of them runs on the bot.
    this = os.path.abspath(__file__)
    engine_src = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(this))))
    if not os.path.isfile(bazel_ci.builds_table(engine_src)):
      self.skipTest('no builds.json beside the module')
    remote = local = 0
    for host in ('linux', 'mac'):
      for build in bazel_ci.load_builds(engine_src, host):
        flags = build['gn']
        if '--bazel' not in flags:
          continue
        # The file's own say: --no-rbe for the recipe, --bazel-rbe after it
        # for a build on RBE.
        self.assertIn('--no-rbe', flags, build['name'])
        self.assertNotIn('--rbe', flags, build['name'])
        say = bazel_ci.rbe_flag(flags)
        self.assertIsNotNone(say, build['name'])
        remote += say
        local += not say
        # With what the recipe appends to an official build's flags.
        self.assertIs(bazel_ci.rbe_flag(flags + ['--no-goma', '--no-rbe']), False, build['name'])
    self.assertGreater(remote, 10)
    self.assertGreater(local, 0)


class RootBazelrcTest(unittest.TestCase):
  """The checked-in root .bazelrc: the disk cache's directory holds nothing else."""

  def test_the_repository_caches_are_outside_the_disk_cache(self):
    # Bazel's disk cache collector takes every file under --disk_cache for
    # an entry and deletes the oldest once the cache is over its size: a
    # repository cache in there loses its downloads, the repo contents
    # cache every file of its repositories (the Mac's T141, 11-25).
    # build/bazel/ -> build/ -> flutter/ -> engine/src -> engine/ -> the checkout.
    root = os.path.abspath(__file__)
    for _ in range(6):
      root = os.path.dirname(root)
    bazelrc = os.path.join(root, '.bazelrc')
    if not os.path.isfile(bazelrc):
      self.skipTest('no root .bazelrc above the module')
    caches = {}
    with open(bazelrc, encoding='utf-8') as file:
      for line in file:
        match = re.match(
            r'(?:build|common)\s+--(disk_cache|repository_cache|repo_contents_cache)=(\S+)', line
        )
        if match:
          caches[match.group(1)] = match.group(2).rstrip('/') + '/'
    self.assertEqual(sorted(caches), ['disk_cache', 'repo_contents_cache', 'repository_cache'])
    for name in ('repository_cache', 'repo_contents_cache'):
      self.assertFalse(caches[name].startswith(caches['disk_cache']), f'{name}: {caches[name]}')


if __name__ == '__main__':
  unittest.main()
