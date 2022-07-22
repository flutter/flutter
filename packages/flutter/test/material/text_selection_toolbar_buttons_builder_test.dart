// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Builds the correct button per-platform', (WidgetTester tester) async {
    const String buttonText = 'Click me';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextSelectionToolbarButtonsBuilder(
              buttonItems: <ContextMenuButtonItem>[
                ContextMenuButtonItem(
                  label: buttonText,
                  onPressed: () {
                  },
                ),
              ],
              builder: (BuildContext context, List<Widget> children) {
                return ListView(
                  children: children,
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text(buttonText), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(find.byType(TextSelectionToolbarTextButton), findsOneWidget);
        expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
        break;
      case TargetPlatform.iOS:
        expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbarButton), findsOneWidget);
        expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
        break;
      case TargetPlatform.macOS:
        expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsOneWidget);
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbarButton), findsOneWidget);
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
        break;
    }
  },
    variant: TargetPlatformVariant.all(),
  );
}

