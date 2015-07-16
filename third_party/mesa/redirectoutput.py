# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import os.path
import subprocess
import sys

if len(sys.argv) < 3:
  print "Usage: %s OUTPUTFILE SCRIPTNAME ARGUMENTS" % sys.argv[0]
  print "Re-execs the python interpreter against SCRIPTNAME with ARGS,"
  print "redirecting output to OUTPUTFILE."
  sys.exit(1)

abs_outputfile = os.path.abspath(sys.argv[1])
abs_outputdir = os.path.dirname(abs_outputfile)

if not os.path.isdir(abs_outputdir):
  os.makedirs(abs_outputdir)

ret = 0

with open(abs_outputfile, "w") as f:
  ret = subprocess.Popen([sys.executable] + sys.argv[2:], stdout=f).wait()

if ret:
  os.remove(abs_outputfile)
  sys.exit(ret)
