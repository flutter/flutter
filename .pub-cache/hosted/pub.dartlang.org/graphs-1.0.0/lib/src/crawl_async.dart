// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

final _empty = Future<Null>.value(null);

/// Finds and returns every node in a graph who's nodes and edges are
/// asynchronously resolved.
///
/// Cycles are allowed. If this is an undirected graph the [edges] function
/// may be symmetric. In this case the [roots] may be any node in each connected
/// graph.
///
/// [V] is the type of values in the graph nodes. [K] must be a type suitable
/// for using as a Map or Set key. [edges] should return the next reachable
/// nodes.
///
/// There are no ordering guarantees. This is useful for ensuring some work is
/// performed at every node in an asynchronous graph, but does not give
/// guarantees that the work is done in topological order.
///
/// If [readNode] returns null for any key it will be ignored from the rest of
/// the graph. If missing nodes are important they should be tracked within the
/// [readNode] callback.
///
/// If either [readNode] or [edges] throws the error will be forwarded
/// through the result stream and no further nodes will be crawled, though some
/// work may have already been started.
///
/// Crawling is eager, so calls to [edges] may overlap with other calls that
/// have not completed. If the [edges] callback needs to be limited or throttled
/// that must be done by wrapping it before calling [crawlAsync].
Stream<V> crawlAsync<K extends Object, V>(
    Iterable<K> roots,
    FutureOr<V> Function(K) readNode,
    FutureOr<Iterable<K>> Function(K, V) edges) {
  final crawl = _CrawlAsync(roots, readNode, edges)..run();
  return crawl.result.stream;
}

class _CrawlAsync<K, V> {
  final result = StreamController<V>();

  final FutureOr<V> Function(K) readNode;
  final FutureOr<Iterable<K>> Function(K, V) edges;
  final Iterable<K> roots;

  final _seen = HashSet<K>();

  _CrawlAsync(this.roots, this.readNode, this.edges);

  /// Add all nodes in the graph to [result] and return a Future which fires
  /// after all nodes have been seen.
  Future<Null> run() async {
    try {
      await Future.wait(roots.map(_visit), eagerError: true);
      await result.close();
    } catch (e, st) {
      result.addError(e, st);
      await result.close();
    }
  }

  /// Resolve the node at [key] and output it, then start crawling all of it's
  /// edges.
  Future<Null> _crawlFrom(K key) async {
    var value = await readNode(key);
    if (value == null) return;
    if (result.isClosed) return;
    result.add(value);
    var next = await edges(key, value);
    await Future.wait(next.map(_visit), eagerError: true);
  }

  /// Synchronously record that [key] is being handled then start work on the
  /// node for [key].
  ///
  /// The returned Future will complete only after the work for [key] and all
  /// transitively reachable nodes has either been finished, or will be finished
  /// by some other Future in [_seen].
  Future<Null> _visit(K key) {
    if (_seen.contains(key)) return _empty;
    _seen.add(key);
    return _crawlFrom(key);
  }
}
