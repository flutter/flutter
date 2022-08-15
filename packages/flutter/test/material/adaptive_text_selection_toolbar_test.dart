// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/clipboard_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockClipboard mockClipboard = MockClipboard();
  TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, mockClipboard.handleMethodCall);

  testWidgets('Builds the right toolbar on each platform, including web, and shows buttonItems', (WidgetTester tester) async {
    const String buttonText = 'Click me';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveTextSelectionToolbar.buttonItems(
              primaryAnchor: Offset.zero,
              buttonItems: <ContextMenuButtonItem>[
                ContextMenuButtonItem(
                  label: buttonText,
                  onPressed: () {
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text(buttonText), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(find.byType(TextSelectionToolbar), findsOneWidget);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
        break;
      case TargetPlatform.iOS:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsOneWidget);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
        break;
      case TargetPlatform.macOS:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsOneWidget);
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsOneWidget);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
        break;
    }
  },
    variant: TargetPlatformVariant.all(),
    skip: isBrowser, // [intended] see https://github.com/flutter/flutter/issues/108382
  );

  testWidgets('Can build children directly as well', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveTextSelectionToolbar(
              primaryAnchor: Offset.zero,
              children: <Widget>[
                Container(key: key),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(key), findsOneWidget);
  });
}
