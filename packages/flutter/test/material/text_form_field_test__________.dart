// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../foundation/leak_tracking.dart';
import '../widgets/clipboard_utils.dart';
import '../widgets/editable_text_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockClipboard mockClipboard = MockClipboard();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, mockClipboard.handleMethodCall);

  setUp(() async {
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  // testWidgetsWithLeakTracking('leak test', (WidgetTester tester) async {
  testWidgets('leak test', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'blah1 blah2',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextField(
              controller: controller,
            ),
          ),
        ),
      ),
    );

    final Offset startBlah1 = textOffsetToPosition(tester, 0);
    await tester.tapAt(startBlah1);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(startBlah1);
    await tester.pumpAndSettle();
    await tester.pump();
  },
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS }),
    skip: kIsWeb, // [intended] we don't supply the cut/copy/paste buttons on the web.
  );
}
