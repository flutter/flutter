// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for RadioListTile.toggleable

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatefulWidget(),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  int? groupValue;
  static const List<String> selections = <String>[
    'Hercules Mulligan',
    'Eliza Hamilton',
    'Philip Schuyler',
    'Maria Reynolds',
    'Samuel Seabury',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return RadioListTile<int>(
            value: index,
            groupValue: groupValue,
            toggleable: true,
            title: Text(selections[index]),
            onChanged: (int? value) {
              setState(() {
                groupValue = value;
              });
            },
          );
        },
        itemCount: selections.length,
      ),
    );
  }
}
