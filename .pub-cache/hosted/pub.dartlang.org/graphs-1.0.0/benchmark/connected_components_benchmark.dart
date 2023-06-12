// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show Random;

import 'package:graphs/graphs.dart';

void main() {
  final _rnd = Random(0);
  final size = 2000;
  final graph = HashMap<int, List<int>>();

  for (var i = 0; i < size * 3; i++) {
    final toList = graph.putIfAbsent(_rnd.nextInt(size), () => <int>[]);

    final toValue = _rnd.nextInt(size);
    if (!toList.contains(toValue)) {
      toList.add(toValue);
    }
  }

  var maxCount = 0;
  var maxIteration = 0;

  final duration = const Duration(milliseconds: 100);

  for (var i = 1;; i++) {
    var count = 0;
    final watch = Stopwatch()..start();
    while (watch.elapsed < duration) {
      count++;
      final length =
          stronglyConnectedComponents(graph.keys, (e) => graph[e] ?? <Never>[])
              .length;
      assert(length == 244, '$length');
    }

    if (count > maxCount) {
      maxCount = count;
      maxIteration = i;
    }

    if (maxIteration == i || (i - maxIteration) % 20 == 0) {
      print('max iterations in ${duration.inMilliseconds}ms: $maxCount\t'
          'after $maxIteration of $i iterations');
    }
  }
}
