// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

@TestOn('!chrome')
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final TextEditingController controller = TextEditingController();
final FocusNode focusNode = FocusNode();
final FocusScopeNode focusScopeNode = FocusScopeNode();
const TextStyle textStyle = TextStyle();
const Color cursorColor = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

void main() {
  setUp(() async {
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });
   testWidgets('cursor has expected padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            backgroundCursorColor: Colors.grey,
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
            cursorPadding: 10.0,
          ),
        ),
      ),
    );

    final EditableText editableText = tester.firstWidget(find.byType(EditableText));
    expect(editableText.cursorPadding, 10.0);
  });

   testWidgets('cursor layout has correct padding', (WidgetTester tester) async {
    EditableText.debugDeterministicCursor = true;
    final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

    late String changedValue;
    final Widget widget = MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey<int>(1),
        child: EditableText(
          backgroundCursorColor: Colors.grey,
          key: editableTextKey,
          controller: TextEditingController(),
          focusNode: FocusNode(),
          style: Typography.material2018().black.subtitle1!,
          cursorColor: Colors.blue,
          selectionControls: materialTextSelectionControls,
          keyboardType: TextInputType.text,
          onChanged: (String value) {
            changedValue = value;
          },
          cursorPadding: 10.0,
        ),
      ),
    );
    await tester.pumpWidget(widget);

    // Populate a fake clipboard.
    const String clipboardContent = ' ';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{'text': clipboardContent};
      if (methodCall.method == 'Clipboard.hasStrings')
        return <String, dynamic>{'value': clipboardContent.isNotEmpty};
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    tester.state<EditableTextState>(textFinder).showToolbar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste'));
    await tester.pump();

    expect(changedValue, clipboardContent);

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('editable_text_test.5.png'),
    );
    EditableText.debugDeterministicCursor = false;
  });
}
