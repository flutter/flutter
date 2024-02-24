// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  //testWidgets('when another instance is shown, calling hide on the old instance does nothing.', (WidgetTester tester) async {
  //testWidgets('when another instance is shown, hides.', (WidgetTester tester) async {
  testWidgets('can be updated.', (WidgetTester tester) async {
    // TODO(justinmc): Or do a List of these?
    Map<String, double>? lastCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'ContextMenu.showSystemContextMenu') {
          expect(methodCall.arguments, isA<Map<String, double>>());
          // TODO(justinmc): Maybe just put the Rects in here directly?
          lastCall = methodCall.arguments as Map<String, double>;
        }
      });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final TextEditingController controller = TextEditingController(
      text: 'one two three',
    );
    late final StateSetter setState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter localSetState) {
                setState = localSetState;
                return TextField(
                  controller: controller,
                  contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                    return SystemContextMenu.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(lastCall, isNull);

    await tester.tap(find.byType(TextField));
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.showToolbar(), true);
    await tester.pump();

    // TODO(justinmc): Maybe actual Rect.
    expect(lastCall, isNotNull);

    setState(() {
      controller.selection = const TextSelection(
        baseOffset: 4,
        extentOffset: 7,
      );
    });
    await tester.pumpAndSettle();

    // TODO(justinmc): Should be different than the last Rect.
    expect(lastCall, isNotNull);
  });
}
