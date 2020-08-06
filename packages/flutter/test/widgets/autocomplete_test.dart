// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class User {
  const User({
    this.email,
    this.name,
  });

  final String email;
  final String name;

  @override
  String toString() {
    return '$name, $email';
  }
}

void main() {
  const List<String> kOptions = <String>[
    'aardvark',
    'baboon',
    'chameleon',
    'dingo',
    'elephant',
    'flamingo',
    'goose',
    'hippopotamus',
    'iguana',
    'jaguar',
    'koala',
    'lemur',
    'mouse',
    'northern white rhinocerous',
  ];

  const List<User> kOptionsUsers = <User>[
    User(name: 'Alice', email: 'alice@example.com'),
    User(name: 'Bob', email: 'bob@example.com'),
    User(name: 'Charlie', email: 'charlie123@gmail.com'),
  ];

  group('AutocompleteController', () {
    group('dispose', () {
      testWidgets('disposes the TextEditingController when not passed in', (WidgetTester tester) async {
        final AutocompleteController<String> autocompleteController =
            AutocompleteController<String>(
              options: kOptions,
            );
        expect(autocompleteController.textEditingController, isNotNull);

        autocompleteController.dispose();
        expect(() {
          autocompleteController.textEditingController.addListener(() {});
        }, throwsFlutterError);
      });

      testWidgets("doesn't dispose the TextEditingController when passed in", (WidgetTester tester) async {
        final TextEditingController textEditingController = TextEditingController();
        final AutocompleteController<String> autocompleteController =
            AutocompleteController<String>(
              options: kOptions,
              textEditingController: textEditingController,
            );
        expect(autocompleteController.textEditingController, isNotNull);

        autocompleteController.dispose();
        expect(() {
          autocompleteController.textEditingController.addListener(() {});
        }, isNot(throwsException));
        // No error thrown
      });
    });
  });

  group('AutocompleteCore', () {
    testWidgets('can filter and select a list of string options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey resultsKey = GlobalKey();
      final AutocompleteController<String> autocompleteController =
          AutocompleteController<String>(
            options: kOptions,
          );
      List<String> lastResults;
      OnSelectedAutocomplete<String> lastOnSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<String>(
            autocompleteController: autocompleteController,
            buildField: (BuildContext context) {
              return Container(key: fieldKey);
            },
            buildResults: (BuildContext context, OnSelectedAutocomplete<String> onSelected, List<String> results) {
              lastResults = results;
              lastOnSelected = onSelected;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);

      // Enter a query. The results are filtered by the query.
      autocompleteController.textEditingController.text = 'ele';
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 2);
      expect(lastResults[0], 'chameleon');
      expect(lastResults[1], 'elephant');

      // Select a result. The results hide and the field updates to show the
      // selection.
      final String selection = lastResults[1];
      lastOnSelected(selection);
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);
      expect(autocompleteController.textEditingController.text, selection);

      // Modify the selected query. The results appear again and are filtered.
      autocompleteController.textEditingController.text = 'e';
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 6);
      expect(lastResults[0], 'chameleon');
      expect(lastResults[1], 'elephant');
      expect(lastResults[2], 'goose');
      expect(lastResults[3], 'lemur');
      expect(lastResults[4], 'mouse');
      expect(lastResults[5], 'northern white rhinocerous');
    });

    testWidgets('can filter and select a list of custom User options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey resultsKey = GlobalKey();
      final AutocompleteController<User> autocompleteController =
          AutocompleteController<User>(
            options: kOptionsUsers,
          );
      List<User> lastResults;
      OnSelectedAutocomplete<User> lastOnSelected;
      User lastUserSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<User>(
            autocompleteController: autocompleteController,
            onSelected: (User selected) {
              lastUserSelected = selected;
            },
            buildField: (BuildContext context) {
              return Container(key: fieldKey);
            },
            buildResults: (BuildContext context, OnSelectedAutocomplete<User> onSelected, List<User> results) {
              lastResults = results;
              lastOnSelected = onSelected;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);

      // Enter a query. The results are filtered by the query.
      autocompleteController.textEditingController.text = 'example';
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 2);
      expect(lastResults[0], kOptionsUsers[0]);
      expect(lastResults[1], kOptionsUsers[1]);

      // Select a result. The results hide and onSelected is called.
      final User selection = lastResults[1];
      lastOnSelected(selection);
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);
      expect(lastUserSelected, selection);
      // The field hasn't been updated because we passed onSelected. When
      // onSelected is passed, it's up to it to update the field.
      expect(autocompleteController.textEditingController.text, 'example');

      // Modify the selected query. The results appear again and are filtered,
      // this time by name instead of email.
      autocompleteController.textEditingController.text = 'B';
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 1);
      expect(lastResults[0], kOptionsUsers[1]);
    });
  });
}
