// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Verbatim Field widget from issue #197193 (with optional focusNode for testing).
class _Field extends StatefulWidget {
  const _Field({this.focusNode});

  final FocusNode? focusNode;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: widget.focusNode,
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Type quickly',
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (BuildContext context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(onTap: () {}, child: const Icon(Icons.open_in_full)),
                // Appears with the first letter; this is what reshapes the field's semantics.
                if (controller.text.isNotEmpty)
                  InkWell(onTap: controller.clear, child: const Icon(Icons.close)),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<int> _focusedSemanticsIds(WidgetTester tester) {
  final ids = <int>[];
  void visit(SemanticsNode node) {
    if (node.flagsCollection.isFocused == Tristate.isTrue) {
      ids.add(node.id);
    }
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  final SemanticsNode? root = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root != null) {
    visit(root);
  }
  return ids;
}

SemanticsNode? _findSemanticsNodeById(SemanticsNode node, int id) {
  if (node.id == id) {
    return node;
  }
  SemanticsNode? result;
  node.visitChildren((SemanticsNode child) {
    result ??= _findSemanticsNodeById(child, id);
    return result == null;
  });
  return result;
}

void main() {
  testWidgets(
    'TextField keeps focus when dynamic suffix button appears (issue #197193)',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 400.0, child: _Field(focusNode: focus)),
            ),
          ),
        ),
      );

      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      final List<int> initialFocusedIds = _focusedSemanticsIds(tester);
      expect(initialFocusedIds, hasLength(1));
      final int initialId = initialFocusedIds.single;

      // Type first character 'h', causing the second suffix InkWell to appear.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: 'h', selection: TextSelection.collapsed(offset: 1)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final List<int> afterFocusedIds = _focusedSemanticsIds(tester);
      expect(afterFocusedIds, hasLength(1));
      final int activeId = afterFocusedIds.single;
      final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner!;
      final SemanticsNode root = semanticsOwner.rootSemanticsNode!;

      // Outer node must no longer carry didLoseAccessibilityFocus once EditableText
      // splits into its own semantics node.
      expect(activeId, isNot(initialId));
      final SemanticsNode? oldNode = _findSemanticsNodeById(root, initialId);
      expect(
        oldNode?.getSemanticsData().hasAction(SemanticsAction.didLoseAccessibilityFocus),
        isFalse,
      );
      semanticsOwner.performAction(initialId, SemanticsAction.didLoseAccessibilityFocus);
      await tester.pump();

      // Field must retain focus so subsequent characters can be typed.
      expect(focus.hasFocus, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: 'hello', selection: TextSelection.collapsed(offset: 5)),
      );
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);

      // Genuine didLoseAccessibilityFocus on the active EditableText node still unfocuses.
      semanticsOwner.performAction(activeId, SemanticsAction.didLoseAccessibilityFocus);
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      handle.dispose();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }),
  );
}
