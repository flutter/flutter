// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/clipboard_utils.dart';
import 'editable_text_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockClipboard = MockClipboard();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    mockClipboard.handleMethodCall,
  );

  setUp(() async {
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  testWidgets(
    'can use the desktop cut/copy/paste buttons on Mac',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'blah1 blah2');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(child: TextFormField(controller: controller)),
          ),
        ),
      );

      // Initially, the menu is not shown and there is no selection.
      expect(find.byType(CupertinoButton), findsNothing);
      expect(controller.selection, const TextSelection(baseOffset: -1, extentOffset: -1));

      final Offset midBlah1 = textOffsetToPosition(tester, 2);

      // Right clicking shows the menu.
      final TestGesture gesture = await tester.startGesture(
        midBlah1,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);

      // Copy the first word.
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(controller.text, 'blah1 blah2');
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(find.byType(CupertinoButton), findsNothing);

      // Paste it at the end.
      await gesture.down(textOffsetToPosition(tester, controller.text.length));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 11, affinity: TextAffinity.upstream),
      );
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(controller.text, 'blah1 blah2blah1');
      expect(controller.selection, const TextSelection.collapsed(offset: 16));

      // Cut the first word.
      await gesture.down(midBlah1);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      await tester.tap(find.text('Cut'));
      await tester.pumpAndSettle();
      expect(controller.text, ' blah2blah1');
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 0));
      expect(find.byType(CupertinoButton), findsNothing);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.macOS}),
    skip: kIsWeb, // [intended] we don't supply the cut/copy/paste buttons on the web.
  );

  testWidgets(
    'can use the desktop cut/copy/paste buttons on Windows and Linux',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'blah1 blah2');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(child: TextFormField(controller: controller)),
          ),
        ),
      );

      // Initially, the menu is not shown and there is no selection.
      expect(find.byType(CupertinoButton), findsNothing);
      expect(controller.selection, const TextSelection(baseOffset: -1, extentOffset: -1));

      final Offset midBlah1 = textOffsetToPosition(tester, 2);

      // Right clicking shows the menu.
      TestGesture gesture = await tester.startGesture(
        midBlah1,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await gesture.removePointer();
      await tester.pumpAndSettle();
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select all'), findsOneWidget);

      // Double tap to select the first word, then right click to show the menu.
      final Offset startBlah1 = textOffsetToPosition(tester, 0);
      gesture = await tester.startGesture(startBlah1, kind: PointerDeviceKind.mouse);
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.down(startBlah1);
      await tester.pump();
      await gesture.up();
      await gesture.removePointer();
      await tester.pumpAndSettle();
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select all'), findsNothing);
      gesture = await tester.startGesture(
        midBlah1,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await gesture.removePointer();
      await tester.pumpAndSettle();
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);

      // Copy the first word.
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(controller.text, 'blah1 blah2');
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(find.byType(CupertinoButton), findsNothing);

      // Paste it at the end.
      gesture = await tester.startGesture(
        textOffsetToPosition(tester, controller.text.length),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.up();
      await gesture.removePointer();
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 11, affinity: TextAffinity.upstream),
      );
      gesture = await tester.startGesture(
        textOffsetToPosition(tester, controller.text.length),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await gesture.removePointer();
      await tester.pumpAndSettle();
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 11, affinity: TextAffinity.upstream),
      );
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(controller.text, 'blah1 blah2blah1');
      expect(controller.selection, const TextSelection.collapsed(offset: 16));

      // Cut the first word.
      gesture = await tester.startGesture(midBlah1, kind: PointerDeviceKind.mouse);
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.down(startBlah1);
      await tester.pump();
      await gesture.up();
      await gesture.removePointer();
      await tester.pumpAndSettle();
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Select all'), findsNothing);
      gesture = await tester.startGesture(
        textOffsetToPosition(tester, controller.text.length),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await gesture.removePointer();
      await tester.pumpAndSettle();
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      await tester.tap(find.text('Cut'));
      await tester.pumpAndSettle();
      expect(controller.text, ' blah2blah1');
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 0));
      expect(find.byType(CupertinoButton), findsNothing);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.linux,
      TargetPlatform.windows,
    }),
    skip: kIsWeb, // [intended] we don't supply the cut/copy/paste buttons on the web.
  );

  testWidgets(
    '$SelectionOverlay is not leaking',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'blah1 blah2');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(child: TextField(controller: controller)),
          ),
        ),
      );

      final Offset startBlah1 = textOffsetToPosition(tester, 0);
      await tester.tapAt(startBlah1);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(startBlah1);
      await tester.pumpAndSettle();
      await tester.pump();
    },
    skip: kIsWeb, // [intended] we don't supply the cut/copy/paste buttons on the web.
  );

  testWidgets(
    'the desktop cut/copy/paste buttons are disabled for read-only obscured form fields',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'blah1 blah2');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: TextFormField(readOnly: true, obscureText: true, controller: controller),
            ),
          ),
        ),
      );

      // Initially, the menu is not shown and there is no selection.
      expect(find.byType(CupertinoButton), findsNothing);
      const invalidSelection = TextSelection(baseOffset: -1, extentOffset: -1);
      expect(controller.selection, invalidSelection);

      final Offset midBlah1 = textOffsetToPosition(tester, 2);

      // Right clicking shows the menu.
      final TestGesture gesture = await tester.startGesture(
        midBlah1,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.selection, invalidSelection);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.byType(CupertinoButton), findsNothing);
    },
    variant: TargetPlatformVariant.desktop(),
    skip: kIsWeb, // [intended] we don't supply the cut/copy/paste buttons on the web.
  );

  testWidgets(
    'the desktop cut/copy buttons are disabled for obscured form fields',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'blah1 blah2');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(child: TextFormField(obscureText: true, controller: controller)),
          ),
        ),
      );

      // Initially, the menu is not shown and there is no selection.
      expect(find.byType(CupertinoButton), findsNothing);
      const invalidSelection = TextSelection(baseOffset: -1, extentOffset: -1);
      expect(controller.selection, invalidSelection);

      final Offset midBlah1 = textOffsetToPosition(tester, 2);

      // Make a selection.
      await tester.tapAt(midBlah1);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(controller.selection, const TextSelection(baseOffset: 2, extentOffset: 0));

      // Right clicking shows the menu.
      final TestGesture gesture = await tester.startGesture(
        midBlah1,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
    },
    variant: TargetPlatformVariant.desktop(),
    skip: kIsWeb, // [intended] we don't supply the cut/copy/paste buttons on the web.
  );

  testWidgets('TextFormField accepts TextField.noMaxLength as value to maxLength parameter', (
    WidgetTester tester,
  ) async {
    bool asserted;
    try {
      TextFormField(maxLength: TextField.noMaxLength);
      asserted = false;
    } catch (e) {
      asserted = true;
    }
    expect(asserted, false);
  });

  testWidgets('Passes textAlign to underlying TextField', (WidgetTester tester) async {
    const TextAlign alignment = TextAlign.center;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(textAlign: alignment)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textAlign, alignment);
  });

  testWidgets('Passes scrollPhysics to underlying TextField', (WidgetTester tester) async {
    const scrollPhysics = ScrollPhysics();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(scrollPhysics: scrollPhysics)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.scrollPhysics, scrollPhysics);
  });

  testWidgets('Passes textAlignVertical to underlying TextField', (WidgetTester tester) async {
    const TextAlignVertical textAlignVertical = TextAlignVertical.bottom;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(textAlignVertical: textAlignVertical)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textAlignVertical, textAlignVertical);
  });

  testWidgets('Passes textInputAction to underlying TextField', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(textInputAction: TextInputAction.next)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textInputAction, TextInputAction.next);
  });

  testWidgets('Passes onEditingComplete to underlying TextField', (WidgetTester tester) async {
    void onEditingComplete() {}

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(onEditingComplete: onEditingComplete)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.onEditingComplete, onEditingComplete);
  });

  testWidgets('Passes cursor attributes to underlying TextField', (WidgetTester tester) async {
    const cursorWidth = 3.14;
    const cursorHeight = 6.28;
    const cursorRadius = Radius.circular(4);
    const Color cursorColor = Colors.purple;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              cursorWidth: cursorWidth,
              cursorHeight: cursorHeight,
              cursorRadius: cursorRadius,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.cursorWidth, cursorWidth);
    expect(textFieldWidget.cursorHeight, cursorHeight);
    expect(textFieldWidget.cursorRadius, cursorRadius);
    expect(textFieldWidget.cursorColor, cursorColor);
  });

  testWidgets('onFieldSubmit callbacks are called', (WidgetTester tester) async {
    var called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onFieldSubmitted: (String value) {
                called = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(called, true);
  });

  testWidgets('onChanged callbacks are called', (WidgetTester tester) async {
    late String value;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onChanged: (String v) {
                value = v;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Soup');
    await tester.pump();
    expect(value, 'Soup');
  });

  testWidgets('autovalidateMode is passed to super', (WidgetTester tester) async {
    var validateCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              autovalidateMode: AutovalidateMode.always,
              validator: (String? value) {
                validateCalled++;
                return null;
              },
            ),
          ),
        ),
      ),
    );

    expect(validateCalled, 1);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(validateCalled, 2);
  });

  testWidgets('validate is called if widget is enabled', (WidgetTester tester) async {
    var validateCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              enabled: true,
              autovalidateMode: AutovalidateMode.always,
              validator: (String? value) {
                validateCalled += 1;
                return null;
              },
            ),
          ),
        ),
      ),
    );

    expect(validateCalled, 1);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(validateCalled, 2);
  });

  testWidgets('Disabled field hides helper and counter in M2', (WidgetTester tester) async {
    const helperText = 'helper text';
    const counterText = 'counter text';
    const errorText = 'error text';
    Widget buildFrame(bool enabled, bool hasError) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Material(
          child: Center(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'label text',
                helperText: helperText,
                counterText: counterText,
                errorText: hasError ? errorText : null,
                enabled: enabled,
              ),
            ),
          ),
        ),
      );
    }

    // When enabled is true, the helper/error and counter are visible.
    await tester.pumpWidget(buildFrame(true, false));
    Text helperWidget = tester.widget(find.text(helperText));
    Text counterWidget = tester.widget(find.text(counterText));
    expect(helperWidget.style!.color, isNot(equals(Colors.transparent)));
    expect(counterWidget.style!.color, isNot(equals(Colors.transparent)));
    await tester.pumpWidget(buildFrame(true, true));
    counterWidget = tester.widget(find.text(counterText));
    Text errorWidget = tester.widget(find.text(errorText));
    expect(helperWidget.style!.color, isNot(equals(Colors.transparent)));
    expect(errorWidget.style!.color, isNot(equals(Colors.transparent)));

    // When enabled is false, the helper/error and counter are not visible.
    await tester.pumpWidget(buildFrame(false, false));
    helperWidget = tester.widget(find.text(helperText));
    counterWidget = tester.widget(find.text(counterText));
    expect(helperWidget.style!.color, equals(Colors.transparent));
    expect(counterWidget.style!.color, equals(Colors.transparent));
    await tester.pumpWidget(buildFrame(false, true));
    errorWidget = tester.widget(find.text(errorText));
    counterWidget = tester.widget(find.text(counterText));
    expect(counterWidget.style!.color, equals(Colors.transparent));
    expect(errorWidget.style!.color, equals(Colors.transparent));
  });

  testWidgets('passing a buildCounter shows returned widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              buildCounter:
                  (BuildContext context, {int? currentLength, int? maxLength, bool? isFocused}) {
                    return Text('$currentLength of $maxLength');
                  },
              maxLength: 10,
            ),
          ),
        ),
      ),
    );

    expect(find.text('0 of 10'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '01234');
    await tester.pump();

    expect(find.text('5 of 10'), findsOneWidget);
  });

  testWidgets('readonly text form field will hide cursor by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(initialValue: 'readonly', readOnly: true)),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextFormField));
    expect(tester.testTextInput.hasAnyClients, false);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, false);

    await tester.longPress(find.byType(TextFormField));
    await tester.pump();

    // Context menu should not have paste.
    expect(find.text('Select all'), findsOneWidget);
    expect(find.text('Paste'), findsNothing);

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    // Make sure it does not paint caret for a period of time.
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));
  }, skip: isBrowser); // [intended] We do not use Flutter-rendered context menu on the Web.

  testWidgets('onTap is called upon tap', (WidgetTester tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onTap: () {
                tapCount += 1;
              },
            ),
          ),
        ),
      ),
    );

    expect(tapCount, 0);
    await tester.tap(find.byType(TextField));
    // Wait a bit so they're all single taps and not double taps.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tapCount, 3);
  });

  testWidgets('onTapOutside is called upon tap outside', (WidgetTester tester) async {
    var tapOutsideCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Outside'),
                TextFormField(
                  autofocus: true,
                  onTapOutside: (PointerEvent event) {
                    tapOutsideCount += 1;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // Wait for autofocus to take effect.

    expect(tapOutsideCount, 0);
    await tester.tap(find.byType(TextFormField));
    await tester.tap(find.text('Outside'));
    await tester.tap(find.text('Outside'));
    await tester.tap(find.text('Outside'));
    expect(tapOutsideCount, 3);
  });

  // Regression test for https://github.com/flutter/flutter/issues/127597.
  testWidgets(
    'The second TextFormField is clicked, triggers the onTapOutside callback of the previous TextFormField',
    (WidgetTester tester) async {
      final GlobalKey keyA = GlobalKey();
      final GlobalKey keyB = GlobalKey();
      final GlobalKey keyC = GlobalKey();
      var outsideClickA = false;
      var outsideClickB = false;
      var outsideClickC = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: Column(
              children: <Widget>[
                const Text('Outside'),
                Material(
                  child: TextFormField(
                    key: keyA,
                    groupId: 'Group A',
                    onTapOutside: (PointerDownEvent event) {
                      outsideClickA = true;
                    },
                  ),
                ),
                Material(
                  child: TextFormField(
                    key: keyB,
                    groupId: 'Group B',
                    onTapOutside: (PointerDownEvent event) {
                      outsideClickB = true;
                    },
                  ),
                ),
                Material(
                  child: TextFormField(
                    key: keyC,
                    groupId: 'Group C',
                    onTapOutside: (PointerDownEvent event) {
                      outsideClickC = true;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      Future<void> click(Finder finder) async {
        await tester.tap(finder);
        await tester.enterText(finder, 'Hello');
        await tester.pump();
      }

      expect(outsideClickA, false);
      expect(outsideClickB, false);
      expect(outsideClickC, false);

      await click(find.byKey(keyA));
      await tester.showKeyboard(find.byKey(keyA));
      await tester.idle();
      expect(outsideClickA, false);
      expect(outsideClickB, false);
      expect(outsideClickC, false);

      await click(find.byKey(keyB));
      expect(outsideClickA, true);
      expect(outsideClickB, false);
      expect(outsideClickC, false);

      await click(find.byKey(keyC));
      expect(outsideClickA, true);
      expect(outsideClickB, true);
      expect(outsideClickC, false);

      await tester.tap(find.text('Outside'));
      expect(outsideClickA, true);
      expect(outsideClickB, true);
      expect(outsideClickC, true);
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/54472.
  testWidgets('reset resets the text fields value to the initialValue', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(initialValue: 'initialValue')),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'changedValue');

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(
      find.byType(TextFormField),
    );
    state.reset();

    expect(find.text('changedValue'), findsNothing);
    expect(find.text('initialValue'), findsOneWidget);
  });

  testWidgets('reset resets the text fields value to the controller initial value', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController(text: 'initialValue');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(controller: controller)),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'changedValue');

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(
      find.byType(TextFormField),
    );
    state.reset();

    expect(find.text('changedValue'), findsNothing);
    expect(find.text('initialValue'), findsOneWidget);
  });

  // Regression test for https://github.com/flutter/flutter/issues/34847.
  testWidgets("didChange resets the text field's value to empty when passed null", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: Center(child: TextFormField())),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'changedValue');
    await tester.pump();
    expect(find.text('changedValue'), findsOneWidget);

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(
      find.byType(TextFormField),
    );
    state.didChange(null);

    expect(find.text('changedValue'), findsNothing);
    expect(find.text(''), findsOneWidget);
  });

  // Regression test for https://github.com/flutter/flutter/issues/34847.
  testWidgets("reset resets the text field's value to empty when initialValue is null", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: Center(child: TextFormField())),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'changedValue');
    await tester.pump();
    expect(find.text('changedValue'), findsOneWidget);

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(
      find.byType(TextFormField),
    );
    state.reset();

    expect(find.text('changedValue'), findsNothing);
    expect(find.text(''), findsOneWidget);
  });

  // Regression test for https://github.com/flutter/flutter/issues/54472.
  testWidgets('didChange changes text fields value', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(initialValue: 'initialValue')),
        ),
      ),
    );

    expect(find.text('initialValue'), findsOneWidget);

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(
      find.byType(TextFormField),
    );
    state.didChange('changedValue');

    expect(find.text('initialValue'), findsNothing);
    expect(find.text('changedValue'), findsOneWidget);
  });

  testWidgets('onChanged callbacks value and FormFieldState.value are sync', (
    WidgetTester tester,
  ) async {
    var called = false;

    late FormFieldState<String> state;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onChanged: (String value) {
                called = true;
                expect(value, state.value);
              },
            ),
          ),
        ),
      ),
    );

    state = tester.state<FormFieldState<String>>(find.byType(TextFormField));

    await tester.enterText(find.byType(TextField), 'Soup');

    expect(called, true);
  });

  testWidgets('autofillHints is passed to super', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(autofillHints: const <String>[AutofillHints.countryName]),
          ),
        ),
      ),
    );

    final TextField widget = tester.widget(find.byType(TextField));
    expect(widget.autofillHints, equals(const <String>[AutofillHints.countryName]));
  });

  testWidgets('autovalidateMode is passed to super', (WidgetTester tester) async {
    var validateCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Scaffold(
            body: TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (String? value) {
                validateCalled++;
                return null;
              },
            ),
          ),
        ),
      ),
    );

    expect(validateCalled, 0);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(validateCalled, 1);
  });

  testWidgets('textSelectionControls is passed to super', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Scaffold(body: TextFormField(selectionControls: materialTextSelectionControls)),
        ),
      ),
    );

    final TextField widget = tester.widget(find.byType(TextField));
    expect(widget.selectionControls, equals(materialTextSelectionControls));
  });

  testWidgets('TextFormField respects hintTextDirection', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Some Label',
                hintText: 'Some Hint',
                hintTextDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );

    final Finder hintTextFinder = find.text('Some Hint');

    final Text hintText = tester.firstWidget(hintTextFinder);
    expect(hintText.textDirection, TextDirection.ltr);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Some Label',
                hintText: 'Some Hint',
              ),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(hintTextFinder);
    final TextDirection textDirection = Directionality.of(context);
    expect(textDirection, TextDirection.rtl);
  });

  testWidgets('Passes scrollController to underlying TextField', (WidgetTester tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(scrollController: scrollController)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.scrollController, scrollController);
  });

  testWidgets('TextFormField changes mouse cursor when hovered', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: TextFormField(mouseCursor: SystemMouseCursors.grab),
          ),
        ),
      ),
    );

    // Center, which is within the area
    final Offset center = tester.getCenter(find.byType(TextFormField));
    // Top left, which is also within the area
    final Offset edge = tester.getTopLeft(find.byType(TextFormField)) + const Offset(1, 1);

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: center);

    await tester.pump();

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.grab,
    );

    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MouseRegion(cursor: SystemMouseCursors.forbidden, child: TextFormField()),
        ),
      ),
    );

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.text,
    );
    await gesture.moveTo(edge);
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.text,
    );
    await gesture.moveTo(center);

    // Test default cursor when disabled
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: TextFormField(enabled: false),
          ),
        ),
      ),
    );

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.basic,
    );
    await gesture.moveTo(edge);
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.basic,
    );
    await gesture.moveTo(center);
  });

  // Regression test for https://github.com/flutter/flutter/issues/101587.
  testWidgets(
    'Right clicking menu behavior',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'blah1 blah2');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(child: TextFormField(controller: controller)),
          ),
        ),
      );

      // Initially, the menu is not shown and there is no selection.
      expect(find.byType(CupertinoButton), findsNothing);
      expect(controller.selection, const TextSelection(baseOffset: -1, extentOffset: -1));

      final Offset midBlah1 = textOffsetToPosition(tester, 2);
      final Offset midBlah2 = textOffsetToPosition(tester, 8);

      // Right click the second word.
      final TestGesture gesture = await tester.startGesture(
        midBlah2,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expect(controller.selection, const TextSelection(baseOffset: 6, extentOffset: 11));
          expect(find.text('Cut'), findsOneWidget);
          expect(find.text('Copy'), findsOneWidget);
          expect(find.text('Paste'), findsOneWidget);

        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(controller.selection, const TextSelection.collapsed(offset: 8));
          expect(find.text('Cut'), findsNothing);
          expect(find.text('Copy'), findsNothing);
          expect(find.text('Paste'), findsOneWidget);
          expect(find.text('Select all'), findsOneWidget);
      }

      // Right click the first word.
      await gesture.down(midBlah1);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
          expect(find.text('Cut'), findsOneWidget);
          expect(find.text('Copy'), findsOneWidget);
          expect(find.text('Paste'), findsOneWidget);

        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(controller.selection, const TextSelection.collapsed(offset: 8));
          expect(find.text('Cut'), findsNothing);
          expect(find.text('Copy'), findsNothing);
          expect(find.text('Paste'), findsNothing);
          expect(find.text('Select all'), findsNothing);
      }
    },
    variant: TargetPlatformVariant.all(),
    skip: kIsWeb, // [intended] we don't supply the cut/copy/paste buttons on the web.
  );

  testWidgets('spellCheckConfiguration passes through to EditableText', (
    WidgetTester tester,
  ) async {
    final mySpellCheckConfiguration = SpellCheckConfiguration(
      spellCheckService: DefaultSpellCheckService(),
      misspelledTextStyle: TextField.materialMisspelledTextStyle,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextFormField(spellCheckConfiguration: mySpellCheckConfiguration)),
      ),
    );

    expect(find.byType(EditableText), findsOneWidget);

    final EditableText editableText = tester.widget(find.byType(EditableText));

    // Can't do equality comparison on spellCheckConfiguration itself because it
    // will have been copied.
    expect(
      editableText.spellCheckConfiguration?.spellCheckService,
      equals(mySpellCheckConfiguration.spellCheckService),
    );
    expect(
      editableText.spellCheckConfiguration?.misspelledTextStyle,
      equals(mySpellCheckConfiguration.misspelledTextStyle),
    );
  });

  testWidgets('magnifierConfiguration passes through to EditableText', (WidgetTester tester) async {
    final myTextMagnifierConfiguration = TextMagnifierConfiguration(
      magnifierBuilder:
          (
            BuildContext context,
            MagnifierController controller,
            ValueNotifier<MagnifierInfo> notifier,
          ) {
            return const Placeholder();
          },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextFormField(magnifierConfiguration: myTextMagnifierConfiguration)),
      ),
    );

    expect(find.byType(EditableText), findsOneWidget);

    final EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.magnifierConfiguration, equals(myTextMagnifierConfiguration));
  });

  testWidgets('Passes undoController to undoController TextField', (WidgetTester tester) async {
    final undoController = UndoHistoryController(value: UndoHistoryValue.empty);
    addTearDown(undoController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(undoController: undoController)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.undoController, undoController);
  });

  testWidgets('Passes cursorOpacityAnimates to cursorOpacityAnimates TextField', (
    WidgetTester tester,
  ) async {
    const cursorOpacityAnimates = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(cursorOpacityAnimates: cursorOpacityAnimates)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.cursorOpacityAnimates, cursorOpacityAnimates);
  });

  testWidgets('Passes contentInsertionConfiguration to contentInsertionConfiguration TextField', (
    WidgetTester tester,
  ) async {
    final contentInsertionConfiguration = ContentInsertionConfiguration(
      onContentInserted: (KeyboardInsertedContent value) {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(contentInsertionConfiguration: contentInsertionConfiguration),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.contentInsertionConfiguration, contentInsertionConfiguration);
  });

  testWidgets('Passes clipBehavior to clipBehavior TextField', (WidgetTester tester) async {
    const Clip clipBehavior = Clip.antiAlias;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(clipBehavior: clipBehavior)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.clipBehavior, clipBehavior);
  });

  testWidgets('Passes scribbleEnabled to scribbleEnabled TextField', (WidgetTester tester) async {
    const scribbleEnabled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(scribbleEnabled: scribbleEnabled)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.scribbleEnabled, scribbleEnabled);
  });

  testWidgets('Passes canRequestFocus to canRequestFocus TextField', (WidgetTester tester) async {
    const canRequestFocus = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(canRequestFocus: canRequestFocus)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.canRequestFocus, canRequestFocus);
  });

  testWidgets('Passes onAppPrivateCommand to onAppPrivateCommand TextField', (
    WidgetTester tester,
  ) async {
    void onAppPrivateCommand(String action, Map<String, dynamic> data) {}

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(onAppPrivateCommand: onAppPrivateCommand)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.onAppPrivateCommand, onAppPrivateCommand);
  });

  testWidgets('Passes selectionHeightStyle to selectionHeightStyle TextField', (
    WidgetTester tester,
  ) async {
    const BoxHeightStyle selectionHeightStyle = BoxHeightStyle.max;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(selectionHeightStyle: selectionHeightStyle)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.selectionHeightStyle, selectionHeightStyle);
  });

  testWidgets('Passes selectionWidthStyle to selectionWidthStyle TextField', (
    WidgetTester tester,
  ) async {
    const BoxWidthStyle selectionWidthStyle = BoxWidthStyle.max;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(selectionWidthStyle: selectionWidthStyle)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.selectionWidthStyle, selectionWidthStyle);
  });

  testWidgets('Passes dragStartBehavior to dragStartBehavior TextField', (
    WidgetTester tester,
  ) async {
    const DragStartBehavior dragStartBehavior = DragStartBehavior.down;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(dragStartBehavior: dragStartBehavior)),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.dragStartBehavior, dragStartBehavior);
  });

  testWidgets('Passes onTapAlwaysCalled to onTapAlwaysCalled TextField', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: Center(child: TextFormField(onTapAlwaysCalled: true))),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.onTapAlwaysCalled, isTrue);
  });

  testWidgets('Passes hintLocales to hintLocales TextField', (WidgetTester tester) async {
    const hintLocales = <Locale>[Locale('fr', 'FR')];
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(child: TextFormField(hintLocales: hintLocales)),
        ),
      ),
    );

    final TextField textFieldWidget = tester.widget(find.byType(TextField));
    expect(textFieldWidget.hintLocales, hintLocales);
  });

  testWidgets('Error color for cursor while validating', (WidgetTester tester) async {
    const themeErrorColor = Color(0xff111111);
    const errorStyleColor = Color(0xff777777);
    const cursorErrorColor = Color(0xffbbbbbb);

    Widget buildWidget({Color? errorStyleColor, Color? cursorErrorColor}) {
      return MaterialApp(
        theme: ThemeData(colorScheme: const ColorScheme.light(error: themeErrorColor)),
        home: Material(
          child: Center(
            child: TextFormField(
              enabled: true,
              autovalidateMode: AutovalidateMode.always,
              decoration: InputDecoration(errorStyle: TextStyle(color: errorStyleColor)),
              cursorErrorColor: cursorErrorColor,
              validator: (String? value) {
                return 'Please enter value';
              },
            ),
          ),
        ),
      );
    }

    Future<void> runTest(Widget widget, {required Color expectedColor}) async {
      await tester.pumpWidget(widget);
      await tester.enterText(find.byType(TextField), 'a');
      final EditableText textField = tester.widget(find.byType(EditableText).first);
      await tester.pump();
      expect(textField.cursorColor, expectedColor);
    }

    await runTest(buildWidget(), expectedColor: themeErrorColor);
    await runTest(buildWidget(errorStyleColor: errorStyleColor), expectedColor: errorStyleColor);
    await runTest(buildWidget(cursorErrorColor: cursorErrorColor), expectedColor: cursorErrorColor);
    await runTest(
      buildWidget(errorStyleColor: errorStyleColor, cursorErrorColor: cursorErrorColor),
      expectedColor: cursorErrorColor,
    );
  });

  testWidgets('TextFormField onChanged is called when the form is reset', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/123009.
    final stateKey = GlobalKey<FormFieldState<String>>();
    final formKey = GlobalKey<FormState>();
    var value = 'initialValue';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextFormField(
              key: stateKey,
              initialValue: value,
              onChanged: (String newValue) {
                value = newValue;
              },
            ),
          ),
        ),
      ),
    );

    // Initial value is 'initialValue'.
    expect(stateKey.currentState!.value, 'initialValue');
    expect(value, 'initialValue');

    // Change value to 'changedValue'.
    await tester.enterText(find.byType(TextField), 'changedValue');
    expect(stateKey.currentState!.value, 'changedValue');
    expect(value, 'changedValue');

    // Should be back to 'initialValue' when the form is reset.
    formKey.currentState!.reset();
    await tester.pump();
    expect(stateKey.currentState!.value, 'initialValue');
    expect(value, 'initialValue');
  });

  testWidgets('isValid returns false when forceErrorText is set and will change error display', (
    WidgetTester tester,
  ) async {
    final fieldKey1 = GlobalKey<FormFieldState<String>>();
    final fieldKey2 = GlobalKey<FormFieldState<String>>();
    const forceErrorText = 'Forcing error.';
    const validString = 'Valid string';
    String? validator(String? s) => s == validString ? null : 'Error text';

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  child: ListView(
                    children: <Widget>[
                      TextFormField(
                        key: fieldKey1,
                        initialValue: validString,
                        validator: validator,
                        autovalidateMode: AutovalidateMode.disabled,
                      ),
                      TextFormField(
                        key: fieldKey2,
                        initialValue: '',
                        forceErrorText: forceErrorText,
                        validator: validator,
                        autovalidateMode: AutovalidateMode.disabled,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(fieldKey1.currentState!.isValid, isTrue);
    expect(fieldKey1.currentState!.hasError, isFalse);
    expect(fieldKey2.currentState!.isValid, isFalse);
    expect(fieldKey2.currentState!.hasError, isTrue);
  });

  testWidgets('forceErrorText will override InputDecoration.error when both are provided', (
    WidgetTester tester,
  ) async {
    const forceErrorText = 'Forcing error';
    const decorationErrorText = 'Decoration';

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  child: TextFormField(
                    forceErrorText: forceErrorText,
                    decoration: const InputDecoration(errorText: decorationErrorText),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(forceErrorText), findsOne);
    expect(find.text(decorationErrorText), findsNothing);
  });

  // Regression test for https://github.com/flutter/flutter/issues/135292.
  testWidgets('Widget returned by errorBuilder is shown', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              autovalidateMode: AutovalidateMode.always,
              validator: (String? value) => 'validation error',
              errorBuilder: (BuildContext context, String errorText) => Text('**$errorText**'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('**validation error**'), findsOneWidget);
  });

  testWidgets(
    'TextFormField asserts when both errorBuilder and decoration.errorText are provided',
    (WidgetTester tester) async {
      expect(
        () => TextFormField(
          decoration: const InputDecoration(errorText: 'Decoration error'),
          errorBuilder: (BuildContext context, String errorText) {
            return Text(errorText);
          },
        ),
        throwsAssertionError,
      );
    },
  );

  group('context menu', () {
    testWidgets(
      'iOS uses the system context menu by default if supported',
      (WidgetTester tester) async {
        tester.platformDispatcher.supportsShowingSystemContextMenu = true;
        addTearDown(() {
          tester.platformDispatcher.resetSupportsShowingSystemContextMenu();
          tester.view.reset();
        });

        final controller = TextEditingController(text: 'one two three');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          // Don't wrap with the global View so that the change to
          // platformDispatcher is read.
          wrapWithView: false,
          View(
            view: tester.view,
            child: MaterialApp(
              home: Material(child: TextField(controller: controller)),
            ),
          ),
        );

        // No context menu shown.
        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
        expect(find.byType(SystemContextMenu), findsNothing);

        // Double tap to select the first word and show the menu.
        await tester.tapAt(textOffsetToPosition(tester, 1));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(textOffsetToPosition(tester, 1));
        await tester.pump(SelectionOverlay.fadeDuration);

        expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
        expect(find.byType(SystemContextMenu), findsOneWidget);
      },
      skip: kIsWeb, // [intended] on web the browser handles the context menu.
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  testWidgets(
    'readOnly disallows SystemContextMenu',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/170521.
      tester.platformDispatcher.supportsShowingSystemContextMenu = true;
      final controller = TextEditingController(text: 'abcdefghijklmnopqr');
      addTearDown(() {
        tester.platformDispatcher.resetSupportsShowingSystemContextMenu();
        tester.view.reset();
        controller.dispose();
      });

      var readOnly = true;
      late StateSetter setState;

      await tester.pumpWidget(
        // Don't wrap with the global View so that the change to
        // platformDispatcher is read.
        wrapWithView: false,
        View(
          view: tester.view,
          child: MaterialApp(
            home: Material(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setter) {
                  setState = setter;
                  return TextFormField(readOnly: readOnly, controller: controller);
                },
              ),
            ),
          ),
        ),
      );

      final Duration waitDuration = SelectionOverlay.fadeDuration > kDoubleTapTimeout
          ? SelectionOverlay.fadeDuration
          : kDoubleTapTimeout;

      // Double tap to select the text.
      await tester.tapAt(textOffsetToPosition(tester, 5));
      await tester.pump(kDoubleTapTimeout ~/ 2);
      await tester.tapAt(textOffsetToPosition(tester, 5));
      await tester.pump(waitDuration);

      // No error as in https://github.com/flutter/flutter/issues/170521.

      // The Flutter-drawn context menu is shown. The SystemContextMenu is not
      // shown because readOnly is true.
      expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
      expect(find.byType(SystemContextMenu), findsNothing);

      // Turn off readOnly and hide the context menu.
      setState(() {
        readOnly = false;
      });
      await tester.tap(find.text('Copy'));
      await tester.pump(waitDuration);

      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      expect(find.byType(SystemContextMenu), findsNothing);

      // Double tap to show the context menu again.
      await tester.tapAt(textOffsetToPosition(tester, 5));
      await tester.pump(kDoubleTapTimeout ~/ 2);
      await tester.tapAt(textOffsetToPosition(tester, 5));
      await tester.pump(waitDuration);

      // Now iOS is showing the SystemContextMenu while others continue to show
      // the Flutter-drawn context menu.
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          expect(find.byType(SystemContextMenu), findsOneWidget);
        case TargetPlatform.macOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
      }
    },
    variant: TargetPlatformVariant.all(),
    skip: kIsWeb, // [intended] on web the browser handles the context menu.
  );

  // Regression test for https://github.com/flutter/flutter/issues/176391.
  testWidgets('TextFormField can inherit decoration from local InputDecorationThemeData', (
    WidgetTester tester,
  ) async {
    const decoration = InputDecoration(labelText: 'Label');
    const decorationTheme = InputDecorationThemeData(labelStyle: TextStyle(color: Colors.green));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InputDecorationTheme(
            data: decorationTheme,
            child: TextFormField(decoration: decoration),
          ),
        ),
      ),
    );

    final InputDecorator decorator = tester.widget(find.byType(InputDecorator));
    final InputDecoration expectedDecoration = decoration
        .applyDefaults(decorationTheme)
        .copyWith(enabled: true, hintMaxLines: 1);
    expect(decorator.decoration, expectedDecoration);
  });

  testWidgets('TextFormField does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    final controller = TextEditingController(text: 'X');
    addTearDown(tester.view.reset);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: TextFormField(controller: controller)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(TextFormField)), Size.zero);
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
  });

  // Regression test for https://github.com/flutter/flutter/issues/180056.
  testWidgets('TextFormField resets to initial value after setState', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: 'Initial Value');
    addTearDown(controller.dispose);

    late StateSetter setState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setter) {
              setState = setter;
              return Form(
                key: formKey,
                child: TextFormField(controller: controller),
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Changed');
    await tester.pump();
    expect(controller.text, 'Changed');

    setState(() {});
    await tester.pump();

    formKey.currentState!.reset();
    await tester.pump();

    expect(controller.text, 'Initial Value');
  });

  testWidgets('onSaved callback is called', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    String? fieldValue;

    Widget builder() {
      return MaterialApp(
        home: Center(
          child: Material(
            child: Form(
              key: formKey,
              child: TextFormField(
                onSaved: (String? value) {
                  fieldValue = value;
                },
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    expect(fieldValue, isNull);

    Future<void> checkText(String testValue) async {
      await tester.enterText(find.byType(TextFormField), testValue);
      formKey.currentState!.save();
      // Pumping is unnecessary because callback happens regardless of frames.
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('Validator sets the error text only when validate is called', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    String? errorText(String? value) => '${value ?? ''}/error';

    Widget builder(AutovalidateMode autovalidateMode) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  autovalidateMode: autovalidateMode,
                  child: TextFormField(validator: errorText),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Start off not autovalidating.
    await tester.pumpWidget(builder(AutovalidateMode.disabled));

    Future<void> checkErrorText(String testValue) async {
      formKey.currentState!.reset();
      await tester.pumpWidget(builder(AutovalidateMode.disabled));
      await tester.enterText(find.byType(TextFormField), testValue);
      await tester.pump();

      // We have to manually validate if we're not autovalidating.
      expect(find.text(errorText(testValue)!), findsNothing);
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text(errorText(testValue)!), findsOneWidget);

      // Try again with autovalidation. Should validate immediately.
      formKey.currentState!.reset();
      await tester.pumpWidget(builder(AutovalidateMode.always));
      await tester.enterText(find.byType(TextFormField), testValue);
      await tester.pump();

      expect(find.text(errorText(testValue)!), findsOneWidget);
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  for (final test in <_PlatformAnnounceScenario>[
    _PlatformAnnounceScenario(
      supportsAnnounce: false,
      testName:
          'Should not announce error message when validate returns errors and supportsAnnounce = false',
    ),
    _PlatformAnnounceScenario(
      supportsAnnounce: true,
      testName:
          'Should announce only the first error message when validate returns errors and supportsAnnounce = true',
    ),
  ]) {
    testWidgets(test.testName, (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(supportsAnnounce: test.supportsAnnounce),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: Material(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(validator: (_) => 'First error message'),
                        TextFormField(validator: (_) => 'Second error message'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      formKey.currentState!.reset();
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pump();

      // Manually validate.
      expect(find.text('First error message'), findsNothing);
      expect(find.text('Second error message'), findsNothing);
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('First error message'), findsOneWidget);
      expect(find.text('Second error message'), findsOneWidget);

      if (test.supportsAnnounce) {
        expect(tester.takeAnnouncements(), [
          isAccessibilityAnnouncement(
            'First error message',
            textDirection: TextDirection.ltr,
            assertiveness: Assertiveness.assertive,
          ),
        ]);
      } else {
        expect(tester.takeAnnouncements(), isEmpty);
      }
    });
  }

  testWidgets('Multiple TextFormFields communicate', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    final fieldKey = GlobalKey<FormFieldState<String>>();
    // Input 2's validator depends on a input 1's value.
    String? errorText(String? input) => '${fieldKey.currentState!.value}/error';

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: ListView(
                    children: <Widget>[
                      TextFormField(key: fieldKey),
                      TextFormField(validator: errorText),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    Future<void> checkErrorText(String testValue) async {
      await tester.enterText(find.byType(TextFormField).first, testValue);
      await tester.pump();

      // Check for a new Text widget with our error text.
      expect(find.text('$testValue/error'), findsOneWidget);
      return;
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Provide initial value to input when no controller is specified', (
    WidgetTester tester,
  ) async {
    const initialValue = 'hello';
    final inputKey = GlobalKey<FormFieldState<String>>();

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  child: TextFormField(key: inputKey, initialValue: 'hello'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(TextFormField));

    // initial value should be loaded into keyboard editing state
    expect(tester.testTextInput.editingState, isNotNull);
    expect(tester.testTextInput.editingState!['text'], equals(initialValue));

    // initial value should also be visible in the raw input line
    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.widget.controller.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(inputKey.currentState!.value, equals(initialValue));
    await tester.enterText(find.byType(TextFormField), 'world');
    await tester.pump();
    expect(inputKey.currentState!.value, equals('world'));
    expect(editableText.widget.controller.text, equals('world'));
  });

  testWidgets('Controller defines initial value', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'hello');
    addTearDown(controller.dispose);
    const initialValue = 'hello';
    final inputKey = GlobalKey<FormFieldState<String>>();

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  child: TextFormField(key: inputKey, controller: controller),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(TextFormField));

    // initial value should be loaded into keyboard editing state
    expect(tester.testTextInput.editingState, isNotNull);
    expect(tester.testTextInput.editingState!['text'], equals(initialValue));

    // initial value should also be visible in the raw input line
    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.widget.controller.text, equals(initialValue));
    expect(controller.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(inputKey.currentState!.value, equals(initialValue));
    await tester.enterText(find.byType(TextFormField), 'world');
    await tester.pump();
    expect(inputKey.currentState!.value, equals('world'));
    expect(editableText.widget.controller.text, equals('world'));
    expect(controller.text, equals('world'));
  });

  testWidgets('TextFormField resets to its initial value', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    final inputKey = GlobalKey<FormFieldState<String>>();
    final controller = TextEditingController(text: 'Plover');
    addTearDown(controller.dispose);

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    key: inputKey,
                    controller: controller,
                    // initialValue is 'Plover'
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(TextFormField));
    final EditableTextState editableText = tester.state(find.byType(EditableText));

    // overwrite initial value.
    controller.text = 'Xyzzy';
    await tester.idle();
    expect(editableText.widget.controller.text, equals('Xyzzy'));
    expect(inputKey.currentState!.value, equals('Xyzzy'));
    expect(controller.text, equals('Xyzzy'));

    // verify value resets to initialValue on reset.
    formKey.currentState!.reset();
    await tester.idle();
    expect(inputKey.currentState!.value, equals('Plover'));
    expect(editableText.widget.controller.text, equals('Plover'));
    expect(controller.text, equals('Plover'));
  });

  testWidgets('TextEditingController updates to/from form field value', (
    WidgetTester tester,
  ) async {
    final controller1 = TextEditingController(text: 'Foo');
    addTearDown(controller1.dispose);
    final controller2 = TextEditingController(text: 'Bar');
    addTearDown(controller2.dispose);
    final inputKey = GlobalKey<FormFieldState<String>>();

    TextEditingController? currentController;
    late StateSetter setState;

    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: Material(
                    child: Form(
                      child: TextFormField(key: inputKey, controller: currentController),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(TextFormField));

    // verify initially empty.
    expect(tester.testTextInput.editingState, isNotNull);
    expect(tester.testTextInput.editingState!['text'], isEmpty);
    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.widget.controller.text, isEmpty);

    // verify changing the controller from null to controller1 sets the value.
    setState(() {
      currentController = controller1;
    });
    await tester.pump();
    expect(editableText.widget.controller.text, equals('Foo'));
    expect(inputKey.currentState!.value, equals('Foo'));

    // verify changes to controller1 text are visible in text field and set in form value.
    controller1.text = 'Wobble';
    await tester.idle();
    expect(editableText.widget.controller.text, equals('Wobble'));
    expect(inputKey.currentState!.value, equals('Wobble'));

    // verify changes to the field text update the form value and controller1.
    await tester.enterText(find.byType(TextFormField), 'Wibble');
    await tester.pump();
    expect(inputKey.currentState!.value, equals('Wibble'));
    expect(editableText.widget.controller.text, equals('Wibble'));
    expect(controller1.text, equals('Wibble'));

    // verify that switching from controller1 to controller2 is handled.
    setState(() {
      currentController = controller2;
    });
    await tester.pump();
    expect(inputKey.currentState!.value, equals('Bar'));
    expect(editableText.widget.controller.text, equals('Bar'));
    expect(controller2.text, equals('Bar'));
    expect(controller1.text, equals('Wibble'));

    // verify changes to controller2 text are visible in text field and set in form value.
    controller2.text = 'Xyzzy';
    await tester.idle();
    expect(editableText.widget.controller.text, equals('Xyzzy'));
    expect(inputKey.currentState!.value, equals('Xyzzy'));
    expect(controller1.text, equals('Wibble'));

    // verify changes to controller1 text are not visible in text field or set in form value.
    controller1.text = 'Plugh';
    await tester.idle();
    expect(editableText.widget.controller.text, equals('Xyzzy'));
    expect(inputKey.currentState!.value, equals('Xyzzy'));
    expect(controller1.text, equals('Plugh'));

    // verify that switching from controller2 to null is handled.
    setState(() {
      currentController = null;
    });
    await tester.pump();
    expect(inputKey.currentState!.value, equals('Xyzzy'));
    expect(editableText.widget.controller.text, equals('Xyzzy'));
    expect(controller2.text, equals('Xyzzy'));
    expect(controller1.text, equals('Plugh'));

    // verify that changes to the field text update the form value but not the previous controllers.
    await tester.enterText(find.byType(TextFormField), 'Plover');
    await tester.pump();
    expect(inputKey.currentState!.value, equals('Plover'));
    expect(editableText.widget.controller.text, equals('Plover'));
    expect(controller1.text, equals('Plugh'));
    expect(controller2.text, equals('Xyzzy'));
  });

  testWidgets('No crash when a TextFormField is removed from the tree', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    String? fieldValue;

    Widget builder(bool remove) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  child: remove
                      ? Container()
                      : TextFormField(
                          autofocus: true,
                          onSaved: (String? value) {
                            fieldValue = value;
                          },
                          validator: (String? value) {
                            return (value == null || value.isEmpty) ? null : 'yes';
                          },
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder(false));

    expect(fieldValue, isNull);
    expect(formKey.currentState!.validate(), isTrue);

    await tester.enterText(find.byType(TextFormField), 'Test');
    await tester.pumpWidget(builder(false));

    // Form wasn't saved yet.
    expect(fieldValue, null);
    expect(formKey.currentState!.validate(), isFalse);

    formKey.currentState!.save();

    // Now fieldValue is saved.
    expect(fieldValue, 'Test');
    expect(formKey.currentState!.validate(), isFalse);

    // Now remove the field with an error.
    await tester.pumpWidget(builder(true));

    // Reset the form. Should not crash.
    formKey.currentState!.reset();
    formKey.currentState!.save();
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets(
    'Form auto-validates form fields only after one of them changes if autovalidateMode is onUserInteraction',
    (WidgetTester tester) async {
      const initialValue = 'foo';
      String? errorText(String? value) => 'error/$value';

      Widget builder() {
        return MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: <Widget>[
                      TextFormField(initialValue: initialValue, validator: errorText),
                      TextFormField(initialValue: initialValue, validator: errorText),
                      TextFormField(initialValue: initialValue, validator: errorText),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Makes sure the Form widget won't auto-validate the form fields
      // after rebuilds if there is not user interaction.
      await tester.pumpWidget(builder());
      await tester.pumpWidget(builder());

      // We expect no validation error text being shown.
      expect(find.text(errorText(initialValue)!), findsNothing);

      // Set a empty string into the first form field to
      // trigger the fields validators.
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pump();

      // Now we expect the errors to be shown for the first Text Field and
      // for the next two form fields that have their contents unchanged.
      expect(find.text(errorText('')!), findsOneWidget);
      expect(find.text(errorText(initialValue)!), findsNWidgets(2));
    },
  );

  testWidgets(
    'Form auto-validates form fields even before any have changed if autovalidateMode is set to always',
    (WidgetTester tester) async {
      String? errorText(String? value) => 'error/$value';

      Widget builder() {
        return MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  autovalidateMode: AutovalidateMode.always,
                  child: TextFormField(validator: errorText),
                ),
              ),
            ),
          ),
        );
      }

      // The issue only happens on the second build so we
      // need to rebuild the tree twice.
      await tester.pumpWidget(builder());
      await tester.pumpWidget(builder());

      // We expect validation error text being shown.
      expect(find.text(errorText('')!), findsOneWidget);
    },
  );

  testWidgets(
    'Form.reset() resets form fields, and auto validation will only happen on the next user interaction if autovalidateMode is onUserInteraction',
    (WidgetTester tester) async {
      final formState = GlobalKey<FormState>();
      String? errorText(String? value) => '$value/error';

      Widget builder() {
        return MaterialApp(
          theme: ThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: Form(
                  key: formState,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Material(
                    child: TextFormField(initialValue: 'foo', validator: errorText),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(builder());

      // No error text is visible yet.
      expect(find.text(errorText('foo')!), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'bar');
      await tester.pumpAndSettle();
      await tester.pump();
      expect(find.text(errorText('bar')!), findsOneWidget);

      // Resetting the form state should remove the error text.
      formState.currentState!.reset();
      await tester.pump();
      expect(find.text(errorText('bar')!), findsNothing);
    },
  );

  testWidgets(
    'Form with AutovalidateMode.onUserInteractionIfError only revalidates when user interacts after an error exists',
    (WidgetTester tester) async {
      final formState = GlobalKey<FormState>();
      String? errorText(String? value) => (value == null || value.isEmpty) ? 'Required' : null;

      Widget builder() {
        return MaterialApp(
          theme: ThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: Form(
                  key: formState,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  child: Material(
                    child: TextFormField(initialValue: 'foo', validator: errorText),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(builder());

      // No error text is visible yet. (Initial valid state).
      expect(find.text('Required'), findsNothing);

      // User types valid input 'bar' → autovalidate is disabled → still no error.
      await tester.enterText(find.byType(TextFormField), 'bar');
      await tester.pump();
      expect(find.text('Required'), findsNothing);

      // Clear the input (invalid).
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      // Manually submit form to show the initial error (AutovalidateMode is now active).
      formState.currentState!.validate();
      expect(find.text('Required'), findsNothing);
      await tester.pump();

      // Verify error is shown.
      expect(find.text('Required'), findsOneWidget);

      // Now user interacts again with valid text ('baz') → validation auto-runs and clears the error.
      await tester.enterText(find.byType(TextFormField), 'baz');
      await tester.pump();
      expect(find.text('Required'), findsNothing);

      // Check the behavior of a manual validate when the text is already valid.
      // This should *confirm* the error is cleared, not re-introduce it.
      formState.currentState!.validate();
      await tester.pump();
      expect(find.text('Required'), findsNothing);

      // Resetting should clear form (already cleared, but a safety check).
      await tester.enterText(find.byType(TextFormField), '');
      formState.currentState!.reset();
      await tester.pump();
      expect(find.text('Required'), findsNothing);
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/63753.
  testWidgets('Validate form should return correct validation if the value is composing', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    String? fieldValue;

    final Widget widget = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Material(
              child: Form(
                key: formKey,
                child: TextFormField(
                  maxLength: 5,
                  maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
                  onSaved: (String? value) {
                    fieldValue = value;
                  },
                  validator: (String? value) =>
                      (value != null && value.length > 5) ? 'Exceeded' : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    final EditableTextState editableText = tester.state<EditableTextState>(
      find.byType(EditableText),
    );
    editableText.updateEditingValue(
      const TextEditingValue(text: '123456', composing: TextRange(start: 2, end: 5)),
    );
    expect(editableText.currentTextEditingValue.composing, const TextRange(start: 2, end: 5));

    formKey.currentState!.save();
    expect(fieldValue, '123456');
    expect(formKey.currentState!.validate(), isFalse);
  });

  testWidgets('hasInteractedByUser returns false when the input has not changed', (
    WidgetTester tester,
  ) async {
    final fieldKey = GlobalKey<FormFieldState<String>>();

    final Widget widget = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Material(child: TextFormField(key: fieldKey)),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    expect(fieldKey.currentState!.hasInteractedByUser, isFalse);
  });

  testWidgets('hasInteractedByUser returns true after the input has changed', (
    WidgetTester tester,
  ) async {
    final fieldKey = GlobalKey<FormFieldState<String>>();

    final Widget widget = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Material(child: TextFormField(key: fieldKey)),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    // initially, the field has not been interacted with
    expect(fieldKey.currentState!.hasInteractedByUser, isFalse);

    // after entering text, the field has been interacted with
    await tester.enterText(find.byType(TextFormField), 'foo');
    expect(fieldKey.currentState!.hasInteractedByUser, isTrue);
  });

  testWidgets('hasInteractedByUser returns false after the field is reset', (
    WidgetTester tester,
  ) async {
    final fieldKey = GlobalKey<FormFieldState<String>>();

    final Widget widget = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Material(child: TextFormField(key: fieldKey)),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    // initially, the field has not been interacted with
    expect(fieldKey.currentState!.hasInteractedByUser, isFalse);

    // after entering text, the field has been interacted with
    await tester.enterText(find.byType(TextFormField), 'foo');
    expect(fieldKey.currentState!.hasInteractedByUser, isTrue);

    // after resetting the field, it has not been interacted with again
    fieldKey.currentState!.reset();
    expect(fieldKey.currentState!.hasInteractedByUser, isFalse);
  });

  testWidgets('forceErrorText forces an error state when first init', (WidgetTester tester) async {
    const forceErrorText = 'Forcing error.';

    Widget builder(AutovalidateMode autovalidateMode) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  autovalidateMode: autovalidateMode,
                  child: TextFormField(forceErrorText: forceErrorText),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder(AutovalidateMode.disabled));
    expect(find.text(forceErrorText), findsOne);
  });

  testWidgets(
    'Validate returns false when forceErrorText is non-null even when validator returns a null value',
    (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      const forceErrorText = 'Forcing error';

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: Material(
                  child: Form(
                    key: formKey,
                    child: TextFormField(
                      forceErrorText: forceErrorText,
                      validator: (String? value) => null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(forceErrorText), findsOne);
      final bool isValid = formKey.currentState!.validate();
      expect(isValid, isFalse);

      await tester.pump();
      expect(find.text(forceErrorText), findsOne);
    },
  );

  testWidgets('forceErrorText forces an error state only after setting it to a non-null value', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    const errorText = 'Forcing Error Text';
    Widget builder(AutovalidateMode autovalidateMode, String? forceErrorText) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  autovalidateMode: autovalidateMode,
                  child: TextFormField(forceErrorText: forceErrorText),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder(AutovalidateMode.disabled, null));
    final bool isValid = formKey.currentState!.validate();
    expect(isValid, true);
    expect(find.text(errorText), findsNothing);
    await tester.pumpWidget(builder(AutovalidateMode.disabled, errorText));
    expect(find.text(errorText), findsOne);
  });

  testWidgets('Validator will not be called if forceErrorText is provided', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    const forceErrorText = 'Forcing error.';
    const validatorErrorText = 'this error should not appear as we override it with forceErrorText';
    var didCallValidator = false;

    Widget builder(AutovalidateMode autovalidateMode) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  autovalidateMode: autovalidateMode,
                  child: TextFormField(
                    forceErrorText: forceErrorText,
                    validator: (String? value) {
                      didCallValidator = true;
                      return validatorErrorText;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Start off not autovalidating.
    await tester.pumpWidget(builder(AutovalidateMode.disabled));
    expect(find.text(forceErrorText), findsOne);
    expect(find.text(validatorErrorText), findsNothing);

    formKey.currentState!.reset();
    await tester.pump();
    expect(find.text(forceErrorText), findsNothing);
    expect(find.text(validatorErrorText), findsNothing);

    // We have to manually validate if we're not autovalidating.
    formKey.currentState!.validate();
    await tester.pump();

    expect(didCallValidator, isFalse);
    expect(find.text(forceErrorText), findsOne);
    expect(find.text(validatorErrorText), findsNothing);

    // Try again with autovalidation. Should validate immediately.
    await tester.pumpWidget(builder(AutovalidateMode.always));

    expect(didCallValidator, isFalse);
    expect(find.text(forceErrorText), findsOne);
    expect(find.text(validatorErrorText), findsNothing);
  });

  testWidgets('Validator is nullified and error text behaves accordingly', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    var useValidator = false;
    late StateSetter setState;

    String? validator(String? value) {
      if (value == null || value.isEmpty) {
        return 'test_error';
      }
      return null;
    }

    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: Material(
                    child: Form(
                      key: formKey,
                      child: TextFormField(validator: useValidator ? validator : null),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(builder());

    // Start with no validator.
    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('test_error'), findsNothing);

    // Now use the validator.
    setState(() {
      useValidator = true;
    });
    await tester.pump();
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('test_error'), findsOneWidget);

    // Remove the validator again and expect the error to disappear.
    setState(() {
      useValidator = false;
    });
    await tester.pump();
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('test_error'), findsNothing);
  });

  testWidgets('AutovalidateMode.onUnfocus', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    String? errorText(String? value) => '$value/error';

    Widget builder() {
      return MaterialApp(
        theme: ThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Material(
                  child: Column(
                    children: <Widget>[
                      TextFormField(initialValue: 'bar', validator: errorText),
                      TextFormField(initialValue: 'bar', validator: errorText),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    // No error text is visible yet.
    expect(find.text(errorText('foo')!), findsNothing);

    // Enter text in the first TextFormField.
    await tester.enterText(find.byType(TextFormField).first, 'foo');
    await tester.pumpAndSettle();

    // No error text is visible yet.
    expect(find.text(errorText('foo')!), findsNothing);

    // Tap on the second TextFormField to trigger validation.
    // This should trigger validation for the first TextFormField as well.
    await tester.tap(find.byType(TextFormField).last);
    await tester.pumpAndSettle();

    // Verify that the error text is displayed for the first TextFormField.
    expect(find.text(errorText('foo')!), findsOneWidget);
    expect(find.text(errorText('bar')!), findsNothing);

    // Tap on the first TextFormField to trigger validation.
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    // Verify that the both error texts are displayed.
    expect(find.text(errorText('foo')!), findsOneWidget);
    expect(find.text(errorText('bar')!), findsOneWidget);
  });

  testWidgets('Validate conflicting AutovalidateModes', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    String? errorText(String? value) => '$value/error';

    Widget builder() {
      return MaterialApp(
        theme: ThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Material(
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        autovalidateMode: AutovalidateMode.always,
                        initialValue: 'foo',
                        validator: errorText,
                      ),
                      TextFormField(
                        autovalidateMode: AutovalidateMode.disabled,
                        initialValue: 'bar',
                        validator: errorText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    // Verify that the error text is displayed for the first TextFormField.
    expect(find.text(errorText('foo')!), findsOneWidget);

    // Enter text in the TextFormField.
    await tester.enterText(find.byType(TextFormField).first, 'foo');
    await tester.pumpAndSettle();

    // Click in the second TextFormField to trigger validation.
    await tester.tap(find.byType(TextFormField).last);
    await tester.pumpAndSettle();

    // No error text is visible yet for the second TextFormField.
    expect(find.text(errorText('bar')!), findsNothing);

    // Now click in the first TextFormField to trigger validation for the second TextFormField.
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    // Verify that the error text is displayed for the second TextFormField.
    expect(find.text(errorText('bar')!), findsOneWidget);
  });

  testWidgets('FocusNode should move to next field when TextInputAction.next is received', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final focusNode1 = FocusNode();
    addTearDown(focusNode1.dispose);
    final focusNode2 = FocusNode();
    addTearDown(focusNode2.dispose);
    final controller1 = TextEditingController();
    addTearDown(controller1.dispose);
    final controller2 = TextEditingController();
    addTearDown(controller2.dispose);

    final Widget widget = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Material(
              child: Form(
                key: formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      focusNode: focusNode1,
                      controller: controller1,
                      textInputAction: TextInputAction.next,
                    ),
                    TextFormField(focusNode: focusNode2, controller: controller2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(focusNode2.hasFocus, isTrue);
  });

  testWidgets('AutovalidateMode.always should validate on second build', (
    WidgetTester tester,
  ) async {
    String errorText(String? value) => '$value/error';

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Center(
          child: Form(
            autovalidateMode: AutovalidateMode.always,
            child: Material(
              child: Column(
                children: <Widget>[
                  TextFormField(initialValue: 'foo', validator: errorText),
                  TextFormField(initialValue: 'bar', validator: errorText),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // The validation happens in a post frame callback, so the error
    // doesn't show up until the second frame.
    expect(find.text(errorText('foo')), findsNothing);
    expect(find.text(errorText('bar')), findsNothing);

    await tester.pump();

    // The error shows up on the second frame.
    expect(find.text(errorText('foo')), findsOneWidget);
    expect(find.text(errorText('bar')), findsOneWidget);
  });

  testWidgets('AutovalidateMode.onUnfocus should validate all fields manually with FormState', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    const fieldKey = Key('form field');
    String errorText(String? value) => '$value/error';

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Material(
              child: Column(
                children: <Widget>[
                  TextFormField(key: fieldKey, initialValue: 'foo', validator: errorText),
                  TextFormField(initialValue: 'bar', validator: errorText),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Focus on the first field.
    await tester.tap(find.byKey(fieldKey));
    await tester.pump();

    // Check no error messages are displayed initially.
    expect(find.text('foo/error'), findsNothing);
    expect(find.text('bar/error'), findsNothing);

    // Validate all fields manually using FormState.
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    // Check error messages are displayed.
    expect(find.text('foo/error'), findsOneWidget);
    expect(find.text('bar/error'), findsOneWidget);
  });

  testWidgets('FormField adds validation result to the semantics of the child', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();

    String? errorText;

    Future<void> pumpWidget() async {
      formKey.currentState?.reset();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: Material(
                  child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.always,
                    child: TextFormField(validator: (String? value) => errorText),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.pump();
    }

    // Test valid case
    await pumpWidget();
    expect(
      tester.getSemantics(find.byType(TextFormField).last),
      isSemantics(
        isTextField: true,
        isFocusable: true,
        validationResult: SemanticsValidationResult.valid,
      ),
    );

    // Test invalid case
    errorText = 'Error';
    await pumpWidget();
    expect(
      tester.getSemantics(find.byType(TextFormField).last),
      isSemantics(
        isTextField: true,
        isFocusable: true,
        validationResult: SemanticsValidationResult.invalid,
      ),
    );
  });
}

class _PlatformAnnounceScenario {
  _PlatformAnnounceScenario({required this.supportsAnnounce, required this.testName});
  final bool supportsAnnounce;
  final String testName;
}
