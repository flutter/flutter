// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/system_context_menu/system_context_menu.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows the system context menu on iOS when supported', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.SystemContextMenuExampleApp(),
    );

    expect(find.byType(SystemContextMenu), findsNothing);

    // Show the context menu.
    final Finder textFinder = find.byType(EditableText);
    await tester.longPress(textFinder);
    tester.state<EditableTextState>(textFinder).showToolbar();
    await tester.pumpAndSettle();

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        // TODO(justinmc): SystemContextMenu is only shown on iOS when
        // maybeSupportsShowingSystemContextMenu is true.
        expect(find.byType(SystemContextMenu), findsOneWidget);
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
    }
  }, variant: TargetPlatformVariant.all(), skip: kIsWeb); // [intended]
}
