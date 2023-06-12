// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show Random;

import 'package:graphs/graphs.dart';
import 'package:test/test.dart';

import 'utils/utils.dart';

void main() {
  const graph = <String, List<String>>{
    '1': ['2', '5'],
    '2': ['3'],
    '3': ['4', '5'],
    '4': ['1'],
    '5': ['8'],
    '6': ['7'],
  };

  List<String> readEdges(String key) => graph[key] ?? [];

  List<X> getXValues(X key) =>
      graph[key.value]?.map((v) => X(v)).toList() ?? [];

  void _singlePathTest(String from, String to, List<String>? expected) {
    test('$from -> $to should be $expected (mapped)', () {
      expect(
          shortestPath<X>(X(from), X(to), getXValues,
                  equals: xEquals, hashCode: xHashCode)
              ?.map((x) => x.value),
          expected);
    });

    test('$from -> $to should be $expected', () {
      expect(shortestPath(from, to, readEdges), expected);
    });
  }

  void _pathsTest(
      String from, Map<String, List<String>> expected, List<String> nullPaths) {
    test('paths from $from (mapped)', () {
      final result = shortestPaths<X>(X(from), getXValues,
              equals: xEquals, hashCode: xHashCode)
          .map((k, v) => MapEntry(k.value, v.map((x) => x.value).toList()));
      expect(result, expected);
    });

    test('paths from $from', () {
      final result = shortestPaths(from, readEdges);
      expect(result, expected);
    });

    for (var entry in expected.entries) {
      _singlePathTest(from, entry.key, entry.value);
    }

    for (var entry in nullPaths) {
      _singlePathTest(from, entry, null);
    }
  }

  _pathsTest('1', {
    '5': ['5'],
    '3': ['2', '3'],
    '8': ['5', '8'],
    '1': [],
    '2': ['2'],
    '4': ['2', '3', '4'],
  }, [
    '6',
    '7',
  ]);

  _pathsTest('6', {
    '7': ['7'],
    '6': [],
  }, [
    '1',
  ]);
  _pathsTest('7', {'7': []}, ['1', '6']);

  _pathsTest('42', {'42': []}, ['1', '6']);

  test('integration test', () {
    // Be deterministic in the generated graph. This test may have to be updated
    // if the behavior of `Random` changes for the provided seed.
    final _rnd = Random(1);
    final size = 1000;
    final graph = HashMap<int, List<int>>();

    Iterable<int>? resultForGraph() =>
        shortestPath(0, size - 1, (e) => graph[e] ?? const []);

    void addRandomEdge() {
      final toList = graph.putIfAbsent(_rnd.nextInt(size), () => <int>[]);

      final toValue = _rnd.nextInt(size);
      if (!toList.contains(toValue)) {
        toList.add(toValue);
      }
    }

    Iterable<int>? result;

    // Add edges until there is a shortest path between `0` and `size - 1`
    do {
      addRandomEdge();
      result = resultForGraph();
    } while (result == null);

    expect(result, [313, 547, 91, 481, 74, 64, 439, 388, 660, 275, 999]);

    var count = 0;
    // Add edges until the shortest path between `0` and `size - 1` is 2 items
    // Adding edges should never increase the length of the shortest path.
    // Adding enough edges should reduce the length of the shortest path.
    do {
      expect(++count, lessThan(size * 5), reason: 'This loop should finish.');
      addRandomEdge();
      final previousResultLength = result!.length;
      result = resultForGraph();
      expect(result, hasLength(lessThanOrEqualTo(previousResultLength)));
    } while (result!.length > 2);

    expect(result, [275, 999]);

    count = 0;
    // Remove edges until there is no shortest path.
    // Removing edges should never reduce the length of the shortest path.
    // Removing enough edges should increase the length of the shortest path and
    // eventually eliminate any path.
    do {
      expect(++count, lessThan(size * 5), reason: 'This loop should finish.');
      final randomKey = graph.keys.elementAt(_rnd.nextInt(graph.length));
      final list = graph[randomKey]!;
      expect(list, isNotEmpty);
      list.removeAt(_rnd.nextInt(list.length));
      if (list.isEmpty) {
        graph.remove(randomKey);
      }
      final previousResultLength = result!.length;
      result = resultForGraph();
      if (result != null) {
        expect(result, hasLength(greaterThanOrEqualTo(previousResultLength)));
      }
    } while (result != null);
  });
}
