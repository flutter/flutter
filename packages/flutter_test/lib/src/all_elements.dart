// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
Iterable<Element> collectAllElementsFrom(Element rootElement) {
  return new CachingIterable<Element>(new _DepthFirstChildIterator(rootElement));
}

class _DepthFirstChildIterator implements Iterator<Element> {
  _DepthFirstChildIterator(Element rootElement)
      : _stack = _reverseChildrenOf(rootElement).toList();

  Element _current;

  final List<Element> _stack;

  @override
  Element get current => _current;

  @override
  bool moveNext() {
    if (_stack.isEmpty)
      return false;

    _current = _stack.removeLast();
    // Stack children in reverse order to traverse first branch first
    _stack.addAll(_reverseChildrenOf(_current));

    return true;
  }

  static Iterable<Element> _reverseChildrenOf(Element element) {
    final List<Element> children = <Element>[];
    element.visitChildren(children.add);
    return children.reversed;
  }
}
