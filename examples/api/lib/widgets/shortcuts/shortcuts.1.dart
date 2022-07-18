// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Shortcuts

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          child: MyStatefulWidget(),
        ),
      ),
    );
  }
}

class Model with ChangeNotifier {
  int count = 0;
  void incrementBy(int amount) {
    count += amount;
    notifyListeners();
  }

  void decrementBy(int amount) {
    count -= amount;
    notifyListeners();
  }
}

class IncrementIntent extends Intent {
  const IncrementIntent(this.amount);

  final int amount;
}

class DecrementIntent extends Intent {
  const DecrementIntent(this.amount);

  final int amount;
}

class IncrementAction extends Action<IncrementIntent> {
  IncrementAction(this.model);

  final Model model;

  @override
  void invoke(covariant IncrementIntent intent) {
    model.incrementBy(intent.amount);
  }
}

class DecrementAction extends Action<DecrementIntent> {
  DecrementAction(this.model);

  final Model model;

  @override
  void invoke(covariant DecrementIntent intent) {
    model.decrementBy(intent.amount);
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  Model model = Model();

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const IncrementIntent(2),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const DecrementIntent(2),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          IncrementIntent: IncrementAction(model),
          DecrementIntent: DecrementAction(model),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: <Widget>[
              const Text('Add to the counter by pressing the up arrow key'),
              const Text(
                  'Subtract from the counter by pressing the down arrow key'),
              AnimatedBuilder(
                animation: model,
                builder: (BuildContext context, Widget? child) {
                  return Text('count: ${model.count}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
