// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Expansible].

void main() => runApp(const ExpansibleApp());

/// An application that shows an example of how to use [Expansible].
class ExpansibleApp extends StatelessWidget {
  const ExpansibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Expansible Widget Example')),
        body: const Center(child: ExpansibleWidgetExample()),
      ),
    );
  }
}

class ExpansibleWidgetExample extends StatefulWidget {
  const ExpansibleWidgetExample({super.key});

  @override
  State<ExpansibleWidgetExample> createState() =>
      _ExpansibleWidgetExampleState();
}

class _ExpansibleWidgetExampleState extends State<ExpansibleWidgetExample> {
  final _controller = ExpansibleController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Expansible(
        controller: _controller,
        headerBuilder: (context, animation) => ListTile(
          title: const Text('Tap to Expand'),
          onTap: () {
            if (_controller.isExpanded) {
              _controller.collapse();
            } else {
              _controller.expand();
            }
          },
          trailing: RotationTransition(
            turns: Tween<double>(begin: 0.0, end: 0.5).animate(animation),
            child: const Icon(Icons.arrow_drop_down),
          ),
        ),
        bodyBuilder: (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: const Text('Hidden content revealed!'),
        ),
        expansibleBuilder: (context, header, body, animation) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, body],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
