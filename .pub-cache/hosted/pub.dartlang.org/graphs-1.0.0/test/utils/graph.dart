// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'utils.dart';

/// A representation of a Graph since none is specified in `lib/`.
class Graph {
  final Map<String, List<String>?> _graph;

  Graph(this._graph);

  List<String> edges(String node) => _graph[node] ?? <Never>[];

  Iterable<String> get allNodes => _graph.keys;
}

class BadGraph {
  final Map<X, List<X>?> _graph;

  BadGraph(Map<String, List<String>?> values)
      : _graph = LinkedHashMap(equals: xEquals, hashCode: xHashCode)
          ..addEntries(values.entries.map(
              (e) => MapEntry(X(e.key), e.value?.map((v) => X(v)).toList())));

  List<X> edges(X node) => _graph[node] ?? <Never>[];

  Iterable<X> get allNodes => _graph.keys;
}

/// A representation of a Graph where keys can asynchronously be resolved to
/// real values or to edges.
class AsyncGraph {
  final Map<String, List<String>?> graph;

  AsyncGraph(this.graph);

  Future<String?> readNode(String node) async =>
      graph.containsKey(node) ? node : null;

  Future<Iterable<String>> edges(String key, String? node) async =>
      graph[key] ?? <Never>[];
}
