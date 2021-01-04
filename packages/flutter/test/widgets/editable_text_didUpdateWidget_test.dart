// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

void main() {
  final FocusNode focusNode = FocusNode(debugLabel: 'EditableText Node');
  const TextStyle textStyle = TextStyle();
  const Color cursorColor = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);
  const Color backgroundColor = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);
  late TextEditingController defaultController;

  group('didUpdateWidget', () {
    final _AppendingFormatter appendingFormatter = _AppendingFormatter();

    Widget build({
      TextDirection textDirection = TextDirection.ltr,
      List<TextInputFormatter>? formatters,
      TextEditingController? controller,
    }) {
      return MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1.0),
        child: Directionality(
          textDirection: textDirection,
          child: EditableText(
            backgroundCursorColor: backgroundColor,
            controller: controller ?? defaultController,
            maxLines: null,  // Remove the builtin newline formatter.
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
            inputFormatters: formatters,
          ),
        ),
      );
    }

    testWidgets('EditableText only reformats when needed', (WidgetTester tester) async {
      appendingFormatter.needsReformat = false;
      defaultController = TextEditingController(text: 'initialText');
      String previousText = defaultController.text;

      // Initial build, do not apply formatters.
      await tester.pumpWidget(build());
      expect(defaultController.text, previousText);

      await tester.pumpWidget(build(formatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(null),
        appendingFormatter,
      ]));

      expect(defaultController.text, contains(previousText + 'a'));
      previousText = defaultController.text;

      // Change the first formatter.
      await tester.pumpWidget(build(formatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(1000),
        appendingFormatter,
      ]));

      // Reformat since the length formatter changed and it becomes more
      // strict (null -> 1000).
      expect(defaultController.text, contains(previousText + 'a'));
      previousText = defaultController.text;

      await tester.pumpWidget(build(formatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(2000),
        appendingFormatter,
      ]));

      // No reformat needed since the length formatter relaxed its constraint
      // (1000 -> 2000).
      expect(defaultController.text, previousText);

      await tester.pumpWidget(build(formatters: <TextInputFormatter>[
        appendingFormatter,
      ]));

      // Reformat since we reduced the number of new formatters.
      expect(defaultController.text, previousText + 'a');
      previousText = defaultController.text;

      // Now the the appending formatter always requests a reformat when
      // didUpdateWidget is called.
      appendingFormatter.needsReformat = true;

      await tester.pumpWidget(build(formatters: <TextInputFormatter>[
        appendingFormatter,
      ]));

      // Reformat since appendingFormatter now always requests a rerun.
      expect(defaultController.text, contains(previousText + 'a'));
      previousText = defaultController.text;
    });

    testWidgets(
      'Changing the controller along with the formatter does not reformat',
      (WidgetTester tester) async {
        // This test verifies that the `shouldReformat` predicate is run against
        // the previous formatter associated with the *TextEditingController*,
        // instead of the one associated with the widget, to avoid unnecessary
        // rebuilds.
        final TextEditingController controller1 = TextEditingController(text: 'shorttxt');
        final TextEditingController controller2 = TextEditingController(text: 'looooong text');

        final Widget editableText1 = build(
          controller: controller1,
          formatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(controller1.text.length)],
        );
        final Widget editableText2 = build(
          controller: controller2,
          formatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(controller2.text.length)],
        );

        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: <Widget>[editableText1, editableText2]),
        ));

        // The 2 input fields swap places. The input formatters should not rerun.
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: <Widget>[editableText2, editableText1]),
        ));

        expect(controller1.text, 'shorttxt');
        expect(controller2.text, 'looooong text');
    });
});

}


// A TextInputFormatter that appends 'a' to the current editing value every time
// it runs.
class _AppendingFormatter extends TextInputFormatter {
  bool needsReformat = true;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text + 'a');
  }

  @override
  bool shouldReformat(TextInputFormatter oldFormatter) => needsReformat;
}
