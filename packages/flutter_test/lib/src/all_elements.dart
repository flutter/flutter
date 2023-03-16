// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
/// [Element.visitChildren] does not guarantee order, but does guarantee stable
/// order. This iterator also guarantees stable order, and iterates in a left
/// to right order:
///
///       1
///     /   \
///    2     3
///   / \   / \
///  4   5 6   7
///
/// Will iterate in order 2, 4, 5, 3, 6, 7.
///
/// Performance is important here because this method is on the critical path
/// for flutter_driver and package:integration_test performance tests.
/// Performance is measured in the all_elements_bench microbenchmark.
/// Any changes to this implementation should check the before and after numbers
/// on that benchmark to avoid regressions in general performance test overhead.
///
/// If we could use RTL order, we could save on performance, but numerous tests
/// have been written (and developers clearly expect) that LTR order will be
/// respected.
class _DepthFirstChildIterator implements Iterator<Element> {
  _DepthFirstChildIterator(Element rootElement, this.skipOffstage) {
    _fillChildren(rootElement);
  }

  final bool skipOffstage;

  late Element _current;

  final List<Element> _stack = <Element>[];

  @override
  Element get current => _current;

  @override
  bool moveNext() {
    if (_stack.isEmpty) {
      return false;
    }

    _current = _stack.removeLast();
    _fillChildren(_current);

    return true;
  }

  void _fillChildren(Element element) {
    assert(element != null);
    // If we did not have to follow LTR order and could instead use RTL,
    // we could avoid reversing this and the operation would be measurably
    // faster. Unfortunately, a lot of tests depend on LTR order.
    final List<Element> reversed = <Element>[];
    if (skipOffstage) {
      element.debugVisitOnstageChildren(reversed.add);
    } else {
      element.visitChildren(reversed.add);
    }
    // This is faster than _stack.addAll(reversed.reversed), presumably since
    // we don't actually care about maintaining an iteration pointer.
    while (reversed.isNotEmpty) {
      _stack.add(reversed.removeLast());
    }
  }
}
