// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Provides an iterable that efficiently returns all the elements
/// rooted at the given element. See [CachingIterable] for details.
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
