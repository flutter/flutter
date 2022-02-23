// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ChangeNotifier with an AnimatedBuilder

import 'package:flutter/material.dart';

void main() {
  runApp(const CounterApp());
}

class AppState extends ChangeNotifier {
  AppState({
    int value = 0,
    Color textColor = Colors.black,
  }) : _counter = value, _textColor = textColor;

  int _counter;
  int get counter => _counter;
  set counter(int value) {
    if (_counter != value) {
      _counter = value;
      notifyListeners();
    }
  }

  Color _textColor;
  Color get textColor => _textColor;
  set textColor(Color colorValue) {
    if (_textColor != colorValue) {
      _textColor = colorValue;
      notifyListeners();
    }
  }
}

class CounterApp extends StatelessWidget {
  const CounterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ChangeNotifier demo'),
        ),
        body: const CounterBody(),
      ),
    );
  }
}

class CounterBody extends StatefulWidget {
  const CounterBody({Key? key}) : super(key: key);

  @override
  State<CounterBody> createState() => _CounterBodyState();
}

class _CounterBodyState extends State<CounterBody> {
  // This variable could have been exposed by an InheritedWidget and moved
  // outside of this widget for example.
  final AppState counterNotifier = AppState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: counterNotifier,
            builder: (BuildContext context, _) {
              return Text(
                '${counterNotifier.counter}',
                style: TextStyle(
                  fontSize: 18,
                  color: counterNotifier.textColor,
                ),
              );
            },
          ),

          const SizedBox(
            height: 30,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              TextButton(
                onPressed: () => counterNotifier.counter++,
                child: const Text('Increase'),
              ),
              AnimatedBuilder(
                animation: counterNotifier,
                builder: (BuildContext context, _) {
                 if (counterNotifier.textColor == Colors.black) {
                   return TextButton(
                     onPressed: () => counterNotifier.textColor = Colors.green,
                     child: const Text('Green text color'),
                   );
                 } else {
                   return TextButton(
                     onPressed: () => counterNotifier.textColor = Colors.black,
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
