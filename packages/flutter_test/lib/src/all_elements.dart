// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Provides an iterable that efficiently returns all the elements
/// rooted at the given element. See [CachingIterable] for details.
///
/// This method must be called again if the tree changes. You cannot
/// call this function once, then reuse the iterable after having
/// changed the state of the tree, because the iterable returned by
/// this function caches the results and only walks the tree once.
///
/// The same applies to any iterable obtained indirectly through this
/// one, for example the results of calling `where` on this iterable
/// are also cached.
Iterable<Element> collectAllElementsFrom(
  Element rootElement, {
  required bool skipOffstage,
}) {
  return CachingIterable<Element>(_DepthFirstChildIterator(rootElement, skipOffstage));
}

/// Provides a recursive, efficient, depth first search of an element tree.
///
/// [Element.visitChildren] does not guarnatee order, but does guarnatee stable
/// order. This iterator also guarantees stable order, but will iterate in a
/// right to left order, e.g.:
///
///       1
///     /   \
///    2     3
///   / \   / \
///  4   5 6   7
///
/// Will iterate in order 1, 3, 7, 6, 2, 5, 4. This avoids unnecessary
/// allocation or CPU time, and performance is important here because this
/// method is on the critical path for flutter_driver and
/// package:integration_test performance tests.
///
/// Performance of this is measured in the all_elements_bench microbenchmark.
class _DepthFirstChildIterator implements Iterator<Element> {
  _DepthFirstChildIterator(Element rootElement, this.skipOffstage)
    : _stack = ListQueue<Element>() {
    _fillChildren(rootElement);
  }

  final bool skipOffstage;

  late Element _current;

  final ListQueue<Element> _stack;

  @override
  Element get current => _current;

  @override
  bool moveNext() {
    if (_stack.isEmpty)
      return false;

    _current = _stack.removeFirst();
    _fillChildren(_current);

    return true;
  }

  void _fillChildren(Element element) {
    assert(element != null);
    if (skipOffstage) {
      element.debugVisitOnstageChildren(_stack.addFirst);
    } else {
      element.visitChildren(_stack.addFirst);
    }
  }
}
