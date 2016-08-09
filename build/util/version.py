#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
version.py -- Chromium version string substitution utility.
"""

import argparse
import os
import sys


def fetch_values_from_file(values_dict, file_name):
  """
  Fetches KEYWORD=VALUE settings from the specified file.

  Everything to the left of the first '=' is the keyword,
  everything to the right is the value.  No stripping of
  white space, so beware.

  The file must exist, otherwise you get the Python exception from open().
  """
  for line in open(file_name, 'r').readlines():
    key, val = line.rstrip('\r\n').split('=', 1)
    values_dict[key] = val


def fetch_values(file_list):
  """
  Returns a dictionary of values to be used for substitution, populating
  the dictionary with KEYWORD=VALUE settings from the files in 'file_list'.

  Explicitly adds the following value from internal calculations:

    OFFICIAL_BUILD
  """
  CHROME_BUILD_TYPE = os.environ.get('CHROME_BUILD_TYPE')
  if CHROME_BUILD_TYPE == '_official':
    official_build = '1'
  else:
    official_build = '0'

  values = dict(
    OFFICIAL_BUILD = official_build,
  )

  for file_name in file_list:
    fetch_values_from_file(values, file_name)

  return values


def subst_template(contents, values):
  """
  Returns the template with substituted values from the specified dictionary.

  Keywords to be substituted are surrounded by '@':  @KEYWORD@.

  No attempt is made to avoid recursive substitution.  The order
  of evaluation is random based on the order of the keywords returned
  by the Python dictionary.  So do NOT substitute a value that
  contains any @KEYWORD@ strings expecting them to be recursively
  substituted, okay?
  """
  for key, val in values.iteritems():
    try:
      contents = contents.replace('@' + key + '@', val)
    except TypeError:
      print repr(key), repr(val)
  return contents


def subst_file(file_name, values):
  """
  Returns the contents of the specified file_name with substituted
  values from the specified dictionary.

  This is like subst_template, except it operates on a file.
  """
  template = open(file_name, 'r').read()
  return subst_template(template, values);


def write_if_changed(file_name, contents):
  """
  Writes the specified contents to the specified file_name
  iff the contents are different than the current contents.
  """
  try:
    old_contents = open(file_name, 'r').read()
  except EnvironmentError:
    pass
  else:
    if contents == old_contents:
      return
    os.unlink(file_name)
  open(file_name, 'w').write(contents)


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('-f', '--file', action='append', default=[],
                      help='Read variables from FILE.')
  parser.add_argument('-i', '--input', default=None,
                      help='Read strings to substitute from FILE.')
  parser.add_argument('-o', '--output', default=None,
                      help='Write substituted strings to FILE.')
  parser.add_argument('-t', '--template', default=None,
                      help='Use TEMPLATE as the strings to substitute.')
  parser.add_argument('-e', '--eval', action='append', default=[],
                      help='Evaluate VAL after reading variables. Can be used '
                           'to synthesize variables. e.g. -e \'PATCH_HI=int('
                           'PATCH)/256.')
  parser.add_argument('args', nargs=argparse.REMAINDER,
                      help='For compatibility: INPUT and OUTPUT can be '
                           'passed as positional arguments.')
  options = parser.parse_args()

  evals = {}
  for expression in options.eval:
    try:
      evals.update(dict([expression.split('=', 1)]))
    except ValueError:
      parser.error('-e requires VAR=VAL')

  # Compatibility with old versions that considered the first two positional
  # arguments shorthands for --input and --output.
  while len(options.args) and (options.input is None or \
                               options.output is None):
    if options.input is None:
      options.input = options.args.pop(0)
    elif options.output is None:
      options.output = options.args.pop(0)
  if options.args:
    parser.error('Unexpected arguments: %r' % options.args)

  values = fetch_values(options.file)
  for key, val in evals.iteritems():
    values[key] = str(eval(val, globals(), values))

  if options.template is not None:
    contents = subst_template(options.template, values)
  elif options.input:
    contents = subst_file(options.input, values)
  else:
    # Generate a default set of version information.
    contents = """MAJOR=%(MAJOR)s
MINOR=%(MINOR)s
BUILD=%(BUILD)s
PATCH=%(PATCH)s
LASTCHANGE=%(LASTCHANGE)s
OFFICIAL_BUILD=%(OFFICIAL_BUILD)s
""" % values

  if options.output is not None:
    write_if_changed(options.output, contents)
  else:
    print contents

  return 0


if __name__ == '__main__':
  sys.exit(main())
