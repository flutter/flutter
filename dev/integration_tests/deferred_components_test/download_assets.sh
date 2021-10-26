#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

mkdir customassets
curl https://raw.githubusercontent.com/flutter/goldens/0fbd6c5d30ec714ffefd63b47910aee7debd2e7e/dev/integration_tests/assets_for_deferred_components_test/flutter_logo.png --output customassets/flutter_logo.png
curl https://raw.githubusercontent.com/flutter/goldens/0fbd6c5d30ec714ffefd63b47910aee7debd2e7e/dev/integration_tests/assets_for_deferred_components_test/key.properties --output android/key.properties
curl https://raw.githubusercontent.com/flutter/goldens/0fbd6c5d30ec714ffefd63b47910aee7debd2e7e/dev/integration_tests/assets_for_deferred_components_test/testing-keystore.jks --output android/testing-keystore.jks
