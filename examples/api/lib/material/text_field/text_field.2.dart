// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for TextField

import 'package:flutter/material.dart';

void main() { runApp(const TextFieldExamplesApp()); }

class TextFieldExamplesApp extends StatelessWidget {
  const TextFieldExamplesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4), useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('TextField Examples')),
        body: Column(
          children: const <Widget>[
            Spacer(),
            FilledTextFieldExample(),
            OutlinedTextFieldExample(),
            Spacer(),
          ],
        ),
      ),
    );
  }
}

/// An example of the filled text field type.
class FilledTextFieldExample extends StatelessWidget {
  const FilledTextFieldExample({ super.key });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
        suffixIcon: Icon(Icons.clear),
        labelText: "Filled",
        hintText: "hint text",
        helperText: "supporting text",
        filled: true,
      )
    );
  }
}

/// An example of the outlined text field type.
class OutlinedTextFieldExample extends StatelessWidget {
  const OutlinedTextFieldExample({ super.key });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
        suffixIcon: Icon(Icons.clear),
        labelText: "Outlined",
        hintText: "hint text",
        helperText: "supporting text",
        border: OutlineInputBorder(),
      ),
    );
  }
}
