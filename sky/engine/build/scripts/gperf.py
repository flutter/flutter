# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Invokes gperf for the GN build. The first argument is the path to gperf.
# TODO(brettw) this can be removed once the run_executable rules have been
# checked in for the GN build.

import subprocess
import sys

subprocess.check_call(sys.argv[1:])
