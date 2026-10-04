// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TextFormField restorationId is passed to inner TextField', (
    WidgetTester tester,
  ) async {
    final formState = GlobalKey<FormFieldState<String>>();
    const restorationId = 'text_form_field';

    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Material(
          child: TextFormField(
            key: formState,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            restorationId: restorationId,
            initialValue: 'foo',
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOne);

    final TextField textField = tester.firstWidget(find.byType(TextField));
    expect(textField.restorationId, restorationId);
  });

  testWidgets('TextFormField value is restorable', (WidgetTester tester) async {
    final formState = GlobalKey<FormFieldState<String>>();

    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Material(
          child: TextFormField(
            key: formState,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            restorationId: 'text_form_field',
            initialValue: 'foo',
          ),
        ),
      ),
    );

    expect(find.text('foo'), findsOne);
    expect(find.text('bar'), findsNothing);

    await tester.enterText(find.byKey(formState), 'bar');
    await tester.pumpAndSettle();

    expect(find.text('foo'), findsNothing);
    expect(find.text('bar'), findsOne);

    final TestRestorationData data = await tester.getRestorationData();
    await tester.restartAndRestore();

    expect(find.text('foo'), findsNothing);
    expect(find.text('bar'), findsOne);

    formState.currentState!.reset();

    expect(find.text('foo'), findsOne);
    expect(find.text('bar'), findsNothing);

    await tester.restoreFrom(data);

    expect(find.text('foo'), findsNothing);
    expect(find.text('bar'), findsOne);
  });

  testWidgets('State restoration (No Form ancestor) - onUserInteraction error text validation', (
    WidgetTester tester,
  ) async {
    String? errorText(String? value) => '$value/error';
    late GlobalKey<FormFieldState<String>> formState;

    Widget builder() {
      return MaterialApp(
        restorationScopeId: 'app',
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter state) {
                  formState = GlobalKey<FormFieldState<String>>();
                  return Material(
                    child: TextFormField(
                      key: formState,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      restorationId: 'text_form_field',
                      initialValue: 'foo',
                      validator: errorText,
                    ),
                  );
                },
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
    expect(find.text(errorText('bar')!), findsOneWidget);

    final TestRestorationData data = await tester.getRestorationData();
    await tester.restartAndRestore();
    // Error text should be present after restart and restore.
    expect(find.text(errorText('bar')!), findsOneWidget);

    // Resetting the form state should remove the error text.
    formState.currentState!.reset();
    await tester.pumpAndSettle();
    expect(find.text(errorText('bar')!), findsNothing);
    await tester.restartAndRestore();
    // Error text should still be removed after restart and restore.
    expect(find.text(errorText('bar')!), findsNothing);

    await tester.restoreFrom(data);
    expect(find.text(errorText('bar')!), findsOneWidget);
  });

  testWidgets(
    'State Restoration (No Form ancestor) - validator sets the error text only when validate is called',
    (WidgetTester tester) async {
      String? errorText(String? value) => '$value/error';
      late GlobalKey<FormFieldState<String>> formState;

      Widget builder(AutovalidateMode mode) {
        return MaterialApp(
          restorationScopeId: 'app',
          home: MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter state) {
                    formState = GlobalKey<FormFieldState<String>>();
                    return Material(
                      child: TextFormField(
                        key: formState,
                        restorationId: 'form_field',
                        autovalidateMode: mode,
                        initialValue: 'foo',
                        validator: errorText,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }

      // Start off not autovalidating.
      await tester.pumpWidget(builder(AutovalidateMode.disabled));

      Future<void> checkErrorText(String testValue) async {
        formState.currentState!.reset();
        await tester.pumpWidget(builder(AutovalidateMode.disabled));
        await tester.enterText(find.byType(TextFormField), testValue);
        await tester.pump();

        // We have to manually validate if we're not autovalidating.
        expect(find.text(errorText(testValue)!), findsNothing);
        formState.currentState!.validate();
        await tester.pump();
        expect(find.text(errorText(testValue)!), findsOneWidget);
        final TestRestorationData data = await tester.getRestorationData();
        await tester.restartAndRestore();
        // Error text should be present after restart and restore.
        expect(find.text(errorText(testValue)!), findsOneWidget);

        formState.currentState!.reset();
        await tester.pumpAndSettle();
        expect(find.text(errorText(testValue)!), findsNothing);

        await tester.restoreFrom(data);
        expect(find.text(errorText(testValue)!), findsOneWidget);

        // Try again with autovalidation. Should validate immediately.
        formState.currentState!.reset();
        await tester.pumpWidget(builder(AutovalidateMode.always));
        await tester.enterText(find.byType(TextFormField), testValue);
        await tester.pump();

        expect(find.text(errorText(testValue)!), findsOneWidget);
        await tester.restartAndRestore();
        // Error text should be present after restart and restore.
        expect(find.text(errorText(testValue)!), findsOneWidget);
      }

      await checkErrorText('Test');
      await checkErrorText('');
    },
  );
}
