// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'keyboard_utils.dart';

void main() {
  Widget buildSpyAboveEditableText({
    required FocusNode editableFocusNode,
    required FocusNode spyFocusNode,
  }) {
    final TextEditingController controller = TextEditingController(text: 'dummy text');
    addTearDown(controller.dispose);

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
              controller: controller,
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

  group('iOS: do not handle delete/backspace events', () {
    final TargetPlatformVariant iOS = TargetPlatformVariant.only(TargetPlatform.iOS);
    final FocusNode editable = FocusNode();
    final FocusNode spy = FocusNode();

    testWidgetsWithLeakTracking('backspace with and without word modifier', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(tester.binding.testTextInput.register);

      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      for (int altShiftState = 0; altShiftState < 1 << 2; altShiftState += 1) {
        final bool alt = altShiftState & 0x1 != 0;
        final bool shift = altShiftState & 0x2 != 0;
        await sendKeyCombination(tester, SingleActivator(LogicalKeyboardKey.backspace, alt: alt, shift: shift));
      }
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: iOS);

    testWidgetsWithLeakTracking('delete with and without word modifier', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(tester.binding.testTextInput.register);

      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      for (int altShiftState = 0; altShiftState < 1 << 2; altShiftState += 1) {
        final bool alt = altShiftState & 0x1 != 0;
        final bool shift = altShiftState & 0x2 != 0;
        await sendKeyCombination(tester, SingleActivator(LogicalKeyboardKey.delete, alt: alt, shift: shift));
      }
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: iOS);

    testWidgetsWithLeakTracking('Exception: deleting to line boundary is handled by the framework', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(tester.binding.testTextInput.register);

      await tester.pumpWidget(
        buildSpyAboveEditableText(
          editableFocusNode: editable,
          spyFocusNode: spy,
        ),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      for (int keyState = 0; keyState < 1 << 2; keyState += 1) {
        final bool shift = keyState & 0x1 != 0;
        final LogicalKeyboardKey key = keyState & 0x2 != 0 ? LogicalKeyboardKey.delete : LogicalKeyboardKey.backspace;

        state.lastIntent = null;
        final SingleActivator activator = SingleActivator(key, meta: true, shift: shift);
        await sendKeyCombination(tester, activator);
        await tester.pump();
        expect(state.lastIntent, isA<DeleteToLineBreakIntent>(), reason: '$activator');
      }
    }, variant: iOS);
  }, skip: kIsWeb); // [intended] specific tests target non-web.

  group('macOS does not accept shortcuts if focus under EditableText', () {
    final TargetPlatformVariant macOSOnly = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgetsWithLeakTracking('word modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('word modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('line modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('line modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('word modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('line modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('word modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('word modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('line modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('line modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('word modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    testWidgetsWithLeakTracking('line modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown((){
        tester.binding.testTextInput.register();
      });
      final FocusNode editable = FocusNode();
      addTearDown(editable.dispose);
      final FocusNode spy = FocusNode();
      addTearDown(spy.dispose);
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

    DeleteToLineBreakIntent: CallbackAction<DeleteToLineBreakIntent>(onInvoke: _captureIntent),
    DeleteToNextWordBoundaryIntent: CallbackAction<DeleteToNextWordBoundaryIntent>(onInvoke: _captureIntent),
    DeleteCharacterIntent: CallbackAction<DeleteCharacterIntent>(onInvoke: _captureIntent),
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
