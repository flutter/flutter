// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show Random;

import 'package:graphs/graphs.dart';

void main() {
  final _rnd = Random(1);
  final size = 1000;
  final graph = HashMap<int, List<int>>();

  for (var i = 0; i < size * 5; i++) {
    final toList = graph.putIfAbsent(_rnd.nextInt(size), () => <int>[]);

    final toValue = _rnd.nextInt(size);
    if (!toList.contains(toValue)) {
      toList.add(toValue);
    }
  }

  int? minTicks;
  var maxIteration = 0;

  final testOutput =
      shortestPath(0, size - 1, (e) => graph[e] ?? <Never>[]).toString();
  print(testOutput);
  assert(testOutput == '(258, 252, 819, 999)', testOutput);

  final watch = Stopwatch();
  for (var i = 1;; i++) {
    watch
      ..reset()
      ..start();
    final result = shortestPath(0, size - 1, (e) => graph[e] ?? <Never>[])!;
    final length = result.length;
    final first = result.first;
    watch.stop();
    assert(length == 4, '$length');
    assert(first == 258, '$first');

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
