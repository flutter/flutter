#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Central list of tests to run (as appropriate for a given config). Add tests
to run by modifying this file.

Note that this file is both imported (by mojob.py) and run directly (via a
recipe)."""


import argparse
import json
import os
import sys

from mopy.config import Config
from mopy.paths import Paths


def GetTestList(config, verbose_count=0):
  """Gets the list of tests to run for the given config. The test list (which is
  returned) is just a list of dictionaries, each dictionary having two required
  fields:
    {
      "name": "Short name",
      "command": ["python", "test_runner.py", "--some", "args"]
    }
  """

  types_to_run = set(config.test_types)

  # See above for a description of the test list.
  test_list = []

  paths = Paths(config)
  build_dir = paths.SrcRelPath(paths.build_dir)
  target_os = config.target_os

  verbose_flags = verbose_count * ["--verbose"]

  # Utility functions ----------------------------------------------------------

  # Call this to determine if a test matching classes this_tests_types should
  # run: e.g., ShouldRunTest(Config.TEST_TYPE_DEFAULT, "sky") returns true if
  # the test list being requested specifies the default set or the "sky" set.
  def ShouldRunTest(*this_tests_types):
    return not types_to_run.isdisjoint(this_tests_types)

  # Call this to add the given command to the test list.
  def AddEntry(name, command):
    if config.sanitizer == Config.SANITIZER_ASAN:
      command = (["python", os.path.join("mojo", "tools",
                                         "run_command_through_symbolizer.py")] +
                 command)
    test_list.append({"name": name, "command": command})

  # Call this to add the given command to the test list. If appropriate, the
  # command will be run under xvfb.
  def AddXvfbEntry(name, command):
    real_command = ["python"]
    if config.target_os == Config.OS_LINUX:
      real_command += ["./testing/xvfb.py", paths.SrcRelPath(paths.build_dir)]
    real_command += command
    AddEntry(name, real_command)

  # ----------------------------------------------------------------------------

  # TODO(vtl): Currently, we only know how to run tests for Android, Linux, or
  # Windows.
  if target_os not in (Config.OS_ANDROID, Config.OS_LINUX, Config.OS_WINDOWS,
                       Config.OS_IOS):
    return test_list

  # Tests run by default -------------------------------------------------------

  # C++ unit tests:
  if ShouldRunTest(Config.TEST_TYPE_DEFAULT, Config.TEST_TYPE_UNIT):
    AddXvfbEntry("Unit tests",
                 [os.path.join("mojo", "tools", "test_runner.py"),
                  os.path.join("mojo", "tools", "data", "unittests"),
                  build_dir] + verbose_flags)
    # NaCl tests (Linux only):
    if (target_os == Config.OS_LINUX and
        config.sanitizer != Config.SANITIZER_ASAN):
      AddEntry("NaCl tests",
               [os.path.join(build_dir, "monacl_shell"),
                os.path.join(build_dir, "irt_" + config.target_cpu,
                             "irt_mojo.nexe"),
                os.path.join(build_dir, "clang_newlib_" + config.target_cpu,
                             "monacl_test.nexe")])

  # C++ app tests:
  if ShouldRunTest(Config.TEST_TYPE_DEFAULT, "app"):
    AddXvfbEntry("App tests",
                 [os.path.join("mojo", "tools", "apptest_runner.py"),
                  os.path.join("mojo", "tools", "data", "apptests"),
                  build_dir] + verbose_flags)
    # NaCl app tests (Linux only):
    if (target_os == Config.OS_LINUX and
        config.sanitizer != Config.SANITIZER_ASAN):
      AddXvfbEntry("NaCl app tests",
                   [os.path.join("mojo", "tools", "apptest_runner.py"),
                    os.path.join("mojo", "tools", "data", "nacl_apptests"),
                    build_dir] + verbose_flags)

  # Go unit tests (Linux-only):
  if (target_os == Config.OS_LINUX and
      config.sanitizer != Config.SANITIZER_ASAN and
      ShouldRunTest(Config.TEST_TYPE_DEFAULT, Config.TEST_TYPE_UNIT, "go")):
    AddEntry("Go unit tests",
             [os.path.join(build_dir, "obj", "mojo", "go", "system_test")])

  # Python unit tests:
  if ShouldRunTest(Config.TEST_TYPE_DEFAULT, Config.TEST_TYPE_UNIT, "python"):
    AddEntry("Python unit tests",
             ["python", os.path.join("mojo", "tools",
              "run_mojo_python_tests.py")])

  # Python bindings tests (Linux-only):
  # See http://crbug.com/438781 for details on asan exclusion.
  if (target_os == Config.OS_LINUX and
      ShouldRunTest(Config.TEST_TYPE_DEFAULT, Config.TEST_TYPE_UNIT,
                    "python") and
      config.sanitizer != Config.SANITIZER_ASAN):
    AddEntry("Python bindings tests",
             ["python",
              os.path.join("mojo", "tools",
                           "run_mojo_python_bindings_tests.py"),
              "--build-dir=" + build_dir])

  # Sky tests (Linux-only):
  # TODO(abarth): Re-enabled in ASAN once the DartVM works in ASAN.
  # See https://code.google.com/p/dart/issues/detail?id=22122
  if (target_os == Config.OS_LINUX and
      ShouldRunTest(Config.TEST_TYPE_DEFAULT, "sky") and
      config.sanitizer != Config.SANITIZER_ASAN):
    sky_command = ["python",
                   "sky/tools/test_sky",
                   "-t", os.path.basename(build_dir),
                   "--no-new-test-results", "--no-show-results", "--verbose"]
    if config.values.get("builder_name"):
      sky_command += ["--builder-name", config.values["builder_name"]]
    if config.values.get("build_number"):
      sky_command += ["--build-number", config.values["build_number"]]
    if config.values.get("master_name"):
      sky_command += ["--master-name", config.values["master_name"]]
    if config.values.get("test_results_server"):
      sky_command += ["--test-results-server",
                      config.values["test_results_server"]]
    AddXvfbEntry("Sky tests", sky_command)

  # Observatory tests (Linux-only):
  if target_os == Config.OS_LINUX:
    AddEntry("Dart Observatory tests",
             ["python",
              os.path.join("mojo", "dart", "observatory_tester", "runner.py"),
              "--build-dir=" + build_dir,
              "--dart-exe=third_party/dart-sdk/dart-sdk/bin/dart"])

  # mojo tools unit tests:
  if ShouldRunTest(Config.TEST_TYPE_DEFAULT, Config.TEST_TYPE_UNIT, "tools"):
    AddEntry("Mojo tools unit tests",
             ["python", os.path.join("mojo", "tools", "testing",
                                     "mojom_fetcher",
                                     "mojom_fetcher_tests.py")])
  # Perf tests -----------------------------------------------------------------

  if target_os == Config.OS_LINUX and ShouldRunTest(Config.TEST_TYPE_PERF):
    perf_id = "linux_%s" % ("debug" if config.is_debug else "release")
    test_names = ["mojo_public_system_perftests",
                  "mojo_public_bindings_perftests"]

    for test_name in test_names:
      command = ["python",
                 os.path.join("mojo", "tools", "perf_test_runner.py"),
                 "--perf-id", perf_id,
                 "--test-name", test_name,
                 "--perf-data-path",
                 os.path.join(build_dir, test_name + "_perf.log"),
                 "--production-dashboard"]
      if config.values.get("builder_name"):
        command += ["--builder-name", config.values["builder_name"]]
      if config.values.get("build_number"):
        command += ["--build-number", config.values["build_number"]]
      if config.values.get("master_name"):
        command += ["--master-name", config.values["master_name"]]
      command += [os.path.join(build_dir, test_name)]

      AddEntry(test_name, command)

  # Integration tests ----------------------------------------------------------

  if target_os == Config.OS_ANDROID and ShouldRunTest(
      Config.TEST_TYPE_DEFAULT, Config.TEST_TYPE_INTEGRATION):
    AddEntry("Integration test (MojoTest)",
             ["python",
              os.path.join("build", "android", "test_runner.py"),
              "instrumentation",
              "--test-apk=MojoTest",
              "--output-directory=%s" % build_dir,
              "--test_data=bindings:mojo/public/interfaces/bindings/tests/data"]
             + verbose_flags)

  return test_list


def main():
  parser = argparse.ArgumentParser(description="Gets tests to execute.")
  parser.add_argument("config_file", metavar="config.json",
                      type=argparse.FileType("rb"),
                      help="Input JSON file with test configuration.")
  parser.add_argument("test_list_file", metavar="test_list.json", nargs="?",
                      type=argparse.FileType("wb"), default=sys.stdout,
                      help="Output JSON file with test list.")
  args = parser.parse_args()

  config = Config(**json.load(args.config_file))
  test_list = GetTestList(config)
  json.dump(test_list, args.test_list_file, indent=2)
  args.test_list_file.write("\n")

  return 0


if __name__ == "__main__":
  sys.exit(main())
