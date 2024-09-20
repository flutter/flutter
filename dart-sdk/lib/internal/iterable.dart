// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

/**
 * Marker interface for [Iterable] subclasses that have an efficient
 * [length] implementation.
 */
abstract class EfficientLengthIterable<T> extends Iterable<T> {
  const EfficientLengthIterable();
  /**
   * Returns the number of elements in the iterable.
   *
   * This is an efficient operation that doesn't require iterating through
   * the elements.
   */
  int get length;
}

/// An interface which hides [EfficientLengthIterable] from upper bounds.
///
/// Every type which implements [EfficientLengthIterable] also implements
/// this interface, and they have the same *depth*, so it's impossible
/// for the upper-bound algorithm to get [EfficientLengthIterable]
/// as the result.
abstract interface class HideEfficientLengthIterable<T>
    implements Iterable<T> {}

/**
 * An [Iterable] for classes that have efficient [length] and [elementAt].
 *
 * All other methods are implemented in terms of [length] and [elementAt],
 * including [iterator].
 */
abstract class ListIterable<E> extends EfficientLengthIterable<E>
    implements HideEfficientLengthIterable<E> {
  int get length;
  E elementAt(int i);

  const ListIterable();

  Iterator<E> get iterator => ListIterator<E>(this);

  void forEach(void action(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      action(elementAt(i));
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
  }

  bool get isEmpty => length == 0;

  E get first {
    if (length == 0) throw IterableElementError.noElement();
    return elementAt(0);
  }

  E get last {
    if (length == 0) throw IterableElementError.noElement();
    return elementAt(length - 1);
  }

  E get single {
    if (length == 0) throw IterableElementError.noElement();
    if (length > 1) throw IterableElementError.tooMany();
    return elementAt(0);
  }

  bool contains(Object? element) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (elementAt(i) == element) return true;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return false;
  }

  bool every(bool test(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (!test(elementAt(i))) return false;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return true;
  }

  bool any(bool test(E element)) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      if (test(elementAt(i))) return true;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return false;
  }

  E firstWhere(bool test(E element), {E Function()? orElse}) {
    int length = this.length;
    for (int i = 0; i < length; i++) {
      E element = elementAt(i);
      if (test(element)) return element;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E element), {E Function()? orElse}) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      E element = elementAt(i);
      if (test(element)) return element;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E element), {E Function()? orElse}) {
    int length = this.length;
    late E match;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      E element = elementAt(i);
      if (test(element)) {
        if (matchFound) {
          throw IterableElementError.tooMany();
        }
        matchFound = true;
        match = element;
      }
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  String join([String separator = ""]) {
    int length = this.length;
    if (!separator.isEmpty) {
      if (length == 0) return "";
      String first = "${elementAt(0)}";
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
      StringBuffer buffer = StringBuffer(first);
      for (int i = 1; i < length; i++) {
        buffer.write(separator);
        buffer.write(elementAt(i));
        if (length != this.length) {
          throw ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    } else {
      StringBuffer buffer = StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.write(elementAt(i));
        if (length != this.length) {
          throw ConcurrentModificationError(this);
        }
      }
      return buffer.toString();
    }
  }

  Iterable<E> where(bool test(E element)) => super.where(test);

  Iterable<T> map<T>(T toElement(E element)) =>
      MappedListIterable<E, T>(this, toElement);

  E reduce(E combine(E value, E element)) {
    int length = this.length;
    if (length == 0) throw IterableElementError.noElement();
    E value = elementAt(0);
    for (int i = 1; i < length; i++) {
      value = combine(value, elementAt(i));
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    var value = initialValue;
    int length = this.length;
    for (int i = 0; i < length; i++) {
      value = combine(value, elementAt(i));
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    return value;
  }

  Iterable<E> skip(int count) => SubListIterable<E>(this, count, null);

  Iterable<E> skipWhile(bool test(E element)) => super.skipWhile(test);

  Iterable<E> take(int count) =>
      SubListIterable<E>(this, 0, checkNotNullable(count, "count"));

  Iterable<E> takeWhile(bool test(E element)) => super.takeWhile(test);

  List<E> toList({bool growable = true}) =>
      List<E>.of(this, growable: growable);

  Set<E> toSet() {
    Set<E> result = Set<E>();
    for (int i = 0; i < length; i++) {
      result.add(elementAt(i));
    }
    return result;
  }
}

base class SubListIterable<E> extends ListIterable<E> {
  final Iterable<E> _iterable; // Has efficient length and elementAt.
  final int _start;
  /** If null, represents the length of the iterable. */
  final int? _endOrLength;

  SubListIterable(this._iterable, this._start, this._endOrLength) {
    RangeError.checkNotNegative(_start, "start");
    int? endOrLength = _endOrLength;
    if (endOrLength != null) {
      RangeError.checkNotNegative(endOrLength, "end");
      if (_start > endOrLength) {
        throw RangeError.range(_start, 0, endOrLength, "start");
      }
    }
  }

  int get _endIndex {
    int length = _iterable.length;
    int? endOrLength = _endOrLength;
    if (endOrLength == null || endOrLength > length) return length;
    return endOrLength;
  }

  int get _startIndex {
    int length = _iterable.length;
    if (_start > length) return length;
    return _start;
  }

  int get length {
    int length = _iterable.length;
    if (_start >= length) return 0;
    int? endOrLength = _endOrLength;
    if (endOrLength == null || endOrLength >= length) {
      return length - _start;
    }
    return endOrLength - _start;
  }

  E elementAt(int index) {
    int realIndex = _startIndex + index;
    if (index < 0 || realIndex >= _endIndex) {
      throw IndexError.withLength(index, length,
          indexable: this, name: "index");
    }
    return _iterable.elementAt(realIndex);
  }

  Iterable<E> skip(int count) {
    RangeError.checkNotNegative(count, "count");
    int newStart = _start + count;
    int? endOrLength = _endOrLength;
    if (endOrLength != null && newStart >= endOrLength) {
      return EmptyIterable<E>();
    }
    return SubListIterable<E>(_iterable, newStart, _endOrLength);
  }

  Iterable<E> take(int count) {
    RangeError.checkNotNegative(count, "count");
    int? endOrLength = _endOrLength;
    if (endOrLength == null) {
      return SubListIterable<E>(_iterable, _start, _start + count);
    } else {
      int newEnd = _start + count;
      if (endOrLength < newEnd) return this;
      return SubListIterable<E>(_iterable, _start, newEnd);
    }
  }

  List<E> toList({bool growable = true}) {
    int start = _start;
    int end = _iterable.length;
    int? endOrLength = _endOrLength;
    if (endOrLength != null && endOrLength < end) end = endOrLength;
    int length = end - start;
    if (length <= 0) return List<E>.empty(growable: growable);

    List<E> result =
        List<E>.filled(length, _iterable.elementAt(start), growable: growable);
    for (int i = 1; i < length; i++) {
      result[i] = _iterable.elementAt(start + i);
      if (_iterable.length < end) throw ConcurrentModificationError(this);
    }
    return result;
  }
}

/**
 * An [Iterator] that iterates a list-like [Iterable].
 *
 * All iterations is done in terms of [Iterable.length] and
 * [Iterable.elementAt]. These operations are fast for list-like
 * iterables.
 */
class ListIterator<E> implements Iterator<E> {
  final Iterable<E> _iterable;
  final int _length;
  int _index;
  E? _current;

  ListIterator(Iterable<E> iterable)
      : _iterable = iterable,
        _length = iterable.length,
        _index = 0;

  E get current => _current as E;

  @pragma("vm:prefer-inline")
  bool moveNext() {
    int length = _iterable.length;
    if (_length != length) {
      throw ConcurrentModificationError(_iterable);
    }
    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable.elementAt(_index);
    _index++;
    return true;
  }
}

typedef T _Transformation<S, T>(S value);

class MappedIterable<S, T> extends Iterable<T> {
  final Iterable<S> _iterable;
  final _Transformation<S, T> _f;

  factory MappedIterable(Iterable<S> iterable, T function(S value)) {
    if (iterable is EfficientLengthIterable) {
      return EfficientLengthMappedIterable<S, T>(iterable, function);
    }
    return MappedIterable<S, T>._(iterable, function);
  }

  MappedIterable._(this._iterable, this._f);

  Iterator<T> get iterator => MappedIterator<S, T>(_iterable.iterator, _f);

  // Length related functions are independent of the mapping.
  int get length => _iterable.length;
  bool get isEmpty => _iterable.isEmpty;

  // Index based lookup can be done before transforming.
  T get first => _f(_iterable.first);
  T get last => _f(_iterable.last);
  T get single => _f(_iterable.single);
  T elementAt(int index) => _f(_iterable.elementAt(index));
}

class EfficientLengthMappedIterable<S, T> extends MappedIterable<S, T>
    implements EfficientLengthIterable<T>, HideEfficientLengthIterable<T> {
  EfficientLengthMappedIterable(Iterable<S> iterable, T function(S value))
      : super._(iterable, function);
}

class MappedIterator<S, T> implements Iterator<T> {
  T? _current;
  final Iterator<S> _iterator;
  final _Transformation<S, T> _f;

  MappedIterator(this._iterator, this._f);

  bool moveNext() {
    if (_iterator.moveNext()) {
      _current = _f(_iterator.current);
      return true;
    }
    _current = null;
    return false;
  }

  T get current => _current as T;
}

/**
 * Specialized alternative to [MappedIterable] for mapped [List]s.
 *
 * Expects efficient `length` and `elementAt` on the source iterable.
 */
base class MappedListIterable<S, T> extends ListIterable<T> {
  final Iterable<S> _source;
  final _Transformation<S, T> _f;

  MappedListIterable(this._source, this._f);

  int get length => _source.length;
  T elementAt(int index) => _f(_source.elementAt(index));
}

typedef bool _ElementPredicate<E>(E element);

class WhereIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final _ElementPredicate<E> _f;

  WhereIterable(this._iterable, this._f);

  Iterator<E> get iterator => WhereIterator<E>(_iterable.iterator, _f);

  // Specialization of [Iterable.map] to non-EfficientLengthIterable.
  Iterable<T> map<T>(T toElement(E element)) =>
      MappedIterable<E, T>._(this, toElement);
}

class WhereIterator<E> implements Iterator<E> {
  final Iterator<E> _iterator;
  final _ElementPredicate<E> _f;

  WhereIterator(this._iterator, this._f);

  bool moveNext() {
    while (_iterator.moveNext()) {
      if (_f(_iterator.current)) {
        return true;
      }
    }
    return false;
  }

  E get current => _iterator.current;
}

typedef Iterable<T> _ExpandFunction<S, T>(S sourceElement);

class ExpandIterable<S, T> extends Iterable<T> {
  final Iterable<S> _iterable;
  final _ExpandFunction<S, T> _f;

  ExpandIterable(this._iterable, this._f);

  Iterator<T> get iterator => ExpandIterator<S, T>(_iterable.iterator, _f);
}

class ExpandIterator<S, T> implements Iterator<T> {
  final Iterator<S> _iterator;
  final _ExpandFunction<S, T> _f;
  // Initialize _currentExpansion to an empty iterable. A null value
  // marks the end of iteration, and we don't want to call _f before
  // the first moveNext call.
  Iterator<T>? _currentExpansion = const EmptyIterator<Never>();
  T? _current;

  ExpandIterator(this._iterator, this._f);

  T get current => _current as T;

  bool moveNext() {
    if (_currentExpansion == null) return false;
    while (!_currentExpansion!.moveNext()) {
      _current = null;
      if (_iterator.moveNext()) {
        // If _f throws, this ends iteration. Otherwise _currentExpansion and
        // _current will be set again below.
        _currentExpansion = null;
        _currentExpansion = _f(_iterator.current).iterator;
      } else {
        return false;
      }
    }
    _current = _currentExpansion!.current;
    return true;
  }
}

class TakeIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final int _takeCount;

  factory TakeIterable(Iterable<E> iterable, int takeCount) {
    ArgumentError.checkNotNull(takeCount, "takeCount");
    RangeError.checkNotNegative(takeCount, "takeCount");
    if (iterable is EfficientLengthIterable) {
      return EfficientLengthTakeIterable<E>(iterable, takeCount);
    }
    return TakeIterable<E>._(iterable, takeCount);
  }

  TakeIterable._(this._iterable, this._takeCount);

  Iterator<E> get iterator {
    return TakeIterator<E>(_iterable.iterator, _takeCount);
  }
}

class EfficientLengthTakeIterable<E> extends TakeIterable<E>
    implements EfficientLengthIterable<E>, HideEfficientLengthIterable<E> {
  EfficientLengthTakeIterable(Iterable<E> iterable, int takeCount)
      : super._(iterable, takeCount);

  int get length {
    int iterableLength = _iterable.length;
    if (iterableLength > _takeCount) return _takeCount;
    return iterableLength;
  }
}

class TakeIterator<E> implements Iterator<E> {
  final Iterator<E> _iterator;
  int _remaining;

  TakeIterator(this._iterator, this._remaining) {
    assert(_remaining >= 0);
  }

  bool moveNext() {
    _remaining--;
    if (_remaining >= 0) {
      return _iterator.moveNext();
    }
    _remaining = -1;
    return false;
  }

  E get current {
    // Before NNBD, this returned null when iteration was complete. In order to
    // avoid a hard breaking change, we return "null as E" in that case so that
    // if strong checking is not enabled or E is nullable, the existing
    // behavior is preserved.
    if (_remaining < 0) return null as E;
    return _iterator.current;
  }
}

class TakeWhileIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final _ElementPredicate<E> _f;

  TakeWhileIterable(this._iterable, this._f);

  Iterator<E> get iterator {
    return TakeWhileIterator<E>(_iterable.iterator, _f);
  }
}

class TakeWhileIterator<E> implements Iterator<E> {
  final Iterator<E> _iterator;
  final _ElementPredicate<E> _f;
  bool _isFinished = false;

  TakeWhileIterator(this._iterator, this._f);

  bool moveNext() {
    if (_isFinished) return false;
    if (!_iterator.moveNext() || !_f(_iterator.current)) {
      _isFinished = true;
      return false;
    }
    return true;
  }

  E get current {
    if (_isFinished) return null as E;
    return _iterator.current;
  }
}

class SkipIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final int _skipCount;

  factory SkipIterable(Iterable<E> iterable, int count) {
    if (iterable is EfficientLengthIterable) {
      return EfficientLengthSkipIterable<E>(iterable, count);
    }
    return SkipIterable<E>._(iterable, _checkCount(count));
  }

  SkipIterable._(this._iterable, this._skipCount);

  Iterable<E> skip(int count) {
    return SkipIterable<E>._(_iterable, _skipCount + _checkCount(count));
  }

  Iterator<E> get iterator {
    return SkipIterator<E>(_iterable.iterator, _skipCount);
  }
}

class EfficientLengthSkipIterable<E> extends SkipIterable<E>
    implements EfficientLengthIterable<E>, HideEfficientLengthIterable<E> {
  factory EfficientLengthSkipIterable(Iterable<E> iterable, int count) {
    return EfficientLengthSkipIterable<E>._(iterable, _checkCount(count));
  }

  EfficientLengthSkipIterable._(Iterable<E> iterable, int count)
      : super._(iterable, count);

  int get length {
    int length = _iterable.length - _skipCount;
    if (length >= 0) return length;
    return 0;
  }

  Iterable<E> skip(int count) {
    return EfficientLengthSkipIterable<E>._(
        _iterable, _skipCount + _checkCount(count));
  }
}

int _checkCount(int count) {
  ArgumentError.checkNotNull(count, "count");
  RangeError.checkNotNegative(count, "count");
  return count;
}

class SkipIterator<E> implements Iterator<E> {
  final Iterator<E> _iterator;
  int _skipCount;

  SkipIterator(this._iterator, this._skipCount) {
    assert(_skipCount >= 0);
  }

  bool moveNext() {
    for (int i = 0; i < _skipCount; i++) _iterator.moveNext();
    _skipCount = 0;
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}

class SkipWhileIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final _ElementPredicate<E> _f;

  SkipWhileIterable(this._iterable, this._f);

  Iterator<E> get iterator {
    return SkipWhileIterator<E>(_iterable.iterator, _f);
  }
}

class SkipWhileIterator<E> implements Iterator<E> {
  final Iterator<E> _iterator;
  final _ElementPredicate<E> _f;
  bool _hasSkipped = false;

  SkipWhileIterator(this._iterator, this._f);

  bool moveNext() {
    if (!_hasSkipped) {
      _hasSkipped = true;
      while (_iterator.moveNext()) {
        if (!_f(_iterator.current)) return true;
      }
    }
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}

/**
 * The always empty [Iterable].
 */
class EmptyIterable<E> extends EfficientLengthIterable<E>
    implements HideEfficientLengthIterable<E> {
  const EmptyIterable();

  Iterator<E> get iterator => const EmptyIterator<Never>();

  void forEach(void action(E element)) {}

  bool get isEmpty => true;

  int get length => 0;

  E get first {
    throw IterableElementError.noElement();
  }

  E get last {
    throw IterableElementError.noElement();
  }

  E get single {
    throw IterableElementError.noElement();
  }

  E elementAt(int index) {
    throw RangeError.range(index, 0, 0, "index");
  }

  bool contains(Object? element) => false;

  bool every(bool test(E element)) => true;

  bool any(bool test(E element)) => false;

  E firstWhere(bool test(E element), {E Function()? orElse}) {
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E element), {E Function()? orElse}) {
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E element), {E Function()? orElse}) {
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  String join([String separator = ""]) => "";

  Iterable<E> where(bool test(E element)) => this;

  Iterable<T> map<T>(T toElement(E element)) => EmptyIterable<T>();

  E reduce(E combine(E value, E element)) {
    throw IterableElementError.noElement();
  }

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    return initialValue;
  }

  Iterable<E> skip(int count) {
    RangeError.checkNotNegative(count, "count");
    return this;
  }

  Iterable<E> skipWhile(bool test(E element)) => this;

  Iterable<E> take(int count) {
    RangeError.checkNotNegative(count, "count");
    return this;
  }

  Iterable<E> takeWhile(bool test(E element)) => this;

  List<E> toList({bool growable = true}) => List<E>.empty(growable: growable);

  Set<E> toSet() => Set<E>();
}

/** The always empty iterator. */
class EmptyIterator<E> implements Iterator<E> {
  const EmptyIterator();
  bool moveNext() => false;
  E get current {
    throw IterableElementError.noElement();
  }
}

class FollowedByIterable<E> extends Iterable<E> {
  final Iterable<E> _first;
  final Iterable<E> _second;
  FollowedByIterable(this._first, this._second);

  factory FollowedByIterable.firstEfficient(
      EfficientLengthIterable<E> first, Iterable<E> second) {
    if (second is EfficientLengthIterable<E>) {
      return EfficientLengthFollowedByIterable<E>(first, second);
    }
    return FollowedByIterable<E>(first, second);
  }

  Iterator<E> get iterator => FollowedByIterator(_first, _second);

  int get length => _first.length + _second.length;
  bool get isEmpty => _first.isEmpty && _second.isEmpty;
  bool get isNotEmpty => _first.isNotEmpty || _second.isNotEmpty;

  // May be more efficient if either iterable is a Set.
  bool contains(Object? value) =>
      _first.contains(value) || _second.contains(value);

  E get first {
    var iterator = _first.iterator;
    if (iterator.moveNext()) return iterator.current;
    return _second.first;
  }

  E get last {
    var iterator = _second.iterator;
    if (iterator.moveNext()) {
      E last = iterator.current;
      while (iterator.moveNext()) last = iterator.current;
      return last;
    }
    return _first.last;
  }

  // If linear sequences of `followedBy` becomes an issue, we can flatten
  // into a list of iterables instead of a tree or spine.
}

class EfficientLengthFollowedByIterable<E> extends FollowedByIterable<E>
    implements EfficientLengthIterable<E>, HideEfficientLengthIterable<E> {
  EfficientLengthFollowedByIterable(
      EfficientLengthIterable<E> first, EfficientLengthIterable<E> second)
      : super(first, second);

  E elementAt(int index) {
    int firstLength = _first.length;
    if (index < firstLength) return _first.elementAt(index);
    return _second.elementAt(index - firstLength);
  }

  E get first {
    if (_first.isNotEmpty) return _first.first;
    return _second.first;
  }

  E get last {
    if (_second.isNotEmpty) return _second.last;
    return _first.last;
  }
}

class FollowedByIterator<E> implements Iterator<E> {
  Iterator<E> _currentIterator;
  Iterable<E>? _nextIterable;

  FollowedByIterator(Iterable<E> first, this._nextIterable)
      : _currentIterator = first.iterator;

  bool moveNext() {
    if (_currentIterator.moveNext()) return true;
    if (_nextIterable != null) {
      _currentIterator = _nextIterable!.iterator;
      _nextIterable = null;
      return _currentIterator.moveNext();
    }
    return false;
  }

  E get current => _currentIterator.current;
}

class WhereTypeIterable<T> extends Iterable<T> {
  final Iterable<Object?> _source;
  WhereTypeIterable(this._source);
  Iterator<T> get iterator => WhereTypeIterator<T>(_source.iterator);
}

class WhereTypeIterator<T> implements Iterator<T> {
  final Iterator<Object?> _source;
  WhereTypeIterator(this._source);
  bool moveNext() {
    while (_source.moveNext()) {
      if (_source.current is T) return true;
    }
    return false;
  }

  T get current => _source.current as T;
}

/// Implementation of [NullableIterableExtensions.nonNulls].
///
/// A filtering iterable, so it doesn't have efficient length
/// and cannot forward most methods to the underlying [_source].
class NonNullsIterable<T extends Object> extends Iterable<T> {
  final Iterable<T?> _source;
  NonNullsIterable(this._source);

  T? get _firstNonNull {
    for (var element in _source) {
      if (element != null) return element;
    }
    return null;
  }

  bool get isEmpty => _firstNonNull == null;
  bool get isNotEmpty => _firstNonNull != null;
  T get first => _firstNonNull ?? (throw IterableElementError.noElement());

  Iterator<T> get iterator => NonNullsIterator<T>(_source.iterator);
}

class NonNullsIterator<T extends Object> implements Iterator<T> {
  final Iterator<T?> _source;
  T? _current;

  NonNullsIterator(this._source);

  bool moveNext() {
    _current = null;
    while (_source.moveNext()) {
      var next = _source.current;
      if (next != null) {
        _current = next;
        return true;
      }
    }
    return false;
  }

  T get current => _current ?? (throw IterableElementError.noElement());
}

/// Implementation of [IterableExtensions.indexed].
///
/// Maps elements of [_source] one-to-one to record values,
/// so has the same length as the original, and can define many
/// operations in terms of the underlying source.
class IndexedIterable<T> extends Iterable<(int, T)> {
  final Iterable<T> _source;

  /// Offset applied to indices.
  ///
  /// Used to implement `skip` efficiently for iterables which can skip
  /// efficiently.
  final int _start;

  @pragma('vm:prefer-inline')
  factory IndexedIterable(Iterable<T> source, int start) {
    if (source is EfficientLengthIterable) {
      return EfficientLengthIndexedIterable(source, start);
    }
    return IndexedIterable._(source, start);
  }

  IndexedIterable.nonEfficientLength(Iterable<T> source, int start)
      : this._(source, start);

  IndexedIterable._(this._source, this._start);

  int get length => _source.length;
  bool get isEmpty => _source.isEmpty;
  bool get isNotEmpty => _source.isNotEmpty;

  (int, T) get first => (_start, _source.first);
  (int, T) get single => (_start, _source.single);
  (int, T) elementAt(int index) => (index + _start, _source.elementAt(index));

  bool contains(Object? element) {
    if (element case (int index, Object? other) when index >= _start) {
      // Try to find the `index`th element without looking at the
      // intermediate values, and without throwing if there are fewer.
      var unbiasedIndex = index - _start;
      var iterator = _source.skip(unbiasedIndex).iterator;
      return iterator.moveNext() && iterator.current == other;
    }
    return false;
  }

  Iterable<(int, T)> take(int count) => IndexedIterable<T>.nonEfficientLength(
      _source.take(_checkCount(count)), _start);

  Iterable<(int, T)> skip(int count) => IndexedIterable<T>.nonEfficientLength(
      _source.skip(_checkCount(count)), count + _start);

  @pragma('vm:prefer-inline')
  Iterator<(int, T)> get iterator =>
      IndexedIterator<T>(_source.iterator, _start);
}

class EfficientLengthIndexedIterable<T> extends IndexedIterable<T>
    implements
        EfficientLengthIterable<(int, T)>,
        HideEfficientLengthIterable<(int, T)> {
  EfficientLengthIndexedIterable(super._source, super._start) : super._();

  (int, T) get last {
    var length = _source.length;
    if (length <= 0) throw IterableElementError.noElement();
    var last = _source.last;
    if (length != this.length) {
      throw ConcurrentModificationError(this);
    }
    return (length - 1 + _start, last);
  }

  bool contains(Object? element) {
    if (element case (int index, Object? other) when index >= _start) {
      var unbiasedIndex = index - _start;
      return unbiasedIndex < _source.length &&
          _source.elementAt(unbiasedIndex) == other;
    }
    return false;
  }

  Iterable<(int, T)> take(int count) => EfficientLengthIndexedIterable<T>(
      _source.take(_checkCount(count)), _start);

  Iterable<(int, T)> skip(int count) => EfficientLengthIndexedIterable<T>(
      _source.skip(_checkCount(count)), _start + count);
}

class IndexedIterator<T> implements Iterator<(int, T)> {
  final Iterator<T> _source;
  final int _start;
  int _index = -1;

  IndexedIterator(this._source, this._start);

  bool moveNext() {
    var index = ++_index;
    if (index >= 0 && _source.moveNext()) {
      return true;
    }
    _index = -2; // Ensures moveNext won't get called again.
    return false;
  }

  (int, T) get current => _index >= 0
      ? (_start + _index, _source.current)
      : (throw IterableElementError.noElement());
}

/**
 * Creates errors throw by [Iterable] when the element count is wrong.
 */
abstract class IterableElementError {
  /** Error thrown by, e.g., [Iterable.first] when there is no result. */
  static StateError noElement() => StateError("No element");
  /** Error thrown by, e.g., [Iterable.single] if there are too many results. */
  static StateError tooMany() => StateError("Too many elements");
  /** Error thrown by, e.g., [List.setRange] if there are too few elements. */
  static StateError tooFew() => StateError("Too few elements");
}
