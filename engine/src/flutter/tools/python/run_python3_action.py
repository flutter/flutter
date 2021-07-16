#!/usr/bin/env python
#
# Copyright 2021 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys

os.execv('/usr/bin/python3', ['python3'] + sys.argv[1:])
