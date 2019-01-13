// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('onSaved callback is called', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String fieldValue;

    Widget builder() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Material(
            child: Form(
              key: formKey,
              child: TextFormField(
                onSaved: (String value) { fieldValue = value; },
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
      formKey.currentState.save();
      // pump'ing is unnecessary because callback happens regardless of frames
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('onChanged callback is called', (WidgetTester tester) async {
    String fieldValue;

    Widget builder() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Material(
            child: Form(
              child: TextField(
                onChanged: (String value) { fieldValue = value; },
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    expect(fieldValue, isNull);

    Future<void> checkText(String testValue) async {
      await tester.enterText(find.byType(TextField), testValue);
      // pump'ing is unnecessary because callback happens regardless of frames
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('Validator sets the error text only when validate is called', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String errorText(String value) => value + '/error';

    Widget builder(bool autovalidate) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Material(
            child: Form(
              key: formKey,
              autovalidate: autovalidate,
              child: TextFormField(
                validator: errorText,
              ),
            ),
          ),
        ),
      );
    }

    // Start off not autovalidating.
    await tester.pumpWidget(builder(false));

    Future<void> checkErrorText(String testValue) async {
      formKey.currentState.reset();
      await tester.pumpWidget(builder(false));
      await tester.enterText(find.byType(TextFormField), testValue);
      await tester.pump();

      // We have to manually validate if we're not autovalidating.
      expect(find.text(errorText(testValue)), findsNothing);
      formKey.currentState.validate();
      await tester.pump();
      expect(find.text(errorText(testValue)), findsOneWidget);

      // Try again with autovalidation. Should validate immediately.
      formKey.currentState.reset();
      await tester.pumpWidget(builder(true));
      await tester.enterText(find.byType(TextFormField), testValue);
      await tester.pump();

      expect(find.text(errorText(testValue)), findsOneWidget);
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Multiple TextFormFields communicate', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final GlobalKey<FormFieldState<String>> fieldKey = GlobalKey<FormFieldState<String>>();
    // Input 2's validator depends on a input 1's value.
    String errorText(String input) => '${fieldKey.currentState.value}/error';

    Widget builder() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Material(
            child: Form(
              key: formKey,
              autovalidate: true,
              child: ListView(
                children: <Widget>[
                  TextFormField(
                    key: fieldKey,
                  ),
                  TextFormField(
                    validator: errorText,
                  ),
                ],
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
      expect(find.text(testValue + '/error'), findsOneWidget);
      return;
    }

    await checkErrorText('Test');
    await checkErrorText('');
  });

  testWidgets('Provide initial value to input when no controller is specified', (WidgetTester tester) async {
    const String initialValue = 'hello';
    final GlobalKey<FormFieldState<String>> inputKey = GlobalKey<FormFieldState<String>>();

    Widget builder() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Material(
            child: Form(
              child: TextFormField(
                key: inputKey,
                initialValue: 'hello',
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
    expect(tester.testTextInput.editingState['text'], equals(initialValue));

    // initial value should also be visible in the raw input line
    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.widget.controller.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(inputKey.currentState.value, equals(initialValue));
    await tester.enterText(find.byType(TextFormField), 'world');
    await tester.pump();
    expect(inputKey.currentState.value, equals('world'));
    expect(editableText.widget.controller.text, equals('world'));
  });

  testWidgets('Controller defines initial value', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'hello');
    const String initialValue = 'hello';
    final GlobalKey<FormFieldState<String>> inputKey = GlobalKey<FormFieldState<String>>();

    Widget builder() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Material(
            child: Form(
              child: TextFormField(
                key: inputKey,
                controller: controller,
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
    expect(tester.testTextInput.editingState['text'], equals(initialValue));

    // initial value should also be visible in the raw input line
    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.widget.controller.text, equals(initialValue));
    expect(controller.text, equals(initialValue));

    // sanity check, make sure we can still edit the text and everything updates
    expect(inputKey.currentState.value, equals(initialValue));
    await tester.enterText(find.byType(TextFormField), 'world');
    await tester.pump();
    expect(inputKey.currentState.value, equals('world'));
    expect(editableText.widget.controller.text, equals('world'));
    expect(controller.text, equals('world'));
  });

  testWidgets('TextFormField resets to its initial value', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final GlobalKey<FormFieldState<String>> inputKey = GlobalKey<FormFieldState<String>>();
    final TextEditingController controller = TextEditingController(text: 'Plover');

    Widget builder() {
      return Directionality(
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
      );
    }
    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(TextFormField));
    final EditableTextState editableText = tester.state(find.byType(EditableText));

    // overwrite initial value.
    controller.text = 'Xyzzy';
    await tester.idle();
    expect(editableText.widget.controller.text, equals('Xyzzy'));
    expect(inputKey.currentState.value, equals('Xyzzy'));
    expect(controller.text, equals('Xyzzy'));

    // verify value resets to initialValue on reset.
    formKey.currentState.reset();
    await tester.idle();
    expect(inputKey.currentState.value, equals('Plover'));
    expect(editableText.widget.controller.text, equals('Plover'));
    expect(controller.text, equals('Plover'));
  });

  testWidgets('TextEditingController updates to/from form field value', (WidgetTester tester) async {
    final TextEditingController controller1 = TextEditingController(text: 'Foo');
    final TextEditingController controller2 = TextEditingController(text: 'Bar');
    final GlobalKey<FormFieldState<String>> inputKey = GlobalKey<FormFieldState<String>>();

    TextEditingController currentController;
    StateSetter setState;

    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  child: TextFormField(
                    key: inputKey,
                    controller: currentController,
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
    expect(tester.testTextInput.editingState['text'], isEmpty);
    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.widget.controller.text, isEmpty);

    // verify changing the controller from null to controller1 sets the value.
    setState(() {
      currentController = controller1;
    });
    await tester.pump();
    expect(editableText.widget.controller.text, equals('Foo'));
    expect(inputKey.currentState.value, equals('Foo'));

    // verify changes to controller1 text are visible in text field and set in form value.
    controller1.text = 'Wobble';
    await tester.idle();
    expect(editableText.widget.controller.text, equals('Wobble'));
    expect(inputKey.currentState.value, equals('Wobble'));

    // verify changes to the field text update the form value and controller1.
    await tester.enterText(find.byType(TextFormField), 'Wibble');
    await tester.pump();
    expect(inputKey.currentState.value, equals('Wibble'));
    expect(editableText.widget.controller.text, equals('Wibble'));
    expect(controller1.text, equals('Wibble'));

    // verify that switching from controller1 to controller2 is handled.
    setState(() {
      currentController = controller2;
    });
    await tester.pump();
    expect(inputKey.currentState.value, equals('Bar'));
    expect(editableText.widget.controller.text, equals('Bar'));
    expect(controller2.text, equals('Bar'));
    expect(controller1.text, equals('Wibble'));

    // verify changes to controller2 text are visible in text field and set in form value.
    controller2.text = 'Xyzzy';
    await tester.idle();
    expect(editableText.widget.controller.text, equals('Xyzzy'));
    expect(inputKey.currentState.value, equals('Xyzzy'));
    expect(controller1.text, equals('Wibble'));

    // verify changes to controller1 text are not visible in text field or set in form value.
    controller1.text = 'Plugh';
    await tester.idle();
    expect(editableText.widget.controller.text, equals('Xyzzy'));
    expect(inputKey.currentState.value, equals('Xyzzy'));
    expect(controller1.text, equals('Plugh'));

    // verify that switching from controller2 to null is handled.
    setState(() {
      currentController = null;
    });
    await tester.pump();
    expect(inputKey.currentState.value, equals('Xyzzy'));
    expect(editableText.widget.controller.text, equals('Xyzzy'));
    expect(controller2.text, equals('Xyzzy'));
    expect(controller1.text, equals('Plugh'));

    // verify that changes to the field text update the form value but not the previous controllers.
    await tester.enterText(find.byType(TextFormField), 'Plover');
    await tester.pump();
    expect(inputKey.currentState.value, equals('Plover'));
    expect(editableText.widget.controller.text, equals('Plover'));
    expect(controller1.text, equals('Plugh'));
    expect(controller2.text, equals('Xyzzy'));
  });

  testWidgets('No crash when a TextFormField is removed from the tree', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String fieldValue;

    Widget builder(bool remove) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Material(
            child: Form(
              key: formKey,
              child: remove ? Container() : TextFormField(
                autofocus: true,
                onSaved: (String value) { fieldValue = value; },
                validator: (String value) { return value.isEmpty ? null : 'yes'; }
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder(false));

    expect(fieldValue, isNull);
    expect(formKey.currentState.validate(), isTrue);

    await tester.enterText(find.byType(TextFormField), 'Test');
    await tester.pumpWidget(builder(false));

    // Form wasn't saved yet.
    expect(fieldValue, null);
    expect(formKey.currentState.validate(), isFalse);

    formKey.currentState.save();

    // Now fieldValue is saved.
    expect(fieldValue, 'Test');
    expect(formKey.currentState.validate(), isFalse);

    // Now remove the field with an error.
    await tester.pumpWidget(builder(true));

    // Reset the form. Should not crash.
    formKey.currentState.reset();
    formKey.currentState.save();
    expect(formKey.currentState.validate(), isTrue);
  });
}
