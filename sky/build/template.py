#!/usr/bin/env python
#
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''Renders a single template file using the Jinga templating engine.'''

import argparse
import sys
import os
import itertools

sys.path.append(os.path.join(os.path.dirname(__file__), '../../../third_party'))
import jinja2
from jinja2 import Environment, FileSystemLoader


def make_stamp_file(stamp_path):
  dir_name = os.path.dirname(stamp_path)

  with open(stamp_path, 'a'):
    os.utime(stamp_path, None)


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  
  parser.add_argument('--template', help='The template file to render')
  parser.add_argument('--stamp', help='The template stamp file')
  parser.add_argument('--output',
                      help='The output file to render the template to')
  parser.add_argument('vars', metavar='V', nargs='+',
                      help='A list of key value pairs used as template args')

  args = parser.parse_args()

  template_file = os.path.abspath(args.template)

  if not os.path.isfile(template_file):
    print 'Cannot find file at path: ', template_file
    return 1

  env = jinja2.Environment(loader=FileSystemLoader('/'),
                           undefined=jinja2.StrictUndefined)

  template = env.get_template(template_file)

  variables = dict(itertools.izip_longest(*[iter(args.vars)] * 2, fillvalue=''))

  output = template.render(variables)

  with open(os.path.abspath(args.output), 'wb') as file:
    file.write(output)

  make_stamp_file(args.stamp)

if __name__ == '__main__':
  main()
