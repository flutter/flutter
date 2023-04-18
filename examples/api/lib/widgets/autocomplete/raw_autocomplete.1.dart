// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [RawAutocomplete].

void main() => runApp(const AutocompleteExampleApp());

class AutocompleteExampleApp extends StatelessWidget {
  const AutocompleteExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('RawAutocomplete Custom Type'),
        ),
        body: const Center(
          child: AutocompleteCustomTypeExample(),
        ),
      ),
    );
  }
}

// An example of a type that someone might want to autocomplete a list of.
@immutable
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

  @override
  bool operator ==(final Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is User && other.name == name && other.email == email;
  }

  @override
  int get hashCode => Object.hash(email, name);
}

class AutocompleteCustomTypeExample extends StatelessWidget {
  const AutocompleteCustomTypeExample({super.key});

  static const List<User> _userOptions = <User>[
    User(name: 'Alice', email: 'alice@example.com'),
    User(name: 'Bob', email: 'bob@example.com'),
    User(name: 'Charlie', email: 'charlie123@gmail.com'),
  ];

  static String _displayStringForOption(final User option) => option.name;

  @override
  Widget build(final BuildContext context) {
    return RawAutocomplete<User>(
      optionsBuilder: (final TextEditingValue textEditingValue) {
        return _userOptions.where((final User option) {
          // Search based on User.toString, which includes both name and
          // email, even though the display string is just the name.
          return option.toString().contains(textEditingValue.text.toLowerCase());
        });
      },
      displayStringForOption: _displayStringForOption,
      fieldViewBuilder: (
        final BuildContext context,
        final TextEditingController textEditingController,
        final FocusNode focusNode,
        final VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          onFieldSubmitted: (final String value) {
            onFieldSubmitted();
          },
        );
      },
      optionsViewBuilder: (final BuildContext context, final AutocompleteOnSelected<User> onSelected, final Iterable<User> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200.0,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (final BuildContext context, final int index) {
                  final User option = options.elementAt(index);
                  return GestureDetector(
                    onTap: () {
                      onSelected(option);
                    },
                    child: ListTile(
                      title: Text(_displayStringForOption(option)),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
