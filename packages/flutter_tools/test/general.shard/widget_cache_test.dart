// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/widget_cache.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  testWithoutContext('widget cache returns null when experiment is disabled', () async {
    final WidgetCache widgetCache = WidgetCache(featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: false));

    expect(await widgetCache.validateLibrary(Uri.parse('package:hello_world/main.dart')), null);
  });

  testWithoutContext('widget cache returns null because functionality is not complete', () async {
    final WidgetCache widgetCache = WidgetCache(featureFlags: TestFeatureFlags(isSingleWidgetReloadEnabled: true));

    expect(await widgetCache.validateLibrary(Uri.parse('package:hello_world/main.dart')), null);
  });
}
