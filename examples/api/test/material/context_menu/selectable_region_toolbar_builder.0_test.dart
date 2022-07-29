// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/context_menu/selection_area.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showing and hiding the custom context menu on SelectionArea', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    // Allow the selection overlay geometry to be created.
    await tester.pump();

    expect(find.byType(DefaultTextSelectionToolbar), findsNothing);

    // Right clicking the Text in the SelectionArea shows the custom context
    // menu.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text(example.text)),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(DefaultTextSelectionToolbar), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);

    // Tap to dismiss.
    await tester.tapAt(tester.getCenter(find.byType(Scaffold)));
    await tester.pumpAndSettle();

    expect(find.byType(DefaultTextSelectionToolbar), findsNothing);
  });
}
