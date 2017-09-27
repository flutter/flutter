// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Fires onChanged when text changes via TextSelectionOverlay', (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey = new GlobalKey<EditableTextState>();

    String changedValue;
    final Widget widget = new MaterialApp(
      home: new EditableText(
        key: editableTextKey,
        controller: new TextEditingController(),
        focusNode: new FocusNode(),
        style: new Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
        onChanged: (String value) {
          changedValue = value;
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Populate a fake clipboard.
    const String clipboardContent = 'Dobunezumi mitai ni utsukushiku naritai';
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{ 'text': clipboardContent };
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    await tester.pump();

    await tester.tap(find.text('PASTE'));
    await tester.pump();

    expect(changedValue, clipboardContent);
  });
}
