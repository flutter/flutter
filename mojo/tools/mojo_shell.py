#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys


def main():
  print 'Good news, the shell runner has moved! Please use: '
  print ''
  print '  mojo/devtools/common/mojo_shell'
  print ''
  print 'as you would use mojo_shell.py before.'
  return -1

if __name__ == "__main__":
  sys.exit(main())
