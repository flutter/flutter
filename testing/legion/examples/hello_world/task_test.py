#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A simple client test module.

This module is invoked by the host by calling the client controller's
Subprocess RPC method. The name is passed in as a required argument on the
command line.
"""

import argparse
import os
import sys


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('name')
  args = parser.parse_args()
  print 'Hello world from', args.name
  return 0


if __name__ == '__main__':
  sys.exit(main())
