// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('asserts when built on an unsupported device', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'one two three',
    );
    await tester.pumpWidget(
      // By default, MediaQueryData.supportsShowingSystemContextMenu is false.
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextField(
              controller: controller,
              contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                return SystemContextMenu.editableText(
                  editableTextState: editableTextState,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.showToolbar(), true);
    await tester.pump();

    expect(tester.takeException(), isAssertionError);
  }, variant: TargetPlatformVariant.all());

  // TODO(justinmc): Do these tests too.
  //testWidgets('when another instance is shown, calling hide on the old instance does nothing.', (WidgetTester tester) async {
  //testWidgets('when another instance is shown, hides.', (WidgetTester tester) async {
  testWidgets('can be updated.', (WidgetTester tester) async {
    final List<Map<String, double>> targetRects = <Map<String, double>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'ContextMenu.showSystemContextMenu') {
          final Map<String, dynamic> arguments = methodCall.arguments as Map<String, dynamic>;
          final Map<String, dynamic> untypedTargetRect = arguments['targetRect'] as Map<String, dynamic>;
          final Map<String, double> lastTargetRect = untypedTargetRect.map((String key, dynamic value) {
            return MapEntry<String, double>(key, value as double);
          });
          targetRects.add(lastTargetRect);
        }
        return;
      });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final TextEditingController controller = TextEditingController(
      text: 'one two three',
    );
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          final MediaQueryData mediaQueryData = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQueryData.copyWith(
              supportsShowingSystemContextMenu: true,
            ),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: TextField(
                    controller: controller,
                    contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                      return SystemContextMenu.editableText(
                        editableTextState: editableTextState,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    expect(targetRects, isEmpty);

    await tester.tap(find.byType(TextField));
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.showToolbar(), true);
    await tester.pump();

    expect(targetRects, hasLength(1));
    expect(targetRects.last, containsPair('width', 0.0));

    controller.selection = const TextSelection(
      baseOffset: 4,
      extentOffset: 7,
    );
    await tester.pumpAndSettle();

    expect(targetRects, hasLength(2));
    expect(targetRects.last['width'], greaterThan(0.0));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('can be rebuilt', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'one two three',
    );
    late StateSetter setState;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          final MediaQueryData mediaQueryData = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQueryData.copyWith(
              supportsShowingSystemContextMenu: true,
            ),
            child: MaterialApp(
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
        },
      ),
    );

    await tester.tap(find.byType(TextField));
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.showToolbar(), true);
    await tester.pump();

    setState(() {});
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
