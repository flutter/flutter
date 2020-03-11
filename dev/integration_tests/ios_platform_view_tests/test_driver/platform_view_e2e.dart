// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e2e/e2e.dart';

// TODO(cyanglaz): e2e test is not current running on flutter/flutter.
// Move the e2e test to engine repo once https://github.com/flutter/flutter/issues/51892 is resolved.
void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  testWidgets('merging thread to remove platform views does not crash',
      (WidgetTester tester) async {
    // Pump a frame with platform view, threads are merged.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        child: const UiKitView(viewType: 'platform_view'),
        width: 300,
        height: 300,
      ),
    ));

    // Pump enough widgets to un-merge the threads.
    for (int i = 0; i < 100; i++) {
      await tester.pump();
    }
    // Remove platform view, thread should be merged during this frame.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(),
    ));
  }, skip: !Platform.isIOS);

  testWidgets('un-merging thread after removing the platform view does not crash',
      (WidgetTester tester) async {
    // Pump a frame with platform view, threads are merged.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        child: const UiKitView(viewType: 'platform_view'),
        width: 300,
        height: 300,
      ),
    ));

    // Remove platform view, thread should still be merged at this moment as the lease hasn't expired.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(),
    ));

    // Pump enough widgets to un-merge the threads.
    for (int i = 0; i < 100; i++) {
      await tester.pump();
    }
  }, skip: !Platform.isIOS);
}
