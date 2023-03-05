// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ListenableFutureBuilder updates UI when future resolves',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int>>(
          listenable: () async => ValueNotifier<int>(42),
          builder: (BuildContext context, Widget? child,
                  AsyncSnapshot<ValueNotifier<int>> snapshot) =>
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
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int>>(
          listenable: () async => Future<ValueNotifier<int>>.delayed(
            const Duration(milliseconds: 500),
            () => throw Exception('Oops'),
          ),
          builder: (BuildContext context, Widget? child,
              AsyncSnapshot<Listenable> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.error != null) {
              final dynamic error = snapshot.error as dynamic;
              // ignore: avoid_dynamic_calls
              final String errorMessage = 'Error: ${error.message}';
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
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<String?>>(
          listenable: () async => ValueNotifier<String?>(null),
          builder: (BuildContext context, Widget? child,
                  AsyncSnapshot<ValueNotifier<String?>> snapshot) =>
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
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int>>(
          listenable: () async => Future<ValueNotifier<int>>.delayed(
            const Duration(seconds: 2),
            () => ValueNotifier<int>(42),
          ),
          builder: (BuildContext context, Widget? child,
                  AsyncSnapshot<ValueNotifier<int>> snapshot) =>
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
      (WidgetTester tester) async {
    final ValueNotifier<int> notifier = ValueNotifier<int>(0);

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int>>(
          listenable: () async => notifier,
          builder: (BuildContext context, Widget? child,
                  AsyncSnapshot<ValueNotifier<int>> snapshot) =>
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

  ///Notes: we need to confirm that the builder drops its reference to the
  ///Listenable when the widget is disposed. If the state holds onto a
  ///previous AsyncSnapshot, it will hold onto the Listenable as well. This
  ///test ensures that the State doesn't hold onto the Listenable after
  ///disposal.
  testWidgets('ListenableFutureBuilder disposes correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableFutureBuilder<ValueNotifier<int?>>(
          listenable: () async => ValueNotifier<int?>(3),
          builder: (BuildContext context, Widget? child,
                  AsyncSnapshot<ValueNotifier<int?>> snapshot) =>
              snapshot.connectionState == ConnectionState.done
                  ? Text('${snapshot.data!.value}')
                  : const CircularProgressIndicator(),
        ),
      ),
    );

    //_ListenableFutureBuilderState is private so we cannot access the state
    //without dynamic
    final dynamic state =
        tester.state(find.byType(ListenableFutureBuilder<ValueNotifier<int?>>));

    //Triggers disposal
    await tester.pumpWidget(const SizedBox());

    final AsyncSnapshot<ValueNotifier<int?>> snapshot =
        //We have lastSnapshot so we can test this. Alternative approaches to
        //testing for this are absolutely welcome, and we can remove this
        //getter if it is too problematic.
        // ignore: avoid_dynamic_calls
        state.lastSnapshot as AsyncSnapshot<ValueNotifier<int?>>;

    //Verify the state does not hold onto the Listenable after disposal
    expect(snapshot.data, isNull);
    expect(snapshot.connectionState, ConnectionState.none);
  });
}
