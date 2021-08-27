// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/freeform.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for RawAutocomplete.focusNode
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This examples shows how to create an autocomplete widget with the text
// field in the AppBar and the results in the main body of the app.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

//*************************************************************************
//* ▼▼▼▼▼▼▼▼ code-main ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(const AutocompleteExampleApp());

class AutocompleteExampleApp extends StatelessWidget {
  const AutocompleteExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
  const RawAutocompleteSplit({Key? key}) : super(key: key);

  @override
  RawAutocompleteSplitState createState() => RawAutocompleteSplitState();
}

class RawAutocompleteSplitState extends State<RawAutocompleteSplit> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _autocompleteKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This is where the real field is being built.
        title: TextFormField(
          controller: _textEditingController,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: 'Split RawAutocomplete App',
          ),
          onFieldSubmitted: (String value) {
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
          optionsBuilder: (TextEditingValue textEditingValue) {
            return _options.where((String option) {
              return option.contains(textEditingValue.text.toLowerCase());
            }).toList();
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> options) {
            return Material(
              elevation: 4.0,
              child: ListView(
                children: options
                    .map((String option) => GestureDetector(
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

//* ▲▲▲▲▲▲▲▲ code-main ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//*************************************************************************
