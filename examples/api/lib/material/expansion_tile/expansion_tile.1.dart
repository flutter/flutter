// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [ExpansionTile].
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
          Flexible(
          child: ExpansionTile(
            title: const Text('Expansion tile with Scrollable content'),
            children: [
              Flexible(
                child: ListView(
                  children: [
                    for (int i = 0; i < 30; ++i)
                      ListTile(title: Text('Tile $i')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ExpansionTile(
            title: const Text('Nested ExpansionTile'),
            subtitle: const Text('Trailing expansion arrow icon'),
            children: <Widget>[
              Flexible(
                child: ExpansionTile(
                  title: const Text('Expansion tile'),
                  children: [
                    Flexible(
                      child: ListView(
                        children: [
                          for (int i = 0; i < 30; ++i)
                            ListTile(title: Text('Tile $i')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const ExpansionTile(
          title: Text('ExpansionTile'),
          subtitle: Text('Leading expansion arrow icon'),
          controlAffinity: ListTileControlAffinity.leading,
          children: <Widget>[
            ListTile(title: Text('This is tile number 3')),
          ],
        ),
      ],
    );
  }
}
