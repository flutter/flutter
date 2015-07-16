# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the InstrumentationOptions named tuple."""

import collections

InstrumentationOptions = collections.namedtuple('InstrumentationOptions', [
    'tool',
    'annotations',
    'exclude_annotations',
    'test_filter',
    'test_data',
    'save_perf_json',
    'screenshot_failures',
    'wait_for_debugger',
    'coverage_dir',
    'test_apk',
    'test_apk_path',
    'test_apk_jar_path',
    'test_runner',
    'test_support_apk_path',
    'device_flags',
    'isolate_file_path',
    'set_asserts',
    'delete_stale_data'])
