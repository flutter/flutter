#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Instruments classes and jar files.

This script corresponds to the 'emma_instr' action in the java build process.
Depending on whether emma_instrument is set, the 'emma_instr' action will either
call one of the instrument commands, or the copy command.

Possible commands are:
- instrument_jar: Accepts a jar and instruments it using emma.jar.
- instrument_classes: Accepts a directory containing java classes and
      instruments it using emma.jar.
- copy: Called when EMMA coverage is not enabled. This allows us to make
      this a required step without necessarily instrumenting on every build.
      Also removes any stale coverage files.
"""

import collections
import json
import os
import shutil
import sys
import tempfile

sys.path.append(os.path.join(os.path.dirname(__file__), os.pardir))
from pylib.utils import command_option_parser

from util import build_utils


def _AddCommonOptions(option_parser):
  """Adds common options to |option_parser|."""
  option_parser.add_option('--input-path',
                           help=('Path to input file(s). Either the classes '
                                 'directory, or the path to a jar.'))
  option_parser.add_option('--output-path',
                           help=('Path to output final file(s) to. Either the '
                                 'final classes directory, or the directory in '
                                 'which to place the instrumented/copied jar.'))
  option_parser.add_option('--stamp', help='Path to touch when done.')
  option_parser.add_option('--coverage-file',
                           help='File to create with coverage metadata.')
  option_parser.add_option('--sources-file',
                           help='File to create with the list of sources.')


def _AddInstrumentOptions(option_parser):
  """Adds options related to instrumentation to |option_parser|."""
  _AddCommonOptions(option_parser)
  option_parser.add_option('--sources',
                           help='Space separated list of sources.')
  option_parser.add_option('--src-root',
                           help='Root of the src repository.')
  option_parser.add_option('--emma-jar',
                           help='Path to emma.jar.')
  option_parser.add_option(
      '--filter-string', default='',
      help=('Filter string consisting of a list of inclusion/exclusion '
            'patterns separated with whitespace and/or comma.'))


def _RunCopyCommand(_command, options, _, option_parser):
  """Copies the jar from input to output locations.

  Also removes any old coverage/sources file.

  Args:
    command: String indicating the command that was received to trigger
        this function.
    options: optparse options dictionary.
    args: List of extra args from optparse.
    option_parser: optparse.OptionParser object.

  Returns:
    An exit code.
  """
  if not (options.input_path and options.output_path and
          options.coverage_file and options.sources_file):
    option_parser.error('All arguments are required.')

  coverage_file = os.path.join(os.path.dirname(options.output_path),
                               options.coverage_file)
  sources_file = os.path.join(os.path.dirname(options.output_path),
                              options.sources_file)
  if os.path.exists(coverage_file):
    os.remove(coverage_file)
  if os.path.exists(sources_file):
    os.remove(sources_file)

  if os.path.isdir(options.input_path):
    shutil.rmtree(options.output_path, ignore_errors=True)
    shutil.copytree(options.input_path, options.output_path)
  else:
    shutil.copy(options.input_path, options.output_path)

  if options.stamp:
    build_utils.Touch(options.stamp)


def _CreateSourcesFile(sources_string, sources_file, src_root):
  """Adds all normalized source directories to |sources_file|.

  Args:
    sources_string: String generated from gyp containing the list of sources.
    sources_file: File into which to write the JSON list of sources.
    src_root: Root which sources added to the file should be relative to.

  Returns:
    An exit code.
  """
  src_root = os.path.abspath(src_root)
  sources = build_utils.ParseGypList(sources_string)
  relative_sources = []
  for s in sources:
    abs_source = os.path.abspath(s)
    if abs_source[:len(src_root)] != src_root:
      print ('Error: found source directory not under repository root: %s %s'
             % (abs_source, src_root))
      return 1
    rel_source = os.path.relpath(abs_source, src_root)

    relative_sources.append(rel_source)

  with open(sources_file, 'w') as f:
    json.dump(relative_sources, f)


def _RunInstrumentCommand(command, options, _, option_parser):
  """Instruments the classes/jar files using EMMA.

  Args:
    command: 'instrument_jar' or 'instrument_classes'. This distinguishes
        whether we copy the output from the created lib/ directory, or classes/
        directory.
    options: optparse options dictionary.
    args: List of extra args from optparse.
    option_parser: optparse.OptionParser object.

  Returns:
    An exit code.
  """
  if not (options.input_path and options.output_path and
          options.coverage_file and options.sources_file and options.sources and
          options.src_root and options.emma_jar):
    option_parser.error('All arguments are required.')

  coverage_file = os.path.join(os.path.dirname(options.output_path),
                               options.coverage_file)
  sources_file = os.path.join(os.path.dirname(options.output_path),
                              options.sources_file)
  if os.path.exists(coverage_file):
    os.remove(coverage_file)
  temp_dir = tempfile.mkdtemp()
  try:
    cmd = ['java', '-cp', options.emma_jar,
           'emma', 'instr',
           '-ip', options.input_path,
           '-ix', options.filter_string,
           '-d', temp_dir,
           '-out', coverage_file,
           '-m', 'fullcopy']
    build_utils.CheckOutput(cmd)

    if command == 'instrument_jar':
      for jar in os.listdir(os.path.join(temp_dir, 'lib')):
        shutil.copy(os.path.join(temp_dir, 'lib', jar),
                    options.output_path)
    else:  # 'instrument_classes'
      if os.path.isdir(options.output_path):
        shutil.rmtree(options.output_path, ignore_errors=True)
      shutil.copytree(os.path.join(temp_dir, 'classes'),
                      options.output_path)
  finally:
    shutil.rmtree(temp_dir)

  _CreateSourcesFile(options.sources, sources_file, options.src_root)

  if options.stamp:
    build_utils.Touch(options.stamp)

  return 0


CommandFunctionTuple = collections.namedtuple(
    'CommandFunctionTuple', ['add_options_func', 'run_command_func'])
VALID_COMMANDS = {
    'copy': CommandFunctionTuple(_AddCommonOptions,
                                 _RunCopyCommand),
    'instrument_jar': CommandFunctionTuple(_AddInstrumentOptions,
                                           _RunInstrumentCommand),
    'instrument_classes': CommandFunctionTuple(_AddInstrumentOptions,
                                               _RunInstrumentCommand),
}


def main():
  option_parser = command_option_parser.CommandOptionParser(
      commands_dict=VALID_COMMANDS)
  command_option_parser.ParseAndExecute(option_parser)


if __name__ == '__main__':
  sys.exit(main())
