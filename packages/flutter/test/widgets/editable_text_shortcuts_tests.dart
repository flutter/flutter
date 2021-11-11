// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

Iterable<SingleActivator> allModifierVariants(LogicalKeyboardKey trigger) {
  const Iterable<bool> trueFalse = <bool>[false, true];
  return trueFalse.expand((bool shift) {
    return trueFalse.expand((bool control) {
      return trueFalse.expand((bool alt) {
        return trueFalse.map((bool meta) => SingleActivator(trigger, shift: shift, control: control, alt: alt, meta: meta));
      });
    });
  });
}

final TargetPlatformVariant allExceptFuchsia = TargetPlatformVariant(
  TargetPlatform.values.toSet()..remove(TargetPlatform.fuchsia),
);

void main() {
  const String testText =
      'Now is the time for\n' // 20
      'all good people\n'     // 20 + 16 => 36
      'to come to the aid\n'  // 36 + 19 => 55
      'of their country.';    // 55 + 17 => 72
  const String testCluster = '👨‍👩‍👦👨‍👩‍👦👨‍👩‍👦'; // 8 * 3

  // Exactly 20 characters each line.
  const String testSoftwrapText =
      '0123456789ABCDEFGHIJ'
      '0123456789ABCDEFGHIJ'
      '0123456789ABCDEFGHIJ'
      '0123456789ABCDEFGHIJ';
  final TextEditingController controller = TextEditingController(text: testText);

  final FocusNode focusNode = FocusNode();
  Widget buildEditableText({ TextAlign textAlign = TextAlign.left, bool readOnly = false, bool obscured = false }) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          // Softwrap at exactly 20 characters.
          width: 201,
          child: EditableText(
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 10),
            textScaleFactor: 1,
            // Avoid the cursor from taking up width.
            cursorWidth: 0,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            maxLines: obscured ? 1 : null,
            readOnly: readOnly,
            textAlign: textAlign,
            obscureText: obscured,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Movement/Deletion shortcuts do nothing when the selection is invalid',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildEditableText());
      controller.text = testText;
      controller.selection = const TextSelection.collapsed(offset: -1);
      await tester.pump();

      const List<LogicalKeyboardKey> triggers = <LogicalKeyboardKey>[
        LogicalKeyboardKey.backspace,
        LogicalKeyboardKey.delete,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.end,
      ];

      for (final SingleActivator activator in triggers.expand(allModifierVariants)) {
        await sendKeyCombination(tester, activator);
        await tester.pump();
        expect(controller.text, testText, reason: activator.toString());
        expect(controller.selection, const TextSelection.collapsed(offset: -1), reason: activator.toString());
      }
    },
    skip: kIsWeb, // [intended]
    variant: allExceptFuchsia,
  );

  group('Common text editing shortcuts: ',
    () {
      final TargetPlatformVariant allExceptMacOSAndFuchsia = TargetPlatformVariant(
        TargetPlatform.values.toSet()..remove(TargetPlatform.macOS)..remove(TargetPlatform.fuchsia),
      );

      group('backspace', () {
        const LogicalKeyboardKey trigger = LogicalKeyboardKey.backspace;

        testWidgets('backspace', (WidgetTester tester) async {
          controller.text = testText;
          // Move the selection to the beginning of the 2nd line (after the newline
          // character).
          controller.selection = const TextSelection.collapsed(
            offset: 20,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            'Now is the time forall good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 19),
          );
        }, variant: allExceptFuchsia);

        testWidgets('backspace readonly', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 20,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText(readOnly: true));
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(controller.text, testText);

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 20, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('backspace at start', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 0,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            'Now is the time for\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('backspace at end', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 72,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            'Now is the time for\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 71),
          );
        }, variant: allExceptFuchsia);

        testWidgets('backspace inside of a cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 1,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('backspace at cluster boundary', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 8,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);
      });

      group('delete: ', () {
        const LogicalKeyboardKey trigger = LogicalKeyboardKey.delete;

        testWidgets('delete', (WidgetTester tester) async {
          controller.text = testText;
          // Move the selection to the beginning of the 2nd line (after the newline
          // character).
          controller.selection = const TextSelection.collapsed(
            offset: 20,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            'Now is the time for\n'
            'll good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 20),
          );
        }, variant: allExceptFuchsia);

        testWidgets('delete readonly', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 20,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText(readOnly: true));
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(controller.text, testText);

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 20, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('delete at start', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 0,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            'ow is the time for\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('delete at end', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 72,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            'Now is the time for\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 72, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('delete inside of a cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 1,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('delete at cluster boundary', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 8,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 8),
          );
        }, variant: allExceptFuchsia);
      });

      group('Non-collapsed delete', () {
        // This shares the same logic as backspace.
        const LogicalKeyboardKey trigger = LogicalKeyboardKey.delete;

        testWidgets('inside of a cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection(
            baseOffset: 9,
            extentOffset: 12,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 8),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at the boundaries of a cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection(
            baseOffset: 8,
            extentOffset: 16,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 8),
          );
        }, variant: allExceptFuchsia);

        testWidgets('cross-cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection(
            baseOffset: 1,
            extentOffset: 9,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            '👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('cross-cluster obscured text', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection(
            baseOffset: 1,
            extentOffset: 9,
          );

          await tester.pumpWidget(buildEditableText(obscured: true));
          await sendKeyCombination(tester, const SingleActivator(trigger));

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 1),
          );
        }, variant: allExceptFuchsia);
      });

      group('word modifier + backspace', () {
        const LogicalKeyboardKey trigger = LogicalKeyboardKey.backspace;
        SingleActivator wordModifierBackspace() {
          final bool isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
          return SingleActivator(trigger, control: !isMacOS, alt: isMacOS);
        }

        testWidgets('WordModifier-backspace', (WidgetTester tester) async {
          controller.text = testText;
          // Place the caret before "people".
          controller.selection = const TextSelection.collapsed(
            offset: 29,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierBackspace());

          expect(
            controller.text,
            'Now is the time for\n'
            'all people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 24),
          );
        }, variant: allExceptFuchsia);

        testWidgets('readonly', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 29,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText(readOnly: true));
          await sendKeyCombination(tester, wordModifierBackspace());

          expect(controller.text, testText);

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 29, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at start', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 0,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierBackspace());

          expect(
            controller.text,
            'Now is the time for\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at end', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 72,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierBackspace());

          expect(
            controller.text,
            'Now is the time for\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 71),
          );
        }, variant: allExceptFuchsia);

        testWidgets('inside of a cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 1,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierBackspace());

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at cluster boundary', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 8,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierBackspace());

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);
      });

      group('word modifier + delete', () {
        const LogicalKeyboardKey trigger = LogicalKeyboardKey.delete;
        SingleActivator wordModifierDelete() {
          final bool isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
          return SingleActivator(trigger, control: !isMacOS, alt: isMacOS);
        }

        testWidgets('WordModifier-delete', (WidgetTester tester) async {
          controller.text = testText;
          // Place the caret after "all".
          controller.selection = const TextSelection.collapsed(
            offset: 23,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierDelete());

          expect(
            controller.text,
            'Now is the time for\n'
            'all people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 23),
          );
        }, variant: allExceptFuchsia);

        testWidgets('readonly', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 23,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText(readOnly: true));
          await sendKeyCombination(tester, wordModifierDelete());

          expect(controller.text, testText);

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 23, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at start', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 0,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierDelete());

          expect(
            controller.text,
            ' is the time for\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at end', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 72,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierDelete());

          expect(controller.text, testText);
          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 72, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('inside of a cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 1,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierDelete());

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at cluster boundary', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 8,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, wordModifierDelete());

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 8),
          );
        }, variant: allExceptFuchsia);
      });

      group('line modifier + backspace', () {
        const LogicalKeyboardKey trigger = LogicalKeyboardKey.backspace;
        SingleActivator lineModifierBackspace() {
          final bool isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
          return SingleActivator(trigger, meta: isMacOS, alt: !isMacOS);
        }

        testWidgets('alt-backspace', (WidgetTester tester) async {
          controller.text = testText;
          // Place the caret before "people".
          controller.selection = const TextSelection.collapsed(
            offset: 29,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierBackspace());

          expect(
            controller.text,
            'Now is the time for\n'
            'people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 20),
          );
        }, variant: allExceptFuchsia);

        testWidgets('softwrap line boundary, upstream', (WidgetTester tester) async {
          controller.text = testSoftwrapText;
          // Place the caret at the beginning of the 3rd line.
          controller.selection = const TextSelection.collapsed(
            offset: 40,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierBackspace());

          expect(
            controller.text,
            '0123456789ABCDEFGHIJ'
            '0123456789ABCDEFGHIJ'
            '0123456789ABCDEFGHIJ'
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 20),
          );
        }, variant: allExceptFuchsia);

        testWidgets('softwrap line boundary, downstream', (WidgetTester tester) async {
          controller.text = testSoftwrapText;
          // Place the caret at the beginning of the 3rd line.
          controller.selection = const TextSelection.collapsed(
            offset: 40,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierBackspace());

          expect(controller.text, testSoftwrapText);

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 40),
          );
        }, variant: allExceptFuchsia);

        testWidgets('readonly', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 29,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText(readOnly: true));
          await sendKeyCombination(tester, lineModifierBackspace());

          expect(controller.text, testText);

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 29, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at start', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 0,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierBackspace());

          expect(
            controller.text,
            'Now is the time for\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at end', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 72,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierBackspace());

          expect(
            controller.text,
            'Now is the time for\n'
            'all good people\n'
            'to come to the aid\n'
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 55),
          );
        }, variant: allExceptFuchsia);

        testWidgets('inside of a cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 1,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierBackspace());

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at cluster boundary', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 8,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierBackspace());

          expect(
            controller.text,
            '👨‍👩‍👦👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);
      });

      group('line modifier + delete', () {
        const LogicalKeyboardKey trigger = LogicalKeyboardKey.delete;
        SingleActivator lineModifierDelete() {
          final bool isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
          return SingleActivator(trigger, meta: isMacOS, alt: !isMacOS);
        }

        testWidgets('alt-delete', (WidgetTester tester) async {
          controller.text = testText;
          // Place the caret after "all".
          controller.selection = const TextSelection.collapsed(
            offset: 23,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierDelete());

          expect(
            controller.text,
            'Now is the time for\n'
            'all\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 23),
          );
        }, variant: allExceptFuchsia);

        testWidgets('softwrap line boundary, upstream', (WidgetTester tester) async {
          controller.text = testSoftwrapText;
          // Place the caret at the beginning of the 3rd line.
          controller.selection = const TextSelection.collapsed(
            offset: 40,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierDelete());

          expect(controller.text, testSoftwrapText);

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 40, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('softwrap line boundary, downstream', (WidgetTester tester) async {
          controller.text = testSoftwrapText;
          // Place the caret at the beginning of the 3rd line.
          controller.selection = const TextSelection.collapsed(
            offset: 40,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierDelete());

          expect(
            controller.text,
            '0123456789ABCDEFGHIJ'
            '0123456789ABCDEFGHIJ'
            '0123456789ABCDEFGHIJ'
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 40),
          );
        }, variant: allExceptFuchsia);

        testWidgets('readonly', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 23,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText(readOnly: true));
          await sendKeyCombination(tester, lineModifierDelete());

          expect(controller.text, testText);

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 23, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at start', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 0,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierDelete());

          expect(
            controller.text,
            '\n'
            'all good people\n'
            'to come to the aid\n'
            'of their country.',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at end', (WidgetTester tester) async {
          controller.text = testText;
          controller.selection = const TextSelection.collapsed(
            offset: 72,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierDelete());

          expect(controller.text, testText);
          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 72, affinity: TextAffinity.upstream),
          );
        }, variant: allExceptFuchsia);

        testWidgets('inside of a cluster', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 1,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierDelete());

          expect(
            controller.text,
            isEmpty,
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
          );
        }, variant: allExceptFuchsia);

        testWidgets('at cluster boundary', (WidgetTester tester) async {
          controller.text = testCluster;
          controller.selection = const TextSelection.collapsed(
            offset: 8,
            affinity: TextAffinity.upstream,
          );

          await tester.pumpWidget(buildEditableText());
          await sendKeyCombination(tester, lineModifierDelete());

          expect(
            controller.text,
            '👨‍👩‍👦',
          );

          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 8),
          );
        }, variant: allExceptFuchsia);
      });

      group('Arrow Movement', () {
        group('left', () {
          const LogicalKeyboardKey trigger = LogicalKeyboardKey.arrowLeft;

          testWidgets('at start', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 0,
            );

            await tester.pumpWidget(buildEditableText());

            for (final SingleActivator activator in allModifierVariants(trigger)) {
              await sendKeyCombination(tester, activator);
              await tester.pump();

              expect(
                controller.selection,
                const TextSelection.collapsed(offset: 0),
                reason: activator.toString(),
              );
            }
          }, variant: allExceptFuchsia);

          testWidgets('base arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 20,
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(trigger));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 19,
            ));
          }, variant: allExceptFuchsia);

          testWidgets('word modifier + arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 7,   // Before the first "the"
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(trigger, control: true));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 4,
            ));
          }, variant: allExceptMacOSAndFuchsia);

          testWidgets('line modifier + arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 24,   // Before the "good".
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(trigger, alt: true));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 20,
            ));
          }, variant: allExceptMacOSAndFuchsia);
        });

        group('right', () {
          const LogicalKeyboardKey trigger = LogicalKeyboardKey.arrowRight;

          testWidgets('at end', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 72,
            );

            await tester.pumpWidget(buildEditableText());

            for (final SingleActivator activator in allModifierVariants(trigger)) {
              await sendKeyCombination(tester, activator);
              await tester.pump();

              expect(controller.selection.isCollapsed, isTrue, reason: activator.toString());
              expect(controller.selection.baseOffset, 72, reason: activator.toString());
            }
          }, variant: allExceptFuchsia);

          testWidgets('base arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 20,
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(trigger));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 21,
            ));
          }, variant: allExceptFuchsia);

          testWidgets('word modifier + arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 7,   // Before the first "the"
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(trigger, control: true));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 10,
            ));
          }, variant: allExceptMacOSAndFuchsia);

         testWidgets('line modifier + arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 24,   // Before the "good".
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(trigger, alt: true));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 35, // Before the newline character.
              affinity: TextAffinity.upstream,
            ));
          }, variant: allExceptMacOSAndFuchsia);
        });

        group('With initial non-collapsed selection', () {
          testWidgets('base arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            // The word "all" is selected.
            controller.selection = const TextSelection(
              baseOffset: 20,
              extentOffset: 23,
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 20,
            ));

            // The word "all" is selected.
            controller.selection = const TextSelection(
              baseOffset: 23,
              extentOffset: 20,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 20,
            ));

            // The word "all" is selected.
            controller.selection = const TextSelection(
              baseOffset: 20,
              extentOffset: 23,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 23,
            ));

            // The word "all" is selected.
            controller.selection = const TextSelection(
              baseOffset: 23,
              extentOffset: 20,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 23,
            ));
          }, variant: allExceptFuchsia);

          testWidgets('word modifier + arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            // "good" to "come" is selected.
            controller.selection = const TextSelection(
              baseOffset: 24,
              extentOffset: 43,
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 39, // Before "come".
            ));

            // "good" to "come" is selected.
            controller.selection = const TextSelection(
              baseOffset: 43,
              extentOffset: 24,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 20, // Before "all".
              //offset: 39, // Before "come".
            ));

            // "good" to "come" is selected.
            controller.selection = const TextSelection(
              baseOffset: 24,
              extentOffset: 43,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, control: true));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 46, // After "to".
            ));

            // "good" to "come" is selected.
            controller.selection = const TextSelection(
              baseOffset: 43,
              extentOffset: 24,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, control: true));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 28, // After "good".
            ));
          }, variant: allExceptMacOSAndFuchsia);

         testWidgets('line modifier + arrow key movement', (WidgetTester tester) async {
            controller.text = testText;
            // "good" to "come" is selected.
            controller.selection = const TextSelection(
              baseOffset: 24,
              extentOffset: 43,
            );
            await tester.pumpWidget(buildEditableText());
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 36, // Before "to".
            ));

            // "good" to "come" is selected.
            controller.selection = const TextSelection(
              baseOffset: 43,
              extentOffset: 24,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 20, // Before "all".
            ));

            // "good" to "come" is selected.
            controller.selection = const TextSelection(
              baseOffset: 24,
              extentOffset: 43,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 54, // After "aid".
              affinity: TextAffinity.upstream,
            ));

            // "good" to "come" is selected.
            controller.selection = const TextSelection(
              baseOffset: 43,
              extentOffset: 24,
            );
            await tester.pump();
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 35, // After "people".
              affinity: TextAffinity.upstream,
            ));
          }, variant: allExceptMacOSAndFuchsia);
        });

        group('vertical movement', () {
          testWidgets('at start', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 0,
            );

            await tester.pumpWidget(buildEditableText());

            for (final SingleActivator activator in allModifierVariants(LogicalKeyboardKey.arrowUp)) {
              await sendKeyCombination(tester, activator);
              await tester.pump();

              expect(controller.text, testText);
              expect(
                controller.selection,
                const TextSelection.collapsed(offset: 0),
                reason: activator.toString(),
              );
            }
          }, variant: allExceptFuchsia);

          testWidgets('at end', (WidgetTester tester) async {
            controller.text = testText;
            controller.selection = const TextSelection.collapsed(
              offset: 72,
            );

            await tester.pumpWidget(buildEditableText());

            for (final SingleActivator activator in allModifierVariants(LogicalKeyboardKey.arrowDown)) {
              await sendKeyCombination(tester, activator);
              await tester.pump();

              expect(controller.text, testText);
              expect(controller.selection.baseOffset, 72, reason: activator.toString());
              expect(controller.selection.extentOffset, 72, reason: activator.toString());
            }
          }, variant: allExceptFuchsia);

          testWidgets('run', (WidgetTester tester) async {
            controller.text =
              'aa\n'     // 3
              'a\n'      // 3 + 2 = 5
              'aa\n'     // 5 + 3 = 8
              'aaa\n'    // 8 + 4 = 12
              'aaaa';    // 12 + 4 = 16

            controller.selection = const TextSelection.collapsed(
              offset: 2,
            );
            await tester.pumpWidget(buildEditableText());

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowDown));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 4,
              affinity: TextAffinity.upstream,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowDown));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 7,
              affinity: TextAffinity.upstream,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowDown));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 10,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowDown));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 14,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowDown));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 16,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowUp));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 10,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowUp));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 7,
              affinity: TextAffinity.upstream,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowUp));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 4,
              affinity: TextAffinity.upstream,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowUp));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 2,
              affinity: TextAffinity.upstream,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowUp));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 0,
            ));

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowDown));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 4,
              affinity: TextAffinity.upstream,
            ));
          }, variant: allExceptFuchsia);

          testWidgets('run can be interrupted by layout changes', (WidgetTester tester) async {
            controller.text =
              'aa\n'     // 3
              'a\n'      // 3 + 2 = 5
              'aa\n'     // 5 + 3 = 8
              'aaa\n'    // 8 + 4 = 12
              'aaaa';    // 12 + 4 = 16

            controller.selection = const TextSelection.collapsed(
              offset: 2,
            );
            await tester.pumpWidget(buildEditableText());

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowUp));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 0,
            ));

            // Layout changes.
            await tester.pumpWidget(buildEditableText(textAlign: TextAlign.right));
            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowDown));
            await tester.pump();

            expect(controller.selection, const TextSelection.collapsed(
              offset: 3,
            ));
          }, variant: allExceptFuchsia);

          testWidgets('run can be interrupted by selection changes', (WidgetTester tester) async {
            controller.text =
              'aa\n'     // 3
              'a\n'      // 3 + 2 = 5
              'aa\n'     // 5 + 3 = 8
              'aaa\n'    // 8 + 4 = 12
              'aaaa';    // 12 + 4 = 16

            controller.selection = const TextSelection.collapsed(
              offset: 2,
            );
            await tester.pumpWidget(buildEditableText());

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowUp));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 0,
            ));

            controller.selection = const TextSelection.collapsed(
              offset: 1,
            );
            await tester.pump();
            controller.selection = const TextSelection.collapsed(
              offset: 0,
            );
            await tester.pump();

            await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowDown));
            await tester.pump();
            expect(controller.selection, const TextSelection.collapsed(
              offset: 3,   // Would have been 4 if the run wasn't interrupted.
            ));
          }, variant: allExceptFuchsia);
        });
      });
    },
    skip: kIsWeb, // [intended]
  );

  group('macOS shortcuts', () {
    final TargetPlatformVariant macOSOnly = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets('word modifier + arrowLeft', (WidgetTester tester) async {
      controller.text = testText;
      controller.selection = const TextSelection.collapsed(
        offset: 7,   // Before the first "the"
      );
      await tester.pumpWidget(buildEditableText());
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(
        offset: 4,
      ));
    }, variant: macOSOnly);

    testWidgets('word modifier + arrowRight', (WidgetTester tester) async {
      controller.text = testText;
      controller.selection = const TextSelection.collapsed(
        offset: 7,   // Before the first "the"
      );
      await tester.pumpWidget(buildEditableText());
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(
        offset: 10,
      ));
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowLeft', (WidgetTester tester) async {
      controller.text = testText;
      controller.selection = const TextSelection.collapsed(
        offset: 24,   // Before the "good".
      );
      await tester.pumpWidget(buildEditableText());
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(
        offset: 20,
      ));
    }, variant: macOSOnly);

    testWidgets('line modifier + arrowRight', (WidgetTester tester) async {
      controller.text = testText;
      controller.selection = const TextSelection.collapsed(
        offset: 24,   // Before the "good".
      );
      await tester.pumpWidget(buildEditableText());
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(
        offset: 35, // Before the newline character.
        affinity: TextAffinity.upstream,
      ));
    }, variant: macOSOnly);

    testWidgets('word modifier + arrow key movement', (WidgetTester tester) async {
      controller.text = testText;
      // "good" to "come" is selected.
      controller.selection = const TextSelection(
        baseOffset: 24,
        extentOffset: 43,
      );
      await tester.pumpWidget(buildEditableText());
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(
        offset: 39, // Before "come".
      ));

      // "good" to "come" is selected.
      controller.selection = const TextSelection(
        baseOffset: 43,
        extentOffset: 24,
      );
      await tester.pump();
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true));
      await tester.pump();
      expect(controller.selection, const TextSelection.collapsed(
        offset: 20, // Before "all".
        //offset: 39, // Before "come".
      ));

      // "good" to "come" is selected.
      controller.selection = const TextSelection(
        baseOffset: 24,
        extentOffset: 43,
      );
      await tester.pump();
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();
      expect(controller.selection, const TextSelection.collapsed(
        offset: 46, // After "to".
      ));

      // "good" to "come" is selected.
      controller.selection = const TextSelection(
        baseOffset: 43,
        extentOffset: 24,
      );
      await tester.pump();
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true));
      await tester.pump();
      expect(controller.selection, const TextSelection.collapsed(
        offset: 28, // After "good".
      ));
    }, variant: macOSOnly);

    testWidgets('line modifier + arrow key movement', (WidgetTester tester) async {
      controller.text = testText;
      // "good" to "come" is selected.
      controller.selection = const TextSelection(
        baseOffset: 24,
        extentOffset: 43,
      );
      await tester.pumpWidget(buildEditableText());
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();

      expect(controller.selection, const TextSelection.collapsed(
        offset: 36, // Before "to".
      ));

      // "good" to "come" is selected.
      controller.selection = const TextSelection(
        baseOffset: 43,
        extentOffset: 24,
      );
      await tester.pump();
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true));
      await tester.pump();
      expect(controller.selection, const TextSelection.collapsed(
        offset: 20, // Before "all".
      ));

      // "good" to "come" is selected.
      controller.selection = const TextSelection(
        baseOffset: 24,
        extentOffset: 43,
      );
      await tester.pump();
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();
      expect(controller.selection, const TextSelection.collapsed(
        offset: 54, // After "aid".
        affinity: TextAffinity.upstream,
      ));

      // "good" to "come" is selected.
      controller.selection = const TextSelection(
        baseOffset: 43,
        extentOffset: 24,
      );
      await tester.pump();
      await sendKeyCombination(tester, const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true));
      await tester.pump();
      expect(controller.selection, const TextSelection.collapsed(
        offset: 35, // After "people".
        affinity: TextAffinity.upstream,
      ));
    }, variant: macOSOnly);
  });

  // TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/93450 .
  // Remove these tests once the above issue is resolved.
  final TargetPlatformVariant fuchsiaOnly = TargetPlatformVariant.only(TargetPlatform.fuchsia);
  group('fuchsia shortcuts', () {
    const int _kFuchsiaKeyIdPlane = LogicalKeyboardKey.fuchsiaPlane;
    const LogicalKeyboardKey _kBackspace = LogicalKeyboardKey(42 | _kFuchsiaKeyIdPlane);
    const LogicalKeyboardKey _kDelete = LogicalKeyboardKey(76 | _kFuchsiaKeyIdPlane);
    const LogicalKeyboardKey _kArrowLeft = LogicalKeyboardKey(80 | _kFuchsiaKeyIdPlane);
    const LogicalKeyboardKey _kArrowRight = LogicalKeyboardKey(79 | _kFuchsiaKeyIdPlane);
    const LogicalKeyboardKey _kArrowDown = LogicalKeyboardKey(81 | _kFuchsiaKeyIdPlane);
    const LogicalKeyboardKey _kArrowUp = LogicalKeyboardKey(82 | _kFuchsiaKeyIdPlane);

    int _getFuchsiaModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
      int result = 0;
      final Set<LogicalKeyboardKey> pressed = RawKeyboard.instance.keysPressed;
      if (isDown) {
        pressed.add(newKey);
      } else {
        pressed.remove(newKey);
      }
      if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
        result |= RawKeyEventDataFuchsia.modifierLeftShift;
      }
      if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
        result |= RawKeyEventDataFuchsia.modifierRightShift;
      }
      if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
        result |= RawKeyEventDataFuchsia.modifierLeftMeta;
      }
      if (pressed.contains(LogicalKeyboardKey.metaRight)) {
        result |= RawKeyEventDataFuchsia.modifierRightMeta;
      }
      if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
        result |= RawKeyEventDataFuchsia.modifierLeftControl;
      }
      if (pressed.contains(LogicalKeyboardKey.controlRight)) {
        result |= RawKeyEventDataFuchsia.modifierRightControl;
      }
      if (pressed.contains(LogicalKeyboardKey.altLeft)) {
        result |= RawKeyEventDataFuchsia.modifierLeftAlt;
      }
      if (pressed.contains(LogicalKeyboardKey.altRight)) {
        result |= RawKeyEventDataFuchsia.modifierRightAlt;
      }
      if (pressed.contains(LogicalKeyboardKey.capsLock)) {
        result |= RawKeyEventDataFuchsia.modifierCapsLock;
      }
      return result;
    }

    Future<bool> simulateFuchsiaKeyEvent(LogicalKeyboardKey logicalKey, bool isDown) async {
      final Completer<bool> result = Completer<bool>();
      final Map<String, dynamic> keyData = <String, dynamic>{
        'type': isDown ? 'keydown' : 'keyup',
        'keymap': 'fuchsia',
        'hidUsage': logicalKey.keyId | LogicalKeyboardKey.unicodePlane,
        'modifiers': _getFuchsiaModifierFlags(logicalKey, isDown),
      };
      await TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.keyEvent.name,
        SystemChannels.keyEvent.codec.encodeMessage(keyData),
        (ByteData? data) {
          if (data == null) {
            result.complete(false);
            return;
          }
          final Map<String, dynamic> decoded = SystemChannels.keyEvent.codec.decodeMessage(data) as Map<String, dynamic>;
          result.complete(decoded['handled'] as bool);
        }
      );
      return result.future;
    }

    Future<void> sendFuchsiaKeyCombination(
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
        await tester.sendKeyDownEvent(modifier, platform: 'fuchsia');
      }
      await simulateFuchsiaKeyEvent(activator.trigger, true);
      await simulateFuchsiaKeyEvent(activator.trigger, false);
      await tester.pump();
      for (final LogicalKeyboardKey modifier in modifiers.reversed) {
        await tester.sendKeyUpEvent(modifier, platform: 'fuchsia');
      }
    }

    setUp(() {
      controller.text = testText;
      controller.selection = const TextSelection.collapsed(
        offset: 32,   // all good peo|ple\n
      );
    });

    testWidgets('delete', (WidgetTester tester) async {
      await tester.pumpWidget(buildEditableText());

      // Character delete.
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kBackspace));
      expect(
        controller.text,
        'Now is the time for\n'
        'all good peple\n'
        'to come to the aid\n'
        'of their country.',
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 31));

      // Word delete.
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kBackspace, control: true));
      expect(
        controller.text,
        'Now is the time for\n'
        'all good ple\n'
        'to come to the aid\n'
        'of their country.',
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 29));

      // Line delete.
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kBackspace, alt: true));
      expect(
        controller.text,
        'Now is the time for\n'
        'ple\n'
        'to come to the aid\n'
        'of their country.',
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 20));
    }, variant: fuchsiaOnly);

    testWidgets('delete forward', (WidgetTester tester) async {
      await tester.pumpWidget(buildEditableText());

      // Character delete.
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kDelete));
      expect(
        controller.text,
        'Now is the time for\n'
        'all good peole\n'
        'to come to the aid\n'
        'of their country.',
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 32));

      // Word delete.
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kDelete, control: true));
      expect(
        controller.text,
        'Now is the time for\n'
        'all good peo\n'
        'to come to the aid\n'
        'of their country.',
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 32));

      // Line delete.
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kDelete, alt: true));
      expect(
        controller.text,
        'Now is the time for\n'
        'all good peo\n'
        'to come to the aid\n'
        'of their country.',
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 32));
    }, variant: fuchsiaOnly);


    testWidgets('arrow key navigation', (WidgetTester tester) async {
      await tester.pumpWidget(buildEditableText());

      // Verical movement.
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kArrowUp));
      expect(controller.selection, const TextSelection.collapsed(offset: 12));
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kArrowDown));
      expect(controller.selection, const TextSelection.collapsed(offset: 32));

      // Horizontal movement.
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kArrowLeft));
      expect(controller.selection, const TextSelection.collapsed(offset: 31));
      await sendFuchsiaKeyCombination(tester, const SingleActivator(_kArrowRight));
      expect(controller.selection, const TextSelection.collapsed(offset: 32));
    }, variant: fuchsiaOnly);
  });
}
