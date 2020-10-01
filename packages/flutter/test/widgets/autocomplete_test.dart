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

  group('AutocompleteCore', () {
    testWidgets('can filter and select a list of string options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey resultsKey = GlobalKey();
      List<String> lastResults;
      AutocompleteOnSelected<String> lastOnSelected;
      TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<String>(
            buildOptions: (TextEditingValue textEditingValue) {
              return kOptions.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              }).toList();
            },
            fieldBuilder: (BuildContext context, TextEditingController fieldTextEditingController, VoidCallback onFieldSubmitted) {
              textEditingController ??= fieldTextEditingController;
              return Container(key: fieldKey);
            },
            resultsBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> results) {
              lastResults = results;
              lastOnSelected = onSelected;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      // The field is always rendered, but the results are not unless needed.
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);

      // Enter text. The results are filtered by the text.
      textEditingController.value = const TextEditingValue(
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
      expect(textEditingController.text, selection);

      // Modify the field text. The results appear again and are filtered.
      textEditingController.value = const TextEditingValue(
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
      List<User> lastResults;
      AutocompleteOnSelected<User> lastOnSelected;
      User lastUserSelected;
      TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<User>(
            buildOptions: (TextEditingValue textEditingValue) {
              return kOptionsUsers.where((User option) {
                return option.toString().contains(textEditingValue.text.toLowerCase());
              }).toList();
            },
            onSelected: (User selected) {
              lastUserSelected = selected;
            },
            fieldBuilder: (BuildContext context, TextEditingController fieldTextEditingController, VoidCallback onFieldSubmitted) {
              textEditingController ??= fieldTextEditingController;
              return Container(key: fieldKey);
            },
            resultsBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, List<User> results) {
              lastResults = results;
              lastOnSelected = onSelected;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);

      // Enter text. The results are filtered by the text.
      textEditingController.value = const TextEditingValue(
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
      expect(textEditingController.text, selection.toString());

      // Modify the field text. The results appear again and are filtered, this
      // time by name instead of email.
      textEditingController.value = const TextEditingValue(
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
      List<User> lastResults;
      AutocompleteOnSelected<User> lastOnSelected;
      User lastUserSelected;
      final AutocompleteOptionToString<User> displayStringForOption = (User option) => option.name;
      TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<User>(
            buildOptions: (TextEditingValue textEditingValue) {
              return kOptionsUsers.where((User option) {
                return option
                    .toString()
                    .contains(textEditingValue.text.toLowerCase());
              }).toList();
            },
            displayStringForOption: displayStringForOption,
            onSelected: (User selected) {
              lastUserSelected = selected;
            },
            fieldBuilder: (BuildContext context, TextEditingController fieldTextEditingController, VoidCallback onFieldSubmitted) {
              textEditingController ??= fieldTextEditingController;
              return Container(key: fieldKey);
            },
            resultsBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, List<User> results) {
              lastResults = results;
              lastOnSelected = onSelected;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);

      // Enter text. The results are filtered by the text.
      textEditingController.value = const TextEditingValue(
        text: 'example',
        selection: TextSelection(baseOffset: 7, extentOffset: 7),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 2);
      expect(lastResults[0], kOptionsUsers[0]);
      expect(lastResults[1], kOptionsUsers[1]);

      // Select a result. The results hide and onSelected is called. The field
      // has its text set to the selection's display string.
      final User selection = lastResults[1];
      lastOnSelected(selection);
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);
      expect(lastUserSelected, selection);
      expect(textEditingController.text, selection.name);

      // Modify the field text. The results appear again and are filtered, this
      // time by name instead of email.
      textEditingController.value = const TextEditingValue(
        text: 'B',
        selection: TextSelection(baseOffset: 1, extentOffset: 1),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsOneWidget);
      expect(lastResults.length, 1);
      expect(lastResults[0], kOptionsUsers[1]);
    });

    testWidgets('onFieldSubmitted selects the first result', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey resultsKey = GlobalKey();
      List<String> lastResults;
      VoidCallback lastOnFieldSubmitted;
      TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: AutocompleteCore<String>(
            buildOptions: (TextEditingValue textEditingValue) {
              return kOptions.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              }).toList();
            },
            fieldBuilder: (BuildContext context, TextEditingController fieldTextEditingController, VoidCallback onFieldSubmitted) {
              textEditingController ??= fieldTextEditingController;
              lastOnFieldSubmitted = onFieldSubmitted;
              return Container(key: fieldKey);
            },
            resultsBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> results) {
              lastResults = results;
              return Container(key: resultsKey);
            },
          ),
        ),
      );

      // Enter text. The results are filtered by the text.
      textEditingController.value = const TextEditingValue(
        text: 'ele',
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
      lastOnFieldSubmitted();
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(resultsKey), findsNothing);
      expect(textEditingController.text, lastResults[0]);
    });

    testWidgets('results follow field when it moves', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey resultsKey = GlobalKey();
      StateSetter setState;
      Alignment alignment = Alignment.center;
      TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return Align(
                  alignment: alignment,
                  child: AutocompleteCore<String>(
                    buildOptions: (TextEditingValue textEditingValue) {
                      return kOptions.where((String option) {
                        return option.contains(textEditingValue.text.toLowerCase());
                      }).toList();
                    },
                    fieldBuilder: (BuildContext context, TextEditingController fieldTextEditingController, VoidCallback onFieldSubmitted) {
                      textEditingController ??= fieldTextEditingController;
                      return TextFormField(
                        controller: fieldTextEditingController,
                        key: fieldKey,
                      );
                    },
                    resultsBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> results) {
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

      // Enter text to show the results.
      textEditingController.value = const TextEditingValue(
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
