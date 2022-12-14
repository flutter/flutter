// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for OrderedTraversalPolicy

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
        body: const Center(
          child: MyStatelessWidget(),
        ),
      ),
    );
  }
}

class DemoButton extends StatelessWidget {
  const DemoButton({
    super.key,
    required this.name,
    this.autofocus = false,
    required this.order,
  });

  final String name;
  final bool autofocus;
  final double order;

  void _handleOnPressed() {
    debugPrint('Button $name pressed.');
    debugDumpFocusTree();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: TextButton(
        autofocus: autofocus,
        onPressed: () => _handleOnPressed(),
        child: Text(name),
      ),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              DemoButton(name: 'Six', order: 6),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              DemoButton(name: 'Five', order: 5),
              DemoButton(name: 'Four', order: 4),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              DemoButton(name: 'Three', order: 3),
              DemoButton(name: 'Two', order: 2),
              DemoButton(name: 'One', order: 1, autofocus: true),
            ],
          ),
        ],
      ),
    );
  }
}
