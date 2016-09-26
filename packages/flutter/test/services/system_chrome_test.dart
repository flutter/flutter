// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_services/platform/system_chrome.dart' as mojom;

void main() {
  testWidgets('SystemChrome overlay style test', (WidgetTester tester) async {
    // The first call is a cache miss and will queue a microtask
    SystemChrome.setSystemUIOverlayStyle(mojom.SystemUiOverlayStyle.light);
    expect(tester.binding.microtaskCount, equals(1));

    // Flush all microtasks
    await tester.idle();
    expect(tester.binding.microtaskCount, equals(0));

    // The second call with the same value should be a no-op
    SystemChrome.setSystemUIOverlayStyle(mojom.SystemUiOverlayStyle.light);
    expect(tester.binding.microtaskCount, equals(0));
  });
}
