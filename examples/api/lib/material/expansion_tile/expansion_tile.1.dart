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
        ExpansionTile.single(
            title: const Text(
                'Expansion tile with fixed height Scrollable content'),
            child: SizedBox(
              height: 200,
              child: Column(
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
            )),
        Flexible(
          child: ExpansionTile.single(
            title: const Text('Nested ExpansionTile'),
            subtitle: const Text('Takes up the available space'),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ExpansionTile.single(
                    title:
                        const Text('Expansion tile takes up the parent space'),
                    child: ListView(
                      children: [
                        for (int i = 0; i < 30; ++i)
                          ListTile(title: Text('Tile $i')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
