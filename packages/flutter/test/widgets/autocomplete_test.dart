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
      final GlobalKey optionsKey = GlobalKey();
      List<String> lastOptions;
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
            optionsBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> options) {
              lastOptions = options;
              lastOnSelected = onSelected;
              return Container(key: optionsKey);
            },
          ),
        ),
      );

      // The field is always rendered, but the options are not unless needed.
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);

      // Enter text. The options are filtered by the text.
      textEditingController.value = const TextEditingValue(
        text: 'ele',
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions[0], 'chameleon');
      expect(lastOptions[1], 'elephant');

      // Select a option. The options hide and the field updates to show the
      // selection.
      final String selection = lastOptions[1];
      lastOnSelected(selection);
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);
      expect(textEditingController.text, selection);

      // Modify the field text. The options appear again and are filtered.
      textEditingController.value = const TextEditingValue(
        text: 'e',
        selection: TextSelection(baseOffset: 1, extentOffset: 1),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 6);
      expect(lastOptions[0], 'chameleon');
      expect(lastOptions[1], 'elephant');
      expect(lastOptions[2], 'goose');
      expect(lastOptions[3], 'lemur');
      expect(lastOptions[4], 'mouse');
      expect(lastOptions[5], 'northern white rhinocerous');
    });

    testWidgets('can filter and select a list of custom User options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      List<User> lastOptions;
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
            optionsBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, List<User> options) {
              lastOptions = options;
              lastOnSelected = onSelected;
              return Container(key: optionsKey);
            },
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);

      // Enter text. The options are filtered by the text.
      textEditingController.value = const TextEditingValue(
        text: 'example',
        selection: TextSelection(baseOffset: 7, extentOffset: 7),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions[0], kOptionsUsers[0]);
      expect(lastOptions[1], kOptionsUsers[1]);

      // Select a option. The options hide and onSelected is called.
      final User selection = lastOptions[1];
      lastOnSelected(selection);
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);
      expect(lastUserSelected, selection);
      expect(textEditingController.text, selection.toString());

      // Modify the field text. The options appear again and are filtered, this
      // time by name instead of email.
      textEditingController.value = const TextEditingValue(
        text: 'B',
        selection: TextSelection(baseOffset: 1, extentOffset: 1),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 1);
      expect(lastOptions[0], kOptionsUsers[1]);
    });

    testWidgets('can specify a custom display string for a list of custom User options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      List<User> lastOptions;
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
            optionsBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, List<User> options) {
              lastOptions = options;
              lastOnSelected = onSelected;
              return Container(key: optionsKey);
            },
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);

      // Enter text. The options are filtered by the text.
      textEditingController.value = const TextEditingValue(
        text: 'example',
        selection: TextSelection(baseOffset: 7, extentOffset: 7),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions[0], kOptionsUsers[0]);
      expect(lastOptions[1], kOptionsUsers[1]);

      // Select a option. The options hide and onSelected is called. The field
      // has its text set to the selection's display string.
      final User selection = lastOptions[1];
      lastOnSelected(selection);
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);
      expect(lastUserSelected, selection);
      expect(textEditingController.text, selection.name);

      // Modify the field text. The options appear again and are filtered, this
      // time by name instead of email.
      textEditingController.value = const TextEditingValue(
        text: 'B',
        selection: TextSelection(baseOffset: 1, extentOffset: 1),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 1);
      expect(lastOptions[0], kOptionsUsers[1]);
    });

    testWidgets('onFieldSubmitted selects the first option', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      List<String> lastOptions;
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
            optionsBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> options) {
              lastOptions = options;
              return Container(key: optionsKey);
            },
          ),
        ),
      );

      // Enter text. The options are filtered by the text.
      textEditingController.value = const TextEditingValue(
        text: 'ele',
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions[0], 'chameleon');
      expect(lastOptions[1], 'elephant');

      // Select the current string, as if the field was submitted. The options
      // hide and the field updates to show the selection.
      lastOnFieldSubmitted();
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);
      expect(textEditingController.text, lastOptions[0]);
    });

    testWidgets('options follow field when it moves', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
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
                    optionsBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> options) {
                      return Container(key: optionsKey);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Field is shown but not options.
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);

      // Enter text to show the options.
      textEditingController.value = const TextEditingValue(
        text: 'ele',
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);

      // Options are just below the field.
      final Offset optionsOffset = tester.getTopLeft(find.byKey(optionsKey));
      Offset fieldOffset = tester.getTopLeft(find.byKey(fieldKey));
      final Size fieldSize = tester.getSize(find.byKey(fieldKey));
      expect(optionsOffset.dy, fieldOffset.dy + fieldSize.height);

      // Move the field (similar to as if the keyboard opened). The options move
      // to follow the field.
      setState(() {
        alignment = Alignment.topCenter;
      });
      await tester.pump();
      fieldOffset = tester.getTopLeft(find.byKey(fieldKey));
      final Offset optionsOffsetOpen = tester.getTopLeft(find.byKey(optionsKey));
      expect(optionsOffsetOpen.dy, isNot(equals(optionsOffset.dy)));
      expect(optionsOffsetOpen.dy, fieldOffset.dy + fieldSize.height);
    });
  });
}
