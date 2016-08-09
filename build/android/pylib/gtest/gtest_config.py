# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Configuration file for android gtest suites."""

# Add new suites here before upgrading them to the stable list below.
EXPERIMENTAL_TEST_SUITES = [
    'components_browsertests',
    'content_gl_tests',
    'heap_profiler_unittests',
    'devtools_bridge_tests',
]

TELEMETRY_EXPERIMENTAL_TEST_SUITES = [
    'telemetry_unittests',
]

# Do not modify this list without approval of an android owner.
# This list determines which suites are run by default, both for local
# testing and on android trybots running on commit-queue.
STABLE_TEST_SUITES = [
    'android_webview_unittests',
    'base_unittests',
    'breakpad_unittests',
    'cc_unittests',
    'components_unittests',
    'content_browsertests',
    'content_unittests',
    'events_unittests',
    'gl_tests',
    'gl_unittests',
    'gpu_unittests',
    'ipc_tests',
    'media_unittests',
    'midi_unittests',
    'net_unittests',
    'sandbox_linux_unittests',
    'skia_unittests',
    'sql_unittests',
    'sync_unit_tests',
    'ui_android_unittests',
    'ui_base_unittests',
    'ui_touch_selection_unittests',
    'unit_tests',
    'webkit_unit_tests',
]

# Tests fail in component=shared_library build, which is required for ASan.
# http://crbug.com/344868
ASAN_EXCLUDED_TEST_SUITES = [
    'breakpad_unittests',
    'sandbox_linux_unittests'
]
