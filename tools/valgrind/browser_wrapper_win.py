# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import glob
import os
import re
import sys
import subprocess

# TODO(timurrrr): we may use it on POSIX too to avoid code duplication once we
# support layout_tests, remove Dr. Memory specific code and verify it works
# on a "clean" Mac.

testcase_name = None
for arg in sys.argv:
  m = re.match("\-\-gtest_filter=(.*)", arg)
  if m:
    assert testcase_name is None
    testcase_name = m.groups()[0]

# arg #0 is the path to this python script
cmd_to_run = sys.argv[1:]

# TODO(timurrrr): this is Dr. Memory-specific
# Usually, we pass "-logdir" "foo\bar\spam path" args to Dr. Memory.
# To group reports per UI test, we want to put the reports for each test into a
# separate directory. This code can be simplified when we have
# https://github.com/DynamoRIO/drmemory/issues/684 fixed.
logdir_idx = cmd_to_run.index("-logdir")
old_logdir = cmd_to_run[logdir_idx + 1]

wrapper_pid = str(os.getpid())

# On Windows, there is a chance of PID collision. We avoid it by appending the
# number of entries in the logdir at the end of wrapper_pid.
# This number is monotonic and we can't have two simultaneously running wrappers
# with the same PID.
wrapper_pid += "_%d" % len(glob.glob(old_logdir + "\\*"))

cmd_to_run[logdir_idx + 1] += "\\testcase.%s.logs" % wrapper_pid
os.makedirs(cmd_to_run[logdir_idx + 1])

if testcase_name:
  f = open(old_logdir + "\\testcase.%s.name" % wrapper_pid, "w")
  print >>f, testcase_name
  f.close()

exit(subprocess.call(cmd_to_run))
