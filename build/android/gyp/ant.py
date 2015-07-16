#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""An Ant wrapper that suppresses useless Ant output.

Ant build scripts output "BUILD SUCCESSFUL" and build timing at the end of
every build. In the Android build, this just adds a lot of useless noise to the
build output. This script forwards its arguments to ant, and prints Ant's
output up until the BUILD SUCCESSFUL line.

Also, when a command fails, this script will re-run that ant command with the
'-verbose' argument so that the failure is easier to debug.
"""

import optparse
import sys
import traceback

from util import build_utils


def main(argv):
  option_parser = optparse.OptionParser()
  build_utils.AddDepfileOption(option_parser)
  options, args = option_parser.parse_args(argv[1:])

  try:
    stdout = build_utils.CheckOutput(['ant'] + args)
  except build_utils.CalledProcessError:
    # It is very difficult to diagnose ant failures without the '-verbose'
    # argument. So, when an ant command fails, re-run it with '-verbose' so that
    # the cause of the failure is easier to identify.
    verbose_args = ['-verbose'] + [a for a in args if a != '-quiet']
    try:
      stdout = build_utils.CheckOutput(['ant'] + verbose_args)
    except build_utils.CalledProcessError:
      traceback.print_exc()
      sys.exit(1)

    # If this did sys.exit(1), building again would succeed (which would be
    # awkward). Instead, just print a big warning.
    build_utils.PrintBigWarning(
        'This is unexpected. `ant ' + ' '.join(args) + '` failed.' +
        'But, running `ant ' + ' '.join(verbose_args) + '` passed.')

  stdout = stdout.strip().split('\n')
  for line in stdout:
    if line.strip() == 'BUILD SUCCESSFUL':
      break
    print line

  if options.depfile:
    assert '-buildfile' in args
    ant_buildfile = args[args.index('-buildfile') + 1]

    build_utils.WriteDepfile(
        options.depfile,
        [ant_buildfile] + build_utils.GetPythonDependencies())


if __name__ == '__main__':
  sys.exit(main(sys.argv))
