// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

/// A rudimentary linked list.
class LinkedList<T extends LinkedListEntry<T>> extends Iterable<T> {
  T get first => _first as T;
  T? _first;

  T get last => _last as T;
  T? _last;

  int length = 0;

  bool get isEmpty => length == 0;

  /**
   * Adds [newLast] to the end of this linked list.
   */
  void add(T newLast) {
    assert(newLast._next == null && newLast._previous == null);
    if (_last != null) {
      assert(_last!._next == null);
      _last!._next = newLast;
    } else {
      _first = newLast;
    }
    newLast._previous = _last;
    _last = newLast;
    _last!._list = this;
    length++;
  }

  /**
   * Adds [newFirst] to the beginning of this linked list.
   */
  void addFirst(T newFirst) {
    if (_first != null) {
      assert(_first!._previous == null);
      _first!._previous = newFirst;
    } else {
      _last = newFirst;
    }
    newFirst._next = _first;
    _first = newFirst;
    _first!._list = this;
    length++;
  }

  /**
   * Removes the given [node] from this list.
   *
   * If the entry is not in this linked list nothing happens.
   *
   * Also see [LinkedListEntry.unlink].
   */
  void remove(T node) {
    if (node._list != this) return;
    length--;
    if (node._previous == null) {
      assert(identical(node, _first));
      _first = node._next;
    } else {
      node._previous!._next = node._next;
    }
    if (node._next == null) {
      assert(identical(node, _last));
      _last = node._previous;
    } else {
      node._next!._previous = node._previous;
    }
    node._next = node._previous = null;
    node._list = null;
  }

  Iterator<T> get iterator => new _LinkedListIterator<T>(this);
}

class LinkedListEntry<T extends LinkedListEntry<T>> {
  T? _next;
  T? _previous;
  LinkedList<T>? _list;

  /**
   * Unlinks the element from its linked list.
   *
   * If the entry is not in a linked list, does nothing. Otherwise, this
   * is equivalent to calling [LinkedList.remove] on the list this entry
   * is currently in.
   */
  void unlink() {
    _list?.remove(this as T);
  }
}

class _LinkedListIterator<T extends LinkedListEntry<T>> implements Iterator<T> {
  /// The current element of the iterator.
  T? _current;

  T get current => _current as T;

  /// The list the iterator iterates over.
  ///
  /// Set to [null] if the provided list was empty (indicating that there were
  /// no entries to iterate over).
  ///
  /// Set to [null] as soon as [moveNext] was invoked (indicating that the
  /// iterator has to work with [current] from now on.
  LinkedList<T>? _list;

  _LinkedListIterator(LinkedList<T> list) : _list = list {
    if (list.length == 0) _list = null;
  }

  bool moveNext() {
    // current is null if the iterator hasn't started iterating, or if the
    // iteration is finished. In the first case, the [_list] field is not null.
    if (_current == null) {
      var list = _list;
      if (list == null) return false;
      assert(list.length > 0);
      _current = list.first;
      _list = null;
      return true;
    }
    _current = _current!._next;
    return _current != null;
  }
}
