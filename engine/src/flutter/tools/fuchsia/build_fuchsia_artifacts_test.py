#!/usr/bin/env vpython3

import unittest

import build_fuchsia_artifacts


class BuildFuchsiaArtifactsTest(unittest.TestCase):

  def test_read_fuchsia_target_api_level(self):
    # It's expected to update this test each time the fuchsia_target_api_level
    # in //flutter/build/config/fuchsia/gn_configs.gni is changed, so we don't
    # accidentally publish the artifacts with an incorrect api level suffix.
    self.assertEqual(build_fuchsia_artifacts.ReadTargetAPILevel(), '18')


if __name__ == '__main__':
  unittest.main()
