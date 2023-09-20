// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgetsWithLeakTracking('runApp inside onPressed does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: ElevatedButton(
            onPressed: () {
              runApp(const Center(child: Text('Done', textDirection: TextDirection.ltr)));
            },
            child: const Text('GO'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('GO'));
    expect(find.text('Done'), findsOneWidget);
  });
}
