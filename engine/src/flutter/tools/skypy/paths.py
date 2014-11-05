# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

BUILD_DIRECTORY = 'out'
CONFIG_DIRECTORY = 'Debug'
SRC_ROOT = os.path.abspath(os.path.join(__file__,
    os.pardir, os.pardir, os.pardir, os.pardir))
SKY_ROOT = os.path.join(SRC_ROOT, 'sky')
GEN_ROOT = os.path.join(SRC_ROOT, BUILD_DIRECTORY, CONFIG_DIRECTORY, 'gen')
SKY_TOOLS_DIRECTORY = os.path.join(SRC_ROOT, 'sky', 'tools')
MOJO_SHELL_PATH = os.path.join(SRC_ROOT, BUILD_DIRECTORY, CONFIG_DIRECTORY, 'mojo_shell')
