#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This should match the ci.bat file in this directory.

# This is called from .cirrus.yml and the LUCI recipes:
# https://flutter.googlesource.com/recipes/+/refs/heads/master/recipe_modules/adhoc_validation/resources/customer_testing.sh

set -ex

dart --enable-asserts ci.dart --skip-on-fetch-failure --skip-template ../../bin/cache/pkg/tests/registry/*.test