// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/banner/material_banner.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BottomNavigationBar Updates Screen Content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MaterialBannerExampleApp(),
    );

    expect(find.byType(MaterialBanner), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Show MaterialBanner'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsOne);
    expect(find.text('Hello, I am a Material Banner'), findsOne);
    expect(find.byIcon(Icons.agriculture_outlined), findsOne);
    expect(find.widgetWithText(TextButton, 'DISMISS'), findsOne);

  });
}
