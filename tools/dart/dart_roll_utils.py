#!/usr/bin/env python
# Copyright 2019 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import datetime
import os
import requests
import subprocess

def env_var(var):
  try:
    return os.environ[var]
  except KeyError:
    return ''


FLUTTER_HOME  = env_var('FLUTTER_HOME')
ENGINE_HOME   = env_var('ENGINE_HOME')
DART_SDK_HOME = env_var('DART_SDK_HOME')

NO_COLOR = env_var('TERM') == 'dumb'

ERROR_ROLL_SUCCESS           = 0
ERROR_GCLIENT_SYNC_FAILED    = 1
ERROR_BUILD_FAILED           = 2
ERROR_PKG_FLUTTER_FAILED     = 3
ERROR_FLUTTER_GALLERY_FAILED = 4
ERROR_MISSING_ROOTS          = 5
ERROR_LICENSE_SCRIPT_FAILED  = 6
ERROR_NO_SUITABLE_COMMIT     = 7
ERROR_OLD_COMMIT_PROVIDED    = 8
ERROR_FLUTTER_DOCTOR_FAILED  = 9

class DartAutorollerException(Exception):
  pass

def c_green():
  if NO_COLOR:
    return ''
  return '\033[92m'

def c_yellow():
  if NO_COLOR:
    return ''
  return '\033[93m'

def c_red():
  if NO_COLOR:
    return ''
  return '\033[91m'

def c_end():
  if NO_COLOR:
    return ''
  return '\033[0m'

STATUS_LABEL  = c_green()  + '[STATUS, {}]  ' + c_end()
WARNING_LABEL = c_yellow() + '[WARNING, {}] ' + c_end()
ERROR_LABEL   = c_red()    + '[ERROR, {}]   ' + c_end()

def engine_home():
  return ENGINE_HOME

def set_engine_home(engine_home):
  global ENGINE_HOME
  ENGINE_HOME = engine_home

def flutter_home():
  return FLUTTER_HOME

def set_flutter_home(flutter_home):
  global FLUTTER_HOME
  FLUTTER_HOME = flutter_home

def dart_sdk_home():
  return DART_SDK_HOME

def set_dart_sdk_home(dart_sdk_home):
  global DART_SDK_HOME
  DART_SDK_HOME = dart_sdk_home

def get_timestamp():
  return datetime.datetime.today().strftime('%Y-%m-%d %H:%M:%S')


def print_status(msg):
  print(STATUS_LABEL.format(get_timestamp()) + msg)


def print_warning(msg):
  print(WARNING_LABEL.format(get_timestamp()) + msg)


def print_error(msg):
  print(ERROR_LABEL.format(get_timestamp()) + msg)


def engine_golden_licenses_path():
  return os.path.join(ENGINE_HOME, 'flutter', 'ci', 'licenses_golden')


def engine_license_script_path():
  return os.path.join(ENGINE_HOME, 'flutter', 'ci', 'licenses.sh')


def engine_license_script_dart_path():
  return os.path.join(engine_license_script_package_path(), 'lib', 'main.dart')


def engine_license_script_package_path():
  return os.path.join(ENGINE_HOME, 'flutter', 'tools', 'licenses')


def engine_license_script_output_path():
  return os.path.join(ENGINE_HOME, 'out', 'licenses')


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


def sky_license_file_path():
  return os.path.join(ENGINE_HOME, 'flutter', 'sky', 'packages', 'sky_engine', 'LICENSE')


def update_dart_deps_path():
  return os.path.join(ENGINE_HOME, 'tools', 'dart', 'create_updated_flutter_deps.py')


# Returns True if `current` is a more recent commit than `potential_ancestor` in
# the git repository at `repo_path`.
def is_ancestor_commit(potential_ancestor, current, repo_path):
  return (subprocess.Popen(['git',
                           'merge-base',
                           '--is-ancestor',
                           potential_ancestor,
                            current], cwd=repo_path).wait() == 0)
