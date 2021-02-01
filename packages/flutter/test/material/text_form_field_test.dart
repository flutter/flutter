// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/editable_text_utils.dart';

class MockClipboard {
  Object _clipboardData = <String, dynamic>{
    'text': null,
  };

  Future<dynamic> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = methodCall.arguments as Object;
        break;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockClipboard mockClipboard = MockClipboard();
  SystemChannels.platform.setMockMethodCallHandler(mockClipboard.handleMethodCall);

  setUp(() async {
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  testWidgets('can use the desktop cut/copy/paste buttons on Mac', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'blah1 blah2',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              controller: controller,
            ),
          ),
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
    addTearDown(gesture.removePointer);
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
    expect(controller.selection, const TextSelection(baseOffset: 5, extentOffset: 5));
    expect(find.byType(CupertinoButton), findsNothing);

    // Paste it at the end.
    await gesture.down(textOffsetToPosition(tester, controller.text.length));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection, const TextSelection(baseOffset: 11, extentOffset: 11, affinity: TextAffinity.upstream));
    expect(find.text('Cut'), findsNothing);
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Paste'), findsOneWidget);
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    expect(controller.text, 'blah1 blah2blah1');
    expect(controller.selection, const TextSelection(baseOffset: 16, extentOffset: 16));

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
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux }), skip: kIsWeb);

  testWidgets('Passes textAlign to underlying TextField', (WidgetTester tester) async {
    const TextAlign alignment = TextAlign.center;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              textAlign: alignment,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textAlign, alignment);
  });

  testWidgets('Passes scrollPhysics to underlying TextField', (WidgetTester tester) async {
    const ScrollPhysics scrollPhysics = ScrollPhysics();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              scrollPhysics: scrollPhysics,
            ),
          ),
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
          child: Center(
            child: TextFormField(
              textAlignVertical: textAlignVertical,
            ),
          ),
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
          child: Center(
            child: TextFormField(
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.textInputAction, TextInputAction.next);
  });

  testWidgets('Passes onEditingComplete to underlying TextField', (WidgetTester tester) async {
    final VoidCallback onEditingComplete = () { };

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onEditingComplete: onEditingComplete,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.onEditingComplete, onEditingComplete);
  });

  testWidgets('Passes cursor attributes to underlying TextField', (WidgetTester tester) async {
    const double cursorWidth = 3.14;
    const double cursorHeight = 6.28;
    const Radius cursorRadius = Radius.circular(4);
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
    bool _called = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onFieldSubmitted: (String value) { _called = true; },
            ),
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_called, true);
  });

  testWidgets('onChanged callbacks are called', (WidgetTester tester) async {
    late String _value;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onChanged: (String value) {
                _value = value;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Soup');
    await tester.pump();
    expect(_value, 'Soup');
  });

  testWidgets('autovalidateMode is passed to super', (WidgetTester tester) async {
    int _validateCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              autovalidateMode: AutovalidateMode.always,
              validator: (String? value) {
                _validateCalled++;
                return null;
              },
            ),
          ),
        ),
      ),
    );

    expect(_validateCalled, 1);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(_validateCalled, 2);
  });

  testWidgets('validate is called if widget is enabled', (WidgetTester tester) async {
    int _validateCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              enabled: true,
              autovalidateMode: AutovalidateMode.always,
              validator: (String? value) {
                _validateCalled += 1;
                return null;
              },
            ),
          ),
        ),
      ),
    );

    expect(_validateCalled, 1);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(_validateCalled, 2);
  });


  testWidgets('Disabled field hides helper and counter', (WidgetTester tester) async {
    const String helperText = 'helper text';
    const String counterText = 'counter text';
    const String errorText = 'error text';
    Widget buildFrame(bool enabled, bool hasError) {
      return MaterialApp(
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
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
            child: TextFormField(
              buildCounter: (BuildContext context, { int? currentLength, int? maxLength, bool? isFocused }) {
                return Text('${currentLength.toString()} of ${maxLength.toString()}');
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
          child: Center(
            child: TextFormField(
              initialValue: 'readonly',
              readOnly: true,
            ),
          ),
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
  }, skip: isBrowser); // We do not use Flutter-rendered context menu on the Web

  testWidgets('onTap is called upon tap', (WidgetTester tester) async {
    int tapCount = 0;
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

  // Regression test for https://github.com/flutter/flutter/issues/54472.
  testWidgets('reset resets the text fields value to the initialValue', (WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: TextFormField(
                initialValue: 'initialValue',
              ),
            ),
          ),
        )
    );

    await tester.enterText(find.byType(TextFormField), 'changedValue');

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(find.byType(TextFormField));
    state.reset();

    expect(find.text('changedValue'), findsNothing);
    expect(find.text('initialValue'), findsOneWidget);
  });

  // Regression test for https://github.com/flutter/flutter/issues/34847.
  testWidgets('didChange resets the text field\'s value to empty when passed null', (WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: TextFormField(
                initialValue: null,
              ),
            ),
          ),
        )
    );

    await tester.enterText(find.byType(TextFormField), 'changedValue');
    await tester.pump();
    expect(find.text('changedValue'), findsOneWidget);

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(find.byType(TextFormField));
    state.didChange(null);

    expect(find.text('changedValue'), findsNothing);
    expect(find.text(''), findsOneWidget);
  });

  // Regression test for https://github.com/flutter/flutter/issues/34847.
  testWidgets('reset resets the text field\'s value to empty when intialValue is null', (WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: TextFormField(
                initialValue: null,
              ),
            ),
          ),
        )
    );

    await tester.enterText(find.byType(TextFormField), 'changedValue');
    await tester.pump();
    expect(find.text('changedValue'), findsOneWidget);

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(find.byType(TextFormField));
    state.reset();

    expect(find.text('changedValue'), findsNothing);
    expect(find.text(''), findsOneWidget);
  });

  // Regression test for https://github.com/flutter/flutter/issues/54472.
  testWidgets('didChange changes text fields value', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              initialValue: 'initialValue',
            ),
          ),
        ),
      )
    );

    expect(find.text('initialValue'), findsOneWidget);

    final FormFieldState<String> state = tester.state<FormFieldState<String>>(find.byType(TextFormField));
    state.didChange('changedValue');

    expect(find.text('initialValue'), findsNothing);
    expect(find.text('changedValue'), findsOneWidget);
  });

  testWidgets('onChanged callbacks value and FormFieldState.value are sync', (WidgetTester tester) async {
    bool _called = false;

    late FormFieldState<String> state;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              onChanged: (String value) {
                _called = true;
                expect(value, state.value);
              },
            ),
          ),
        ),
      ),
    );

    state = tester.state<FormFieldState<String>>(find.byType(TextFormField));

    await tester.enterText(find.byType(TextField), 'Soup');

    expect(_called, true);
  });

  testWidgets('autofillHints is passed to super', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              autofillHints: const <String>[AutofillHints.countryName],
            ),
          ),
        ),
      ),
    );

    final TextField widget = tester.widget(find.byType(TextField));
    expect(widget.autofillHints, equals(const <String>[AutofillHints.countryName]));
  });

  testWidgets('autovalidateMode is passed to super', (WidgetTester tester) async {
    int _validateCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Scaffold(
            body: TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (String? value) {
                _validateCalled++;
                return null;
              },
            ),
          ),
        ),
      ),
    );

    expect(_validateCalled, 0);
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(_validateCalled, 1);
  });

  testWidgets('autovalidateMode and autovalidate should not be used at the same time', (WidgetTester tester) async {
    expect(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Scaffold(
              body: TextFormField(
                autovalidate: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
          ),
        ),
      );
      }, throwsAssertionError);
  });

  testWidgets('textSelectionControls is passed to super', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Scaffold(
            body: TextFormField(
              selectionControls: materialTextSelectionControls,
            ),
          ),
        ),
      ),
    );

    final TextField widget = tester.widget(find.byType(TextField));
    expect(widget.selectionControls, equals(materialTextSelectionControls));
  });

  testWidgets('TextFormField respects hintTextDirection', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
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
    ));

    final Finder hintTextFinder = find.text('Some Hint');

    final Text hintText = tester.firstWidget(hintTextFinder);
    expect(hintText.textDirection, TextDirection.ltr);

    await tester.pumpWidget(MaterialApp(
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
    ));

    final BuildContext context = tester.element(hintTextFinder);
    final TextDirection textDirection = Directionality.of(context);
    expect(textDirection, TextDirection.rtl);
  });

  testWidgets('Passes scrollController to underlying TextField', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextFormField(
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    );

    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textFieldWidget = tester.widget(textFieldFinder);
    expect(textFieldWidget.scrollController, scrollController);
  });
}
