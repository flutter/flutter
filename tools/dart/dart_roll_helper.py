#!/usr/bin/env python
# Copyright 2018 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script automates the Dart SDK roll steps, including:
#   - Updating the Dart revision in DEPS
#   - Updating the Dart dependencies in DEPS
#   - Syncing dependencies with 'gclient sync'
#   - Generating GN files for relevant engine configurations
#   - Building relevant engine configurations
#   - Running tests in 'example/flutter_gallery' and 'packages/flutter'
#   - Launching flutter_gallery in release and debug mode
#   - Running license.sh and updating license files in
#     'flutter/ci/licenses_golden'
#   - Generating a commit with relevant Dart SDK commit logs (optional)
#
# The following environment variables can be set instead of being passed as
# arguments:
#   - FLUTTER_HOME: the absolute path to the 'flutter' directory
#   - ENGINE_HOME: the absolute path to the 'engine/src' directory
#   - DART_SDK_HOME: the absolute path to the root of a Dart SDK project

from dart_roll_utils import *
import argparse
import datetime
import fileinput
import os
import platform
import shutil
import subprocess
import sys

DART_REVISION_ENTRY = 'dart_revision'
FLUTTER_RUN  = ['flutter', 'run']
FLUTTER_TEST = ['{}/bin/flutter'.format(FLUTTER_HOME), 'test', '--coverage']

MAX_GCLIENT_RETRIES = 3

# Returned when licenses do not require updating.
LICENSE_SCRIPT_OKAY       = 0
# Returned when licenses require updating.
LICENSE_SCRIPT_UPDATES    = 1
# Returned when either 'pub' or 'dart' isn't in the path.
LICENSE_SCRIPT_EXIT_ERROR = 127

def update_dart_revision(dart_revision):
  original_revision = ''
  print_status('Updating Dart revision to {}'.format(dart_revision))
  content = get_deps()
  for idx, line in enumerate(content):
    if DART_REVISION_ENTRY in line:
      original_revision = line.strip().split(' ')[1][1:-2]
      if not is_ancestor_commit(original_revision,
                                dart_revision,
                                DART_SDK_HOME):
        print_error('Dart revision {} is older than existing revision, {}.' +
                    ' Aborting roll.'.format(dart_revision, original_revision))
        sys.exit(ERROR_OLD_COMMIT_PROVIDED)

      content[idx] = "  'dart_revision': '" + dart_revision + "',\n"
      break
  write_deps(content)
  return original_revision


def gclient_sync():
  exit_code = None
  num_retries = 0

  while ((exit_code != 0) and not (num_retries >= MAX_GCLIENT_RETRIES)):
    print_status('Running gclient sync (Attempt {}/{})'
                 .format(num_retries + 1, MAX_GCLIENT_RETRIES))
    p = subprocess.Popen(['gclient', 'sync', '--delete_unversioned_trees'],
                         cwd=ENGINE_HOME)
    exit_code = p.wait()
    if exit_code != 0:
      num_retries += 1
  if num_retries == MAX_GCLIENT_RETRIES:
    print_error('Max number of gclient sync retries attempted. Aborting roll.')
    sys.exit(ERROR_GCLIENT_SYNC_FAILED)


def get_deps():
  with open(flutter_deps_path(), 'r') as f:
    content = f.readlines()
  return content


def update_deps():
  print_status('Updating Dart dependencies')
  p = subprocess.Popen([update_dart_deps_path()], cwd=ENGINE_HOME)
  p.wait()


def write_deps(newdeps):
  with open(flutter_deps_path(), 'w') as f:
    f.write(''.join(newdeps))


def run_gn():
  print_status('Generating build files')
  common = [os.path.join('flutter', 'tools', 'gn'), '--goma']
  debug = ['--runtime-mode=debug']
  profile = ['--runtime-mode=profile']
  release = ['--runtime-mode=release']
  runtime_modes = [debug, profile, release]
  unopt = ['--unoptimized']
  android = ['--android']

  for mode in runtime_modes:
    if set(mode) != set(release):
      p = subprocess.Popen(common + android + unopt + mode, cwd=ENGINE_HOME)
      p.wait()
    q = subprocess.Popen(common + android + mode, cwd=ENGINE_HOME)
    host = common[:]
    if set(mode) == set(debug):
      host += unopt
    r = subprocess.Popen(host + mode, cwd=ENGINE_HOME)
    q.wait()
    r.wait()


def build():
  print_status('Building Flutter engine')
  command = ['ninja', '-j1000']
  configs = [
    'host_debug_unopt',
    'host_release',
    'host_profile',
    'android_debug_unopt',
    'android_debug',
    'android_profile_unopt',
    'android_profile',
    'android_release'
  ]

  build_dir = 'out'
  if platform.system() == 'Darwin':
    build_dir = 'xcodebuild'

  for config in configs:
    p = subprocess.Popen(command + ['-C', os.path.join(build_dir, config)],
                         cwd=ENGINE_HOME)
    error_code = p.wait()
    if error_code != 0:
      print_error('Build failure for configuration "' +
                  config +
                  '". Aborting roll.')
      sys.exit(ERROR_BUILD_FAILED)


def run_tests():
  print_status('Running tests in packages/flutter')
  engine_src_path = '--local-engine-src-path={}'.format(ENGINE_HOME)
  p = subprocess.Popen(FLUTTER_TEST + ['--local-engine=host_debug_unopt',
                                       engine_src_path],
                       cwd=package_flutter_path())
  result = p.wait()
  if result != 0:
    print_error('package/flutter tests failed. Aborting roll.')
    sys.exit(ERROR_PKG_FLUTTER_FAILED)

  print_status('Running tests in examples/flutter_gallery')
  p = subprocess.Popen(FLUTTER_TEST + ['--local-engine=host_debug_unopt',
                                       engine_src_path],
                       cwd=flutter_gallery_path());
  p.wait()
  if result != 0:
    print_error('flutter_gallery tests failed. Aborting roll.')
    sys.exit(ERROR_FLUTTER_GALLERY_FAILED)


def run_hot_reload_configurations():
  print_status('Running flutter gallery release')
  engine_src_path = '--local-engine-src-path={}'.format(ENGINE_HOME)
  p = subprocess.Popen(FLUTTER_RUN + ['--release',
                                      '--local-engine=android_release',
                                      engine_src_path],
                       cwd=flutter_gallery_path())
  p.wait()
  print_status('Running flutter gallery debug')
  p = subprocess.Popen(FLUTTER_RUN + ['--local-engine=android_debug_unopt',
                                      engine_src_path],
                       cwd=flutter_gallery_path())
  p.wait()


def update_licenses():
  print_status('Updating Flutter licenses')
  p = subprocess.Popen([engine_license_script_path()], cwd=ENGINE_HOME)
  result = p.wait()
  if result == LICENSE_SCRIPT_EXIT_ERROR:
    print_error('License script failed to run. Is the Dart SDK (specifically' +
                ' dart and pub) in your path? Aborting roll.')
    sys.exit(ERROR_LICENSE_SCRIPT_FAILED)
  elif (result != LICENSE_SCRIPT_OKAY) and (result != LICENSE_SCRIPT_UPDATES):
    print_error('Unknown license script error: {}. Aborting roll.'
                .format(result))
    sys.exit(ERROR_LICENSE_SCRIPT_FAILED)

  # Ignore 'licenses_skia' as they shouldn't change during a Dart SDK roll.
  src_files = ['licenses_flutter', 'licenses_third_party', 'tool_signature']
  for f in src_files:
    path = os.path.join(license_script_output_path(), f)
    if os.path.isfile(path):
      shutil.copy(path, engine_golden_licenses_path())
  p = subprocess.Popen(['pub', 'get'], cwd=engine_license_script_package_path())
  p.wait()
  gclient_sync()

  # Update the LICENSE file.
  with open(sky_license_file_path(), 'w') as sky_license:
    p = subprocess.Popen(['dart', os.path.join('lib', 'main.dart'),
                          '--release', '--src', ENGINE_HOME,
                          '--out', engine_license_script_output_path()],
                          cwd=engine_license_script_package_path(),
                          stdout=sky_license)
    p.wait()


def get_commit_range(start, finish):
  range_str = '{}..{}'.format(start, finish)
  command = ['git', 'log', '--oneline', range_str]
  orig_dir = os.getcwd()
  os.chdir(DART_SDK_HOME)
  result = subprocess.check_output(command)
  os.chdir(orig_dir)
  return result


def get_short_rev(rev):
  command = ['git', 'rev-parse', '--short', rev]
  orig_dir = os.getcwd()
  os.chdir(DART_SDK_HOME)
  result = subprocess.check_output(command)
  os.chdir(orig_dir)
  return result.rstrip()


def git_commit(original_revision, updated_revision):
  print_status('Committing Dart SDK roll')
  current_date = datetime.date.today()
  sdk_log = get_commit_range(original_revision, updated_revision)
  num_commits = len(sdk_log.splitlines())
  commit_msg = ('Roll src/third_party/dart {}..{} ({} commits)'
                .format(get_short_rev(original_revision),
                        get_short_rev(updated_revision), num_commits))
  commit_msg += '\n\n' + sdk_log
  commit_cmd = ['git', 'commit', '-a', '-m', commit_msg]
  p = subprocess.Popen(commit_cmd, cwd=engine_flutter_path())
  p.wait()


def update_roots(args):
  # These globals are set from environment variables in dart_roll_utils.py
  global FLUTTER_HOME
  global ENGINE_HOME
  global DART_SDK_HOME

  if args.flutter_home:
    FLUTTER_HOME = args.flutter_home

  if args.engine_home:
    ENGINE_HOME = args.engine_home

  if args.dart_sdk_home:
    DART_SDK_HOME = args.dart_sdk_home

  if FLUTTER_HOME == '':
    print_error('Either "--flutter-home" must be provided or FLUTTER_HOME must' +
                ' be set. Aborting roll.')
    sys.exit(ERROR_MISSING_ROOTS)

  if ENGINE_HOME == '':
    print_error('Either "--engine-home" must be provided or ENGINE_HOME must' +
                ' be set. Aborting roll.')
    sys.exit(ERROR_MISSING_ROOTS)

  if DART_SDK_HOME == '':
    print_error('Either "--dart-sdk-home" must be provided or DART_SDK_HOME ' +
                'must be set. Aborting roll.')
    sys.exit(ERROR_MISSING_ROOTS)


def main():
  parser = argparse.ArgumentParser(description='Automate most Dart SDK roll tasks.')
  parser.add_argument('--dart-sdk-home', help='Path to the Dart SDK ' +
                      'repository. Overrides DART_SDK_HOME environment variable')
  parser.add_argument('dart_sdk_revision', help='Target Dart SDK revision')
  parser.add_argument('--create-commit', action='store_true',
                      help='Create the engine commit with Dart SDK commit log')
  parser.add_argument('--engine-home', help='Path to the Flutter engine ' +
                      'repository. Overrides ENGINE_HOME environment variable')
  parser.add_argument('--flutter-home', help='Path to the Flutter framework ' +
                      'repository. Overrides FLUTTER_HOME environment variable')
  parser.add_argument('--no-build', action='store_true',
                      help='Skip rebuilding the Flutter engine')
  parser.add_argument('--no-hot-reload', action='store_true',
                      help="Skip hot reload testing")
  parser.add_argument('--no-test', action='store_true',
                      help='Skip running host tests for package/flutter and ' +
                      'flutter_gallery')
  parser.add_argument('--no-update-deps', action='store_true',
                      help='Skip updating DEPS file')
  parser.add_argument('--no-update-licenses', action='store_true',
                      help='Skip updating licenses')

  args = parser.parse_args()

  original_revision = None
  updated_revision = args.dart_sdk_revision

  update_roots(args)

  print_status('Starting Dart SDK roll')
  if not args.no_update_deps:
    original_revision = update_dart_revision(updated_revision)
    gclient_sync()
    update_deps()
    gclient_sync()
  if not args.no_build:
    run_gn()
    build()
  if not args.no_test:
    run_tests()
  if not args.no_hot_reload:
    run_hot_reload_configurations()
  if not args.no_update_licenses:
    update_licenses()
  if args.create_commit:
    if original_revision == None:
      print_warning('"original_revision" not specified. Skipping commit.')
      print_warning('This happens when the "--no_update_deps" argument is ' +
                    'provided')
    else:
      git_commit(original_revision, updated_revision)
  print_status('Dart SDK roll complete!')


if __name__ == '__main__':
  main()
