#!/usr/bin/env python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Prints if the the terminal is likely to understand ANSI codes."""

import os

# Add more terminals here as needed.
print 'ANSICON' in os.environ
