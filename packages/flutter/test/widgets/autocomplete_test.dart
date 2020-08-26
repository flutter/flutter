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
    'bobcat',
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
    testWidgets('default filter on options', (WidgetTester tester) async {
      final AutocompleteController<String> autocompleteController =
          AutocompleteController<String>(
            options: kOptions,
          );

      // Set a query and see that the results are filtered.
      autocompleteController.textEditingController.text = 'ele';
      expect(autocompleteController.results.value.length, 2);
      expect(autocompleteController.results.value[0], 'chameleon');
      expect(autocompleteController.results.value[1], 'elephant');

      // Modify the selected query. The results are filtered again.
      autocompleteController.textEditingController.text = 'e';
      expect(autocompleteController.results.value.length, 6);
      expect(autocompleteController.results.value[0], 'chameleon');
      expect(autocompleteController.results.value[1], 'elephant');
      expect(autocompleteController.results.value[2], 'goose');
      expect(autocompleteController.results.value[3], 'lemur');
      expect(autocompleteController.results.value[4], 'mouse');
      expect(autocompleteController.results.value[5], 'northern white rhinocerous');

      // The filter is not case sensitive.
      autocompleteController.textEditingController.text = 'ELE';
      expect(autocompleteController.results.value.length, 2);
      expect(autocompleteController.results.value[0], 'chameleon');
      expect(autocompleteController.results.value[1], 'elephant');
    });

    testWidgets('custom filter', (WidgetTester tester) async {
      final AutocompleteController<String> autocompleteController =
          AutocompleteController<String>(
            // A custom filter that always includes 'goose' in the results.
            filter: (String query) {
              return kOptions
                .where((String option) => option.contains(query) || option == 'goose')
                .toList();
            },
          );

      // Set a query and see that the results are filtered by the custom filter.
      autocompleteController.textEditingController.text = 'ele';
      expect(autocompleteController.results.value.length, 3);
      expect(autocompleteController.results.value[0], 'chameleon');
      expect(autocompleteController.results.value[1], 'elephant');
      expect(autocompleteController.results.value[2], 'goose');

      // Modify the selected query. The results are filtered again.
      autocompleteController.textEditingController.text = 'e';
      expect(autocompleteController.results.value.length, 6);
      expect(autocompleteController.results.value[0], 'chameleon');
      expect(autocompleteController.results.value[1], 'elephant');
      expect(autocompleteController.results.value[2], 'goose');
      expect(autocompleteController.results.value[3], 'lemur');
      expect(autocompleteController.results.value[4], 'mouse');
      expect(autocompleteController.results.value[5], 'northern white rhinocerous');
    });

    testWidgets('User options with custom filter string', (WidgetTester tester) async {
      final AutocompleteController<User> autocompleteController =
          AutocompleteController<User>(
            options: kOptionsUsers,
            filterStringForOption: (User option) => option.name + option.email,
          );

      // Set a query based on the email and see that the results are filtered.
      autocompleteController.textEditingController.text = 'example';
      expect(autocompleteController.results.value.length, 2);
      expect(autocompleteController.results.value[0], kOptionsUsers[0]);
      expect(autocompleteController.results.value[1], kOptionsUsers[1]);

      // Modify the selected query. The results appear again and are filtered,
      // this time by name instead of email.
      autocompleteController.textEditingController.text = 'B';
      expect(autocompleteController.results.value.length, 1);
      expect(autocompleteController.results.value[0], kOptionsUsers[1]);
    });

    testWidgets('custom filter on User options', (WidgetTester tester) async {
      final AutocompleteController<User> autocompleteController =
          AutocompleteController<User>(
            // A custom filter that searches by name case sensitively.
            filter: (String query) {
              return kOptionsUsers
                .where((User option) => option.name.contains(query))
                .toList();
            },
          );

      // Set a query based on the email and see that nothing is found.
      autocompleteController.textEditingController.text = 'example';
      expect(autocompleteController.results.value.length, 0);

      // Modify the selected query. The results appear again and are filtered.
      // A lowercase "a" matches "Charlie" and not "Alice".
      autocompleteController.textEditingController.text = 'a';
      expect(autocompleteController.results.value.length, 1);
      expect(autocompleteController.results.value[0], kOptionsUsers[2]);

      // Modify the selected query. An uppercase "A" matches "Alice" and not
      // "Charlie".
      autocompleteController.textEditingController.text = 'A';
      expect(autocompleteController.results.value.length, 1);
      expect(autocompleteController.results.value[0], kOptionsUsers[0]);
    });

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
      AutocompleteOnSelected<String> lastOnSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<String>(
            autocompleteController: autocompleteController,
            buildField: (BuildContext context, TextEditingController textEditingController, AutocompleteOnSelectedString onSelectedString) {
              return Container(key: fieldKey);
            },
            buildResults: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> results) {
              lastResults = results;
              lastOnSelected = onSelected;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      // The query field is always rendered, but the results are not unless
      // needed.
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);

      // Enter a query. The results are filtered by the query.
      autocompleteController.textEditingController.value = const TextEditingValue(
        text: 'ele',
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
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
      autocompleteController.textEditingController.value = const TextEditingValue(
        text: 'e',
        selection: TextSelection(baseOffset: 1, extentOffset: 1),
      );
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
      AutocompleteOnSelected<User> lastOnSelected;
      User lastUserSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<User>(
            autocompleteController: autocompleteController,
            onSelected: (User selected) {
              lastUserSelected = selected;
            },
            buildField: (BuildContext context, TextEditingController textEditingController, AutocompleteOnSelectedString onSelectedString) {
              return Container(key: fieldKey);
            },
            buildResults: (BuildContext context, AutocompleteOnSelected<User> onSelected, List<User> results) {
              lastResults = results;
              lastOnSelected = onSelected;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);

      // Enter a query. The results are filtered by the query.
      autocompleteController.textEditingController.value = const TextEditingValue(
        text: 'example',
        selection: TextSelection(baseOffset: 7, extentOffset: 7),
      );
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
      expect(autocompleteController.textEditingController.text, selection.toString());

      // Modify the selected query. The results appear again and are filtered,
      // this time by name instead of email.
      autocompleteController.textEditingController.value = const TextEditingValue(
        text: 'B',
        selection: TextSelection(baseOffset: 1, extentOffset: 1),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 1);
      expect(lastResults[0], kOptionsUsers[1]);
    });

    testWidgets('can specify a custom display string for a list of custom User options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey resultsKey = GlobalKey();
      final AutocompleteController<User> autocompleteController =
          AutocompleteController<User>(
            options: kOptionsUsers,
            displayStringForOption: (User option) => option.name,
          );
      List<User> lastResults;
      AutocompleteOnSelected<User> lastOnSelected;
      User lastUserSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<User>(
            autocompleteController: autocompleteController,
            onSelected: (User selected) {
              lastUserSelected = selected;
            },
            buildField: (BuildContext context, TextEditingController textEditingController, AutocompleteOnSelectedString onSelectedString) {
              return Container(key: fieldKey);
            },
            buildResults: (BuildContext context, AutocompleteOnSelected<User> onSelected, List<User> results) {
              lastResults = results;
              lastOnSelected = onSelected;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);

      // Enter a query. The results are filtered by the query.
      autocompleteController.textEditingController.value = const TextEditingValue(
        text: 'example',
        selection: TextSelection(baseOffset: 7, extentOffset: 7),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 2);
      expect(lastResults[0], kOptionsUsers[0]);
      expect(lastResults[1], kOptionsUsers[1]);

      // Select a result. The results hide and onSelected is called. The query
      // field has its text set to the selection's display string.
      final User selection = lastResults[1];
      lastOnSelected(selection);
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);
      expect(lastUserSelected, selection);
      expect(autocompleteController.textEditingController.text, selection.name);

      // Modify the selected query. The results appear again and are filtered,
      // this time by name instead of email.
      autocompleteController.textEditingController.value = const TextEditingValue(
        text: 'B',
        selection: TextSelection(baseOffset: 1, extentOffset: 1),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 1);
      expect(lastResults[0], kOptionsUsers[1]);
    });

    testWidgets('onSelectedString selects the first result', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey resultsKey = GlobalKey();
      final AutocompleteController<String> autocompleteController =
          AutocompleteController<String>(
            options: kOptions,
          );
      List<String> lastResults;
      AutocompleteOnSelectedString lastOnSelectedString;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<String>(
            autocompleteController: autocompleteController,
            buildField: (BuildContext context, TextEditingController textEditingController, AutocompleteOnSelectedString onSelectedString) {
              lastOnSelectedString = onSelectedString;
              return Container(key: fieldKey);
            },
            buildResults: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> results) {
              lastResults = results;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      // Enter a query. The results are filtered by the query.
      const String textInField = 'ele';
      autocompleteController.textEditingController.value = const TextEditingValue(
        text: textInField,
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 2);
      expect(lastResults[0], 'chameleon');
      expect(lastResults[1], 'elephant');

      // Select the current string, as if the field was submitted. The results
      // hide and the field updates to show the selection.
      lastOnSelectedString(textInField);
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);
      expect(autocompleteController.textEditingController.text, lastResults[0]);
    });

    testWidgets('results follow field when it moves', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey resultsKey = GlobalKey();
      final AutocompleteController<String> autocompleteController =
          AutocompleteController<String>(
            options: kOptions,
          );
      StateSetter setState;
      Alignment alignment = Alignment.center;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return Align(
                  alignment: alignment,
                  child: AutocompleteCore<String>(
                    autocompleteController: autocompleteController,
                    buildField: (BuildContext context, TextEditingController textEditingController, AutocompleteOnSelectedString onSelectedString) {
                      return TextFormField(
                        key: fieldKey,
                      );
                    },
                    buildResults: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> results) {
                      return Container(key: resultsKey);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Field is shown but not results.
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);

      // Enter a query to show the results.
      autocompleteController.textEditingController.value = const TextEditingValue(
        text: 'ele',
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);

      // Results are just below the field.
      final Offset resultsOffset = tester.getTopLeft(find.byKey(resultsKey));
      Offset fieldOffset = tester.getTopLeft(find.byKey(fieldKey));
      final Size fieldSize = tester.getSize(find.byKey(fieldKey));
      expect(resultsOffset.dy, fieldOffset.dy + fieldSize.height);

      // Move the field (similar to as if the keyboard opened). The results
      // move to follow the field.
      setState(() {
        alignment = Alignment.topCenter;
      });
      await tester.pump();
      fieldOffset = tester.getTopLeft(find.byKey(fieldKey));
      final Offset resultsOffsetOpen = tester.getTopLeft(find.byKey(resultsKey));
      expect(resultsOffsetOpen.dy, isNot(equals(resultsOffset.dy)));
      expect(resultsOffsetOpen.dy, fieldOffset.dy + fieldSize.height);
    });
  });
}
