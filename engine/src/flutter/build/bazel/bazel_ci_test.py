#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests of bazel_ci.py: the match of tools/gn flags against the builds table, the files.

Run from this directory: `python3 bazel_ci_test.py`; CI runs it as
//engine/src/flutter/build/bazel:bazel_ci_test.
"""

import json
import os
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
            '--android-cpu=arm64'
        ]), ['--target-dir', 'ci/x', '--android-cpu', 'arm64']
    )

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
    # cocoon's no_lto property on a release builder's presubmit builds:
    # the recipe appends --no-lto to flags that lack it.
    build = bazel_ci.match_build(BUILDS, HOST_DEBUG_UNOPT['gn'] + ['--bazel', '--no-lto'])
    self.assertEqual(build['name'], HOST_DEBUG_UNOPT['name'])
    self.assertEqual(build['options'], ['--//engine/src/flutter/build/bazel:lto=false'])
    # A build whose own flags have it matches as it is.
    self.assertEqual(bazel_ci.match_build(BUILDS, HOST_DEBUG['gn'] + ['--bazel'])['options'], [])

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
    # task, and there is no disk cache to keep.
    root = os.path.join(self.tmp.name, 'checkout')
    out_dir = os.path.join(self.engine_src, 'out', 'ci', 'host_debug_unopt')
    with unittest.mock.patch.dict(
        os.environ,
        {'LUCI_CONTEXT': '/b/s/w/ir/tmp/t/luci_context.json', 'TMPDIR': '/b/s/w/ir/tmp/t'}):
      bazel_ci.write_build_directory(self.engine_src, HOST_DEBUG_UNOPT, out_dir, '/tools/bazelisk')
      description = bazel_ci.read_build_directory(out_dir)
    self.assertEqual(
        description['startup_options'],
        ['--output_user_root=/b/s/w/ir/tmp/t/bazel_ci/output', '--max_idle_secs=300']
    )
    self.assertEqual(description['build_options'], [])
    self.assertEqual(
        description['environment'], {'BAZELISK_HOME': '/b/s/w/ir/tmp/t/bazel_ci/bazelisk'}
    )
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


if __name__ == '__main__':
  unittest.main()
