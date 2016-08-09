#!/usr/bin/python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import subprocess
import sys
import re

def ListIdentities():
  return subprocess.check_output([
    '/usr/bin/env',
    'xcrun',
    'security',
    'find-identity',
    '-v',
    '-p',
    'codesigning',
  ]).strip()


def FindValidIdentity():
  lines = ListIdentities().splitlines()
  # Look for something like "2) XYZ "iPhone Developer: Name (ABC)""
  exp = re.compile('.*\) ([A-F|0-9]*)(.*)')
  for line in lines:
    res = exp.match(line)
    if res is None:
      continue
    if "iPhone Developer: Google Development" in res.group(2):
      return res.group(1)
  return ""


if __name__ == '__main__':
  print FindValidIdentity()
