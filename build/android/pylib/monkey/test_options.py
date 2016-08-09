# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the MonkeyOptions named tuple."""

import collections

MonkeyOptions = collections.namedtuple('MonkeyOptions', [
    'verbose_count',
    'package',
    'event_count',
    'category',
    'throttle',
    'seed',
    'extra_args'])
