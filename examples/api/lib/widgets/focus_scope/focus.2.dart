// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Focus

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  int focusedChild = 0;
  List<Widget> children = <Widget>[];
  List<FocusNode> childFocusNodes = <FocusNode>[];

  @override
  void initState() {
    super.initState();
    // Add the first child.
    _addChild();
  }

  @override
  void dispose() {
    for (final FocusNode node in childFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _addChild() {
    // Calling requestFocus here creates a deferred request for focus, since the
    // node is not yet part of the focus tree.
    childFocusNodes
        .add(FocusNode(debugLabel: 'Child ${children.length}')..requestFocus());

    children.add(Padding(
      padding: const EdgeInsets.all(2.0),
      child: ActionChip(
        focusNode: childFocusNodes.last,
        label: Text('CHILD ${children.length}'),
        onPressed: () {},
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Wrap(
          children: children,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            focusedChild = children.length;
            _addChild();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
