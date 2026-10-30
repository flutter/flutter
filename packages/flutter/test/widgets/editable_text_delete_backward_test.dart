// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sends the message the iOS embedder sends after it performs a backward
/// deletion. Uses the magical -1 client id so the test does not have to mock
/// the engine side of text input.
Future<void> sendDidDeleteBackward(WidgetTester tester, String deletedText) async {
  final ByteData message = const JSONMessageCodec().encodeMessage(<String, dynamic>{
    'method': 'TextInputClient.didDeleteBackward',
    'args': <dynamic>[-1, deletedText],
  })!;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/textinput',
    message,
    (ByteData? _) {},
  );
  await tester.pump();
}

void main() {
  Widget boilerplate({
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onDeleteBackward,
    bool readOnly = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          onDeleteBackward: onDeleteBackward,
        ),
      ),
    );
  }

  testWidgets('fires on an empty field, where no text changes', (WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final deletions = <String>[];

    await tester.pumpWidget(
      boilerplate(
        controller: controller,
        focusNode: focusNode,
        onDeleteBackward: deletions.add,
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(deletions, <String>['']);
    expect(controller.text, isEmpty);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android}));

  testWidgets('reports the removed text on a non-empty field', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'ab');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final deletions = <String>[];

    await tester.pumpWidget(
      boilerplate(
        controller: controller,
        focusNode: focusNode,
        onDeleteBackward: deletions.add,
      ),
    );
    focusNode.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(deletions, <String>['b']);
    expect(controller.text, 'a');
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android}));

  testWidgets('fires with an empty payload with the caret at offset 0', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'ab');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final deletions = <String>[];

    await tester.pumpWidget(
      boilerplate(
        controller: controller,
        focusNode: focusNode,
        onDeleteBackward: deletions.add,
      ),
    );
    focusNode.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(deletions, <String>['']);
    expect(controller.text, 'ab');
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android}));

  testWidgets('does not fire for a forward delete', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'ab');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final deletions = <String>[];

    await tester.pumpWidget(
      boilerplate(
        controller: controller,
        focusNode: focusNode,
        onDeleteBackward: deletions.add,
      ),
    );
    focusNode.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(deletions, isEmpty);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android}));

  testWidgets('does not fire on a readOnly field', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'ab');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final deletions = <String>[];

    await tester.pumpWidget(
      boilerplate(
        controller: controller,
        focusNode: focusNode,
        onDeleteBackward: deletions.add,
        readOnly: true,
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(deletions, isEmpty);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android}));

  testWidgets('the embedder notification reaches the callback', (WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final deletions = <String>[];

    await tester.pumpWidget(
      boilerplate(
        controller: controller,
        focusNode: focusNode,
        onDeleteBackward: deletions.add,
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    // The empty payload is the case the iOS engine cannot report any other
    // way: the press deleted nothing, so no editing state is sent.
    await sendDidDeleteBackward(tester, '');
    expect(deletions, <String>['']);

    await sendDidDeleteBackward(tester, 'x');
    expect(deletions, <String>['', 'x']);

    // The notification must never mutate the text itself; the embedder has
    // already applied the deletion.
    expect(controller.text, isEmpty);
  });

  testWidgets('a bare backspace key does not reach the action on iOS', (WidgetTester tester) async {
    // _iOSDisablingTextShortcuts maps backspace to
    // DoNothingAndStopPropagationTextIntent, so the framework leg must stay
    // silent there and leave the press to the engine. Otherwise a press would
    // be reported twice.
    final controller = TextEditingController(text: 'ab');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final deletions = <String>[];

    await tester.pumpWidget(
      boilerplate(
        controller: controller,
        focusNode: focusNode,
        onDeleteBackward: deletions.add,
      ),
    );
    focusNode.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(deletions, isEmpty);
    expect(controller.text, 'ab');
  }, variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}));
}
