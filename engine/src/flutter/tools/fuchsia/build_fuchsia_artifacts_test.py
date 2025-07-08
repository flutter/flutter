#!/usr/bin/env vpython3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

import build_fuchsia_artifacts


class BuildFuchsiaArtifactsTest(unittest.TestCase):

  def test_read_fuchsia_target_api_level(self):
    self.assertGreater(int(build_fuchsia_artifacts.ReadTargetAPILevel()), 21)


if __name__ == '__main__':
  unittest.main()
