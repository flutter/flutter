#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A tool that runs a perf test and uploads the resulting data to the
performance dashboard.
"""

import argparse
from mopy import perf_data_uploader
from mopy.version import Version
import subprocess
import sys


def _GetCurrentCommitCount():
  return subprocess.check_output(
      ["git", "rev-list", "HEAD", "--count"]).strip()


def main():
  parser = argparse.ArgumentParser(
      description="A tool that runs a perf test and uploads the resulting data "
                  "to the performance dashboard.")

  parser.add_argument(
      "--master-name",
      help="Buildbot master name, used to construct link to buildbot log by "
           "the dashboard, and also as the top-level category for the data.")
  parser.add_argument(
      "--perf-id",
      help="Used as the second-level category for the data, usually the "
           "platform type.")
  parser.add_argument(
      "--test-name",
      help="Name of the test that the perf data was generated from.")
  parser.add_argument(
      "--builder-name",
      help="Buildbot builder name, used to construct link to buildbot log by "
           "the dashboard.")
  parser.add_argument(
      "--build-number", type=int,
      help="Build number, used to construct link to buildbot log by the "
           "dashboard.")
  parser.add_argument(
      "--perf-data-path",
      help="The path to the perf data that the perf test generates.")
  server_group = parser.add_mutually_exclusive_group()
  server_group.add_argument(
      "--testing-dashboard", action="store_true", default=True,
      help="Upload the data to the testing dashboard (default).")
  server_group.add_argument(
      "--production-dashboard", dest="testing_dashboard", action="store_false",
      default=False, help="Upload the data to the production dashboard.")
  parser.add_argument("command", nargs=argparse.REMAINDER)
  args = parser.parse_args()

  subprocess.check_call(args.command)

  if args.master_name is None or \
     args.perf_id is None or \
     args.test_name is None or \
     args.builder_name is None or \
     args.build_number is None or \
     args.perf_data_path is None:
    print "Won't upload perf data to the dashboard because not all of the " \
          "following values are specified: master-name, perf-id, test-name, " \
          "builder-name, build-number, perf-data-path."
    return 0

  revision = Version().version
  perf_data = open(args.perf_data_path, "r")
  point_id = _GetCurrentCommitCount()

  result = perf_data_uploader.UploadPerfData(
      args.master_name, args.perf_id, args.test_name, args.builder_name,
      args.build_number, revision, perf_data, point_id, False,
      args.testing_dashboard)

  return 0 if result else 1


if __name__ == '__main__':
  sys.exit(main())
