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
    late String lastSelection;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Autocomplete<String>(
            onSelected: (String selection) {
              lastSelection = selection;
            },
            optionsBuilder: (TextEditingValue textEditingValue) {
              return kOptions.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              });
            },
          ),
        ),
      ),
    );

    // The field is always rendered, but the options are not unless needed.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsNothing);

    // Focus the empty field. All the options are displayed.
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(find.byType(ListView), findsOneWidget);
    ListView list = find.byType(ListView).evaluate().first.widget as ListView;
    expect(list.semanticChildCount, kOptions.length);

    // Enter text. The options are filtered by the text.
    await tester.enterText(find.byType(TextFormField), 'ele');
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    list = find.byType(ListView).evaluate().first.widget as ListView;
    // 'chameleon' and 'elephant' are displayed.
    expect(list.semanticChildCount, 2);

    // Select a option. The options hide and the field updates to show the
    // selection.
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    final TextFormField field = find.byType(TextFormField).evaluate().first.widget as TextFormField;
    expect(field.controller!.text, 'chameleon');
    expect(lastSelection, 'chameleon');

    // Modify the field text. The options appear again and are filtered.
    await tester.enterText(find.byType(TextFormField), 'e');
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    list = find.byType(ListView).evaluate().first.widget as ListView;
    // 'chameleon', 'elephant', 'goose', 'lemur', 'mouse', and
    // 'northern white rhinocerous' are displayed.
    expect(list.semanticChildCount, 6);
  });

  testWidgets('can filter and select a list of custom User options', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Autocomplete<User>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              return kOptionsUsers.where((User option) {
                return option.toString().contains(textEditingValue.text.toLowerCase());
              });
            },
          ),
        ),
      ),
    );

    // The field is always rendered, but the options are not unless needed.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsNothing);

    // Focus the empty field. All the options are displayed.
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(find.byType(ListView), findsOneWidget);
    ListView list = find.byType(ListView).evaluate().first.widget as ListView;
    expect(list.semanticChildCount, kOptionsUsers.length);

    // Enter text. The options are filtered by the text.
    await tester.enterText(find.byType(TextFormField), 'example');
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    list = find.byType(ListView).evaluate().first.widget as ListView;
    // 'Alice' and 'Bob' are displayed because they have "example.com" emails.
    expect(list.semanticChildCount, 2);

    // Select a option. The options hide and the field updates to show the
    // selection.
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    final TextFormField field = find.byType(TextFormField).evaluate().first.widget as TextFormField;
    expect(field.controller!.text, 'Alice, alice@example.com');

    // Modify the field text. The options appear again and are filtered.
    await tester.enterText(find.byType(TextFormField), 'B');
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    list = find.byType(ListView).evaluate().first.widget as ListView;
    // 'Bob' is displayed.
    expect(list.semanticChildCount, 1);
  });

  testWidgets('displayStringForOption is displayed in the options', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Autocomplete<User>(
            displayStringForOption: (User option) {
              return option.name;
            },
            optionsBuilder: (TextEditingValue textEditingValue) {
              return kOptionsUsers.where((User option) {
                return option.toString().contains(textEditingValue.text.toLowerCase());
              });
            },
          ),
        ),
      ),
    );

    // The field is always rendered, but the options are not unless needed.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsNothing);

    // Focus the empty field. All the options are displayed, and the string that
    // is used comes from displayStringForOption.
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(find.byType(ListView), findsOneWidget);
    final ListView list = find.byType(ListView).evaluate().first.widget as ListView;
    expect(list.semanticChildCount, kOptionsUsers.length);
    for (int i = 0; i < kOptionsUsers.length; i++) {
      expect(find.text(kOptionsUsers[i].name), findsOneWidget);
    }

    // Select a option. The options hide and the field updates to show the
    // selection. The text in the field is given by displayStringForOption.
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    final TextFormField field = find.byType(TextFormField).evaluate().first.widget as TextFormField;
    expect(field.controller!.text, kOptionsUsers.first.name);
  });

  testWidgets('can build a custom field', (WidgetTester tester) async {
    final GlobalKey fieldKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              return kOptions.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              });
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              return Container(key: fieldKey);
            },
          ),
        ),
      ),
    );

    // The custom field is rendered and not the default TextFormField.
    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('can build custom options', (WidgetTester tester) async {
    final GlobalKey optionsKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              return kOptions.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              });
            },
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
              return Container(key: optionsKey);
            },
          ),
        ),
      ),
    );

    // The default field is rendered but not the options, yet.
    expect(find.byKey(optionsKey), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);

    // Focus the empty field. The custom options is displayed.
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(find.byKey(optionsKey), findsOneWidget);
  });
}
