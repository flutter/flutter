// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
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
    String displayStringForOption(User option) => option.name;
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

    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsNothing);

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

  testWidgets('can create a field outside of fieldViewBuilder', (WidgetTester tester) async {
    final GlobalKey fieldKey = GlobalKey();
    final GlobalKey optionsKey = GlobalKey();
    final GlobalKey autocompleteKey = GlobalKey();
    late Iterable<String> lastOptions;
    final FocusNode focusNode = FocusNode();
    final TextEditingController textEditingController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            // This is where the real field is being built.
            title: TextFormField(
              key: fieldKey,
              controller: textEditingController,
              focusNode: focusNode,
              onFieldSubmitted: (String value) {
                RawAutocomplete.onFieldSubmitted(autocompleteKey);
              },
            ),
          ),
          body: RawAutocomplete<String>(
            key: autocompleteKey,
            focusNode: focusNode,
            textEditingController: textEditingController,
            optionsBuilder: (TextEditingValue textEditingValue) {
              return kOptions.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              });
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
              lastOptions = options;
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
      text: 'ele',
      selection: TextSelection(baseOffset: 3, extentOffset: 3),
    );
    await tester.pump();
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsOneWidget);
    expect(lastOptions.length, 2);
    expect(lastOptions.elementAt(0), 'chameleon');
    expect(lastOptions.elementAt(1), 'elephant');

    // Submit the field. The options hide and the field updates to show the
    // selection.
    await tester.showKeyboard(find.byType(TextFormField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsNothing);
    expect(textEditingController.text, lastOptions.elementAt(0));
  });
}
