# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import itertools
import sys
import unittest

import mopy.gn as gn

from mopy.config import Config


class GTestListTestsTest(unittest.TestCase):
  """Tests mopy.gn."""

  def testConfigToGNToConfig(self):
    """Tests that config to gn to config is the identity"""
    configs_to_test = {
      "target_os": [None, "android", "linux", "ios"],
      "target_cpu": [None, "x86", "x64", "arm"],
      "is_simulator": [False, True],
      "is_debug": [False, True],
      "is_official_build": [False, True],
      "is_clang": [False, True],
      "sanitizer": [None, Config.SANITIZER_ASAN],
      "use_goma": [False],
      "use_nacl": [False, True],
      "mojo_use_go": [False],
      "dcheck_always_on": [False, True],
    }
    if sys.platform == "darwin":
      configs_to_test["target_os"].remove("linux")

    for args in _iterate_over_config(configs_to_test):
      if args.get("target_os") != "ios" and args["is_simulator"]:
        continue
      config = Config(**args)
      gn_args = gn.GNArgsForConfig(config)
      new_config = gn.ConfigForGNArgs(gn_args)
      self.assertDictEqual(config.values, new_config.values)

  def testGNToConfigToGN(self):
    """Tests that gn to config to gn is the identity"""
    # TODO(vtl): Test OSes other than None (== host?) and "android".
    configs_to_test = {
      "target_os": [None, "android"],
      "target_cpu": ["x86", "x64", "arm"],
      "is_debug": [False, True],
      "is_official_build": [False, True],
      "is_clang": [False, True],
      "is_asan": [False, True],
      "use_goma": [False],
      "mojo_use_nacl": [False, True],
      "mojo_use_go": [False],
      "dcheck_always_on": [False, True],
    }

    for args in _iterate_over_config(configs_to_test):
      if args.get("target_os", None) is None and sys.platform[:5] == "linux":
        args["use_aura"] = False
        args["use_glib"] = False
        args["use_system_harfbuzz"] = False
      config = gn.ConfigForGNArgs(args)
      new_args = gn.GNArgsForConfig(config)
      self.assertDictEqual(args, new_args)


def _iterate_over_config(config):
  def product_to_dict(p):
    return dict(filter(lambda x: x[1] is not None, zip(config.keys(), p)))
  return itertools.imap(product_to_dict, itertools.product(*config.values()))


if __name__ == "__main__":
  unittest.main()
