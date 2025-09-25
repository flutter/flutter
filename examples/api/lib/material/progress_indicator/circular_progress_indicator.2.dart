// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [CircularProgressIndicator].

void main() => runApp(const ProgressIndicatorExampleApp());

class ProgressIndicatorExampleApp extends StatelessWidget {
  const ProgressIndicatorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4)),
      home: const ProgressIndicatorExample(),
    );
  }
}

class ProgressIndicatorExample extends StatefulWidget {
  const ProgressIndicatorExample({super.key});

  @override
  State<ProgressIndicatorExample> createState() => _ProgressIndicatorExampleState();
}

class _ProgressIndicatorExampleState extends State<ProgressIndicatorExample>
    with TickerProviderStateMixin {
  late AnimationController controller;
  int indicatorNum = 1;
  bool hasThemeController = true;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: CircularProgressIndicator.defaultAnimationDuration * 0.8,
    );
    controller.repeat();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Theme(
        data: ThemeData(
          progressIndicatorTheme: hasThemeController
              ? ProgressIndicatorThemeData(controller: controller)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            spacing: 8.0,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        indicatorNum += 1;
                      });
                    },
                    child: const Text('More indicators'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        indicatorNum -= 1;
                      });
                    },
                    child: const Text('Fewer indicators'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Theme controller? ${hasThemeController ? 'Yes' : 'No'}'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        hasThemeController = !hasThemeController;
                      });
                    },
                    child: const Text('Toggle'),
                  ),
                ],
              ),
              ManyProgressIndicators(indicatorNum: indicatorNum),
            ],
          ),
        ),
      ),
    );
  }
}

/// Display several [CircularProgressIndicator] in nested `Container`s.
class ManyProgressIndicators extends StatelessWidget {
  const ManyProgressIndicators({super.key, required this.indicatorNum});

  final int indicatorNum;

  Widget _nestIndicator({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(100, 240, 240, 0),
        border: Border.all(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[const CircularProgressIndicator(), child],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox();
    for (int i = 0; i < indicatorNum; i++) {
      child = _nestIndicator(child: child);
    }
    return child;
  }
}
