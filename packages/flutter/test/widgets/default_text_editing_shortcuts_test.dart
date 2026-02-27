// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'keyboard_utils.dart';

void main() {
  Widget buildSpyAboveEditableText({
    required FocusNode editableFocusNode,
    required FocusNode spyFocusNode,
  }) {
    final controller = TextEditingController(text: 'dummy text');
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
    final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);
    final editable = FocusNode();
    final spy = FocusNode();

    testWidgets('backspace with and without word modifier', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(tester.binding.testTextInput.register);

      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      for (var altShiftState = 0; altShiftState < 1 << 2; altShiftState += 1) {
        final alt = altShiftState & 0x1 != 0;
        final shift = altShiftState & 0x2 != 0;
        await sendKeyCombination(
          tester,
          SingleActivator(LogicalKeyboardKey.backspace, alt: alt, shift: shift),
        );
      }
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: iOS);

    testWidgets('delete with and without word modifier', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(tester.binding.testTextInput.register);

      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      for (var altShiftState = 0; altShiftState < 1 << 2; altShiftState += 1) {
        final alt = altShiftState & 0x1 != 0;
        final shift = altShiftState & 0x2 != 0;
        await sendKeyCombination(
          tester,
          SingleActivator(LogicalKeyboardKey.delete, alt: alt, shift: shift),
        );
      }
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: iOS);

    testWidgets('Exception: deleting to line boundary is handled by the framework', (
      WidgetTester tester,
    ) async {
      tester.binding.testTextInput.unregister();
      addTearDown(tester.binding.testTextInput.register);

      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      for (var keyState = 0; keyState < 1 << 2; keyState += 1) {
        final shift = keyState & 0x1 != 0;
        final LogicalKeyboardKey key = keyState & 0x2 != 0
            ? LogicalKeyboardKey.delete
            : LogicalKeyboardKey.backspace;

        state.lastIntent = null;
        final activator = SingleActivator(key, meta: true, shift: shift);
        await sendKeyCombination(tester, activator);
        await tester.pump();
        expect(state.lastIntent, isA<DeleteToLineBreakIntent>(), reason: '$activator');
      }
    }, variant: iOS);
  }, skip: kIsWeb); // [intended] specific tests target non-web.

  group('macOS does not accept shortcuts if focus under EditableText', () {
    final macOSOnly = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets('word modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
      );
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('word modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
      );
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true),
      );
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true),
      );
      await tester.pump();

      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('word modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
      );
      await tester.pump();

      expect(state.lastIntent, isNull);

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
      );
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
      );
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
      );
      await tester.pump();
      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);

    testWidgets('line modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      editable.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true),
      );
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true),
      );
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true),
      );
      await tester.pump();
      expect(state.lastIntent, isNull);

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true),
      );
      await tester.pump();
      expect(state.lastIntent, isNull);
    }, variant: macOSOnly);
  });

  group('macOS does accept shortcuts if focus above EditableText', () {
    final macOSOnly = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets('word modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
      );
      await tester.pump();

      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
    }, variant: macOSOnly);

    testWidgets('word modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
      );
      await tester.pump();

      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowLeft', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true),
      );
      await tester.pump();

      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowRight', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true),
      );
      await tester.pump();

      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
    }, variant: macOSOnly);

    testWidgets('word modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
      );
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());

      state.lastIntent = null;
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
      );
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());

      state.lastIntent = null;
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
      );
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());

      state.lastIntent = null;
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
      );
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
    }, variant: macOSOnly);

    testWidgets('line modifier + arrow key movement', (WidgetTester tester) async {
      tester.binding.testTextInput.unregister();
      addTearDown(() {
        tester.binding.testTextInput.register();
      });
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);
      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true),
      );
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());

      state.lastIntent = null;
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true),
      );
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());

      state.lastIntent = null;
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true),
      );
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());

      state.lastIntent = null;
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true),
      );
      await tester.pump();
      expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
    }, variant: macOSOnly);
  }, skip: kIsWeb); // [intended] specific tests target non-web.

  group('Linux numpad shortcuts', () {
    testWidgets(
      'are triggered when numlock is locked',
      (WidgetTester tester) async {
        final editable = FocusNode();
        addTearDown(editable.dispose);
        final spy = FocusNode();
        addTearDown(spy.dispose);

        await tester.pumpWidget(
          buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
        );
        spy.requestFocus();
        await tester.pump();
        final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

        // Lock NumLock.
        await tester.sendKeyEvent(LogicalKeyboardKey.numLock);
        expect(
          HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.numLock),
          isTrue,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad6, shift: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionByCharacterIntent>());
        expect((state.lastIntent! as ExtendSelectionByCharacterIntent).forward, true);
        expect((state.lastIntent! as ExtendSelectionByCharacterIntent).collapseSelection, false);

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad4, shift: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionByCharacterIntent>());
        expect((state.lastIntent! as ExtendSelectionByCharacterIntent).forward, false);
        expect((state.lastIntent! as ExtendSelectionByCharacterIntent).collapseSelection, false);

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad8, shift: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentLineIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad2, shift: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentLineIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad9, shift: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentPageIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentPageIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentPageIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad3, shift: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentPageIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentPageIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentPageIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad7, shift: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentLineIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad1, shift: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentLineIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpadDecimal, shift: true),
        );
        expect(state.lastIntent, isA<DeleteCharacterIntent>());
        expect((state.lastIntent! as DeleteCharacterIntent).forward, true);

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad6, shift: true, control: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToNextWordBoundaryIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionToNextWordBoundaryIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad4, shift: true, control: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToNextWordBoundaryIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionToNextWordBoundaryIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad8, shift: true, control: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionToNextParagraphBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToNextParagraphBoundaryIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionToNextParagraphBoundaryIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad2, shift: true, control: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionToNextParagraphBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToNextParagraphBoundaryIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionToNextParagraphBoundaryIntent).collapseSelection,
          false,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpadDecimal, shift: true, control: true),
        );
        expect(state.lastIntent, isA<DeleteToNextWordBoundaryIntent>());
        expect((state.lastIntent! as DeleteToNextWordBoundaryIntent).forward, true);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );

    testWidgets(
      'are triggered when numlock is unlocked',
      (WidgetTester tester) async {
        final editable = FocusNode();
        addTearDown(editable.dispose);
        final spy = FocusNode();
        addTearDown(spy.dispose);

        await tester.pumpWidget(
          buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
        );
        spy.requestFocus();
        await tester.pump();
        final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

        // Verify that NumLock is unlocked.
        expect(
          HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.numLock),
          isFalse,
        );

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad6));
        expect(state.lastIntent, isA<ExtendSelectionByCharacterIntent>());
        expect((state.lastIntent! as ExtendSelectionByCharacterIntent).forward, true);
        expect((state.lastIntent! as ExtendSelectionByCharacterIntent).collapseSelection, true);

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad4));
        expect(state.lastIntent, isA<ExtendSelectionByCharacterIntent>());
        expect((state.lastIntent! as ExtendSelectionByCharacterIntent).forward, false);
        expect((state.lastIntent! as ExtendSelectionByCharacterIntent).collapseSelection, true);

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad8));
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentLineIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad2));
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentLineIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad9));
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentPageIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentPageIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentPageIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad3));
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentPageIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentPageIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentPageIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad7));
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentLineIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad1));
        expect(state.lastIntent, isA<ExtendSelectionVerticallyToAdjacentLineIntent>());
        expect((state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionVerticallyToAdjacentLineIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpadDecimal));
        expect(state.lastIntent, isA<DeleteCharacterIntent>());
        expect((state.lastIntent! as DeleteCharacterIntent).forward, true);

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad6, control: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToNextWordBoundaryIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionToNextWordBoundaryIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad4, control: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionToNextWordBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToNextWordBoundaryIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionToNextWordBoundaryIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad8, control: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionToNextParagraphBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToNextParagraphBoundaryIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionToNextParagraphBoundaryIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpad2, control: true),
        );
        expect(state.lastIntent, isA<ExtendSelectionToNextParagraphBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToNextParagraphBoundaryIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionToNextParagraphBoundaryIntent).collapseSelection,
          true,
        );

        await sendKeyCombination(
          tester,
          const SingleActivator(LogicalKeyboardKey.numpadDecimal, control: true),
        );
        expect(state.lastIntent, isA<DeleteToNextWordBoundaryIntent>());
        expect((state.lastIntent! as DeleteToNextWordBoundaryIntent).forward, true);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );

    testWidgets(
      'update the editable text content when triggered on non-web',
      (WidgetTester tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        final controller = TextEditingController(text: 'Flutter');
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: EditableText(
                controller: controller,
                autofocus: true,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 10.0),
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
              ),
            ),
          ),
        );

        // Verify that NumLock is unlocked.
        expect(
          HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.numLock),
          isFalse,
        );

        await tester.enterText(find.byType(EditableText), 'Flutter');
        expect(controller.selection.end, 7);

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad4));
        // Verify the cursor moved to the left (numpad4).
        expect(controller.selection.end, 6);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
      skip: kIsWeb, // [intended] Non-web test.
    );

    testWidgets(
      'do not update the editable text content when triggered on web',
      (WidgetTester tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        final controller = TextEditingController(text: 'Flutter');
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: EditableText(
                controller: controller,
                autofocus: true,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 10.0),
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
              ),
            ),
          ),
        );

        // Verify that NumLock is unlocked.
        expect(
          HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.numLock),
          isFalse,
        );

        await tester.enterText(find.byType(EditableText), 'Flutter');
        expect(controller.selection.end, 7);

        await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.numpad4));
        // On web, the editable text would have been updated by the browser.
        // In the flutter test environment, the browser logic is not called
        // so the editable content is not updated when a shortcut is triggered.
        // This is the intended result, this test is checking that numpad shortcuts
        // have no effect on the web (their intent is set to DoNothingAndStopPropagationTextIntent).
        expect(controller.selection.end, 7);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
      skip: !kIsWeb, // [intended] Web only.
    );
  });

  testWidgets('Home and end keys on Android and Windows', (WidgetTester tester) async {
    final editable = FocusNode();
    addTearDown(editable.dispose);
    final spy = FocusNode();
    addTearDown(spy.dispose);

    await tester.pumpWidget(
      buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
    );
    spy.requestFocus();
    await tester.pump();
    final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

    // Press home.
    await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.home));
    switch (defaultTargetPlatform) {
      // These platforms do nothing when home/end are pressed.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(state.lastIntent, isNull);

      // These platforms go to the line start/end.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).forward, false);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).collapseSelection, true);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).continuesAtWrap, true);

      // Linux goes to the line start/end but does not wrap.
      case TargetPlatform.linux:
        expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).forward, false);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).collapseSelection, true);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).continuesAtWrap, false);
    }

    // Press end.
    state.lastIntent = null;
    await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.end));
    switch (defaultTargetPlatform) {
      // These platforms do nothing when home/end are pressed.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(state.lastIntent, isNull);

      // These platforms go to the line start/end.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).forward, true);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).collapseSelection, true);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).continuesAtWrap, true);

      // Linux goes to the line start/end but does not wrap.
      case TargetPlatform.linux:
        expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).forward, true);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).collapseSelection, true);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).continuesAtWrap, false);
    }

    // Press home + shift.
    state.lastIntent = null;
    await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.home, shift: true));
    switch (defaultTargetPlatform) {
      // These platforms select to the start of the document.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(state.lastIntent, isA<ExpandSelectionToDocumentBoundaryIntent>());
        expect((state.lastIntent! as ExpandSelectionToDocumentBoundaryIntent).forward, false);

      // These platforms select to the line start.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).forward, false);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).collapseSelection, false);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).continuesAtWrap, true);

      // Linux selects to the start but does not wrap.
      case TargetPlatform.linux:
        expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).forward, false);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).collapseSelection, false);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).continuesAtWrap, false);
    }

    // Press end + shift.
    state.lastIntent = null;
    await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.end, shift: true));
    switch (defaultTargetPlatform) {
      // These platforms select to the end of the document.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(state.lastIntent, isA<ExpandSelectionToDocumentBoundaryIntent>());
        expect((state.lastIntent! as ExpandSelectionToDocumentBoundaryIntent).forward, true);

      // These platforms select to the line end.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
        expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).forward, true);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).collapseSelection, false);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).continuesAtWrap, true);

      // Linux selects to the end but does not wrap.
      case TargetPlatform.linux:
        expect(state.lastIntent, isA<ExtendSelectionToLineBreakIntent>());
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).forward, true);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).collapseSelection, false);
        expect((state.lastIntent! as ExtendSelectionToLineBreakIntent).continuesAtWrap, false);
    }

    // Press home + control.
    state.lastIntent = null;
    await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.home, control: true));
    switch (defaultTargetPlatform) {
      // These platforms do nothing.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(state.lastIntent, isNull);

      // These platforms go to the line start/end.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(state.lastIntent, isA<ExtendSelectionToDocumentBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToDocumentBoundaryIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionToDocumentBoundaryIntent).collapseSelection,
          true,
        );
    }

    // Press end + control.
    state.lastIntent = null;
    await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.end, control: true));
    switch (defaultTargetPlatform) {
      // These platforms do nothing.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(state.lastIntent, isNull);

      // These platforms go to the line start/end.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(state.lastIntent, isA<ExtendSelectionToDocumentBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToDocumentBoundaryIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionToDocumentBoundaryIntent).collapseSelection,
          true,
        );
    }

    // Press home + control + shift.
    state.lastIntent = null;
    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.home, control: true, shift: true),
    );
    switch (defaultTargetPlatform) {
      // These platforms do nothing.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(state.lastIntent, isNull);

      // These platforms go to the line start/end.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(state.lastIntent, isA<ExtendSelectionToDocumentBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToDocumentBoundaryIntent).forward, false);
        expect(
          (state.lastIntent! as ExtendSelectionToDocumentBoundaryIntent).collapseSelection,
          false,
        );
    }

    // Press end + control + shift.
    state.lastIntent = null;
    await sendKeyCombination(
      tester,
      const SingleActivator(LogicalKeyboardKey.end, control: true, shift: true),
    );
    switch (defaultTargetPlatform) {
      // These platforms do nothing.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(state.lastIntent, isNull);

      // These platforms go to the line start/end.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(state.lastIntent, isA<ExtendSelectionToDocumentBoundaryIntent>());
        expect((state.lastIntent! as ExtendSelectionToDocumentBoundaryIntent).forward, true);
        expect(
          (state.lastIntent! as ExtendSelectionToDocumentBoundaryIntent).collapseSelection,
          false,
        );
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    'Clipboard shortcuts (Xerox/Apple)',
    (WidgetTester tester) async {
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);

      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      // Press ^X.
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.keyX, control: true),
      );
      expect(state.lastIntent, isA<CopySelectionTextIntent>());
      expect((state.lastIntent! as CopySelectionTextIntent).collapseSelection, true);

      // Press ^C.
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.keyC, control: true),
      );
      expect(state.lastIntent, isA<CopySelectionTextIntent>());
      expect((state.lastIntent! as CopySelectionTextIntent).collapseSelection, false);

      // Press ^V.
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true),
      );
      expect(state.lastIntent, isA<PasteTextIntent>());
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.linux,
      TargetPlatform.windows,
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'Clipboard shortcuts (IBM CUA)',
    (WidgetTester tester) async {
      final editable = FocusNode();
      addTearDown(editable.dispose);
      final spy = FocusNode();
      addTearDown(spy.dispose);

      await tester.pumpWidget(
        buildSpyAboveEditableText(editableFocusNode: editable, spyFocusNode: spy),
      );
      spy.requestFocus();
      await tester.pump();
      final ActionSpyState state = tester.state<ActionSpyState>(find.byType(ActionSpy));

      // Press Shift-Delete.
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.delete, shift: true),
      );
      expect(state.lastIntent, isA<CopySelectionTextIntent>());
      expect((state.lastIntent! as CopySelectionTextIntent).collapseSelection, true);

      // Press Ctrl-Insert.
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.insert, control: true),
      );
      expect(state.lastIntent, isA<CopySelectionTextIntent>());
      expect((state.lastIntent! as CopySelectionTextIntent).collapseSelection, false);

      // Press Shift-Insert.
      await sendKeyCombination(
        tester,
        const SingleActivator(LogicalKeyboardKey.insert, shift: true),
      );
      expect(state.lastIntent, isA<PasteTextIntent>());
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.linux,
      TargetPlatform.windows,
      TargetPlatform.android,
    }),
  );
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
    ExtendSelectionByCharacterIntent: CallbackAction<ExtendSelectionByCharacterIntent>(
      onInvoke: _captureIntent,
    ),
    ExtendSelectionToNextWordBoundaryIntent:
        CallbackAction<ExtendSelectionToNextWordBoundaryIntent>(onInvoke: _captureIntent),
    ExtendSelectionToLineBreakIntent: CallbackAction<ExtendSelectionToLineBreakIntent>(
      onInvoke: _captureIntent,
    ),
    ExpandSelectionToLineBreakIntent: CallbackAction<ExpandSelectionToLineBreakIntent>(
      onInvoke: _captureIntent,
    ),
    ExpandSelectionToDocumentBoundaryIntent:
        CallbackAction<ExpandSelectionToDocumentBoundaryIntent>(onInvoke: _captureIntent),
    ExtendSelectionVerticallyToAdjacentLineIntent:
        CallbackAction<ExtendSelectionVerticallyToAdjacentLineIntent>(onInvoke: _captureIntent),
    ExtendSelectionToDocumentBoundaryIntent:
        CallbackAction<ExtendSelectionToDocumentBoundaryIntent>(onInvoke: _captureIntent),
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent:
        CallbackAction<ExtendSelectionToNextWordBoundaryOrCaretLocationIntent>(
          onInvoke: _captureIntent,
        ),
    ExtendSelectionToNextParagraphBoundaryIntent:
        CallbackAction<ExtendSelectionToNextParagraphBoundaryIntent>(onInvoke: _captureIntent),
    ExtendSelectionVerticallyToAdjacentPageIntent:
        CallbackAction<ExtendSelectionVerticallyToAdjacentPageIntent>(onInvoke: _captureIntent),

    DeleteToLineBreakIntent: CallbackAction<DeleteToLineBreakIntent>(onInvoke: _captureIntent),
    DeleteToNextWordBoundaryIntent: CallbackAction<DeleteToNextWordBoundaryIntent>(
      onInvoke: _captureIntent,
    ),
    DeleteCharacterIntent: CallbackAction<DeleteCharacterIntent>(onInvoke: _captureIntent),

    CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(onInvoke: _captureIntent),
    PasteTextIntent: CallbackAction<PasteTextIntent>(onInvoke: _captureIntent),
  };

  // ignore: use_setters_to_change_properties
  void _captureIntent(Intent intent) {
    lastIntent = intent;
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: _actions,
      child: Focus(focusNode: widget.focusNode, child: widget.child),
    );
  }
}
