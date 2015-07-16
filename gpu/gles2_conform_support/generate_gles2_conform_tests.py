#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""code generator for OpenGL ES 2.0 conformance tests."""

import os
import re
import sys

def ReadFileAsLines(filename):
  """Reads a file, removing blank lines and lines that start with #"""
  file = open(filename, "r")
  raw_lines = file.readlines()
  file.close()
  lines = []
  for line in raw_lines:
    line = line.strip()
    if len(line) > 0 and not line.startswith("#"):
      lines.append(line)
  return lines


def GenerateTests(file):
  """Generates gles2_conform_test_autogen.cc"""

  tests = ReadFileAsLines(
      "../../third_party/gles2_conform/GTF_ES/glsl/GTF/mustpass_es20.run")

  file.write("""
#include "gpu/gles2_conform_support/gles2_conform_test.h"
#include "testing/gtest/include/gtest/gtest.h"
""")

  for test in tests:
    file.write("""
TEST(GLES2ConformTest, %(name)s) {
  EXPECT_TRUE(RunGLES2ConformTest("%(path)s"));
}
""" % {
        "name": re.sub(r'[^A-Za-z0-9]', '_', test),
        "path": test,
      })


def main(argv):
  """This is the main function."""

  if len(argv) >= 1:
    dir = argv[0]
  else:
    dir = '.'

  file = open(os.path.join(dir, 'gles2_conform_test_autogen.cc'), 'wb')
  GenerateTests(file)
  file.close()

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
