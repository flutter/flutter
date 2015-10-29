#!/bin/bash

# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fast fail the script on failures.
set -e

# Fetch all our dependencies
pub get

# Verify that the libraries are error free.
pub global activate tuneup
pub global run tuneup check

# And run our tests.
pub run test -j1
