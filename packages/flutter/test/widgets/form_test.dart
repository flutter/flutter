// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onSaved callback is called', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String? fieldValue;

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    onSaved: (String? value) { fieldValue = value; },
                  ),
                ),
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

  testWidgets('onChanged callback is called', (WidgetTester tester) async {
    String? fieldValue;

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
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
    String? errorText(String? value) => '${value ?? ''}/error';

    Widget builder(AutovalidateMode autovalidateMode) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  autovalidateMode: autovalidateMode,
                  child: TextFormField(
                    validator: errorText,
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

  testWidgets('isValid returns true when a field is valid', (WidgetTester tester) async {
    final GlobalKey<FormFieldState<String>> fieldKey1 = GlobalKey<FormFieldState<String>>();
    final GlobalKey<FormFieldState<String>> fieldKey2 = GlobalKey<FormFieldState<String>>();
    const String validString = 'Valid string';
    String? validator(String? s) => s == validString ? null : 'Error text';

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
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
                        autovalidateMode: AutovalidateMode.always,
                      ),
                      TextFormField(
                        key: fieldKey2,
                        initialValue: validString,
                        validator: validator,
                        autovalidateMode: AutovalidateMode.always,
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

    expect(fieldKey1.currentState!.isValid, isTrue);
    expect(fieldKey2.currentState!.isValid, isTrue);
  });

  testWidgets(
    'isValid returns false when the field is invalid and does not change error display',
    (WidgetTester tester) async {
      final GlobalKey<FormFieldState<String>> fieldKey1 = GlobalKey<FormFieldState<String>>();
      final GlobalKey<FormFieldState<String>> fieldKey2 = GlobalKey<FormFieldState<String>>();
      const String validString = 'Valid string';
      String? validator(String? s) => s == validString ? null : 'Error text';

      Widget builder() {
        return MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 1.0),
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
        );
      }

      await tester.pumpWidget(builder());

      expect(fieldKey1.currentState!.isValid, isTrue);
      expect(fieldKey2.currentState!.isValid, isFalse);
      expect(fieldKey2.currentState!.hasError, isFalse);
    },
  );

  testWidgets('Multiple TextFormFields communicate', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final GlobalKey<FormFieldState<String>> fieldKey = GlobalKey<FormFieldState<String>>();
    // Input 2's validator depends on a input 1's value.
    String? errorText(String? input) => '${fieldKey.currentState!.value}/error';

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.always,
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

  testWidgets('Provide initial value to input when no controller is specified', (WidgetTester tester) async {
    const String initialValue = 'hello';
    final GlobalKey<FormFieldState<String>> inputKey = GlobalKey<FormFieldState<String>>();

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
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
    final TextEditingController controller = TextEditingController(text: 'hello');
    const String initialValue = 'hello';
    final GlobalKey<FormFieldState<String>> inputKey = GlobalKey<FormFieldState<String>>();

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
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
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final GlobalKey<FormFieldState<String>> inputKey = GlobalKey<FormFieldState<String>>();
    final TextEditingController controller = TextEditingController(text: 'Plover');

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
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

  testWidgets('TextEditingController updates to/from form field value', (WidgetTester tester) async {
    final TextEditingController controller1 = TextEditingController(text: 'Foo');
    final TextEditingController controller2 = TextEditingController(text: 'Bar');
    final GlobalKey<FormFieldState<String>> inputKey = GlobalKey<FormFieldState<String>>();

    TextEditingController? currentController;
    late StateSetter setState;

    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(devicePixelRatio: 1.0),
              child: Directionality(
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

  testWidgets('No crash when a TextFormField is removed from the tree', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String? fieldValue;

    Widget builder(bool remove) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: formKey,
                  child: remove ? Container() : TextFormField(
                    autofocus: true,
                    onSaved: (String? value) { fieldValue = value; },
                    validator: (String? value) { return (value == null || value.isEmpty) ? null : 'yes'; },
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

  testWidgets('Does not auto-validate before value changes when autovalidateMode is set to onUserInteraction', (WidgetTester tester) async {
    late FormFieldState<String> formFieldState;

    String? errorText(String? value) => '$value/error';

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: FormField<String>(
                  initialValue: 'foo',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  builder: (FormFieldState<String> state) {
                    formFieldState = state;
                    return Container();
                  },
                  validator: errorText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    // The form field has no error.
    expect(formFieldState.hasError, isFalse);
    // No error widget is visible.
    expect(find.text(errorText('foo')!), findsNothing);
  });

  testWidgets('auto-validate before value changes if autovalidateMode was set to always', (WidgetTester tester) async {
    late FormFieldState<String> formFieldState;

    String? errorText(String? value) => '$value/error';

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: FormField<String>(
                  initialValue: 'foo',
                  autovalidateMode: AutovalidateMode.always,
                  builder: (FormFieldState<String> state) {
                    formFieldState = state;
                    return Container();
                  },
                  validator: errorText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    expect(formFieldState.hasError, isTrue);
  });

  testWidgets('Form auto-validates form fields only after one of them changes if autovalidateMode is onUserInteraction', (WidgetTester tester) async {
    const String initialValue = 'foo';
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
                    TextFormField(
                      initialValue: initialValue,
                      validator: errorText,
                    ),
                    TextFormField(
                      initialValue: initialValue,
                      validator: errorText,
                    ),
                    TextFormField(
                      initialValue: initialValue,
                      validator: errorText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Makes sure the Form widget won't autovalidate the form fields
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
  });

  testWidgets('Form auto-validates form fields even before any have changed if autovalidateMode is set to always', (WidgetTester tester) async {
    String? errorText(String? value) => 'error/$value';

    Widget builder() {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Material(
              child: Form(
                autovalidateMode: AutovalidateMode.always,
                child: TextFormField(
                  validator: errorText,
                ),
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
  });

  testWidgets('autovalidate parameter is still used if true', (WidgetTester tester) async {
    late FormFieldState<String> formFieldState;
    String? errorText(String? value) => '$value/error';

    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: FormField<String>(
                  initialValue: 'foo',
                  autovalidate: true,
                  builder: (FormFieldState<String> state) {
                    formFieldState = state;
                    return Container();
                  },
                  validator: errorText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    expect(formFieldState.hasError, isTrue);
  });

  testWidgets('Form.reset() resets form fields, and auto validation will only happen on the next user interaction if autovalidateMode is onUserInteraction', (WidgetTester tester) async {
    final GlobalKey<FormState> formState = GlobalKey<FormState>();
    String? errorText(String? value) => '$value/error';

    Widget builder() {
      return MaterialApp(
        theme: ThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Form(
                key: formState,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Material(
                  child: TextFormField(
                    initialValue: 'foo',
                    validator: errorText,
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

    await tester.enterText(find.byType(TextFormField), 'bar');
    await tester.pumpAndSettle();
    await tester.pump();
    expect(find.text(errorText('bar')!), findsOneWidget);

    // Resetting the form state should remove the error text.
    formState.currentState!.reset();
    await tester.pump();
    expect(find.text(errorText('bar')!), findsNothing);
  });

  testWidgets('Form.autovalidateMode and Form.autovalidate should not be used at the same time', (WidgetTester tester) async {
    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Form(
              autovalidate: true,
              autovalidateMode: AutovalidateMode.disabled,
              child: Container(),
            ),
          ),
        ),
      );
    }
    expect(() => builder(), throwsAssertionError);
  });

  testWidgets('FormField.autovalidateMode and FormField.autovalidate should not be used at the same time', (WidgetTester tester) async {
    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: FormField<String>(
              autovalidate: true,
              autovalidateMode: AutovalidateMode.disabled,
              builder: (_) {
                return Container();
              },
            ),
          ),
        ),
      );
    }
    expect(() => builder(), throwsAssertionError);
  });

  // Regression test for https://github.com/flutter/flutter/issues/63753.
  testWidgets('Validate form should return correct validation if the value is composing', (WidgetTester tester) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String? fieldValue;

    final Widget widget = MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Material(
              child: Form(
                key: formKey,
                child: TextFormField(
                  maxLength: 5,
                  maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
                  onSaved: (String? value) { fieldValue = value; },
                  validator: (String? value) => (value != null && value.length > 5) ? 'Exceeded' : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    final EditableTextState editableText = tester.state<EditableTextState>(find.byType(EditableText));
    editableText.updateEditingValue(const TextEditingValue(text: '123456', composing: TextRange(start: 2, end: 5)));
    expect(editableText.currentTextEditingValue.composing, const TextRange(start: 2, end: 5));

    formKey.currentState!.save();
    expect(fieldValue, '123456');
    expect(formKey.currentState!.validate(), isFalse);
  });

  testWidgets('FormField.autovalidate parameter is passed into class the property', (WidgetTester tester) async {
    String? errorText(String? value) => '$value/error';
    const ObjectKey widgetKey = ObjectKey('key');

    Widget builder({required bool autovalidate}) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: FormField<String>(
                  key: widgetKey,
                  initialValue: 'foo',
                  autovalidate: autovalidate,
                  builder: (FormFieldState<String> state) {
                    return Container();
                  },
                  validator: errorText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // When autovalidate is true
    await tester.pumpWidget(builder(autovalidate: true));

    final Finder formFieldFinder = find.byKey(widgetKey);
    FormField<String> formField = tester.widget(formFieldFinder);
    expect(formField.autovalidate, isTrue);
    expect(formField.autovalidateMode, equals(AutovalidateMode.always));

    // When autovalidate is false
    await tester.pumpWidget(builder(autovalidate: false));

    formField = tester.widget(formFieldFinder);
    expect(formField.autovalidate, isFalse);
    expect(formField.autovalidateMode, equals(AutovalidateMode.disabled));
  });

  testWidgets('Form.autovalidate parameter is passed into class the property', (WidgetTester tester) async {
    const ObjectKey widgetKey = ObjectKey('key');

    Widget builder({required bool autovalidate}) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: Form(
                  key: widgetKey,
                  autovalidate: autovalidate,
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // When autovalidate is true
    await tester.pumpWidget(builder(autovalidate: true));

    final Finder formFinder = find.byKey(widgetKey);
    Form formWidget = tester.widget(formFinder);
    expect(formWidget.autovalidate, isTrue);
    expect(formWidget.autovalidateMode, equals(AutovalidateMode.always));

    // When autovalidate is false
    await tester.pumpWidget(builder(autovalidate: false));

    formWidget = tester.widget(formFinder);
    expect(formWidget.autovalidate, isFalse);
    expect(formWidget.autovalidateMode, equals(AutovalidateMode.disabled));
  });
}
