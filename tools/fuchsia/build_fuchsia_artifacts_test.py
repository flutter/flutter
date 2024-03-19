#!/usr/bin/env vpython3

import unittest

import build_fuchsia_artifacts


class BuildFuchsiaArtifactsTest(unittest.TestCase):

  def test_read_fuchsia_target_api_level(self):
    # It's expected to update this test each time the fuchsia_target_api_level
    # in //flutter/build/config/fuchsia/gn_configs.gni is changed, so it won't
    # accidentally publishing the artifacts with a wrong api level suffix.
    self.assertEqual(build_fuchsia_artifacts.ReadTargetAPILevel(), '16')


if __name__ == '__main__':
  unittest.main()
