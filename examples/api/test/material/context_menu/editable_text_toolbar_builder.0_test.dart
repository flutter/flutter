// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/context_menu/custom_button_appearance.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showing and hiding the context menu in TextField with custom buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      example.MyApp(),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(find.byType(DefaultTextSelectionToolbar), findsNothing);

    // Long pressing the field shows the default context menu but with custom
    // buttons.
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();

    expect(find.byType(DefaultTextSelectionToolbar), findsOneWidget);
    expect(find.byType(CupertinoButton), findsAtLeastNWidgets(1));

    // Tap to dismiss.
    await tester.tapAt(tester.getTopLeft(find.byType(EditableText)));
    await tester.pumpAndSettle();

    expect(find.byType(DefaultTextSelectionToolbar), findsNothing);
    expect(find.byType(CupertinoButton), findsNothing);
  });
}
