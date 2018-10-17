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

import argparse
import datetime
import fileinput
import os
import platform
import shutil
import subprocess
import sys

def env_var(var):
  try:
    return os.environ[var]
  except KeyError:
    return ''


FLUTTER_HOME  = env_var('FLUTTER_HOME')
ENGINE_HOME   = env_var('ENGINE_HOME')
DART_SDK_HOME = env_var('DART_SDK_HOME')

MAX_GCLIENT_RETRIES = 3

ERROR_GCLIENT_SYNC_FAILED    = 1
ERROR_BUILD_FAILED           = 2
ERROR_PKG_FLUTTER_FAILED     = 3
ERROR_FLUTTER_GALLERY_FAILED = 4
ERROR_MISSING_ROOTS          = 5
ERROR_LICENSE_SCRIPT_FAILED  = 6

DART_REVISION_ENTRY = 'dart_revision'
FLUTTER_RUN  = ['flutter', 'run']
FLUTTER_TEST = ['flutter', 'test', '--coverage']

# Returned when licenses do not require updating.
LICENSE_SCRIPT_OKAY       = 0
# Returned when licenses require updating.
LICENSE_SCRIPT_UPDATES    = 1
# Returned when either 'pub' or 'dart' isn't in the path.
LICENSE_SCRIPT_EXIT_ERROR = 127

def engine_golden_licenses_path():
  return os.path.join(ENGINE_HOME, 'flutter', 'ci', 'licenses_golden')


def engine_license_script_path():
  return os.path.join(ENGINE_HOME, 'flutter', 'ci', 'licenses.sh')


def engine_flutter_path():
  return os.path.join(ENGINE_HOME, 'flutter')


def flutter_deps_path():
  return os.path.join(ENGINE_HOME, 'flutter', 'DEPS')


def flutter_gallery_path():
  return os.path.join(FLUTTER_HOME, 'examples', 'flutter_gallery')


def license_script_output_path():
  return os.path.join(ENGINE_HOME, 'out', 'license_script_output')


def package_flutter_path():
  return os.path.join(FLUTTER_HOME, 'packages', 'flutter')


def update_dart_deps_path():
  return os.path.join(ENGINE_HOME, 'tools', 'dart', 'create_updated_flutter_deps.py')


def print_status(msg):
  CGREEN = '\033[92m'
  CEND = '\033[0m'
  print(CGREEN + '[STATUS] ' + msg + CEND)


def print_warning(msg):
  CYELLOW = '\033[93m'
  CEND = '\033[0m'
  print(CYELLOW + '[WARNING] ' + msg + CEND)


def print_error(msg):
  CRED = '\033[91m'
  CEND = '\033[0m'
  print(CRED + '[ERROR] ' + msg + CEND)


def update_dart_revision(dart_revision):
  original_revision = ''
  print_status('Updating Dart revision to {}'.format(dart_revision))
  content = get_deps()
  for idx, line in enumerate(content):
    if DART_REVISION_ENTRY in line:
      original_revision = line.strip().split(' ')[1][1:-2]
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
    p = subprocess.Popen(['gclient', 'sync'], cwd=ENGINE_HOME)
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
  p = subprocess.Popen(FLUTTER_TEST + ['--local-engine=host_debug_unopt'],
                       cwd=package_flutter_path())
  result = p.wait()
  if result != 0:
    print_error('package/flutter tests failed. Aborting roll.')
    sys.exit(ERROR_PKG_FLUTTER_FAILED)

  print_status('Running tests in examples/flutter_gallery')
  p = subprocess.Popen(FLUTTER_TEST + ['--local-engine=host_debug_unopt'],
                       cwd=flutter_gallery_path());
  p.wait()
  if result != 0:
    print_error('flutter_gallery tests failed. Aborting roll.')
    sys.exit(ERROR_FLUTTER_GALLERY_FAILED)


def run_hot_reload_configurations():
  print_status('Running flutter gallery release')
  p = subprocess.Popen(FLUTTER_RUN + ['--release', '--local-engine=android_release'],
                       cwd=flutter_gallery_path())
  p.wait()
  print_status('Running flutter gallery debug')
  p = subprocess.Popen(FLUTTER_RUN + ['--local-engine=android_debug_unopt'],
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
  src_files = os.listdir(license_script_output_path())
  for f in src_files:
    path = os.path.join(license_script_output_path(), f)
    if os.path.isfile(path):
      shutil.copy(path, engine_golden_licenses_path())


def get_commit_range(start, finish):
  range_str = '{}...{}'.format(start, finish)
  command = ['git', 'log', '--oneline', range_str]
  orig_dir = os.getcwd()
  os.chdir(DART_SDK_HOME)
  result = subprocess.check_output(command)
  os.chdir(orig_dir)
  return result


def git_commit(original_revision, updated_revision):
  print_status('Committing Dart SDK roll')
  current_date = datetime.date.today()
  sdk_log = get_commit_range(original_revision, updated_revision)
  commit_msg = 'Dart SDK roll for {}\n\n'.format(current_date)
  commit_msg += sdk_log
  commit_cmd = ['git', 'commit', '-a', '-m', commit_msg]
  p = subprocess.Popen(commit_cmd, cwd=engine_flutter_path())
  p.wait()


def update_roots(args):
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
    print_error('Either "--flutter_home" must be provided or FLUTTER_HOME must' +
                ' be set. Aborting roll.')
    sys.exit(ERROR_MISSING_ROOTS)

  if ENGINE_HOME == '':
    print_error('Either "--engine_home" must be provided or ENGINE_HOME must' +
                ' be set. Aborting roll.')
    sys.exit(ERROR_MISSING_ROOTS)

  if DART_SDK_HOME == '':
    print_error('Either "--dart_sdk_home" must be provided or DART_SDK_HOME ' +
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
