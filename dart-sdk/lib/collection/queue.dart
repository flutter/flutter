// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// Helper interface to hide [EfficientLengthIterable] from the public
/// declaration of [Queue].
abstract class _QueueIterable<E>
    implements EfficientLengthIterable<E>, HideEfficientLengthIterable<E> {}

/// A [Queue] is a collection that can be manipulated at both ends. One
/// can iterate over the elements of a queue through [forEach] or with
/// an [Iterator].
///
/// It is generally not allowed to modify the queue (add or remove entries)
/// while an operation in the queue is being performed, for example during a
/// call to [forEach].
/// Modifying the queue while it is being iterated will most likely break the
/// iteration.
/// This goes both for using the [iterator] directly, or for iterating an
/// `Iterable` returned by a method like [map] or [where].
///
/// Example:
/// ```dart
/// final queue = Queue<int>(); // ListQueue() by default
/// print(queue.runtimeType); // ListQueue
///
/// // Adding items to queue
/// queue.addAll([1, 2, 3]);
/// queue.addFirst(0);
/// queue.addLast(10);
/// print(queue); // {0, 1, 2, 3, 10}
///
/// // Removing items from queue
/// queue.removeFirst();
/// queue.removeLast();
/// print(queue); // {1, 2, 3}
/// ```
abstract interface class Queue<E> implements Iterable<E>, _QueueIterable<E> {
  /// Creates a queue.
  factory Queue() = ListQueue<E>;

  /// Creates a queue containing all [elements].
  ///
  /// The element order in the queue is as if the elements were added using
  /// [addLast] in the order provided by [elements].iterator.
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `Queue`, for example as:
  /// ```dart
  /// Queue<SuperType> superQueue = ...;
  /// Queue<SubType> subQueue =
  ///     Queue<SubType>.from(superQueue.whereType<SubType>());
  /// ```
  factory Queue.from(Iterable elements) = ListQueue<E>.from;

  /// Creates a queue from [elements].
  ///
  /// The element order in the queue is as if the elements were added using
  /// [addLast] in the order provided by [elements].iterator.
  factory Queue.of(Iterable<E> elements) = ListQueue<E>.of;

  /// Adapts [source] to be a `Queue<T>`.
  ///
  /// Any time the queue would produce an element that is not a [T],
  /// the element access will throw.
  ///
  /// When a [T] value is stored into the adapted queue,
  /// the operation will throw unless the value is also an instance of [S].
  ///
  /// If all accessed elements of [source] are actually instances of [T],
  /// and if all elements stored into the returned queue are actually instances
  /// of [S],
  /// then the returned queue can be used as a `Queue<T>`.
  ///
  /// Methods which accept `Object?` as argument, like [contains] and [remove],
  /// will pass the argument directly to this queue's method
  /// without any checks.
  static Queue<T> castFrom<S, T>(Queue<S> source) => CastQueue<S, T>(source);

  /// Provides a view of this queue as a queue of [R] instances, if necessary.
  ///
  /// If this queue contains only instances of [R], all read operations
  /// will work correctly. If any operation tries to access an element
  /// that is not an instance of [R], the access will throw instead.
  ///
  /// Elements added to the queue (e.g., by using [addFirst] or [addAll])
  /// must be instances of [R] to be valid arguments to the adding function,
  /// and they must also be instances of [E] to be accepted by
  /// this queue as well.
  ///
  /// Methods which accept `Object?` as argument, like [contains] and [remove],
  /// will pass the argument directly to the this queue's method
  /// without any checks.
  /// That means that you can do `queueOfStrings.cast<int>().remove("a")`
  /// successfully, even if it looks like it shouldn't have any effect.
  Queue<R> cast<R>();

  /// Removes and returns the first element of this queue.
  ///
  /// The queue must not be empty when this method is called.
  E removeFirst();

  /// Removes and returns the last element of the queue.
  ///
  /// The queue must not be empty when this method is called.
  E removeLast();

  /// Adds [value] at the beginning of the queue.
  void addFirst(E value);

  /// Adds [value] at the end of the queue.
  void addLast(E value);

  /// Adds [value] at the end of the queue.
  void add(E value);

  /// Removes a single instance of [value] from the queue.
  ///
  /// Returns `true` if a value was removed, or `false` if the queue
  /// contained no element equal to [value].
  bool remove(Object? value);

  /// Adds all elements of [iterable] at the end of the queue. The
  /// length of the queue is extended by the length of [iterable].
  void addAll(Iterable<E> iterable);

  /// Removes all elements matched by [test] from the queue.
  ///
  /// The `test` function must not throw or modify the queue.
  void removeWhere(bool test(E element));

  /// Removes all elements not matched by [test] from the queue.
  ///
  /// The `test` function must not throw or modify the queue.
  void retainWhere(bool test(E element));

  /// Removes all elements in the queue. The size of the queue becomes zero.
  void clear();
}

/// Interface and base class for the link classes used by [DoubleLinkedQueue].
///
/// Both the [_DoubleLinkedQueueElement] and [_DoubleLinkedQueueSentinel]
/// implement this interface.
abstract class _DoubleLinkedQueueEntry<E> {
  _DoubleLinkedQueueEntry<E>? _previousLink;
  _DoubleLinkedQueueEntry<E>? _nextLink;

  void _link(
      _DoubleLinkedQueueEntry<E>? previous, _DoubleLinkedQueueEntry<E>? next) {
    _nextLink = next;
    _previousLink = previous;
    previous?._nextLink = this;
    next?._previousLink = this;
  }

  void _unlink() {
    _previousLink?._nextLink = _nextLink;
    _nextLink?._previousLink = _previousLink;
    _previousLink = _nextLink = null;
  }

  _DoubleLinkedQueueElement<E>? _asNonSentinelEntry();

  void _append(E element, DoubleLinkedQueue<E>? queue) {
    _DoubleLinkedQueueElement<E>(element, queue)._link(this, _nextLink);
  }

  void _prepend(E element, DoubleLinkedQueue<E>? queue) {
    _DoubleLinkedQueueElement<E>(element, queue)._link(_previousLink, this);
  }

  E _remove();

  E get element;
}

/// Linked list entry used by the [DoubleLinkedQueue] to hold an element.
///
/// These entry objects are also exposed by [DoubleLinkedQueue.firstEntry],
/// [DoubleLinkedQueue.lastEntry] and [DoubleLinkedQueue.forEachEntry].
///
/// The entry contains both the [element] (which is mutable to anyone with
/// access to the entry object) and a reference to the queue, allowing
/// [append]/[prepend] to update the list length.
///
/// When an entry is removed from its queue, the [_queue] is set to `null`
/// and will never change again. You can still use the unlinked entry
/// to create a new list, by calling [append] and [prepend], but it won't
/// be part of any [DoubleLinkedQueue].
class _DoubleLinkedQueueElement<E> extends _DoubleLinkedQueueEntry<E>
    implements DoubleLinkedQueueEntry<E> {
  DoubleLinkedQueue<E>? _queue;
  E element;

  _DoubleLinkedQueueElement(this.element, this._queue);

  void append(E e) {
    _append(e, _queue);
    _queue?._elementCount++;
  }

  void prepend(E e) {
    _prepend(e, _queue);
    _queue?._elementCount++;
  }

  E _remove() {
    _queue = null;
    _unlink();
    return element;
  }

  E remove() {
    _queue?._elementCount--;
    return _remove();
  }

  _DoubleLinkedQueueElement<E> _asNonSentinelEntry() => this;

  DoubleLinkedQueueEntry<E>? previousEntry() =>
      _previousLink?._asNonSentinelEntry();

  DoubleLinkedQueueEntry<E>? nextEntry() => _nextLink?._asNonSentinelEntry();
}

/// A header object used to hold the two ends of a double linked queue.
///
/// A [DoubleLinkedQueue] has exactly one sentinel,
/// which is the only entry when the list is constructed.
///
/// Initially, a sentinel has its next and previous entries point to itself.
/// Its next and previous links are never `null` after creation, and
/// the entries linked always form a circular structure with the next link
/// pointing to the first element of the queue, and the previous link
/// pointing to the last element of the queue, or both pointing to itself
/// again if the queue becomes empty.
///
/// Implements [_DoubleLinkedQueueEntry._remove] and
/// [_DoubleLinkedQueueEntry.element] as throwing because
/// it makes it simple to implement members like [Queue.removeFirst]
/// or [Queue.first] as throwing on an empty queue.
///
/// A sentinel does not contain any user element.
class _DoubleLinkedQueueSentinel<E> extends _DoubleLinkedQueueEntry<E> {
  _DoubleLinkedQueueSentinel() {
    _previousLink = this;
    _nextLink = this;
  }

  Null _asNonSentinelEntry() => null;

  /// Hit by, e.g., [DoubleLinkedQueue.removeFirst] if the queue is empty.
  E _remove() {
    throw IterableElementError.noElement();
  }

  /// Hit by, e.g., [DoubleLinkedQueue.first] if the queue is empty.
  E get element {
    throw IterableElementError.noElement();
  }
}

/// A [Queue] implementation based on a double-linked list.
///
/// Allows constant time add, remove-at-ends and peek operations.
final class DoubleLinkedQueue<E> extends Iterable<E> implements Queue<E> {
  final _DoubleLinkedQueueSentinel<E> _sentinel =
      _DoubleLinkedQueueSentinel<E>();

  int _elementCount = 0;

  DoubleLinkedQueue();

  /// Creates a double-linked queue containing all [elements].
  ///
  /// The element order in the queue is as if the elements were added using
  /// [addLast] in the order provided by [elements].iterator.
  ///
  /// All the [elements] should be instances of [E].
  /// The [elements] iterable itself may have any element type, so this
  /// constructor can be used to down-cast a [Queue], for example as:
  /// ```dart
  /// Queue<SuperType> superQueue = ...;
  /// Queue<SubType> subQueue =
  ///     DoubleLinkedQueue<SubType>.from(superQueue.whereType<SubType>());
  /// ```
  factory DoubleLinkedQueue.from(Iterable<dynamic> elements) {
    DoubleLinkedQueue<E> list = DoubleLinkedQueue<E>();
    for (final e in elements) {
      list.addLast(e as E);
    }
    return list;
  }

  /// Creates a double-linked queue from [elements].
  ///
  /// The element order in the queue is as if the elements were added using
  /// [addLast] in the order provided by [elements].iterator.
  factory DoubleLinkedQueue.of(Iterable<E> elements) =>
      DoubleLinkedQueue<E>()..addAll(elements);

  Queue<R> cast<R>() => Queue.castFrom<E, R>(this);

  int get length => _elementCount;

  void addLast(E value) {
    _sentinel._prepend(value, this);
    _elementCount++;
  }

  void addFirst(E value) {
    _sentinel._append(value, this);
    _elementCount++;
  }

  void add(E value) {
    _sentinel._prepend(value, this);
    _elementCount++;
  }

  void addAll(Iterable<E> iterable) {
    for (final E value in iterable) {
      _sentinel._prepend(value, this);
      _elementCount++;
    }
  }

  E removeLast() {
    // Hits sentinel's `_remove` if queue is empty.
    E result = _sentinel._previousLink!._remove();
    _elementCount--;
    return result;
  }

  E removeFirst() {
    // Hits sentinel's `_remove` if queue is empty.
    E result = _sentinel._nextLink!._remove();
    _elementCount--;
    return result;
  }

  bool remove(Object? o) {
    _DoubleLinkedQueueEntry<E> entry = _sentinel._nextLink!;
    while (true) {
      var elementEntry = entry._asNonSentinelEntry();
      if (elementEntry == null) return false;
      bool equals = (elementEntry.element == o);
      if (!identical(this, elementEntry._queue)) {
        // Entry must still be in the queue.
        throw ConcurrentModificationError(this);
      }
      if (equals) {
        entry._remove();
        _elementCount--;
        return true;
      }
      entry = entry._nextLink!;
    }
  }

  void _filter(bool test(E element), bool removeMatching) {
    _DoubleLinkedQueueEntry<E> entry = _sentinel._nextLink!;
    while (true) {
      var elementEntry = entry._asNonSentinelEntry();
      if (elementEntry == null) return;
      bool matches = test(elementEntry.element);
      if (!identical(this, elementEntry._queue)) {
        // Entry must still be in the queue.
        throw ConcurrentModificationError(this);
      }
      var next = entry._nextLink!; // Cannot be null while entry is in queue.
      if (identical(removeMatching, matches)) {
        elementEntry._remove();
        _elementCount--;
      }
      entry = next;
    }
  }

  void removeWhere(bool test(E element)) {
    _filter(test, true);
  }

  void retainWhere(bool test(E element)) {
    _filter(test, false);
  }

  // Hits sentinel's `get element` if no element in queue.
  E get first => _sentinel._nextLink!.element;

  // Hits sentinel's `get element` if no element in queue.
  E get last => _sentinel._previousLink!.element;

  E get single {
    // Note that this throws correctly if the queue is empty
    // because reading the element of the sentinel throws.
    if (identical(_sentinel._nextLink, _sentinel._previousLink)) {
      return _sentinel._nextLink!.element;
    }
    throw IterableElementError.tooMany();
  }

  /// The entry object of the first element in the queue.
  ///
  /// Each element of the queue has an associated [DoubleLinkedQueueEntry].
  ///
  /// Returns the entry object corresponding to the first element of the queue,
  /// or `null` if the queue is empty.
  ///
  /// The entry objects can also be accessed using [lastEntry],
  /// and they can be iterated using [DoubleLinkedQueueEntry.nextEntry] and
  /// [DoubleLinkedQueueEntry.previousEntry].
  DoubleLinkedQueueEntry<E>? firstEntry() =>
      _sentinel._nextLink!._asNonSentinelEntry();

  /// The entry object of the last element in the queue.
  ///
  /// Each element of the queue has an associated [DoubleLinkedQueueEntry].
  ///
  /// Returns the entry object corresponding to the last element of the queue,
  /// or `null` if the queue is empty.
  ///
  /// The entry objects can also be accessed using [firstEntry],
  /// and they can be iterated using [DoubleLinkedQueueEntry.nextEntry] and
  /// [DoubleLinkedQueueEntry.previousEntry].
  DoubleLinkedQueueEntry<E>? lastEntry() =>
      _sentinel._previousLink!._asNonSentinelEntry();

  bool get isEmpty => identical(_sentinel._nextLink, _sentinel);

  void clear() {
    var cursor = _sentinel._nextLink!;
    while (true) {
      var entry = cursor._asNonSentinelEntry();
      if (entry == null) break;
      cursor = cursor._nextLink!;
      entry
        .._nextLink = null
        .._previousLink = null
        .._queue = null;
    }
    _sentinel._nextLink = _sentinel;
    _sentinel._previousLink = _sentinel;
    _elementCount = 0;
  }

  /// Calls [action] for each entry object of this double-linked queue.
  ///
  /// Each element of the queue has an associated [DoubleLinkedQueueEntry].
  /// This method iterates the entry objects from first to last and calls
  /// [action] with each object in turn.
  ///
  /// The entry objects can also be accessed using [firstEntry] and [lastEntry],
  /// and iterated using [DoubleLinkedQueueEntry.nextEntry()] and
  /// [DoubleLinkedQueueEntry.previousEntry()].
  ///
  /// The [action] function can use methods on [DoubleLinkedQueueEntry] to
  /// remove the entry or it can insert elements before or after the entry.
  /// If the current entry is removed, iteration continues with the entry that
  /// was following the current entry when [action] was called. Any elements
  /// inserted after the current element before it is removed will not be
  /// visited by the iteration.
  void forEachEntry(void action(DoubleLinkedQueueEntry<E> element)) {
    var cursor = _sentinel._nextLink!;
    while (true) {
      var element = cursor._asNonSentinelEntry();
      if (element == null) break;
      if (!identical(element._queue, this)) {
        throw ConcurrentModificationError(this);
      }
      cursor = cursor._nextLink!;
      // Remember both element and element._nextLink (as cursor).
      // If someone calls `element.remove()` we continue from `next`.
      // Otherwise we use the value of element._nextLink which may have been
      // updated.
      action(element);
      if (identical(this, element._queue)) {
        cursor = element._nextLink!;
      }
    }
  }

  _DoubleLinkedQueueIterator<E> get iterator {
    return _DoubleLinkedQueueIterator<E>(this);
  }

  String toString() => Iterable.iterableToFullString(this, '{', '}');
}

class _DoubleLinkedQueueIterator<E> implements Iterator<E> {
  /// Queue being iterated. Used for concurrent modification checks.
  DoubleLinkedQueue<E>? _queue;

  /// Next entry to visit. Set to null when hitting the sentinel.
  _DoubleLinkedQueueEntry<E>? _nextEntry;

  /// Current element value, when valid.
  E? _current;

  _DoubleLinkedQueueIterator(DoubleLinkedQueue<E> this._queue)
      : _nextEntry = _queue._sentinel._nextLink;

  bool moveNext() {
    var nextElement = _nextEntry?._asNonSentinelEntry();
    if (nextElement == null) {
      // Clear everything to not unnecessarily keep values alive.
      _current = null;
      _nextEntry = null;
      _queue = null;
      return false;
    }
    if (!identical(_queue, nextElement._queue)) {
      throw ConcurrentModificationError(_queue);
    }
    _current = nextElement.element;
    _nextEntry = nextElement._nextLink;
    return true;
  }

  E get current => _current as E;
}

/// List based [Queue].
///
/// Keeps a cyclic buffer of elements, and grows to a larger buffer when
/// it fills up. This guarantees constant time peek and remove operations, and
/// amortized constant time add operations.
///
/// The structure is efficient for any queue or stack usage.
///
/// Example:
/// ```dart
/// final queue = ListQueue<int>();
/// ```
/// To add objects to a queue, use [add], [addAll], [addFirst] or[addLast].
/// ```dart continued
/// queue.add(5);
/// queue.addFirst(0);
/// queue.addLast(10);
/// queue.addAll([1, 2, 3]);
/// print(queue); // {0, 5, 10, 1, 2, 3}
/// ```
/// To check if the queue is empty, use [isEmpty] or [isNotEmpty].
/// To find the number of queue entries, use [length].
/// ```dart continued
/// final isEmpty = queue.isEmpty; // false
/// final queueSize = queue.length; // 6
/// ```
/// To get first or last item from queue, use [first] or [last].
/// ```dart continued
/// final first = queue.first; // 0
/// final last = queue.last; // 3
/// ```
/// To get item value using index, use [elementAt].
/// ```dart continued
/// final itemAt = queue.elementAt(2); // 10
/// ```
/// To convert queue to list, call [toList].
/// ```dart continued
/// final numbers = queue.toList();
/// print(numbers); // [0, 5, 10, 1, 2, 3]
/// ```
/// To remove item from queue, call [remove], [removeFirst] or [removeLast].
/// ```dart continued
/// queue.remove(10);
/// queue.removeFirst();
/// queue.removeLast();
/// print(queue); // {5, 1, 2}
/// ```
/// To remove multiple elements at the same time, use [removeWhere].
/// ```dart continued
/// queue.removeWhere((element) => element == 1);
/// print(queue); // {5, 2}
/// ```
/// To remove all elements in this queue that do not meet a condition,
/// use [retainWhere].
/// ```dart continued
/// queue.retainWhere((element) => element < 4);
/// print(queue); // {2}
/// ```
/// To remove all items and empty the set, use [clear].
/// ```dart continued
/// queue.clear();
/// print(queue.isEmpty); // true
/// print(queue); // {}
/// ```
final class ListQueue<E> extends ListIterable<E> implements Queue<E> {
  static const int _INITIAL_CAPACITY = 8;
  List<E?> _table;
  int _head;
  int _tail;
  int _modificationCount = 0;

  /// Create an empty queue.
  ///
  /// If [initialCapacity] is given, prepare the queue for at least that many
  /// elements.
  ListQueue([int? initialCapacity])
      : _head = 0,
        _tail = 0,
        _table = List<E?>.filled(_calculateCapacity(initialCapacity), null);

  static int _calculateCapacity(int? initialCapacity) {
    if (initialCapacity == null || initialCapacity < _INITIAL_CAPACITY) {
      return _INITIAL_CAPACITY;
    } else if (!_isPowerOf2(initialCapacity)) {
      return _nextPowerOf2(initialCapacity);
    }
    assert(_isPowerOf2(initialCapacity));
    return initialCapacity;
  }

  /// Create a `ListQueue` containing all [elements].
  ///
  /// The elements are added to the queue, as by [addLast], in the order given
  /// by `elements.iterator`.
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `Queue`, for example as:
  /// ```dart
  /// Queue<SuperType> superQueue = ...;
  /// Queue<SubType> subQueue =
  ///     ListQueue<SubType>.from(superQueue.whereType<SubType>());
  /// ```
  /// Example:
  /// ```dart
  /// final numbers = <num>[10, 20, 30];
  /// final queue = ListQueue<int>.from(numbers);
  /// print(queue); // {10, 20, 30}
  /// ```
  factory ListQueue.from(Iterable<dynamic> elements) {
    if (elements is List<dynamic>) {
      int length = elements.length;
      ListQueue<E> queue = ListQueue<E>(length + 1);
      assert(queue._table.length > length);
      for (int i = 0; i < length; i++) {
        queue._table[i] = elements[i] as E;
      }
      queue._tail = length;
      return queue;
    } else {
      int capacity = _INITIAL_CAPACITY;
      if (elements is EfficientLengthIterable) {
        capacity = elements.length;
      }
      ListQueue<E> result = ListQueue<E>(capacity);
      for (final element in elements) {
        result.addLast(element as E);
      }
      return result;
    }
  }

  /// Create a `ListQueue` from [elements].
  ///
  /// The elements are added to the queue, as by [addLast], in the order given
  /// by `elements.iterator`.
  /// Example:
  /// ```dart
  /// final baseQueue = ListQueue.of([1.0, 2.0, 3.0]); // A ListQueue<double>
  /// final numQueue = ListQueue<num>.of(baseQueue);
  /// print(numQueue); // {1.0, 2.0, 3.0}
  /// ```
  factory ListQueue.of(Iterable<E> elements) =>
      ListQueue<E>()..addAll(elements);

  // Iterable interface.

  Queue<R> cast<R>() => Queue.castFrom<E, R>(this);
  Iterator<E> get iterator => _ListQueueIterator<E>(this);

  void forEach(void f(E element)) {
    int modificationCount = _modificationCount;
    for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
      f(_table[i] as E);
      _checkModification(modificationCount);
    }
  }

  bool get isEmpty => _head == _tail;

  int get length => (_tail - _head) & (_table.length - 1);

  E get first {
    if (_head == _tail) throw IterableElementError.noElement();
    return _table[_head] as E;
  }

  E get last {
    if (_head == _tail) throw IterableElementError.noElement();
    return _table[(_tail - 1) & (_table.length - 1)] as E;
  }

  E get single {
    if (_head == _tail) throw IterableElementError.noElement();
    if (length > 1) throw IterableElementError.tooMany();
    return _table[_head] as E;
  }

  E elementAt(int index) {
    IndexError.check(index, length, indexable: this);
    return _table[(_head + index) & (_table.length - 1)] as E;
  }

  List<E> toList({bool growable = true}) {
    int mask = _table.length - 1;
    int length = (_tail - _head) & mask;
    if (length == 0) return List<E>.empty(growable: growable);

    var list = List<E>.filled(length, first, growable: growable);
    for (int i = 0; i < length; i++) {
      list[i] = _table[(_head + i) & mask] as E;
    }
    return list;
  }

  // Collection interface.

  void add(E value) {
    _add(value);
  }

  void addAll(Iterable<E> elements) {
    if (elements is List<E>) {
      List<E> list = elements;
      int addCount = list.length;
      int length = this.length;
      if (length + addCount >= _table.length) {
        _preGrow(length + addCount);
        // After preGrow, all elements are at the start of the list.
        _table.setRange(length, length + addCount, list, 0);
        _tail += addCount;
      } else {
        // Adding addCount elements won't reach _head.
        int endSpace = _table.length - _tail;
        if (addCount < endSpace) {
          _table.setRange(_tail, _tail + addCount, list, 0);
          _tail += addCount;
        } else {
          int preSpace = addCount - endSpace;
          _table.setRange(_tail, _tail + endSpace, list, 0);
          _table.setRange(0, preSpace, list, endSpace);
          _tail = preSpace;
        }
      }
      _modificationCount++;
    } else {
      for (E element in elements) _add(element);
    }
  }

  bool remove(Object? value) {
    for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
      E? element = _table[i];
      if (element == value) {
        _remove(i);
        _modificationCount++;
        return true;
      }
    }
    return false;
  }

  void _filterWhere(bool test(E element), bool removeMatching) {
    int modificationCount = _modificationCount;
    int i = _head;
    while (i != _tail) {
      E element = _table[i] as E;
      bool remove = identical(removeMatching, test(element));
      _checkModification(modificationCount);
      if (remove) {
        i = _remove(i);
        modificationCount = ++_modificationCount;
      } else {
        i = (i + 1) & (_table.length - 1);
      }
    }
  }

  /// Remove all elements matched by [test].
  ///
  /// This method is inefficient since it works by repeatedly removing single
  /// elements, each of which can take linear time.
  void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }

  /// Remove all elements not matched by [test].
  ///
  /// This method is inefficient since it works by repeatedly removing single
  /// elements, each of which can take linear time.
  void retainWhere(bool test(E element)) {
    _filterWhere(test, false);
  }

  void clear() {
    if (_head != _tail) {
      for (int i = _head; i != _tail; i = (i + 1) & (_table.length - 1)) {
        _table[i] = null;
      }
      _head = _tail = 0;
      _modificationCount++;
    }
  }

  String toString() => Iterable.iterableToFullString(this, "{", "}");

  // Queue interface.

  void addLast(E value) {
    _add(value);
  }

  void addFirst(E value) {
    _head = (_head - 1) & (_table.length - 1);
    _table[_head] = value;
    if (_head == _tail) _grow();
    _modificationCount++;
  }

  E removeFirst() {
    if (_head == _tail) throw IterableElementError.noElement();
    _modificationCount++;
    E result = _table[_head] as E;
    _table[_head] = null;
    _head = (_head + 1) & (_table.length - 1);
    return result;
  }

  E removeLast() {
    if (_head == _tail) throw IterableElementError.noElement();
    _modificationCount++;
    _tail = (_tail - 1) & (_table.length - 1);
    E result = _table[_tail] as E;
    _table[_tail] = null;
    return result;
  }

  // Internal helper functions.

  /// Whether [number] is a power of two.
  ///
  /// Only works for positive numbers.
  static bool _isPowerOf2(int number) => (number & (number - 1)) == 0;

  /// Rounds [number] up to the nearest power of 2.
  ///
  /// If [number] is a power of 2 already, it is returned.
  ///
  /// Only works for positive numbers.
  static int _nextPowerOf2(int number) {
    assert(number > 0);
    number = (number << 1) - 1;
    for (;;) {
      int nextNumber = number & (number - 1);
      if (nextNumber == 0) return number;
      number = nextNumber;
    }
  }

  /// Check if the queue has been modified during iteration.
  void _checkModification(int expectedModificationCount) {
    if (expectedModificationCount != _modificationCount) {
      throw ConcurrentModificationError(this);
    }
  }

  /// Adds element at end of queue. Used by both [add] and [addAll].
  void _add(E element) {
    _table[_tail] = element;
    _tail = (_tail + 1) & (_table.length - 1);
    if (_head == _tail) _grow();
    _modificationCount++;
  }

  /// Removes the element at [offset] into [_table].
  ///
  /// Removal is performed by linearly moving elements either before or after
  /// [offset] by one position.
  ///
  /// Returns the new offset of the following element. This may be the same
  /// offset or the following offset depending on how elements are moved
  /// to fill the hole.
  int _remove(int offset) {
    int mask = _table.length - 1;
    int startDistance = (offset - _head) & mask;
    int endDistance = (_tail - offset) & mask;
    if (startDistance < endDistance) {
      // Closest to start.
      int i = offset;
      while (i != _head) {
        int prevOffset = (i - 1) & mask;
        _table[i] = _table[prevOffset];
        i = prevOffset;
      }
      _table[_head] = null;
      _head = (_head + 1) & mask;
      return (offset + 1) & mask;
    } else {
      _tail = (_tail - 1) & mask;
      int i = offset;
      while (i != _tail) {
        int nextOffset = (i + 1) & mask;
        _table[i] = _table[nextOffset];
        i = nextOffset;
      }
      _table[_tail] = null;
      return offset;
    }
  }

  /// Grow the table when full.
  void _grow() {
    List<E?> newTable = List<E?>.filled(_table.length * 2, null);
    int split = _table.length - _head;
    newTable.setRange(0, split, _table, _head);
    newTable.setRange(split, split + _head, _table, 0);
    _head = 0;
    _tail = _table.length;
    _table = newTable;
  }

  int _writeToList(List<E?> target) {
    assert(target.length >= length);
    if (_head <= _tail) {
      int length = _tail - _head;
      target.setRange(0, length, _table, _head);
      return length;
    } else {
      int firstPartSize = _table.length - _head;
      target.setRange(0, firstPartSize, _table, _head);
      target.setRange(firstPartSize, firstPartSize + _tail, _table, 0);
      return _tail + firstPartSize;
    }
  }

  /// Grows the table even if it is not full.
  void _preGrow(int newElementCount) {
    assert(newElementCount >= length);

    // Add some extra room to ensure that there's room for more elements after
    // expansion.
    newElementCount += newElementCount >> 1;
    int newCapacity = _nextPowerOf2(newElementCount);
    List<E?> newTable = List<E?>.filled(newCapacity, null);
    _tail = _writeToList(newTable);
    _table = newTable;
    _head = 0;
  }
}

/// Iterator for a [ListQueue].
///
/// Considers any add or remove operation a concurrent modification.
class _ListQueueIterator<E> implements Iterator<E> {
  final ListQueue<E> _queue;
  final int _end;
  final int _modificationCount;
  int _position;
  E? _current;

  _ListQueueIterator(ListQueue<E> queue)
      : _queue = queue,
        _end = queue._tail,
        _modificationCount = queue._modificationCount,
        _position = queue._head;

  E get current => _current as E;

  bool moveNext() {
    _queue._checkModification(_modificationCount);
    if (_position == _end) {
      _current = null;
      return false;
    }
    _current = _queue._table[_position];
    _position = (_position + 1) & (_queue._table.length - 1);
    return true;
  }
}
