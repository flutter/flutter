// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ListenableFutureBuilder updates UI when future resolves',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int>>(
          future: () async => ValueNotifier(42),
          builder: (context, child, snapshot) =>
              snapshot.connectionState == ConnectionState.done
                  ? Text('${snapshot.data!.value}')
                  : const CircularProgressIndicator(),
        ),
      ),
    );

    // Verify that CircularProgressIndicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('42'), findsNothing);

    // Wait for future to resolve
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that Text widget with value 42 is shown after future resolves
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('ListenableFutureBuilder updates UI when future errors',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int>>(
          future: () async => Future<ValueNotifier<int>>.delayed(
            const Duration(milliseconds: 500),
            () => throw Exception('Oops'),
          ),
          builder: (context, child, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.error != null) {
              final dynamic error = snapshot.error as dynamic;
              // ignore: avoid_dynamic_calls
              final errorMessage = 'Error: ${error.message}';
              return Text(errorMessage);
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );

    // Verify that CircularProgressIndicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Error: Oops'), findsNothing);

    // Wait for future to resolve
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that Text widget with error message is shown after future errors
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Error: Oops'), findsOneWidget);
  });

  testWidgets('ListenableFutureBuilder updates UI when future returns null',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<String?>>(
          future: () async => ValueNotifier<String?>(null),
          builder: (context, child, snapshot) =>
              snapshot.connectionState == ConnectionState.done
                  ? Text(
                      snapshot.data?.value == null
                          ? 'Nothing'
                          : snapshot.data!.value!,
                    )
                  : const CircularProgressIndicator(),
        ),
      ),
    );

    // Verify that CircularProgressIndicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Nothing'), findsNothing);

    // Wait for future to resolve
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that Text widget with value null is shown after future resolves
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Nothing'), findsOneWidget);
  });

  testWidgets(
      'ListenableFutureBuilder updates UI when future takes a while to resolve',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int>>(
          future: () async => Future.delayed(
            const Duration(seconds: 2),
            () => ValueNotifier(42),
          ),
          builder: (context, child, snapshot) =>
              snapshot.connectionState == ConnectionState.done
                  ? Text('${snapshot.data!.value}')
                  : const CircularProgressIndicator(),
        ),
      ),
    );

    // Verify that CircularProgressIndicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('42'), findsNothing);

    // Wait for future to resolve
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that Text widget with value 42 is shown after future resolves
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('ListenableFutureBuilder updates UI when the notifier is changed',
      (tester) async {
    final notifier = ValueNotifier<int>(0);

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int>>(
          future: () async => notifier,
          builder: (context, child, snapshot) =>
              snapshot.connectionState == ConnectionState.done
                  ? Text('${snapshot.data!.value}')
                  : const CircularProgressIndicator(),
        ),
      ),
    );

    // Verify that CircularProgressIndicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('0'), findsNothing);

    // Wait for future to resolve
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that Text widget with value 0 is shown after future resolves
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('0'), findsOneWidget);

    // Increment the value of the notifier
    notifier.value = 1;

    // Verify that Text widget with value 1 is shown after notifier is changed
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });
}
