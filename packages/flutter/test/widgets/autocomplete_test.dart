// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    'northern white rhinoceros',
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

    // Select an option. The options hide and the field updates to show the
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
    expect(lastOptions.elementAt(5), 'northern white rhinoceros');
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

    // Select an option. The options hide and onSelected is called.
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

    // Select an option. The options hide and onSelected is called. The field
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

  testWidgets('initialValue sets initial text field value', (WidgetTester tester) async {
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
            // Should initialize text field with 'lem'.
            initialValue: const TextEditingValue(text: 'lem'),
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
    // The text editing controller value starts off with initialized value.
    expect(textEditingController.text, 'lem');

    // Focus the empty field. All the options are displayed.
    focusNode.requestFocus();
    await tester.pump();
    expect(find.byKey(optionsKey), findsOneWidget);
    expect(lastOptions.elementAt(0), 'lemur');

    // Select an option. The options hide and the field updates to show the
    // selection.
    final String selection = lastOptions.elementAt(0);
    lastOnSelected(selection);
    await tester.pump();
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsNothing);
    expect(textEditingController.text, selection);
  });

  testWidgets('initialValue cannot be defined if TextEditingController is defined', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    final TextEditingController textEditingController = TextEditingController();

    expect(
      () {
        RawAutocomplete<String>(
          focusNode: focusNode,
          // Both [initialValue] and [textEditingController] cannot be
          // simultaneously defined.
          initialValue: const TextEditingValue(text: 'lemur'),
          textEditingController: textEditingController,
          optionsBuilder: (TextEditingValue textEditingValue) {
            return kOptions.where((String option) {
              return option.contains(textEditingValue.text.toLowerCase());
            });
          },
          optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
            return Container();
          },
          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
            return TextField(
              focusNode: focusNode,
              controller: textEditingController,
            );
          },
        );
      },
      throwsAssertionError,
    );
  });

  testWidgets('support asynchronous options builder', (WidgetTester tester) async {
    final GlobalKey fieldKey = GlobalKey();
    final GlobalKey optionsKey = GlobalKey();
    late FocusNode focusNode;
    late TextEditingController textEditingController;
    Iterable<String>? lastOptions;
    Duration? delay;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RawAutocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              final Iterable<String> options = kOptions.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              });
              if (delay == null) {
                return options;
              }
              return Future<Iterable<String>>.delayed(delay, () => options);
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
              return Container(key: optionsKey);
            },
          ),
        ),
      )
    );

    // Enter text to build the options with delay.
    focusNode.requestFocus();
    delay = const Duration(milliseconds: 500);
    await tester.enterText(find.byKey(fieldKey), 'go');
    await tester.pumpAndSettle();

    // The options have not yet been built.
    expect(find.byKey(optionsKey), findsNothing);
    expect(lastOptions, isNull);

    // Await asynchronous options builder.
    await tester.pumpAndSettle(delay);
    expect(find.byKey(optionsKey), findsOneWidget);
    expect(lastOptions, <String>['dingo', 'flamingo', 'goose']);

    // Enter text to rebuild the options without delay.
    delay = null;
    await tester.enterText(find.byKey(fieldKey), 'ngo');
    await tester.pump();
    expect(lastOptions, <String>['dingo', 'flamingo']);
  });

  testWidgets('can navigate options with the keyboard', (WidgetTester tester) async {
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
              return kOptions.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              });
            },
            fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
              focusNode = fieldFocusNode;
              textEditingController = fieldTextEditingController;
              return TextFormField(
                key: fieldKey,
                focusNode: focusNode,
                controller: textEditingController,
                onFieldSubmitted: (String value) {
                  onFieldSubmitted();
                },
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
    await tester.enterText(find.byKey(fieldKey), 'ele');
    await tester.pumpAndSettle();
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsOneWidget);
    expect(lastOptions.length, 2);
    expect(lastOptions.elementAt(0), 'chameleon');
    expect(lastOptions.elementAt(1), 'elephant');

    // Move the highlighted option to the second item 'elephant' and select it
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    // Can't use the key event for enter to submit to the text field using
    // the test framework, so this appears to be the equivalent.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsNothing);
    expect(textEditingController.text, 'elephant');

    // Modify the field text. The options appear again and are filtered.
    focusNode.requestFocus();
    textEditingController.clear();
    await tester.enterText(find.byKey(fieldKey), 'e');
    await tester.pump();
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsOneWidget);
    expect(lastOptions.length, 6);
    expect(lastOptions.elementAt(0), 'chameleon');
    expect(lastOptions.elementAt(1), 'elephant');
    expect(lastOptions.elementAt(2), 'goose');
    expect(lastOptions.elementAt(3), 'lemur');
    expect(lastOptions.elementAt(4), 'mouse');
    expect(lastOptions.elementAt(5), 'northern white rhinoceros');

    // The selection should wrap at the top and bottom. Move up to 'mouse'
    // and then back down to 'goose' and select it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsNothing);
    expect(textEditingController.text, 'goose');
  });

  testWidgets('optionsViewBuilders can use AutocompleteHighlightedOption to highlight selected option', (WidgetTester tester) async {
    final GlobalKey fieldKey = GlobalKey();
    final GlobalKey optionsKey = GlobalKey();
    late Iterable<String> lastOptions;
    late int lastHighlighted;
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
              return TextFormField(
                key: fieldKey,
                focusNode: focusNode,
                controller: textEditingController,
                onFieldSubmitted: (String value) {
                  onFieldSubmitted();
                },
              );
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
              lastOptions = options;
              lastHighlighted = AutocompleteHighlightedOption.of(context);
              return Container(key: optionsKey);
            },
          ),
        ),
      ),
    );

    // Enter text. The options are filtered by the text.
    focusNode.requestFocus();
    await tester.enterText(find.byKey(fieldKey), 'e');
    await tester.pump();
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(optionsKey), findsOneWidget);
    expect(lastOptions.length, 6);
    expect(lastOptions.elementAt(0), 'chameleon');
    expect(lastOptions.elementAt(1), 'elephant');
    expect(lastOptions.elementAt(2), 'goose');
    expect(lastOptions.elementAt(3), 'lemur');
    expect(lastOptions.elementAt(4), 'mouse');
    expect(lastOptions.elementAt(5), 'northern white rhinoceros');

    // Move the highlighted option down and check the highlighted index
    expect(lastHighlighted, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(lastHighlighted, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(lastHighlighted, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(lastHighlighted, 3);

    // And move it back up
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(lastHighlighted, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(lastHighlighted, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(lastHighlighted, 0);

    // Going back up should wrap around
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(lastHighlighted, 5);
  });

}
