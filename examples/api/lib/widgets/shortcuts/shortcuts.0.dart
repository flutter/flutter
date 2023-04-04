// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter code sample for [Shortcuts].

void main() => runApp(const ShortcutsExampleApp());

class ShortcutsExampleApp extends StatelessWidget {
  const ShortcutsExampleApp({super.key});

  static const String _title = 'Shortcuts Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: ShortcutsExample(),
        ),
      ),
    );
  }
}

class IncrementIntent extends Intent {
  const IncrementIntent();
}

class DecrementIntent extends Intent {
  const DecrementIntent();
}

class ShortcutsExample extends StatefulWidget {
  const ShortcutsExample({super.key});

  @override
  State<ShortcutsExample> createState() => _ShortcutsExampleState();
}

class _ShortcutsExampleState extends State<ShortcutsExample> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): IncrementIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): DecrementIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          IncrementIntent: CallbackAction<IncrementIntent>(
            onInvoke: (IncrementIntent intent) => setState(() {
              count = count + 1;
            }),
          ),
          DecrementIntent: CallbackAction<DecrementIntent>(
            onInvoke: (DecrementIntent intent) => setState(() {
              count = count - 1;
            }),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: <Widget>[
              const Text('Add to the counter by pressing the up arrow key'),
              const Text(
                  'Subtract from the counter by pressing the down arrow key'),
              Text('count: $count'),
            ],
          ),
        ),
      ),
    );
  }
}
