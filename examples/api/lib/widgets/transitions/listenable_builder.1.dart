// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for a [ValueNotifier] with a [ListenableBuilder].

void main() {
  runApp(const ListenableBuilderExample());
}

class ListenableBuilderExample extends StatefulWidget {
  const ListenableBuilderExample({super.key});

  @override
  State<ListenableBuilderExample> createState() => _ListenableBuilderExampleState();
}

class _ListenableBuilderExampleState extends State<ListenableBuilderExample> {
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ListenableBuilder Example')),
        body: CounterBody(counterValueNotifier: _counter),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _counter.value++,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class CounterBody extends StatelessWidget {
  const CounterBody({super.key, required this.counterValueNotifier});

  final ValueNotifier<int> counterValueNotifier;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Current counter value:'),
          // Thanks to the ListenableBuilder, only the widget displaying the
          // current count is rebuilt when counterValueNotifier notifies its
          // listeners. The Text widget above and CounterBody itself aren't
          // rebuilt.
          ListenableBuilder(
            listenable: counterValueNotifier,
            builder: (BuildContext context, Widget? child) {
              return Text('${counterValueNotifier.value}');
            },
          ),
        ],
      ),
    );
  }
}
