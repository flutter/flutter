# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the PerfOptions named tuple."""

import collections

PerfOptions = collections.namedtuple('PerfOptions', [
    'steps',
    'flaky_steps',
    'output_json_list',
    'print_step',
    'no_timeout',
    'test_filter',
    'dry_run',
    'single_step',
    'collect_chartjson_data',
    'output_chartjson_data',
    'max_battery_temp',
    'min_battery_level',
])
