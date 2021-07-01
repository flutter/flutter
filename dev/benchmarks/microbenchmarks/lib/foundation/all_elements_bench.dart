// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart' show collectAllElementsFrom;

import '../common.dart';

const int _kNumIters = 10000;

Future<void> main() async {
  assert(false, "Don't run benchmarks in debug mode! Use 'flutter run --release'.");
  runApp(MaterialApp(
    home: Scaffold(
      body: GridView.count(
        crossAxisCount: 5,
        children: List<Widget>.generate(25, (int index) {
          return Center(
            child: Scaffold(
              appBar: AppBar(
                title: Text('App $index'),
                actions: const <Widget>[
                  Icon(Icons.help),
                  Icon(Icons.add),
                  Icon(Icons.ac_unit),
                ],
              ),
              body: Column(
                children: const <Widget>[
                  Text('Item 1'),
                  Text('Item 2'),
                  Text('Item 3'),
                  Text('Item 4'),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  ));

  // Wait for frame rendering to stabilize.
  for (int i = 0; i < 5; i++) {
    await SchedulerBinding.instance?.endOfFrame;
  }

  final Stopwatch watch = Stopwatch();

  print('flutter_test allElements benchmark... (${WidgetsBinding.instance?.renderViewElement})');
  // Make sure we get enough elements to process for consistent benchmark runs
  int elementCount = collectAllElementsFrom(WidgetsBinding.instance!.renderViewElement!, skipOffstage: false).length;
  while (elementCount < 2458) {
    await Future<void>.delayed(Duration.zero);
    elementCount = collectAllElementsFrom(WidgetsBinding.instance!.renderViewElement!, skipOffstage: false).length;
  }
  print('element count: $elementCount');

  watch.start();
  for (int i = 0; i < _kNumIters; i += 1) {
    final List<Element> allElements = collectAllElementsFrom(
      WidgetsBinding.instance!.renderViewElement!,
      skipOffstage: false,
    ).toList();
    allElements.clear();
  }
  watch.stop();

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description: 'All elements iterate',
    value: watch.elapsedMicroseconds / _kNumIters,
    unit: 'µs per iteration',
    name: 'all_elements_iteration',
  );
  printer.printToStdout();
}
