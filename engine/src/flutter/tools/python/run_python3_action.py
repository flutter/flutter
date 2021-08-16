#!/usr/bin/env vpython3
#
# Copyright 2021 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
import subprocess

subprocess.run(['vpython3'] + sys.argv[1:])
