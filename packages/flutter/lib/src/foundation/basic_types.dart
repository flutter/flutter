// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

// COMMON SIGNATURES

export 'dart:ui' show VoidCallback;

/// Signature for callbacks that report that an underlying value has changed.
///
/// See also [ValueSetter].
typedef ValueChanged<T> = void Function(T value);

/// Signature for callbacks that report that a value has been set.
///
/// This is the same signature as [ValueChanged], but is used when the
/// callback is called even if the underlying value has not changed.
/// For example, service extensions use this callback because they
/// call the callback whenever the extension is called with a
/// value, regardless of whether the given value is new or not.
///
/// See also:
///
///  * [ValueGetter], the getter equivalent of this signature.
///  * [AsyncValueSetter], an asynchronous version of this signature.
typedef ValueSetter<T> = void Function(T value);

/// Signature for callbacks that are to report a value on demand.
///
/// See also:
///
///  * [ValueSetter], the setter equivalent of this signature.
///  * [AsyncValueGetter], an asynchronous version of this signature.
typedef ValueGetter<T> = T Function();

/// Signature for callbacks that filter an iterable.
typedef IterableFilter<T> = Iterable<T> Function(Iterable<T> input);

/// Signature of callbacks that have no arguments and return no data, but that
/// return a [Future] to indicate when their work is complete.
///
/// See also:
///
///  * [VoidCallback], a synchronous version of this signature.
///  * [AsyncValueGetter], a signature for asynchronous getters.
///  * [AsyncValueSetter], a signature for asynchronous setters.
typedef AsyncCallback = Future<void> Function();

/// Signature for callbacks that report that a value has been set and return a
/// [Future] that completes when the value has been saved.
///
/// See also:
///
///  * [ValueSetter], a synchronous version of this signature.
///  * [AsyncValueGetter], the getter equivalent of this signature.
typedef AsyncValueSetter<T> = Future<void> Function(T value);

/// Signature for callbacks that are to asynchronously report a value on demand.
///
/// See also:
///
///  * [ValueGetter], a synchronous version of this signature.
///  * [AsyncValueSetter], the setter equivalent of this signature.
typedef AsyncValueGetter<T> = Future<T> Function();


// BITFIELD

/// The largest SMI value.
///
/// See <https://www.dartlang.org/articles/numeric-computation/#smis-and-mints>
const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;

/// A BitField over an enum (or other class whose values implement "index").
/// Only the first 62 values of the enum can be used as indices.
class BitField<T extends dynamic> {
  /// Creates a bit field of all zeros.
  ///
  /// The given length must be at most 62.
  BitField(this._length)
    : assert(_length <= _smiBits),
      _bits = _allZeros;

  /// Creates a bit field filled with a particular value.
  ///
  /// If the value argument is true, the bits are filled with ones. Otherwise,
  /// the bits are filled with zeros.
  ///
  /// The given length must be at most 62.
  BitField.filled(this._length, bool value)
    : assert(_length <= _smiBits),
      _bits = value ? _allOnes : _allZeros;

  final int _length;
  int _bits;

  static const int _smiBits = 62; // see https://www.dartlang.org/articles/numeric-computation/#smis-and-mints
  static const int _allZeros = 0;
  static const int _allOnes = kMaxUnsignedSMI; // 2^(_kSMIBits+1)-1

  /// Returns whether the bit with the given index is set to one.
  bool operator [](T index) {
    assert(index.index < _length);
    return (_bits & 1 << index.index) > 0;
  }

  /// Sets the bit with the given index to the given value.
  ///
  /// If value is true, the bit with the given index is set to one. Otherwise,
  /// the bit is set to zero.
  void operator []=(T index, bool value) {
    assert(index.index < _length);
    if (value)
      _bits = _bits | (1 << index.index);
    else
      _bits = _bits & ~(1 << index.index);
  }

  /// Sets all the bits to the given value.
  ///
  /// If the value is true, the bits are all set to one. Otherwise, the bits are
  /// all set to zero. Defaults to setting all the bits to zero.
  void reset([ bool value = false ]) {
    _bits = value ? _allOnes : _allZeros;
  }
}


// LAZY CACHING ITERATOR

/// A lazy caching version of [Iterable].
///
/// This iterable is efficient in the following ways:
///
///  * It will not walk the given iterator more than you ask for.
///
///  * If you use it twice (e.g. you check [isNotEmpty], then
///    use [single]), it will only walk the given iterator
///    once. This caching will even work efficiently if you are
///    running two side-by-side iterators on the same iterable.
///
///  * [toList] uses its EfficientLength variant to create its
///    list quickly.
///
/// It is inefficient in the following ways:
///
///  * The first iteration through has caching overhead.
///
///  * It requires more memory than a non-caching iterator.
///
///  * the [length] and [toList] properties immediately precache the
///    entire list. Using these fields therefore loses the laziness of
///    the iterable. However, it still gets cached.
///
/// The caching behavior is propagated to the iterators that are
/// created by [map], [where], [expand], [take], [takeWhile], [skip],
/// and [skipWhile], and is used by the built-in methods that use an
/// iterator like [isNotEmpty] and [single].
///
/// Because a CachingIterable only walks the underlying data once, it
/// cannot be used multiple times with the underlying data changing
/// between each use. You must create a new iterable each time. This
/// also applies to any iterables derived from this one, e.g. as
/// returned by `where`.
class CachingIterable<E> extends IterableBase<E> {
  /// Creates a CachingIterable using the given [Iterator] as the
  /// source of data. The iterator must be non-null and must not throw
  /// exceptions.
  ///
  /// Since the argument is an [Iterator], not an [Iterable], it is
  /// guaranteed that the underlying data set will only be walked
  /// once. If you have an [Iterable], you can pass its [iterator]
  /// field as the argument to this constructor.
  ///
  /// You can use a `sync*` function with this as follows:
  ///
  /// ```dart
  /// Iterable<int> range(int start, int end) sync* {
  ///   for (int index = start; index <= end; index += 1)
  ///     yield index;
  ///  }
  ///
  /// Iterable<int> i = CachingIterable<int>(range(1, 5).iterator);
  /// print(i.length); // walks the list
  /// print(i.length); // efficient
  /// ```
  CachingIterable(this._prefillIterator);

  final Iterator<E> _prefillIterator;
  final List<E> _results = <E>[];

  @override
  Iterator<E> get iterator {
    return _LazyListIterator<E>(this);
  }

  @override
  Iterable<T> map<T>(T f(E e)) {
    return CachingIterable<T>(super.map<T>(f).iterator);
  }

  @override
  Iterable<E> where(bool test(E element)) {
    return CachingIterable<E>(super.where(test).iterator);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> f(E element)) {
    return CachingIterable<T>(super.expand<T>(f).iterator);
  }

  @override
  Iterable<E> take(int count) {
    return CachingIterable<E>(super.take(count).iterator);
  }

  @override
  Iterable<E> takeWhile(bool test(E value)) {
    return CachingIterable<E>(super.takeWhile(test).iterator);
  }

  @override
  Iterable<E> skip(int count) {
    return CachingIterable<E>(super.skip(count).iterator);
  }

  @override
  Iterable<E> skipWhile(bool test(E value)) {
    return CachingIterable<E>(super.skipWhile(test).iterator);
  }

  @override
  int get length {
    _precacheEntireList();
    return _results.length;
  }

  @override
  List<E> toList({ bool growable = true }) {
    _precacheEntireList();
    return List<E>.from(_results, growable: growable);
  }

  void _precacheEntireList() {
    while (_fillNext()) { }
  }

  bool _fillNext() {
    if (!_prefillIterator.moveNext())
      return false;
    _results.add(_prefillIterator.current);
    return true;
  }
}

class _LazyListIterator<E> implements Iterator<E> {
  _LazyListIterator(this._owner) : _index = -1;

  final CachingIterable<E> _owner;
  int _index;

  @override
  E get current {
    assert(_index >= 0); // called "current" before "moveNext()"
    if (_index < 0 || _index == _owner._results.length)
      return null;
    return _owner._results[_index];
  }

  @override
  bool moveNext() {
    if (_index >= _owner._results.length)
      return false;
    _index += 1;
    if (_index == _owner._results.length)
      return _owner._fillNext();
    return true;
  }
}

/// A factory interface that also reports the type of the created objects.
class Factory<T> {
  /// Creates a new factory.
  ///
  /// The `constructor` parameter must not be null.
  const Factory(this.constructor) : assert(constructor != null);

  /// Creates a new object of type T.
  final ValueGetter<T> constructor;

  /// The type of the objects created by this factory.
  Type get type => T;

  @override
  String toString() {
    return 'Factory(type: $type)';
  }
}

