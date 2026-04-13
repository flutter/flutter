#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# See documentation at: packages/flutter_tools/README.md#forcing-flutter-tools-snapshot-regeneration

# To be run from its own directory
rm -f ../../../../bin/cache/flutter_tools.snapshot
rm -f ../../../../bin/cache/flutter_tools.stamp
../../../../bin/flutter help # Triggers the rebuild by executing a flutter command
