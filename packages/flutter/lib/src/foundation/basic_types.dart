// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dart:ui';
///
/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/rendering.dart';
library;

import 'dart:collection';

// COMMON SIGNATURES

/// Signature for callbacks that report that an underlying value has changed.
///
/// See also:
///
///  * [ValueSetter], for callbacks that report that a value has been set.
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

/// The two cardinal directions in two dimensions.
///
/// The axis is always relative to the current coordinate space. This means, for
/// example, that a [horizontal] axis might actually be diagonally from top
/// right to bottom left, due to some local [Transform] applied to the scene.
///
/// See also:
///
///  * [AxisDirection], which is a directional version of this enum (with values
///    like left and right, rather than just horizontal).
///  * [TextDirection], which disambiguates between left-to-right horizontal
///    content and right-to-left horizontal content.
enum Axis {
  /// Left and right.
  ///
  /// See also:
  ///
  ///  * [TextDirection], which disambiguates between left-to-right horizontal
  ///    content and right-to-left horizontal content.
  horizontal,

  /// Up and down.
  vertical,
}

/// A direction in which boxes flow vertically.
///
/// This is used by the flex algorithm (e.g. [Column]) to decide in which
/// direction to draw boxes.
///
/// This is also used to disambiguate `start` and `end` values (e.g.
/// [MainAxisAlignment.start] or [CrossAxisAlignment.end]).
///
/// See also:
///
///  * [TextDirection], which controls the same thing but horizontally.
enum VerticalDirection {
  /// Boxes should start at the bottom and be stacked vertically towards the top.
  ///
  /// The "start" is at the bottom, the "end" is at the top.
  up,

  /// Boxes should start at the top and be stacked vertically towards the bottom.
  ///
  /// The "start" is at the top, the "end" is at the bottom.
  down,
}

/// A direction along either the horizontal or vertical [Axis] in which the
/// origin, or zero position, is determined.
///
/// This value relates to the direction in which the scroll offset increases
/// from the origin. This value does not represent the direction of user input
/// that may be modifying the scroll offset, such as from a drag. For the
/// active scrolling direction, see [ScrollDirection].
///
/// {@tool dartpad}
/// This sample shows a [CustomScrollView], with [Radio] buttons in the
/// [AppBar.bottom] that change the [AxisDirection] to illustrate different
/// configurations.
///
/// ** See code in examples/api/lib/painting/axis_direction/axis_direction.0.dart **
/// {@end-tool}
///
/// See also:
///
///   * [ScrollDirection], the direction of active scrolling, relative to the positive
///     scroll offset axis given by an [AxisDirection] and a [GrowthDirection].
///   * [GrowthDirection], the direction in which slivers and their content are
///     ordered, relative to the scroll offset axis as specified by
///     [AxisDirection].
///   * [CustomScrollView.anchor], the relative position of the zero scroll
///     offset in a viewport and inflection point for [AxisDirection]s of the
///     same cardinal [Axis].
///   * [axisDirectionIsReversed], which returns whether traveling along the
///     given axis direction visits coordinates along that axis in numerically
///     decreasing order.
enum AxisDirection {
  /// A direction in the [Axis.vertical] where zero is at the bottom and
  /// positive values are above it: `⇈`
  ///
  /// Alphabetical content with a [GrowthDirection.forward] would have the A at
  /// the bottom and the Z at the top.
  ///
  /// For example, the behavior of a [ListView] with [ListView.reverse] set to
  /// true would have this axis direction.
  ///
  /// See also:
  ///
  ///   * [axisDirectionIsReversed], which returns whether traveling along the
  ///     given axis direction visits coordinates along that axis in numerically
  ///     decreasing order.
  up,

  /// A direction in the [Axis.horizontal] where zero is on the left and
  /// positive values are to the right of it: `⇉`
  ///
  /// Alphabetical content with a [GrowthDirection.forward] would have the A on
  /// the left and the Z on the right. This is the ordinary reading order for a
  /// horizontal set of tabs in an English application, for example.
  ///
  /// For example, the behavior of a [ListView] with [ListView.scrollDirection]
  /// set to [Axis.horizontal] would have this axis direction.
  ///
  /// See also:
  ///
  ///   * [axisDirectionIsReversed], which returns whether traveling along the
  ///     given axis direction visits coordinates along that axis in numerically
  ///     decreasing order.
  right,

  /// A direction in the [Axis.vertical] where zero is at the top and positive
  /// values are below it: `⇊`
  ///
  /// Alphabetical content with a [GrowthDirection.forward] would have the A at
  /// the top and the Z at the bottom. This is the ordinary reading order for a
  /// vertical list.
  ///
  /// For example, the default behavior of a [ListView] would have this axis
  /// direction.
  ///
  /// See also:
  ///
  ///   * [axisDirectionIsReversed], which returns whether traveling along the
  ///     given axis direction visits coordinates along that axis in numerically
  ///     decreasing order.
  down,

  /// A direction in the [Axis.horizontal] where zero is to the right and
  /// positive values are to the left of it: `⇇`
  ///
  /// Alphabetical content with a [GrowthDirection.forward] would have the A at
  /// the right and the Z at the left. This is the ordinary reading order for a
  /// horizontal set of tabs in a Hebrew application, for example.
  ///
  /// For example, the behavior of a [ListView] with [ListView.scrollDirection]
  /// set to [Axis.horizontal] and [ListView.reverse] set to true would have
  /// this axis direction.
  ///
  /// See also:
  ///
  ///   * [axisDirectionIsReversed], which returns whether traveling along the
  ///     given axis direction visits coordinates along that axis in numerically
  ///     decreasing order.
  left,
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
///  * The [length] and [toList] properties immediately pre-cache the
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
  /// Creates a [CachingIterable] using the given [Iterator] as the source of
  /// data. The iterator must not throw exceptions.
  ///
  /// Since the argument is an [Iterator], not an [Iterable], it is
  /// guaranteed that the underlying data set will only be walked
  /// once. If you have an [Iterable], you can pass its [iterator]
  /// field as the argument to this constructor.
  ///
  /// You can this with an existing `sync*` function as follows:
  ///
  /// ```dart
  /// Iterable<int> range(int start, int end) sync* {
  ///   for (int index = start; index <= end; index += 1) {
  ///     yield index;
  ///   }
  /// }
  ///
  /// Iterable<int> i = CachingIterable<int>(range(1, 5).iterator);
  /// print(i.length); // walks the list
  /// print(i.length); // efficient
  /// ```
  ///
  /// Beware that this will eagerly evaluate the `range` iterable, and because
  /// of that it would be better to just implement `range` as something that
  /// returns a `List` to begin with if possible.
  CachingIterable(this._prefillIterator);

  final Iterator<E> _prefillIterator;
  final List<E> _results = <E>[];

  @override
  Iterator<E> get iterator {
    return _LazyListIterator<E>(this);
  }

  @override
  Iterable<T> map<T>(T Function(E e) toElement) {
    return CachingIterable<T>(super.map<T>(toElement).iterator);
  }

  @override
  Iterable<E> where(bool Function(E element) test) {
    return CachingIterable<E>(super.where(test).iterator);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) {
    return CachingIterable<T>(super.expand<T>(toElements).iterator);
  }

  @override
  Iterable<E> take(int count) {
    return CachingIterable<E>(super.take(count).iterator);
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) {
    return CachingIterable<E>(super.takeWhile(test).iterator);
  }

  @override
  Iterable<E> skip(int count) {
    return CachingIterable<E>(super.skip(count).iterator);
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) {
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
    return List<E>.of(_results, growable: growable);
  }

  void _precacheEntireList() {
    while (_fillNext()) { }
  }

  bool _fillNext() {
    if (!_prefillIterator.moveNext()) {
      return false;
    }
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
    if (_index < 0 || _index == _owner._results.length) {
      throw StateError('current can not be call after moveNext has returned false');
    }
    return _owner._results[_index];
  }

  @override
  bool moveNext() {
    if (_index >= _owner._results.length) {
      return false;
    }
    _index += 1;
    if (_index == _owner._results.length) {
      return _owner._fillNext();
    }
    return true;
  }
}

/// A factory interface that also reports the type of the created objects.
class Factory<T> {
  /// Creates a new factory.
  const Factory(this.constructor);

  /// Creates a new object of type T.
  final ValueGetter<T> constructor;

  /// The type of the objects created by this factory.
  Type get type => T;

  @override
  String toString() {
    return 'Factory(type: $type)';
  }
}

/// Linearly interpolate between two `Duration`s.
Duration lerpDuration(Duration a, Duration b, double t) {
  return Duration(
    microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
  );
}
