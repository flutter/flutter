// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [RawAutocomplete.focusNode].

void main() => runApp(const AutocompleteExampleApp());

class AutocompleteExampleApp extends StatelessWidget {
  const AutocompleteExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return const MaterialApp(
      home: RawAutocompleteSplit(),
    );
  }
}

const List<String> _options = <String>[
  'aardvark',
  'bobcat',
  'chameleon',
];

class RawAutocompleteSplit extends StatefulWidget {
  const RawAutocompleteSplit({super.key});

  @override
  RawAutocompleteSplitState createState() => RawAutocompleteSplitState();
}

class RawAutocompleteSplitState extends State<RawAutocompleteSplit> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _autocompleteKey = GlobalKey();

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This is where the real field is being built.
        title: TextFormField(
          controller: _textEditingController,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: 'Split RawAutocomplete App',
          ),
          onFieldSubmitted: (final String value) {
            RawAutocomplete.onFieldSubmitted<String>(_autocompleteKey);
          },
        ),
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: RawAutocomplete<String>(
          key: _autocompleteKey,
          focusNode: _focusNode,
          textEditingController: _textEditingController,
          optionsBuilder: (final TextEditingValue textEditingValue) {
            return _options.where((final String option) {
              return option.contains(textEditingValue.text.toLowerCase());
            }).toList();
          },
          optionsViewBuilder: (
            final BuildContext context,
            final AutocompleteOnSelected<String> onSelected,
            final Iterable<String> options,
          ) {
            return Material(
              elevation: 4.0,
              child: ListView(
                children: options
                    .map((final String option) => GestureDetector(
                          onTap: () {
                            onSelected(option);
                          },
                          child: ListTile(
                            title: Text(option),
                          ),
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
