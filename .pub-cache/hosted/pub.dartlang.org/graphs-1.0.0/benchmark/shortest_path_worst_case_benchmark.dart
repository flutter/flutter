// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:graphs/graphs.dart';

void main() {
  final size = 1000;
  final graph = HashMap<int, List<int>>();

  // We create a graph where every subsequent node has an edge to every other
  // node before it as well as the next node. This triggers worst case behavior
  // in many algorithms as it requires visiting all nodes and edges before
  // finding a solution, and there are a maximum number of edges.
  for (var i = 0; i < size; i++) {
    final toList = graph.putIfAbsent(i, () => <int>[]);
    for (var t = 0; t < i + 2 && i < size; t++) {
      if (i == t) continue;
      toList.add(t);
    }
  }

  int? minTicks;
  var maxIteration = 0;

  final testOutput =
      shortestPath(0, size - 1, (e) => graph[e] ?? <Never>[]).toString();
  print(testOutput);
  assert(testOutput == Iterable.generate(size - 1, (i) => i + 1).toString(),
      '$testOutput');

  final watch = Stopwatch();
  for (var i = 1;; i++) {
    watch
      ..reset()
      ..start();
    final result = shortestPath(0, size - 1, (e) => graph[e] ?? <Never>[])!;
    final length = result.length;
    final first = result.first;
    watch.stop();
    assert(length == 999, '$length');
    assert(first == 1, '$first');

    if (minTicks == null || watch.elapsedTicks < minTicks) {
      minTicks = watch.elapsedTicks;
      maxIteration = i;
    }

    if (maxIteration == i || (i - maxIteration) % 100000 == 0) {
      print('min ticks for one run: $minTicks\t'
          'after $maxIteration of $i iterations');
    }
  }
}
