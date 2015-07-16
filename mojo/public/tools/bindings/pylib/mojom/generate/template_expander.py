# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Based on:
# http://src.chromium.org/viewvc/blink/trunk/Source/build/scripts/template_expander.py

import imp
import inspect
import os.path
import sys

# Disable lint check for finding modules:
# pylint: disable=F0401

def _GetDirAbove(dirname):
  """Returns the directory "above" this file containing |dirname| (which must
  also be "above" this file)."""
  path = os.path.abspath(__file__)
  while True:
    path, tail = os.path.split(path)
    assert tail
    if tail == dirname:
      return path

try:
  imp.find_module("jinja2")
except ImportError:
  sys.path.append(os.path.join(_GetDirAbove("public"), "public/third_party"))
import jinja2


def ApplyTemplate(mojo_generator, base_dir, path_to_template, params,
                  filters=None, **kwargs):
  template_directory, template_name = os.path.split(path_to_template)
  path_to_templates = os.path.join(base_dir, template_directory)
  loader = jinja2.FileSystemLoader([path_to_templates])
  final_kwargs = dict(mojo_generator.GetJinjaParameters())
  final_kwargs.update(kwargs)
  jinja_env = jinja2.Environment(loader=loader, keep_trailing_newline=True,
                                 **final_kwargs)
  jinja_env.globals.update(mojo_generator.GetGlobals())
  if filters:
    jinja_env.filters.update(filters)
  template = jinja_env.get_template(template_name)
  return template.render(params)


def UseJinja(path_to_template, **kwargs):
  # Get the directory of our caller's file.
  base_dir = os.path.dirname(inspect.getfile(sys._getframe(1)))
  def RealDecorator(generator):
    def GeneratorInternal(*args, **kwargs2):
      parameters = generator(*args, **kwargs2)
      return ApplyTemplate(args[0], base_dir, path_to_template, parameters,
                           **kwargs)
    GeneratorInternal.func_name = generator.func_name
    return GeneratorInternal
  return RealDecorator
