# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the GTestOptions named tuple."""

import collections

GTestOptions = collections.namedtuple('GTestOptions', [
    'tool',
    'gtest_filter',
    'run_disabled',
    'test_arguments',
    'timeout',
    'isolate_file_path',
    'suite_name',
    'app_data_files',
    'app_data_file_dir',
    'delete_stale_data'])
