// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('enterText works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TextField(),
        ),
      ),
    );

    final EditableTextState state = tester.state(find.byType(EditableText));
    expect(state.textEditingValue.text, '');

    await tester.enterText(find.byType(EditableText), 'let there be text');
    expect(state.textEditingValue.text, 'let there be text');
    expect(state.textEditingValue.selection.isCollapsed, isTrue);
    expect(state.textEditingValue.selection.baseOffset, 17);
  });

  testWidgets('receiveAction() forwards exception when exception occurs during action processing', (WidgetTester tester) async {
    // Setup a widget that can receive focus so that we can open the keyboard.
    const Widget widget = MaterialApp(
      home: Material(
        child: TextField(),
      ),
    );
    await tester.pumpWidget(widget);

    // Keyboard must be shown for receiveAction() to function.
    await tester.showKeyboard(find.byType(TextField));

    // Register a handler for the text input channel that throws an error. This
    // error should be reported within a PlatformException by TestTextInput.
    SystemChannels.textInput.setMethodCallHandler((MethodCall call) {
      throw FlutterError('A fake error occurred during action processing.');
    });

    try {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      fail('Expected a PlatformException, but it was not thrown.');
    } catch (e) {
      expect(e, isA<PlatformException>());
    }
  });
}
