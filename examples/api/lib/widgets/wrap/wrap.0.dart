// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [Wrap] with [Wrapped] children.

void main() => runApp(const WrapExampleApp());

class WrapExampleApp extends StatelessWidget {
  const WrapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WrapExample(),
    );
  }
}

class WrapExample extends StatefulWidget {
  const WrapExample({super.key});

  @override
  State<WrapExample> createState() => _WrapExampleState();
}

class _WrapExampleState extends State<WrapExample> {
  List<String> items = <String>['Item 0', 'Item 1'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wrap Example')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          runSpacing: 8,
          spacing: 8,
          children: <Widget>[
            for (int i = 0; i < items.length; i++)
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(items[i]),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          items.removeAt(i);
                        });
                      },
                      icon: const Icon(Icons.delete),
                    )
                  ],),
              ),
            Wrapped(
              // If the child fits in the current run,
              // its max width is set to the remaining space.
              // Otherwise it may be as wide as the Wrap
              fit: WrapFit.runLoose,
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'some text',
                  counterText: 'press ENTER to add'
                ),
                onSubmitted: (String value) {
                  setState(() {
                    items.add(value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
