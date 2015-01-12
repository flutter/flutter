# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

# FIXME: All callers should use mopy/paths.py instead!
class Paths(object):
    def __init__(self, build_directory):
        self.src_root = os.path.abspath(os.path.join(__file__,
            os.pardir, os.pardir, os.pardir, os.pardir))
        self.sky_root = os.path.join(self.src_root, 'sky')
        self.gen_root = os.path.join(self.src_root, build_directory, 'gen')
        self.sky_tools_directory = os.path.join(self.src_root, 'sky', 'tools')
        self.mojo_shell_path = os.path.join(self.src_root, build_directory, 'mojo_shell')
