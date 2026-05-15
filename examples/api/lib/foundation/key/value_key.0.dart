// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [ValueKey].

void main() {
  runApp(const KeyValueComparisonExample());
}

class KeyValueComparisonExample extends StatelessWidget {
  const KeyValueComparisonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const KeyValueComparisonPage(title: 'Key Comparison Demo'),
    );
  }
}

class KeyValueComparisonPage extends StatefulWidget {
  const KeyValueComparisonPage({super.key, required this.title});

  final String title;

  @override
  State<KeyValueComparisonPage> createState() => _KeyValueComparisonPageState();
}

class _KeyValueComparisonPageState extends State<KeyValueComparisonPage> {
  var _colors = <Color>[Colors.red, Colors.green, Colors.blue];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Reversing list: Keyed vs Keyless"),
            ),
            ..._colors.map(
              (Color color) => ColoredWidgetsList(
                // Adding the Key ensures the state stays in sync with the color
                key: ValueKey(color),
                color: color,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _colors = _colors.reversed.toList();
          });
        },
        tooltip: 'Reverse it',
        child: const Icon(Icons.flip),
      ),
    );
  }
}

class ColoredWidgetsList extends StatefulWidget {
  const ColoredWidgetsList({super.key, required this.color});

  final Color color;

  @override
  State<ColoredWidgetsList> createState() => ColoredWidgetsListState();
}

class ColoredWidgetsListState extends State<ColoredWidgetsList> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.all(8),
      color: widget.color,
      child: TextButton(
        onPressed: () {
          setState(() {
            _count++;
          });
        },
        child: Text(
          '$_count',
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
