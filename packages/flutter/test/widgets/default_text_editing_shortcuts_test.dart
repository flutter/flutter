// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> sendKeyCombination(
  WidgetTester tester,
  SingleActivator activator,
) async {
  final List<LogicalKeyboardKey> modifiers = <LogicalKeyboardKey>[
    if (activator.control) LogicalKeyboardKey.control,
    if (activator.shift) LogicalKeyboardKey.shift,
    if (activator.alt) LogicalKeyboardKey.alt,
    if (activator.meta) LogicalKeyboardKey.meta,
  ];
  for (final LogicalKeyboardKey modifier in modifiers) {
    await tester.sendKeyDownEvent(modifier);
  }
  await tester.sendKeyDownEvent(activator.trigger);
  await tester.sendKeyUpEvent(activator.trigger);
  await tester.pump();
  for (final LogicalKeyboardKey modifier in modifiers.reversed) {
    await tester.sendKeyUpEvent(modifier);
  }
}

void main() {
  Widget buildSpyAboveEditableText({
    required FocusNode editableFocusNode,
    required FocusNode spyFocusNode,
  }) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          // Softwrap at exactly 20 characters.
          width: 201,
          height: 200,
          child: ActionSpy(
            focusNode: spyFocusNode,
            child: EditableText(
              controller: TextEditingController(text: 'dummy text'),
              showSelectionHandles: true,
              autofocus: true,
              focusNode: editableFocusNode,
              style: const TextStyle(fontSize: 10.0),
              textScaleFactor: 1,
              // Avoid the cursor from taking up width.
              cursorWidth: 0,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              maxLines: null,
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ),
    );
  }
  group('macOS does not accept shortcuts if focus under EditableText', () {
    final TargetPlatformVariant macOSOnly = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets('word modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('word modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('word modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();

      expect(state.lastIntent, isNull);

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();
      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('line modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();
      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);
  });

  group('macOS does accept shortcuts if focus above EditableText', () {
    final TargetPlatformVariant macOSOnly = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets('word modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();

      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
    }, variant: macOSOnly);

    testWidgets('word modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();

      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();

      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();

      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
    }, variant: macOSOnly);

    testWidgets('word modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());

      state.lastIntent = null;
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());

      state.lastIntent = null;
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());

      state.lastIntent = null;
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
    }, variant: macOSOnly);

    testWidgets('line modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      final FocusNode spy = FocusNode();
      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());

      state.lastIntent = null;
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());

      state.lastIntent = null;
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());

      state.lastIntent = null;
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
    }, variant: macOSOnly);
  }, skip: kIsWeb); // [intended] specific tests target non-web.
}

class ActionSpy extends StatefulWidget {
  const ActionSpy({super.key, required this.focusNode, required this.child});
  final FocusNode focusNode;
  final Widget child;

  @override
  State<ActionSpy> createState() => ActionSpyState();
}

class ActionSpyState extends State<ActionSpy> {
  Intent? lastIntent;
  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    ExtendSelectionByCharacterIntent: CallbackAction<ExtendSelectionByCharacterIntent>(onInvoke: _captureIntent),
    ExtendSelectionToNextWordBoundaryIntent: CallbackAction<ExtendSelectionToNextWordBoundaryIntent>(onInvoke: _captureIntent),
    ExtendSelectionToLineBreakIntent: CallbackAction<ExtendSelectionToLineBreakIntent>(onInvoke: _captureIntent),
    ExpandSelectionToLineBreakIntent: CallbackAction<ExpandSelectionToLineBreakIntent>(onInvoke: _captureIntent),
    ExpandSelectionToDocumentBoundaryIntent: CallbackAction<ExpandSelectionToDocumentBoundaryIntent>(onInvoke: _captureIntent),
    ExtendSelectionVerticallyToAdjacentLineIntent: CallbackAction<ExtendSelectionVerticallyToAdjacentLineIntent>(onInvoke: _captureIntent),
    ExtendSelectionToDocumentBoundaryIntent: CallbackAction<ExtendSelectionToDocumentBoundaryIntent>(onInvoke: _captureIntent),
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent: CallbackAction<ExtendSelectionToNextWordBoundaryOrCaretLocationIntent>(onInvoke: _captureIntent),
  };

  // ignore: use_setters_to_change_properties
  void _captureIntent(Intent intent) {
    lastIntent = intent;
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: _actions,
      child: Focus(
        focusNode: widget.focusNode,
        child: widget.child,
      ),
    );
  }
}
