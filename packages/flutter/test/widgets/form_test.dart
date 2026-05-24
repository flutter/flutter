// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
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
                  autovalidateMode: AutovalidateMode.disabled,
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
