// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class User {
  const User({
    required this.email,
    required this.name,
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

      // Enter text and see that the results are filtered.
      autocompleteController.textEditingController.text = 'ele';
      expect(autocompleteController.results.value.length, 2);
      expect(autocompleteController.results.value[0], 'chameleon');
      expect(autocompleteController.results.value[1], 'elephant');

      // Modify the text. The results are filtered again.
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

    testWidgets('custom getResults', (WidgetTester tester) async {
      final AutocompleteController<String> autocompleteController =
          AutocompleteController<String>.generated(
            // A custom getResults that always includes 'goose' in the results.
            getResults: (TextEditingValue value) {
              return kOptions
                .where((String option) => option.contains(value.text) || option == 'goose')
                .toList();
            },
          );

      // Set text in the field and see that the results are filtered by
      // getResults.
      autocompleteController.textEditingController.text = 'ele';
      expect(autocompleteController.results.value.length, 3);
      expect(autocompleteController.results.value[0], 'chameleon');
      expect(autocompleteController.results.value[1], 'elephant');
      expect(autocompleteController.results.value[2], 'goose');

      // Modify the text. The results are filtered again.
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

      // Set the field text based on the email and see that the results are
      // filtered.
      autocompleteController.textEditingController.text = 'example';
      expect(autocompleteController.results.value.length, 2);
      expect(autocompleteController.results.value[0], kOptionsUsers[0]);
      expect(autocompleteController.results.value[1], kOptionsUsers[1]);

      // Modify the field text. The results appear again and are filtered, this
      // time by name instead of email.
      autocompleteController.textEditingController.text = 'B';
      expect(autocompleteController.results.value.length, 1);
      expect(autocompleteController.results.value[0], kOptionsUsers[1]);
    });

    testWidgets('custom getResults on User options', (WidgetTester tester) async {
      final AutocompleteController<User> autocompleteController =
          AutocompleteController<User>.generated(
            // A custom getResults that searches by name case sensitively.
            getResults: (TextEditingValue value) {
              return kOptionsUsers
                .where((User option) => option.name.contains(value.text))
                .toList();
            },
          );

      // Set field text based on the email and see that nothing is found.
      autocompleteController.textEditingController.text = 'example';
      expect(autocompleteController.results.value.length, 0);

      // Modify the field text. The results appear again and are filtered. A
      // lowercase "a" matches "Charlie" and not "Alice".
      autocompleteController.textEditingController.text = 'a';
      expect(autocompleteController.results.value.length, 1);
      expect(autocompleteController.results.value[0], kOptionsUsers[2]);

      // Modify the field text. An uppercase "A" matches "Alice" and not
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

  group('RawAutocomplete', () {
    testWidgets('can filter and select a list of string options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      late Iterable<String> lastOptions;
      late AutocompleteOnSelected<String> lastOnSelected;
      late FocusNode focusNode;
      late TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawAutocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return kOptions.where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                focusNode = fieldFocusNode;
                textEditingController = fieldTextEditingController;
                return TextField(
                  key: fieldKey,
                  focusNode: focusNode,
                  controller: textEditingController,
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                lastOptions = options;
                lastOnSelected = onSelected;
                return Container(key: optionsKey);
              },
            ),
          ),
        ),
      );

      // The field is always rendered, but the options are not unless needed.
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);

      // Focus the empty field. All the options are displayed.
      focusNode.requestFocus();
      await tester.pump();
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, kOptions.length);

      // Enter text. The options are filtered by the text.
      textEditingController.value = const TextEditingValue(
        text: 'ele',
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions.elementAt(0), 'chameleon');
      expect(lastOptions.elementAt(1), 'elephant');

      // Select a option. The options hide and the field updates to show the
      // selection.
      final String selection = lastOptions.elementAt(1);
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
      expect(lastOptions.elementAt(0), 'chameleon');
      expect(lastOptions.elementAt(1), 'elephant');
      expect(lastOptions.elementAt(2), 'goose');
      expect(lastOptions.elementAt(3), 'lemur');
      expect(lastOptions.elementAt(4), 'mouse');
      expect(lastOptions.elementAt(5), 'northern white rhinocerous');
    });

    testWidgets('can filter and select a list of custom User options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      late Iterable<User> lastOptions;
      late AutocompleteOnSelected<User> lastOnSelected;
      late User lastUserSelected;
      late FocusNode focusNode;
      late TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawAutocomplete<User>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return kOptionsUsers.where((User option) {
                  return option.toString().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (User selected) {
                lastUserSelected = selected;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                focusNode = fieldFocusNode;
                textEditingController = fieldTextEditingController;
                return TextField(
                  key: fieldKey,
                  focusNode: focusNode,
                  controller: fieldTextEditingController,
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, Iterable<User> options) {
                lastOptions = options;
                lastOnSelected = onSelected;
                return Container(key: optionsKey);
              },
            ),
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);

      // Enter text. The options are filtered by the text.
      focusNode.requestFocus();
      textEditingController.value = const TextEditingValue(
        text: 'example',
        selection: TextSelection(baseOffset: 7, extentOffset: 7),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions.elementAt(0), kOptionsUsers[0]);
      expect(lastOptions.elementAt(1), kOptionsUsers[1]);

      // Select a option. The options hide and onSelected is called.
      final User selection = lastOptions.elementAt(1);
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
      expect(lastOptions.elementAt(0), kOptionsUsers[1]);
    });

    testWidgets('can specify a custom display string for a list of custom User options', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      late Iterable<User> lastOptions;
      late AutocompleteOnSelected<User> lastOnSelected;
      late User lastUserSelected;
      late final AutocompleteOptionToString<User> displayStringForOption = (User option) => option.name;
      late FocusNode focusNode;
      late TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawAutocomplete<User>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return kOptionsUsers.where((User option) {
                  return option
                      .toString()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              displayStringForOption: displayStringForOption,
              onSelected: (User selected) {
                lastUserSelected = selected;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                textEditingController = fieldTextEditingController;
                focusNode = fieldFocusNode;
                return TextField(
                  key: fieldKey,
                  focusNode: focusNode,
                  controller: fieldTextEditingController,
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, Iterable<User> options) {
                lastOptions = options;
                lastOnSelected = onSelected;
                return Container(key: optionsKey);
              },
            ),
          ),
        ),
      );

      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);

      // Enter text. The options are filtered by the text.
      focusNode.requestFocus();
      textEditingController.value = const TextEditingValue(
        text: 'example',
        selection: TextSelection(baseOffset: 7, extentOffset: 7),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions.elementAt(0), kOptionsUsers[0]);
      expect(lastOptions.elementAt(1), kOptionsUsers[1]);

      // Select a option. The options hide and onSelected is called. The field
      // has its text set to the selection's display string.
      final User selection = lastOptions.elementAt(1);
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
      expect(lastOptions.elementAt(0), kOptionsUsers[1]);
    });

    testWidgets('onFieldSubmitted selects the first option', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      late Iterable<String> lastOptions;
      late VoidCallback lastOnFieldSubmitted;
      late FocusNode focusNode;
      late TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawAutocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return kOptions.where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                textEditingController = fieldTextEditingController;
                focusNode = fieldFocusNode;
                lastOnFieldSubmitted = onFieldSubmitted;
                return TextField(
                  key: fieldKey,
                  focusNode: focusNode,
                  controller: fieldTextEditingController,
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                lastOptions = options;
                return Container(key: optionsKey);
              },
            ),
          ),
        ),
      );

      // Enter text. The options are filtered by the text.
      focusNode.requestFocus();
      textEditingController.value = const TextEditingValue(
        text: 'ele',
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions.elementAt(0), 'chameleon');
      expect(lastOptions.elementAt(1), 'elephant');

      // Select the current string, as if the field was submitted. The options
      // hide and the field updates to show the selection.
      lastOnFieldSubmitted();
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);
      expect(textEditingController.text, lastOptions.elementAt(0));
    });

    testWidgets('options follow field when it moves', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      late StateSetter setState;
      Alignment alignment = Alignment.center;
      late FocusNode focusNode;
      late TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return Align(
                  alignment: alignment,
                  child: RawAutocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return kOptions.where((String option) {
                        return option.contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                      focusNode = fieldFocusNode;
                      textEditingController = fieldTextEditingController;
                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: focusNode,
                        key: fieldKey,
                      );
                    },
                    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
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
      focusNode.requestFocus();
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

    testWidgets('can prevent options from showing by returning an empty iterable', (WidgetTester tester) async {
      final GlobalKey fieldKey = GlobalKey();
      final GlobalKey optionsKey = GlobalKey();
      late Iterable<String> lastOptions;
      late FocusNode focusNode;
      late TextEditingController textEditingController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawAutocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == null || textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return kOptions.where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                focusNode = fieldFocusNode;
                textEditingController = fieldTextEditingController;
                return TextField(
                  key: fieldKey,
                  focusNode: focusNode,
                  controller: fieldTextEditingController,
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                lastOptions = options;
                return Container(key: optionsKey);
              },
            ),
          ),
        ),
      );

      // The field is always rendered, but the options are not unless needed.
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsNothing);

      // Focus the empty field. The options are not displayed because
      // optionsBuilder returns nothing for an empty field query.
      focusNode.requestFocus();
      textEditingController.value = const TextEditingValue(
        text: '',
        selection: TextSelection(baseOffset: 0, extentOffset: 0),
      );
      await tester.pump();
      expect(find.byKey(optionsKey), findsNothing);

      // Enter text. Now the options appear, filtered by the text.
      textEditingController.value = const TextEditingValue(
        text: 'ele',
        selection: TextSelection(baseOffset: 3, extentOffset: 3),
      );
      await tester.pump();
      expect(find.byKey(fieldKey), findsOneWidget);
      expect(find.byKey(optionsKey), findsOneWidget);
      expect(lastOptions.length, 2);
      expect(lastOptions.elementAt(0), 'chameleon');
      expect(lastOptions.elementAt(1), 'elephant');
    });
  });
}
