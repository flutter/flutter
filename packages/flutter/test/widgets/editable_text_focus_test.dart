// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editable_text_utils.dart';

SemanticsNode textFieldSemantics() {
  return find.semantics.byFlag(SemanticsFlag.isTextField).evaluate().single;
}

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/195407.
  testWidgets('EditableText updates RenderEditable.hasFocus and semantics when it regains focus '
      'with a valid selection', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final controller = TextEditingController(text: 'draft');
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      TestWidgetsApp(
        home: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 14.0),
          cursorColor: const Color(0xFF000000),
          backgroundCursorColor: const Color(0xFF9E9E9E),
        ),
      ),
    );

    // Focus changes are applied in a microtask, and the frame that rebuilds
    // with the new focus is scheduled from the focus listener.
    Future<void> pumpFocusChange() async {
      await tester.pump();
      await tester.pump();
    }

    // The first focus places a collapsed selection at the end of the text.
    focusNode.requestFocus();
    await pumpFocusChange();
    expect(controller.selection, const TextSelection.collapsed(offset: 5));
    expect(findRenderEditable(tester).hasFocus, isTrue);

    focusNode.unfocus();
    await pumpFocusChange();
    expect(findRenderEditable(tester).hasFocus, isFalse);
    expect(textFieldSemantics(), containsSemantics(isTextField: true, isFocused: false));

    // The selection is still valid, so focusing again doesn't change it.
    focusNode.requestFocus();
    await pumpFocusChange();
    expect(controller.selection, const TextSelection.collapsed(offset: 5));
    expect(focusNode.hasFocus, isTrue);
    expect(findRenderEditable(tester).hasFocus, isTrue);
    expect(textFieldSemantics(), containsSemantics(isTextField: true, isFocused: true));

    semantics.dispose();
  });
}
