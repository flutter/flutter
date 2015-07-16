# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys

import test_support

EXPECT_EQ = test_support.EXPECT_EQ
EXPECT_TRUE = test_support.EXPECT_TRUE
RunTest = test_support.RunTest
ModulesAreEqual = test_support.ModulesAreEqual
BuildTestModule = test_support.BuildTestModule
TestTestModule = test_support.TestTestModule


def BuildAndTestModule():
  return TestTestModule(BuildTestModule())


def TestModulesEqual():
  return EXPECT_TRUE(ModulesAreEqual(BuildTestModule(), BuildTestModule()))


def Main(args):
  errors = 0
  errors += RunTest(BuildAndTestModule)
  errors += RunTest(TestModulesEqual)

  return errors


if __name__ == '__main__':
  sys.exit(Main(sys.argv[1:]))
