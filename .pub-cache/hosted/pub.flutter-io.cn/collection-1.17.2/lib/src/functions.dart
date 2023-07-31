// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'utils.dart';

/// Creates a new map from [map] with new keys and values.
///
/// The return values of [key] are used as the keys and the return values of
/// [value] are used as the values for the new map.
@Deprecated('Use Map.map or a for loop in a Map literal.')
Map<K2, V2> mapMap<K1, V1, K2, V2>(Map<K1, V1> map,
    {K2 Function(K1, V1)? key, V2 Function(K1, V1)? value}) {
  var keyFn = key ?? (mapKey, _) => mapKey as K2;
  var valueFn = value ?? (_, mapValue) => mapValue as V2;

  var result = <K2, V2>{};
  map.forEach((mapKey, mapValue) {
    result[keyFn(mapKey, mapValue)] = valueFn(mapKey, mapValue);
  });
  return result;
}

/// Returns a new map with all key/value pairs in both [map1] and [map2].
///
/// If there are keys that occur in both maps, the [value] function is used to
/// select the value that goes into the resulting map based on the two original
/// values. If [value] is omitted, the value from [map2] is used.
Map<K, V> mergeMaps<K, V>(Map<K, V> map1, Map<K, V> map2,
    {V Function(V, V)? value}) {
  var result = Map<K, V>.of(map1);
  if (value == null) return result..addAll(map2);

  map2.forEach((key, mapValue) {
    result[key] =
        result.containsKey(key) ? value(result[key] as V, mapValue) : mapValue;
  });
  return result;
}

/// Associates the elements in [values] by the value returned by [key].
///
/// Returns a map from keys computed by [key] to the last value for which [key]
/// returns that key.
Map<T, S> lastBy<S, T>(Iterable<S> values, T Function(S) key) =>
    {for (var element in values) key(element): element};

/// Groups the elements in [values] by the value returned by [key].
///
/// Returns a map from keys computed by [key] to a list of all values for which
/// [key] returns that key. The values appear in the list in the same relative
/// order as in [values].
Map<T, List<S>> groupBy<S, T>(Iterable<S> values, T Function(S) key) {
  var map = <T, List<S>>{};
  for (var element in values) {
    (map[key(element)] ??= []).add(element);
  }
  return map;
}

/// Returns the element of [values] for which [orderBy] returns the minimum
/// value.
///
/// The values returned by [orderBy] are compared using the [compare] function.
/// If [compare] is omitted, values must implement [Comparable<T>] and they are
/// compared using their [Comparable.compareTo].
///
/// Returns `null` if [values] is empty.
S? minBy<S, T>(Iterable<S> values, T Function(S) orderBy,
    {int Function(T, T)? compare}) {
  compare ??= defaultCompare;

  S? minValue;
  T? minOrderBy;
  for (var element in values) {
    var elementOrderBy = orderBy(element);
    if (minOrderBy == null || compare(elementOrderBy, minOrderBy) < 0) {
      minValue = element;
      minOrderBy = elementOrderBy;
    }
  }
  return minValue;
}

/// Returns the element of [values] for which [orderBy] returns the maximum
/// value.
///
/// The values returned by [orderBy] are compared using the [compare] function.
/// If [compare] is omitted, values must implement [Comparable<T>] and they are
/// compared using their [Comparable.compareTo].
///
/// Returns `null` if [values] is empty.
S? maxBy<S, T>(Iterable<S> values, T Function(S) orderBy,
    {int Function(T, T)? compare}) {
  compare ??= defaultCompare;

  S? maxValue;
  T? maxOrderBy;
  for (var element in values) {
    var elementOrderBy = orderBy(element);
    if (maxOrderBy == null || compare(elementOrderBy, maxOrderBy) > 0) {
      maxValue = element;
      maxOrderBy = elementOrderBy;
    }
  }
  return maxValue;
}

/// Returns the [transitive closure][] of [graph].
///
/// [transitive closure]: https://en.wikipedia.org/wiki/Transitive_closure
///
/// Interprets [graph] as a directed graph with a vertex for each key and edges
/// from each key to the values that the key maps to.
///
/// Assumes that every vertex in the graph has a key to represent it, even if
/// that vertex has no outgoing edges. This isn't checked, but if it's not
/// satisfied, the function may crash or provide unexpected output. For example,
/// `{"a": ["b"]}` is not valid, but `{"a": ["b"], "b": []}` is.
Map<T, Set<T>> transitiveClosure<T>(Map<T, Iterable<T>> graph) {
  // This uses [Warshall's algorithm][], modified not to add a vertex from each
  // node to itself.
  //
  // [Warshall's algorithm]: https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm#Applications_and_generalizations.
  var result = <T, Set<T>>{};
  graph.forEach((vertex, edges) {
    result[vertex] = Set<T>.from(edges);
  });

  // Lists are faster to iterate than maps, so we create a list since we're
  // iterating repeatedly.
  var keys = graph.keys.toList();
  for (var vertex1 in keys) {
    for (var vertex2 in keys) {
      for (var vertex3 in keys) {
        if (result[vertex2]!.contains(vertex1) &&
            result[vertex1]!.contains(vertex3)) {
          result[vertex2]!.add(vertex3);
        }
      }
    }
  }

  return result;
}

/// Returns the [strongly connected components][] of [graph], in topological
/// order.
///
/// [strongly connected components]: https://en.wikipedia.org/wiki/Strongly_connected_component
///
/// Interprets [graph] as a directed graph with a vertex for each key and edges
/// from each key to the values that the key maps to.
///
/// Assumes that every vertex in the graph has a key to represent it, even if
/// that vertex has no outgoing edges. This isn't checked, but if it's not
/// satisfied, the function may crash or provide unexpected output. For example,
/// `{"a": ["b"]}` is not valid, but `{"a": ["b"], "b": []}` is.
List<Set<T>> stronglyConnectedComponents<T>(Map<T, Iterable<T>> graph) {
  // This uses [Tarjan's algorithm][].
  //
  // [Tarjan's algorithm]: https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
  var index = 0;
  var stack = <T?>[];
  var result = <Set<T>>[];

  // The order of these doesn't matter, so we use un-linked implementations to
  // avoid unnecessary overhead.
  var indices = HashMap<T, int>();
  var lowLinks = HashMap<T, int>();
  var onStack = HashSet<T>();

  void strongConnect(T vertex) {
    indices[vertex] = index;
    lowLinks[vertex] = index;
    index++;

    stack.add(vertex);
    onStack.add(vertex);

    for (var successor in graph[vertex]!) {
      if (!indices.containsKey(successor)) {
        strongConnect(successor);
        lowLinks[vertex] = math.min(lowLinks[vertex]!, lowLinks[successor]!);
      } else if (onStack.contains(successor)) {
        lowLinks[vertex] = math.min(lowLinks[vertex]!, lowLinks[successor]!);
      }
    }

    if (lowLinks[vertex] == indices[vertex]) {
      var component = <T>{};
      T? neighbor;
      do {
        neighbor = stack.removeLast();
        onStack.remove(neighbor);
        component.add(neighbor as T);
      } while (neighbor != vertex);
      result.add(component);
    }
  }

  for (var vertex in graph.keys) {
    if (!indices.containsKey(vertex)) strongConnect(vertex);
  }

  // Tarjan's algorithm produces a reverse-topological sort, so we reverse it to
  // get a normal topological sort.
  return result.reversed.toList();
}
