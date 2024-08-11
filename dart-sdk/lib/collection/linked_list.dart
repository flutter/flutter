// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// A specialized double-linked list of elements that extends [LinkedListEntry].
///
/// This is not a generic data structure. It only accepts elements that *extend*
/// the [LinkedListEntry] class. See the [Queue] implementations for generic
/// collections that allow constant time adding and removing at the ends.
///
/// This is not a [List] implementation. Despite its name, this class does not
/// implement the [List] interface. It does not allow constant time lookup by
/// index.
///
/// Because the elements themselves contain the links of this linked list,
/// each element can be in only one list at a time. To add an element to another
/// list, it must first be removed from its current list (if any).
/// For the same reason, the [remove] and [contains] methods
/// are based on *identity*, even if the [LinkedListEntry] chooses
/// to override [Object.==].
///
/// In return, each element knows its own place in the linked list, as well as
/// which list it is in. This allows constant time
/// [LinkedListEntry.insertAfter], [LinkedListEntry.insertBefore] and
/// [LinkedListEntry.unlink] operations when all you have is the element.
///
/// A `LinkedList` also allows constant time adding and removing at either end,
/// and a constant time length getter.
///
/// Example:
/// ```dart
/// final class EntryItem extends LinkedListEntry<EntryItem> {
///   final int id;
///   final String text;
///   EntryItem(this.id, this.text);
///
///   @override
///   String toString() {
///     return '$id : $text';
///   }
/// }
///
/// void main() {
///   final linkedList = LinkedList<EntryItem>();
///   linkedList
///       .addAll([EntryItem(1, 'A'), EntryItem(2, 'B'), EntryItem(3, 'C')]);
///   print(linkedList.first); // 1 : A
///   print(linkedList.last); // 3 : C
///
///   // Add new item after first item.
///   linkedList.first.insertAfter(EntryItem(15, 'E'));
///   // Add new item before last item.
///   linkedList.last.insertBefore(EntryItem(10, 'D'));
///   // Iterate items.
///   for (var entry in linkedList) {
///     print(entry);
///     // 1 : A
///     // 15 : E
///     // 2 : B
///     // 10 : D
///     // 3 : C
///   }
///
///   // Remove item using index from list.
///   linkedList.elementAt(2).unlink();
///   print(linkedList); // (1 : A, 15 : E, 10 : D, 3 : C)
///   // Remove first item.
///   linkedList.first.unlink();
///   print(linkedList); // (15 : E, 10 : D, 3 : C)
///   // Remove last item from list.
///   linkedList.remove(linkedList.last);
///   print(linkedList); // (15 : E, 10 : D)
///   // Remove all items.
///   linkedList.clear();
///   print(linkedList.length); // 0
///   print(linkedList.isEmpty); // true
/// }
/// ```
base class LinkedList<E extends LinkedListEntry<E>> extends Iterable<E> {
  int _modificationCount = 0;
  int _length = 0;
  E? _first;

  /// Constructs a new empty linked list.
  LinkedList();

  /// Adds [entry] to the beginning of the linked list.
  void addFirst(E entry) {
    _insertBefore(_first, entry, updateFirst: true);
    _first = entry;
  }

  /// Adds [entry] to the end of the linked list.
  void add(E entry) {
    _insertBefore(_first, entry, updateFirst: false);
  }

  /// Adds [entries] to the end of the linked list.
  void addAll(Iterable<E> entries) {
    entries.forEach(add);
  }

  /// Removes [entry] from the linked list.
  ///
  /// Returns false and does nothing if [entry] is not in this linked list.
  ///
  /// This is equivalent to calling `entry.unlink()` if the entry is in this
  /// list.
  bool remove(E entry) {
    if (entry._list != this) return false;
    _unlink(entry); // Unlink will decrement length.
    return true;
  }

  /// Whether [entry] is a [LinkedListEntry] belonging to this list.
  ///
  /// The [entry] is considered as belonging to this list if
  /// its [LinkedListEntry.list] is this list.
  bool contains(Object? entry) =>
      entry is LinkedListEntry && identical(this, entry.list);

  Iterator<E> get iterator => _LinkedListIterator<E>(this);

  int get length => _length;

  /// Remove all elements from this linked list.
  void clear() {
    _modificationCount++;
    if (isEmpty) return;

    E next = _first!;
    do {
      E entry = next;
      next = entry._next!;
      entry._next = entry._previous = entry._list = null;
    } while (!identical(next, _first));

    _first = null;
    _length = 0;
  }

  E get first {
    if (isEmpty) {
      throw StateError('No such element');
    }
    return _first!;
  }

  E get last {
    if (isEmpty) {
      throw StateError('No such element');
    }
    return _first!._previous!;
  }

  E get single {
    if (isEmpty) {
      throw StateError('No such element');
    }
    if (_length > 1) {
      throw StateError('Too many elements');
    }
    return _first!;
  }

  /// Call [action] with each entry in this linked list.
  ///
  /// It's an error if [action] modifies the linked list.
  void forEach(void action(E entry)) {
    int modificationCount = _modificationCount;
    if (isEmpty) return;

    E current = _first!;
    do {
      action(current);
      if (modificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      current = current._next!;
    } while (!identical(current, _first));
  }

  bool get isEmpty => _length == 0;

  /// Inserts [newEntry] as last entry of the list.
  ///
  /// If [updateFirst] is true and [entry] is the first entry in the list,
  /// updates the [_first] field to point to the [newEntry] as first entry.
  void _insertBefore(E? entry, E newEntry, {required bool updateFirst}) {
    if (newEntry.list != null) {
      throw StateError('LinkedListEntry is already in a LinkedList');
    }
    _modificationCount++;

    newEntry._list = this;
    if (isEmpty) {
      assert(entry == null);
      newEntry._previous = newEntry._next = newEntry;
      _first = newEntry;
      _length++;
      return;
    }
    E predecessor = entry!._previous!;
    E successor = entry;
    newEntry._previous = predecessor;
    newEntry._next = successor;
    predecessor._next = newEntry;
    successor._previous = newEntry;
    if (updateFirst && identical(entry, _first)) {
      _first = newEntry;
    }
    _length++;
  }

  void _unlink(E entry) {
    _modificationCount++;
    entry._next!._previous = entry._previous;
    E? next = entry._previous!._next = entry._next;
    _length--;
    entry._list = entry._next = entry._previous = null;
    if (isEmpty) {
      _first = null;
    } else if (identical(entry, _first)) {
      _first = next;
    }
  }
}

class _LinkedListIterator<E extends LinkedListEntry<E>> implements Iterator<E> {
  final LinkedList<E> _list;
  final int _modificationCount;
  E? _current;
  E? _next;
  bool _visitedFirst;

  _LinkedListIterator(LinkedList<E> list)
      : _list = list,
        _modificationCount = list._modificationCount,
        _next = list._first,
        _visitedFirst = false;

  E get current => _current as E;

  bool moveNext() {
    if (_modificationCount != _list._modificationCount) {
      throw ConcurrentModificationError(this);
    }
    if (_list.isEmpty || (_visitedFirst && identical(_next, _list.first))) {
      _current = null;
      return false;
    }
    _visitedFirst = true;
    _current = _next;
    _next = _next!._next;
    return true;
  }
}

/// An object that can be an element in a [LinkedList].
///
/// All elements of a `LinkedList` must extend this class.
/// The class provides the internal links that link elements together
/// in the `LinkedList`, and a reference to the linked list itself
/// that an element is currently part of.
///
/// An entry can be in at most one linked list at a time.
/// While an entry is in a linked list, the [list] property points to that
/// linked list, and otherwise the `list` property is `null`.
///
/// When created, an entry is not in any linked list.
abstract base mixin class LinkedListEntry<E extends LinkedListEntry<E>> {
  LinkedList<E>? _list;
  E? _next;
  E? _previous;

  /// The linked list containing this element.
  ///
  /// The value is `null` if this entry is not currently in any list.
  LinkedList<E>? get list => _list;

  /// Unlink the element from its linked list.
  ///
  /// The entry must currently be in a linked list when this method is called.
  void unlink() {
    _list!._unlink(this as E);
  }

  /// The successor of this element in its linked list.
  ///
  /// The value is `null` if there is no successor in the linked list,
  /// or if this entry is not currently in any list.
  E? get next {
    if (_list == null || identical(_list!.first, _next)) return null;
    return _next;
  }

  /// The predecessor of this element in its linked list.
  ///
  /// The value is `null` if there is no predecessor in the linked list,
  /// or if this entry is not currently in any list.
  E? get previous {
    if (_list == null || identical(this, _list!.first)) return null;
    return _previous;
  }

  /// Insert an element after this element in this element's linked list.
  ///
  /// This entry must be in a linked list when this method is called.
  /// The [entry] must not be in a linked list.
  void insertAfter(E entry) {
    _list!._insertBefore(_next, entry, updateFirst: false);
  }

  /// Insert an element before this element in this element's linked list.
  ///
  /// This entry must be in a linked list when this method is called.
  /// The [entry] must not be in a linked list.
  void insertBefore(E entry) {
    _list!._insertBefore(this as E, entry, updateFirst: true);
  }
}
