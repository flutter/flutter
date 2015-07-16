#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""BUILD file generator for mojoms."""

import argparse
import errno
import imp
import logging
import os
import sys
import urllib2

# Local library
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "pylib"))
# Bindings library
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "bindings", "pylib"))
# Jinja2 library
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "..", "third_party"))
import jinja2

from fetcher.repository import Repository


class BuildGNGenerator(object):
  def __init__(self, repository, template_dir):
    self._repository = repository
    self._import_dirs = []
    self.environment = jinja2.Environment(
        loader=jinja2.FileSystemLoader(template_dir))

  def generate(self):
    build_gn_tmpl = self.environment.get_template('build_gn.tmpl')
    directories = self._repository.get_all_external_mojom_directories()
    for directory in directories:
      logging.debug("Generating %s", directory.get_build_gn_path())
      params = directory.get_jinja_parameters(self._import_dirs)
      f = self._open(directory.get_build_gn_path(), "w")
      f.write(build_gn_tmpl.render(**params))

  def add_import_dirs(self, import_dirs):
    self._import_dirs.extend(import_dirs)

  def _open(self, filename, mode):
    return open(filename, mode)


def _main(args):
  repository_path = os.path.abspath(args.repository_path)
  repository = Repository(repository_path, args.external_dir)
  gn_generator = BuildGNGenerator(
      repository, os.path.dirname(os.path.abspath(__file__)))
  if args.extra_import_dirs:
    gn_generator.add_import_dirs(args.extra_import_dirs)
  gn_generator.generate()


def main():
  logging.basicConfig(level=logging.WARNING)
  parser = argparse.ArgumentParser(
      description='Generate BUILD.gn files for mojoms.')
  parser.add_argument('--repository-path', type=str, default='.',
                      help='The path to the client repository.')
  parser.add_argument('--external-dir', type=str, default='external',
                      help='Directory for external interfaces')
  parser.add_argument(
      '--extra-import-dirs', type=str, action='append',
      help='Additional directories to search for imported mojoms.')
  args = parser.parse_args()
  return _main(args)


if __name__ == '__main__':
  sys.exit(main())
