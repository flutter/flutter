#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Renders one or more template files using the Jinja template engine."""

import codecs
import optparse
import os
import sys

from util import build_utils

# Import jinja2 from third_party/jinja2
sys.path.append(os.path.join(os.path.dirname(__file__), '../../../third_party'))
import jinja2  # pylint: disable=F0401


class RecordingFileSystemLoader(jinja2.FileSystemLoader):
  '''A FileSystemLoader that stores a list of loaded templates.'''
  def __init__(self, searchpath):
    jinja2.FileSystemLoader.__init__(self, searchpath)
    self.loaded_templates = set()

  def get_source(self, environment, template):
    contents, filename, uptodate = jinja2.FileSystemLoader.get_source(
        self, environment, template)
    self.loaded_templates.add(os.path.relpath(filename))
    return contents, filename, uptodate

  def get_loaded_templates(self):
    return list(self.loaded_templates)


def ProcessFile(env, input_filename, loader_base_dir, output_filename,
                variables):
  input_rel_path = os.path.relpath(input_filename, loader_base_dir)
  template = env.get_template(input_rel_path)
  output = template.render(variables)
  with codecs.open(output_filename, 'w', 'utf-8') as output_file:
    output_file.write(output)


def ProcessFiles(env, input_filenames, loader_base_dir, inputs_base_dir,
                 outputs_zip, variables):
  with build_utils.TempDir() as temp_dir:
    for input_filename in input_filenames:
      relpath = os.path.relpath(os.path.abspath(input_filename),
                                os.path.abspath(inputs_base_dir))
      if relpath.startswith(os.pardir):
        raise Exception('input file %s is not contained in inputs base dir %s'
                        % (input_filename, inputs_base_dir))

      output_filename = os.path.join(temp_dir, relpath)
      parent_dir = os.path.dirname(output_filename)
      build_utils.MakeDirectory(parent_dir)
      ProcessFile(env, input_filename, loader_base_dir, output_filename,
                  variables)

    build_utils.ZipDir(outputs_zip, temp_dir)


def main():
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)
  parser.add_option('--inputs', help='The template files to process.')
  parser.add_option('--output', help='The output file to generate. Valid '
                    'only if there is a single input.')
  parser.add_option('--outputs-zip', help='A zip file containing the processed '
                    'templates. Required if there are multiple inputs.')
  parser.add_option('--inputs-base-dir', help='A common ancestor directory of '
                    'the inputs. Each output\'s path in the output zip will '
                    'match the relative path from INPUTS_BASE_DIR to the '
                    'input. Required if --output-zip is given.')
  parser.add_option('--loader-base-dir', help='Base path used by the template '
                    'loader. Must be a common ancestor directory of '
                    'the inputs. Defaults to CHROMIUM_SRC.',
                    default=build_utils.CHROMIUM_SRC)
  parser.add_option('--variables', help='Variables to be made available in the '
                    'template processing environment, as a GYP list (e.g. '
                    '--variables "channel=beta mstone=39")', default='')
  options, args = parser.parse_args()

  build_utils.CheckOptions(options, parser, required=['inputs'])
  inputs = build_utils.ParseGypList(options.inputs)

  if (options.output is None) == (options.outputs_zip is None):
    parser.error('Exactly one of --output and --output-zip must be given')
  if options.output and len(inputs) != 1:
    parser.error('--output cannot be used with multiple inputs')
  if options.outputs_zip and not options.inputs_base_dir:
    parser.error('--inputs-base-dir must be given when --output-zip is used')
  if args:
    parser.error('No positional arguments should be given.')

  variables = {}
  for v in build_utils.ParseGypList(options.variables):
    if '=' not in v:
      parser.error('--variables argument must contain "=": ' + v)
    name, _, value = v.partition('=')
    variables[name] = value

  loader = RecordingFileSystemLoader(options.loader_base_dir)
  env = jinja2.Environment(loader=loader, undefined=jinja2.StrictUndefined,
                           line_comment_prefix='##')
  if options.output:
    ProcessFile(env, inputs[0], options.loader_base_dir, options.output,
                variables)
  else:
    ProcessFiles(env, inputs, options.loader_base_dir, options.inputs_base_dir,
                 options.outputs_zip, variables)

  if options.depfile:
    deps = loader.get_loaded_templates() + build_utils.GetPythonDependencies()
    build_utils.WriteDepfile(options.depfile, deps)


if __name__ == '__main__':
  main()
