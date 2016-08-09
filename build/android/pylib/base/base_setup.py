# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Base script for doing test setup."""

import logging
import os

from pylib import constants
from pylib import valgrind_tools
from pylib.utils import isolator

def GenerateDepsDirUsingIsolate(suite_name, isolate_file_path,
                                isolate_file_paths, deps_exclusion_list):
  """Generate the dependency dir for the test suite using isolate.

  Args:
    suite_name: Name of the test suite (e.g. base_unittests).
    isolate_file_path: .isolate file path to use. If there is a default .isolate
                       file path for the suite_name, this will override it.
    isolate_file_paths: Dictionary with the default .isolate file paths for
                        the test suites.
    deps_exclusion_list: A list of files that are listed as dependencies in the
                         .isolate files but should not be pushed to the device.
  Returns:
    The Isolator instance used to remap the dependencies, or None.
  """
  if isolate_file_path:
    if os.path.isabs(isolate_file_path):
      isolate_abs_path = isolate_file_path
    else:
      isolate_abs_path = os.path.join(constants.DIR_SOURCE_ROOT,
                                      isolate_file_path)
  else:
    isolate_rel_path = isolate_file_paths.get(suite_name)
    if not isolate_rel_path:
      logging.info('Did not find an isolate file for the test suite.')
      return
    isolate_abs_path = os.path.join(constants.DIR_SOURCE_ROOT, isolate_rel_path)

  isolated_abs_path = os.path.join(
      constants.GetOutDirectory(), '%s.isolated' % suite_name)
  assert os.path.exists(isolate_abs_path), 'Cannot find %s' % isolate_abs_path

  i = isolator.Isolator(constants.ISOLATE_DEPS_DIR)
  i.Clear()
  i.Remap(isolate_abs_path, isolated_abs_path)
  # We're relying on the fact that timestamps are preserved
  # by the remap command (hardlinked). Otherwise, all the data
  # will be pushed to the device once we move to using time diff
  # instead of md5sum. Perform a sanity check here.
  i.VerifyHardlinks()
  i.PurgeExcluded(deps_exclusion_list)
  i.MoveOutputDeps()
  return i


def PushDataDeps(device, device_dir, test_options):
  valgrind_tools.PushFilesForTool(test_options.tool, device)
  if os.path.exists(constants.ISOLATE_DEPS_DIR):
    device.PushChangedFiles([(constants.ISOLATE_DEPS_DIR, device_dir)],
                            delete_device_stale=test_options.delete_stale_data)
