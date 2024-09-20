// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html_common;

/**
 * An indexable collection of a node's direct descendants in the document tree,
 * filtered so that only elements are in the collection.
 */
class FilteredElementList extends ListBase<Element> implements NodeListWrapper {
  final Node _node;
  final List<Node> _childNodes;

  /**
   * Creates a collection of the elements that descend from a node.
   *
   * Example usage:
   *
   *     var filteredElements = new FilteredElementList(query("#container"));
   *     // filteredElements is [a, b, c].
   */
  FilteredElementList(Node node)
      : _childNodes = node.nodes,
        _node = node;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  Iterable<Element> get _iterable =>
      _childNodes.where((n) => n is Element).map<Element>((n) => n as Element);
  List<Element> get _filtered =>
      new List<Element>.from(_iterable, growable: false);

  void forEach(void f(Element element)) {
    // This cannot use the iterator, because operations during iteration might
    // modify the collection, e.g. addAll might append a node to another parent.
    _filtered.forEach(f);
  }

  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  set length(int newLength) {
    final len = this.length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw new ArgumentError("Invalid list length");
    }

    removeRange(newLength, len);
  }

  void add(Element value) {
    _childNodes.add(value);
  }

  void addAll(Iterable<Element> iterable) {
    for (Element element in iterable) {
      add(element);
    }
  }

  bool contains(Object? needle) {
    if (needle is! Element) return false;
    Element element = needle;
    return element.parentNode == _node;
  }

  Iterable<Element> get reversed => _filtered.reversed;

  void sort([int compare(Element a, Element b)?]) {
    throw new UnsupportedError('Cannot sort filtered list');
  }

  void setRange(int start, int end, Iterable<Element> iterable,
      [int skipCount = 0]) {
    throw new UnsupportedError('Cannot setRange on filtered list');
  }

  void fillRange(int start, int end, [Element? fillValue]) {
    throw new UnsupportedError('Cannot fillRange on filtered list');
  }

  void replaceRange(int start, int end, Iterable<Element> iterable) {
    throw new UnsupportedError('Cannot replaceRange on filtered list');
  }

  void removeRange(int start, int end) {
    new List<Element>.from(_iterable.skip(start).take(end - start))
        .forEach((el) => el.remove());
  }

  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  Element removeLast() {
    final result = _iterable.last;
    if (result != null) {
      result.remove();
    }
    return result;
  }

  void insert(int index, Element value) {
    if (index == length) {
      add(value);
    } else {
      var element = _iterable.elementAt(index);
      element.parentNode!.insertBefore(value, element);
    }
  }

  void insertAll(int index, Iterable<Element> iterable) {
    if (index == length) {
      addAll(iterable);
    } else {
      var element = _iterable.elementAt(index);
      element.parentNode!.insertAllBefore(iterable, element);
    }
  }

  Element removeAt(int index) {
    final result = this[index];
    result.remove();
    return result;
  }

  bool remove(Object? element) {
    if (element is! Element) return false;
    if (contains(element)) {
      (element as Element).remove(); // Placate the type checker
      return true;
    } else {
      return false;
    }
  }

  int get length => _iterable.length;
  Element operator [](int index) => _iterable.elementAt(index);
  // This cannot use the iterator, because operations during iteration might
  // modify the collection, e.g. addAll might append a node to another parent.
  Iterator<Element> get iterator => _filtered.iterator;

  List<Node> get rawList => _node.childNodes;
}
