// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateful_widget_scaffold_center.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for Shortcuts
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This slightly more complicated, but more flexible, example creates a custom
// [Action] subclass to increment and decrement within a widget (a [Column])
// that has keyboard focus. When the user presses the up and down arrow keys,
// the counter will increment and decrement a data model using the custom
// actions.
//
// One thing that this demonstrates is passing arguments to the [Intent] to be
// carried to the [Action]. This shows how actions can get data either from
// their own construction (like the `model` in this example), or from the
// intent passed to them when invoked (like the increment `amount` in this
// example).

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

import 'package:flutter/material.dart';
//****************************************************************************
//* ▼▼▼▼▼▼▼▼ code-imports ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

import 'package:flutter/services.dart';

//* ▲▲▲▲▲▲▲▲ code-imports ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//****************************************************************************

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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

//*****************************************************************************
//* ▼▼▼▼▼▼▼▼ code-preamble ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

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

//* ▲▲▲▲▲▲▲▲ code-preamble ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//*****************************************************************************

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

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

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
