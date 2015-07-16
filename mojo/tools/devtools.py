# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys


def add_lib_to_path():
  """ Adds the devtools pylib to path, allowing to use it in the internal
  /mojo/tools/ tooling. """
  sys.path.append(os.path.join(os.path.dirname(__file__),
                               os.pardir,
                               "devtools",
                               "common"))
