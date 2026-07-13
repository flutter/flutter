// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editable_text_tester.dart';
import 'widgets_app_tester.dart';

void main() {
  testWidgets('onChanged callback is called', (WidgetTester tester) async {
    String? fieldValue;

    await tester.pumpWidget(
      _formTestApp(
        Form(
          child: TestTextField(
            onChanged: (String value) {
              fieldValue = value;
            },
          ),
        ),
      ),
    );

    expect(fieldValue, isNull);

    Future<void> checkText(String testValue) async {
      await tester.enterText(find.byType(TestTextField), testValue);
      // Pumping is unnecessary because callback happens regardless of frames.
      expect(fieldValue, equals(testValue));
    }

    await checkText('Test');
    await checkText('');
  });

  testWidgets('onReset callback is called', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    var resetCalled = false;

    await tester.pumpWidget(
      _formTestApp(
        Form(
          key: formKey,
          child: FormField<String>(
            builder: (_) => const SizedBox.shrink(),
            onReset: () {
              resetCalled = true;
            },
          ),
        ),
      ),
    );

    expect(resetCalled, isFalse);

    formKey.currentState!.reset();
    await tester.pump();

    expect(resetCalled, isTrue);
  });

  testWidgets('Form reports error when SemanticsService.sendAnnouncement fails during validation', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final formKey = GlobalKey<FormState>();
      const validString = 'Valid string';
      String? validator(String? s) => s == validString ? null : 'error';
      final errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final String contextStr = details.context?.toString() ?? '';
        if (contextStr.contains('while sending semantics announcement')) {
          errors.add(details);
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = originalOnError;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          SystemChannels.accessibility.name,
          null,
        );
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        SystemChannels.accessibility.name,
        (ByteData? message) async {
          const codec = StandardMessageCodec();
          final Object? decoded = codec.decodeMessage(message);
          if (decoded is Map && decoded['type'] == 'announce') {
            final data = ByteData(1);
            data.setUint8(0, 255); // Invalid type byte
            return data;
          }
          return null; // Success for other events
        },
      );

      await tester.pumpWidget(
        _formTestApp(
          Form(
            key: formKey,
            child: ListView(
              children: <Widget>[
                FormField<String>(
                  initialValue: '',
                  validator: validator,
                  builder: (FormFieldState<String> state) {
                    return Container();
                  },
                ),
              ],
            ),
          ),
          mediaQueryData: const MediaQueryData(supportsAnnounce: true),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(errors, isNotEmpty);
      final bool hasAnnouncementError = errors.any(
        (e) =>
            e.exception.toString().contains('FormatException') &&
            e.context.toString().contains('while sending semantics announcement'),
      );
      expect(hasAnnouncementError, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'Does not auto-validate before value changes when autovalidateMode is set to onUserInteraction',
    (WidgetTester tester) async {
      late FormFieldState<String> formFieldState;

      String? errorText(String? value) => '$value/error';

      await tester.pumpWidget(
        _formTestApp(
          FormField<String>(
            initialValue: 'foo',
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (FormFieldState<String> state) {
              formFieldState = state;
              return Container();
            },
            validator: errorText,
          ),
        ),
      );

      // The form field has no error.
      expect(formFieldState.hasError, isFalse);
      // No error widget is visible.
      expect(find.text(errorText('foo')!), findsNothing);
    },
  );

  testWidgets(
    'Does not auto-validate before value changes when autovalidateMode is set to onUserInteractionIfError',
    (WidgetTester tester) async {
      late FormFieldState<String> formFieldState;

      String? errorText(String? value) => (value == null || value.isEmpty) ? 'Required' : null;

      await tester.pumpWidget(
        _formTestApp(
          FormField<String>(
            initialValue: 'foo',
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            builder: (FormFieldState<String> state) {
              formFieldState = state;
              return Container();
            },
            validator: errorText,
          ),
        ),
      );

      // The form field has no error.
      expect(formFieldState.hasError, isFalse);
      // No "Required" error is visible.
      expect(find.text('Required'), findsNothing);
    },
  );

  testWidgets(
    'Does not auto-validate before value changes even when initialValue is empty and autovalidateMode is set to onUserInteractionIfError',
    (WidgetTester tester) async {
      late FormFieldState<String> formFieldState;

      String? errorText(String? value) => (value == null || value.isEmpty) ? 'Required' : null;

      await tester.pumpWidget(
        _formTestApp(
          FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            builder: (FormFieldState<String> state) {
              formFieldState = state;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(),
                  if (state.errorText != null) Text(state.errorText!),
                ],
              );
            },
            validator: errorText,
          ),
        ),
      );

      expect(formFieldState.hasError, isFalse);

      expect(find.text('Required'), findsNothing);

      expect(formFieldState.errorText, isNull);

      formFieldState.validate();
      await tester.pump();

      expect(formFieldState.hasError, isTrue);

      expect(find.text('Required'), findsOneWidget);
    },
  );

  testWidgets('auto-validate before value changes if autovalidateMode was set to always', (
    WidgetTester tester,
  ) async {
    late FormFieldState<String> formFieldState;

    String? errorText(String? value) => '$value/error';

    await tester.pumpWidget(
      _formTestApp(
        FormField<String>(
          initialValue: 'foo',
          autovalidateMode: AutovalidateMode.always,
          builder: (FormFieldState<String> state) {
            formFieldState = state;
            return Container();
          },
          validator: errorText,
        ),
      ),
    );
    expect(formFieldState.hasError, isTrue);
  });

  testWidgets('Form does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(child: Form(child: Text('X'))),
        ),
      ),
    );
    expect(tester.getSize(find.byType(Form)), Size.zero);
  });

  testWidgets('FormField does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(
            child: FormField<String>(builder: (FormFieldState<String> field) => const Text('X')),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(FormField<String>)), Size.zero);
  });

  testWidgets('isValid returns true when a field is valid', (WidgetTester tester) async {
    final fieldKey1 = GlobalKey<FormFieldState<String>>();
    final fieldKey2 = GlobalKey<FormFieldState<String>>();
    const validString = 'Valid string';
    String? validator(String? s) => s == validString ? null : 'Error text';

    await tester.pumpWidget(
      _formTestApp(
        Form(
          child: Column(
            children: <Widget>[
              _TestFormField<String>(
                key: fieldKey1,
                initialValue: validString,
                validator: validator,
                autovalidateMode: AutovalidateMode.always,
              ),
              _TestFormField<String>(
                key: fieldKey2,
                initialValue: validString,
                validator: validator,
                autovalidateMode: AutovalidateMode.always,
              ),
            ],
          ),
        ),
      ),
    );

    expect(fieldKey1.currentState!.isValid, isTrue);
    expect(fieldKey2.currentState!.isValid, isTrue);
  });

  testWidgets('isValid returns false when the field is invalid and does not change error display', (
    WidgetTester tester,
  ) async {
    final fieldKey1 = GlobalKey<FormFieldState<String>>();
    final fieldKey2 = GlobalKey<FormFieldState<String>>();
    const validString = 'Valid string';
    String? validator(String? s) => s == validString ? null : 'Error text';

    await tester.pumpWidget(
      _formTestApp(
        Form(
          child: Column(
            children: <Widget>[
              _TestFormField<String>(
                key: fieldKey1,
                initialValue: validString,
                validator: validator,
              ),
              _TestFormField<String>(key: fieldKey2, initialValue: '', validator: validator),
            ],
          ),
        ),
      ),
    );

    expect(fieldKey1.currentState!.isValid, isTrue);
    expect(fieldKey2.currentState!.isValid, isFalse);
    expect(fieldKey2.currentState!.hasError, isFalse);
  });

  testWidgets('validateGranularly returns a set containing all, and only, invalid fields', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final validFieldsKey = UniqueKey();
    final invalidFieldsKey1 = UniqueKey();
    final invalidFieldsKey2 = UniqueKey();

    const validString = 'Valid string';
    const invalidString = 'Invalid string';
    String? validator(String? s) => s == validString ? null : 'Error text';

    await tester.pumpWidget(
      _formTestApp(
        Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              _TestFormField<String>(
                key: validFieldsKey,
                initialValue: validString,
                validator: validator,
              ),
              _TestFormField<String>(
                key: invalidFieldsKey1,
                initialValue: invalidString,
                validator: validator,
              ),
              _TestFormField<String>(
                key: invalidFieldsKey2,
                initialValue: invalidString,
                validator: validator,
              ),
            ],
          ),
        ),
      ),
    );

    final Set<FormFieldState<dynamic>> validationResult = formKey.currentState!
        .validateGranularly();

    expect(validationResult.length, equals(2));
    expect(
      validationResult.map<Key?>((FormFieldState<dynamic> field) => field.widget.key),
      unorderedEquals(<Key>[invalidFieldsKey1, invalidFieldsKey2]),
    );
    expect(
      validationResult
          .where((FormFieldState<dynamic> field) => field.widget.key == validFieldsKey)
          .length,
      equals(0),
    );
  });

  testWidgets('Should announce error text when validateGranularly is called', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    const validString = 'Valid string';
    String? validator(String? s) => s == validString ? null : 'error';

    await tester.pumpWidget(
      _formTestApp(
        Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              _TestFormField<String>(initialValue: validString, validator: validator),
              _TestFormField<String>(initialValue: '', validator: validator),
            ],
          ),
        ),
        mediaQueryData: const MediaQueryData(supportsAnnounce: true),
      ),
    );
    expect(find.text('error'), findsNothing);

    formKey.currentState!.validateGranularly();

    await tester.pump();
    expect(find.text('error'), findsOneWidget);

    expect(tester.takeAnnouncements(), [
      isAccessibilityAnnouncement(
        'error',
        textDirection: TextDirection.ltr,
        assertiveness: Assertiveness.assertive,
      ),
    ]);
  });

  testWidgets('clearError() clears error but keeps value', (WidgetTester tester) async {
    final fieldKey = GlobalKey<FormFieldState<String>>();
    String errorText(String? value) => '$value/error';

    await tester.pumpWidget(
      _formTestApp(
        Form(
          child: _TestFormField<String>(key: fieldKey, initialValue: 'foo', validator: errorText),
        ),
      ),
    );

    fieldKey.currentState?.validate();
    await tester.pump();
    expect(find.text(errorText('foo')), findsOneWidget);

    fieldKey.currentState?.clearError();
    await tester.pump();

    expect(find.text(errorText('foo')), findsNothing);

    // Value is preserved.
    expect(find.text('foo'), findsOneWidget);
  });

  testWidgets('clearError() clears all field errors', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    String errorText(String? value) => '$value/error';

    await tester.pumpWidget(
      _formTestApp(
        Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              _TestFormField<String>(initialValue: 'foo', validator: errorText),
              _TestFormField<String>(initialValue: 'bar', validator: errorText),
            ],
          ),
        ),
      ),
    );

    formKey.currentState?.validate();
    await tester.pump();

    expect(find.text(errorText('foo')), findsOneWidget);
    expect(find.text(errorText('bar')), findsOneWidget);

    formKey.currentState?.clearError();
    await tester.pump();

    expect(find.text(errorText('foo')), findsNothing);
    expect(find.text(errorText('bar')), findsNothing);

    // Values are preserved.
    expect(find.text('foo'), findsOneWidget);
    expect(find.text('bar'), findsOneWidget);
  });

  testWidgets('exposes all registered FormFieldStates with their values', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _formTestApp(
        Form(
          key: formKey,
          child: const Column(
            children: <Widget>[
              _TestFormField<String>(initialValue: 'A'),
              _TestFormField<String>(initialValue: 'B'),
            ],
          ),
        ),
      ),
    );

    final FormState formState = formKey.currentState!;

    expect(formState.fields.length, equals(2));
    expect(formState.fields.map((field) => field.value), containsAll(<String>['A', 'B']));
  });

  testWidgets('reports all fields as invalid after validation errors', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    String errorText(String? value) => '$value/error';

    await tester.pumpWidget(
      _formTestApp(
        Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              _TestFormField<String>(initialValue: 'foo', validator: errorText),
              _TestFormField<String>(initialValue: 'bar', validator: errorText),
            ],
          ),
        ),
      ),
    );

    formKey.currentState?.validate();
    await tester.pump();

    expect(find.text(errorText('foo')), findsOneWidget);
    expect(find.text(errorText('bar')), findsOneWidget);

    final List<FormFieldState<dynamic>> fields = formKey.currentState!.fields.toList();

    // Expect all fields to be invalid.
    expect(fields.every((field) => !field.isValid), isTrue);
  });

  testWidgets('isValid evaluates validity without updating error UI', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    String errorText(String? value) => '$value/error';

    await tester.pumpWidget(
      _formTestApp(
        Form(
          key: formKey,
          child: _TestFormField<String>(initialValue: 'foo', validator: errorText),
        ),
      ),
    );

    final FormFieldState<dynamic> field = formKey.currentState!.fields.single;

    expect(field.isValid, isFalse);

    // No error UI should be shown.
    expect(find.text(errorText('foo')), findsNothing);
    expect(field.hasError, isFalse);
  });

  testWidgets('allows collecting and updating values from registered FormFields', (
    WidgetTester tester,
  ) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _formTestApp(
        Form(
          key: formKey,
          child: const Column(
            children: <Widget>[
              _TestFormField<String>(key: ValueKey<String>('name'), initialValue: 'Name'),
              _TestFormField<String>(key: ValueKey<String>('email'), initialValue: 'Email'),
              _TestFormField<int>(key: ValueKey<String>('age'), initialValue: 18),
              _TestFormField<String>(key: ValueKey<String>('animal'), initialValue: 'cat'),
            ],
          ),
        ),
      ),
    );

    Map<String, dynamic> collectData() {
      return {
        for (final field in formKey.currentState!.fields)
          if (field.widget.key case ValueKey<String>(:final value)) value: field.value,
      };
    }

    expect(collectData(), <String, Object>{
      'name': 'Name',
      'email': 'Email',
      'age': 18,
      'animal': 'cat',
    });

    FormFieldState<T> field<T>(String key) => formKey.currentState!.fields
        .whereType<FormFieldState<T>>()
        .singleWhere((f) => f.widget.key == ValueKey(key));

    field<String>('name').didChange('New Name');
    field<String>('email').didChange('new@email.com');
    field<int>('age').didChange(30);
    field<String>('animal').didChange('dog');

    await tester.pump();

    expect(collectData(), <String, Object>{
      'name': 'New Name',
      'email': 'new@email.com',
      'age': 30,
      'animal': 'dog',
    });
  });
}

Widget _formTestApp(Widget child, {MediaQueryData? mediaQueryData}) {
  return TestWidgetsApp(
    textStyle: const TextStyle(),
    home: Center(child: child),
    builder: mediaQueryData == null
        ? null
        : (BuildContext context, Widget? child) {
            return MediaQuery(data: mediaQueryData, child: child!);
          },
  );
}

class _TestFormField<T> extends FormField<T> {
  const _TestFormField({
    super.key,
    super.initialValue,
    super.validator,
    super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(builder: _builder);

  static Widget _builder<T>(FormFieldState<T> field) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('${field.value}'),
        if (field.errorText != null) Text(field.errorText!),
      ],
    );
  }
}
