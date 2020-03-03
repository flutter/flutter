// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e2e/e2e.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  testWidgets('merging thread to remove platform views does not crash',
      (WidgetTester tester) async {
    // Pump a frame with platform view, threads are merged.
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        child: UiKitView(viewType: 'platform_view'),
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
  });
}
