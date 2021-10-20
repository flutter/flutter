// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Radio.toggleable

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const MyStatefulWidget({Key? key}) : super(key: key);

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
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Radio<int>(
                  value: index,
                  groupValue: groupValue,
                  // TRY THIS: Try setting the toggleable value to false and
                  // see how that changes the behavior of the widget.
                  toggleable: true,
                  onChanged: (int? value) {
                    setState(() {
                      groupValue = value;
                    });
                  }),
              Text(selections[index]),
            ],
          );
        },
        itemCount: selections.length,
      ),
    );
  }
}
