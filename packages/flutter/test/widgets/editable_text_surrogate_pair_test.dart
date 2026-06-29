// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/188713
//
// EditableText must never report a caret that sits inside a UTF-16 surrogate pair to the platform
// text input plugin (IME). If it does, the IME inserts a character at that offset and splits the
// pair into lone surrogates, which corrupt as the editing value crosses the input channel (each
// lone half is encoded as '?') and crash ParagraphBuilder on paint ("string is not well-formed
// UTF-16"). The value sent over the channel is now snapped off the pair. Flutter's internal,
// framework-side cursor behavior (which already handles mid-grapheme deletes) is intentionally
// left unchanged.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

/// Whether [value] contains a UTF-16 surrogate code unit that is not part of a valid high-low pair.
bool _hasLoneSurrogate(String value) {
  final List<int> codeUnits = value.codeUnits;
  for (var i = 0; i < codeUnits.length; i++) {
    final int codeUnit = codeUnits[i];
    if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
      // A high surrogate must be immediately followed by a low surrogate.
      if (i + 1 >= codeUnits.length ||
          !(codeUnits[i + 1] >= 0xDC00 && codeUnits[i + 1] <= 0xDFFF)) {
        return true;
      }
      i++;
    } else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
      // A low surrogate not preceded by a high surrogate.
      return true;
    }
  }
  return false;
}

void main() {
  // 'a😓b' -> code units [0061, D83D, DE13, 0062]; offset 2 is between D83D and DE13.
  const text = 'a😓b';

  /// Pumps an autofocused [EditableText] driven by [controller] and [focusNode] inside a minimal
  /// [TestWidgetsApp] (no Material), and opens its input connection so
  /// [WidgetTester.testTextInput] sees its state.
  Future<void> pumpEditable(
    WidgetTester tester,
    TextEditingController controller,
    FocusNode focusNode,
  ) async {
    await tester.pumpWidget(
      TestWidgetsApp(
        home: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(),
          cursorColor: const Color(0xFF000000),
          backgroundCursorColor: const Color(0xFF000000),
          autofocus: true,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'a caret inside a surrogate pair is snapped off the pair before being sent to the IME',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: text);
      addTearDown(controller.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await pumpEditable(tester, controller, focusNode);

      // The platform reports a caret inside the surrogate pair (offset 2).
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: text, selection: TextSelection.collapsed(offset: 2)),
      );
      await tester.pump();

      // Framework-internal cursor behavior is intentionally unchanged.
      expect(controller.selection.baseOffset, 2);

      // But the value sent back over the input channel is snapped past the pair end (offset 3), so it
      // never sits inside the pair.
      expect(tester.testTextInput.editingState!['selectionBase'], 3);
      expect(tester.testTextInput.editingState!['selectionExtent'], 3);
    },
  );

  testWidgets('with the clamped IME caret, the next insert does not split the emoji or crash', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController(text: text);
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpEditable(tester, controller, focusNode);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: text, selection: TextSelection.collapsed(offset: 2)),
    );
    await tester.pump();
    final imeCaret = tester.testTextInput.editingState!['selectionBase'] as int;
    expect(imeCaret, 3);

    // The IME inserts a character at the offset the framework reported to it.
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text.replaceRange(imeCaret, imeCaret, 'x'),
        selection: TextSelection.collapsed(offset: imeCaret + 1),
      ),
    );
    await tester.pump();

    expect(_hasLoneSurrogate(controller.text), isFalse);
    expect(controller.text.contains('😓'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('boundary carets are left unchanged (only the pair interior is clamped)', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController(text: text);
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpEditable(tester, controller, focusNode);

    for (final offset in <int>[0, 1, 3, 4]) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset),
        ),
      );
      await tester.pump();
      expect(
        controller.selection.baseOffset,
        offset,
        reason: 'boundary offset $offset must be kept',
      );
    }
  });
}
