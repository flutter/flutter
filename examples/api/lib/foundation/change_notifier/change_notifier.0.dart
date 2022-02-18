// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ChangeNotifier with an AnimatedBuilder

import 'package:flutter/material.dart';

void main() {
  runApp(const CounterApp());
}

/// This class holds the counter value and the text color.
class Counter extends ChangeNotifier {
  int _counter;
  Color _textColor;

  /// Creates a [Counter] class and, by default, sets [value] to `0` and
  /// [textColor] to [Colors.black].
  Counter({
    int value = 0,
    Color textColor = Colors.black,
  }) : _counter = value, _textColor = textColor;

  /// The counter value.
  int get value => _counter;
  set value(int value) {
    if (_counter != value) {
      _counter = value;
      notifyListeners();
    }
  }

  /// The text color.
  Color get textColor => _textColor;
  set textColor(Color colorValue) {
    if (_textColor != colorValue) {
      _textColor = colorValue;
      notifyListeners();
    }
  }
}

/// An [InheritedWidget] that exposes a [Counter] class to the subtree.
class CounterWidget extends InheritedWidget {
  /// Requires a [Counter] and a [child].
  const CounterWidget({
    Key? key,
    required this.counter,
    required Widget child,
  }) : super(key: key, child: child);

  /// The [Counter] class holding the state of the counter app.
  final Counter counter;

  /// Returns the closest [CounterWidget] up in the tree.
  static CounterWidget of(BuildContext context) {
    final CounterWidget? result = context.dependOnInheritedWidgetOfExactType<CounterWidget>();
    assert(result != null, 'No CounterWidget found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(CounterWidget oldWidget) {
    return counter.value != oldWidget.counter.value ||
        counter.textColor != oldWidget.counter.textColor;
  }
}

/// The counter app page.
class CounterApp extends StatelessWidget {
  /// Creates an instance of the [CounterApp] widget.
  const CounterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CounterWidget(
        counter: Counter(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ChangeNotifier demo'),
          ),
          body: const CounterBody(),
        ),
      ),
    );
  }
}

/// The actual body of the counter app, containing a button to change the
/// counter value and another one to swap colors.
class CounterBody extends StatelessWidget {
  /// Creates an instance of the [CounterBody] widget.
  const CounterBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Counter counter = CounterWidget.of(context).counter;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The counter
          AnimatedBuilder(
            animation: counter,
            builder: (context, _) {
              return Text(
                '${counter.value}',
                style: TextStyle(
                  fontSize: 18,
                  color: counter.textColor,
                ),
              );
            },
          ),

          // Some spacing
          const SizedBox(
            height: 30,
          ),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () => counter.value++,
                child: const Text('Increase'),
              ),
              AnimatedBuilder(
                animation: counter,
                builder: (context, _) {
                 if (counter.textColor == Colors.black) {
                   return TextButton(
                     onPressed: () => counter.textColor = Colors.green,
                     child: const Text('Green text color'),
                   );
                 } else {
                   return TextButton(
                     onPressed: () => counter.textColor = Colors.black,
                     child: const Text('Black text color'),
                   );
                 }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
