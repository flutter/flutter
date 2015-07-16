#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
This script runs every build as the first hook (See DEPS). If it detects that
the build should be clobbered, it will delete the contents of the build
directory.

A landmine is tripped when a builder checks out a different revision, and the
diff between the new landmines and the old ones is non-null. At this point, the
build is clobbered.
"""

import difflib
import errno
import logging
import optparse
import os
import shutil
import sys
import subprocess
import time

import landmine_utils


SRC_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))


def get_build_dir(build_tool, is_iphone=False):
  """
  Returns output directory absolute path dependent on build and targets.
  Examples:
    r'c:\b\build\slave\win\build\src\out'
    '/mnt/data/b/build/slave/linux/build/src/out'
    '/b/build/slave/ios_rel_device/build/src/xcodebuild'

  Keep this function in sync with tools/build/scripts/slave/compile.py
  """
  ret = None
  if build_tool == 'xcode':
    ret = os.path.join(SRC_DIR, 'xcodebuild')
  elif build_tool in ['make', 'ninja', 'ninja-ios']:  # TODO: Remove ninja-ios.
    if 'CHROMIUM_OUT_DIR' in os.environ:
      output_dir = os.environ.get('CHROMIUM_OUT_DIR').strip()
      if not output_dir:
        raise Error('CHROMIUM_OUT_DIR environment variable is set but blank!')
    else:
      output_dir = landmine_utils.gyp_generator_flags().get('output_dir', 'out')
    ret = os.path.join(SRC_DIR, output_dir)
  else:
    raise NotImplementedError('Unexpected GYP_GENERATORS (%s)' % build_tool)
  return os.path.abspath(ret)


def extract_gn_build_commands(build_ninja_file):
  """Extracts from a build.ninja the commands to run GN.

  The commands to run GN are the gn rule and build.ninja build step at the
  top of the build.ninja file. We want to keep these when deleting GN builds
  since we want to preserve the command-line flags to GN.

  On error, returns the empty string."""
  result = ""
  with open(build_ninja_file, 'r') as f:
    # Read until the second blank line. The first thing GN writes to the file
    # is the "rule gn" and the second is the section for "build build.ninja",
    # separated by blank lines.
    num_blank_lines = 0
    while num_blank_lines < 2:
      line = f.readline()
      if len(line) == 0:
        return ''  # Unexpected EOF.
      result += line
      if line[0] == '\n':
        num_blank_lines = num_blank_lines + 1
  return result

def delete_build_dir(build_dir):
  # GN writes a build.ninja.d file. Note that not all GN builds have args.gn.
  build_ninja_d_file = os.path.join(build_dir, 'build.ninja.d')
  if not os.path.exists(build_ninja_d_file):
    shutil.rmtree(build_dir)
    return

  # GN builds aren't automatically regenerated when you sync. To avoid
  # messing with the GN workflow, erase everything but the args file, and
  # write a dummy build.ninja file that will automatically rerun GN the next
  # time Ninja is run.
  build_ninja_file = os.path.join(build_dir, 'build.ninja')
  build_commands = extract_gn_build_commands(build_ninja_file)

  try:
    gn_args_file = os.path.join(build_dir, 'args.gn')
    with open(gn_args_file, 'r') as f:
      args_contents = f.read()
  except IOError:
    args_contents = ''

  shutil.rmtree(build_dir)

  # Put back the args file (if any).
  os.mkdir(build_dir)
  if args_contents != '':
    with open(gn_args_file, 'w') as f:
      f.write(args_contents)

  # Write the build.ninja file sufficiently to regenerate itself.
  with open(os.path.join(build_dir, 'build.ninja'), 'w') as f:
    if build_commands != '':
      f.write(build_commands)
    else:
      # Couldn't parse the build.ninja file, write a default thing.
      f.write('''rule gn
command = gn -q gen //out/%s/
description = Regenerating ninja files

build build.ninja: gn
generator = 1
depfile = build.ninja.d
''' % (os.path.split(build_dir)[1]))

  # Write a .d file for the build which references a nonexistant file. This
  # will make Ninja always mark the build as dirty.
  with open(build_ninja_d_file, 'w') as f:
    f.write('build.ninja: nonexistant_file.gn\n')


def clobber_if_necessary(new_landmines):
  """Does the work of setting, planting, and triggering landmines."""
  out_dir = get_build_dir(landmine_utils.builder())
  landmines_path = os.path.normpath(os.path.join(out_dir, '..', '.landmines'))
  try:
    os.makedirs(out_dir)
  except OSError as e:
    if e.errno == errno.EEXIST:
      pass

  if os.path.exists(landmines_path):
    with open(landmines_path, 'r') as f:
      old_landmines = f.readlines()
    if old_landmines != new_landmines:
      old_date = time.ctime(os.stat(landmines_path).st_ctime)
      diff = difflib.unified_diff(old_landmines, new_landmines,
          fromfile='old_landmines', tofile='new_landmines',
          fromfiledate=old_date, tofiledate=time.ctime(), n=0)
      sys.stdout.write('Clobbering due to:\n')
      sys.stdout.writelines(diff)

      # Clobber contents of build directory but not directory itself: some
      # checkouts have the build directory mounted.
      for f in os.listdir(out_dir):
        path = os.path.join(out_dir, f)
        if os.path.isfile(path):
          os.unlink(path)
        elif os.path.isdir(path):
          delete_build_dir(path)

  # Save current set of landmines for next time.
  with open(landmines_path, 'w') as f:
    f.writelines(new_landmines)


def process_options():
  """Returns a list of landmine emitting scripts."""
  parser = optparse.OptionParser()
  parser.add_option(
      '-s', '--landmine-scripts', action='append',
      default=[os.path.join(SRC_DIR, 'build', 'get_landmines.py')],
      help='Path to the script which emits landmines to stdout. The target '
           'is passed to this script via option -t. Note that an extra '
           'script can be specified via an env var EXTRA_LANDMINES_SCRIPT.')
  parser.add_option('-v', '--verbose', action='store_true',
      default=('LANDMINES_VERBOSE' in os.environ),
      help=('Emit some extra debugging information (default off). This option '
          'is also enabled by the presence of a LANDMINES_VERBOSE environment '
          'variable.'))

  options, args = parser.parse_args()

  if args:
    parser.error('Unknown arguments %s' % args)

  logging.basicConfig(
      level=logging.DEBUG if options.verbose else logging.ERROR)

  extra_script = os.environ.get('EXTRA_LANDMINES_SCRIPT')
  if extra_script:
    return options.landmine_scripts + [extra_script]
  else:
    return options.landmine_scripts


def main():
  landmine_scripts = process_options()

  if landmine_utils.builder() in ('dump_dependency_json', 'eclipse'):
    return 0


  landmines = []
  for s in landmine_scripts:
    proc = subprocess.Popen([sys.executable, s], stdout=subprocess.PIPE)
    output, _ = proc.communicate()
    landmines.extend([('%s\n' % l.strip()) for l in output.splitlines()])
  clobber_if_necessary(landmines)

  return 0


if __name__ == '__main__':
  sys.exit(main())
