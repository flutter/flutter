# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the UIAutomatorOptions named tuple."""

import collections

UIAutomatorOptions = collections.namedtuple('UIAutomatorOptions', [
    'tool',
    'annotations',
    'exclude_annotations',
    'test_filter',
    'test_data',
    'save_perf_json',
    'screenshot_failures',
    'uiautomator_jar',
    'uiautomator_info_jar',
    'package',
    'set_asserts'])
