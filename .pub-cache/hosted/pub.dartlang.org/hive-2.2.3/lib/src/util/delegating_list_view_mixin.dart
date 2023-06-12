import 'package:meta/meta.dart';

/// Not part of public API
abstract class DelegatingListViewMixin<E> implements List<E> {
  /// Not part of public API
  @protected
  @visibleForTesting
  List<E> get delegate;

  @override
  E get first => delegate.first;

  @override
  E get last => delegate.last;

  @override
  int get length => delegate.length;

  @override
  List<E> operator +(List<E> other) => delegate + other;

  @override
  E operator [](int index) => delegate[index];

  @override
  bool any(bool Function(E element) test) => delegate.any(test);

  @override
  Map<int, E> asMap() => delegate.asMap();

  @override
  List<R> cast<R>() => delegate.cast<R>();

  @override
  bool contains(Object? element) => delegate.contains(element);

  @override
  E elementAt(int index) => delegate.elementAt(index);

  @override
  bool every(bool Function(E element) test) => delegate.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      delegate.expand<T>(f);

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      delegate.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      delegate.fold<T>(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => delegate.followedBy(other);

  @override
  void forEach(void Function(E element) f) => delegate.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) => delegate.getRange(start, end);

  @override
  int indexOf(Object? element, [int start = 0]) =>
      delegate.indexOf(element as E, start);

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      delegate.indexWhere(test, start);

  @override
  bool get isEmpty => delegate.isEmpty;

  @override
  bool get isNotEmpty => delegate.isNotEmpty;

  @override
  Iterator<E> get iterator => delegate.iterator;

  @override
  String join([String separator = '']) => delegate.join(separator);

  @override
  int lastIndexOf(Object? element, [int? start]) =>
      delegate.lastIndexOf(element as E, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) =>
      delegate.lastIndexWhere(test, start);

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      delegate.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E e) f) => delegate.map<T>(f);

  @override
  E reduce(E Function(E value, E element) combine) => delegate.reduce(combine);

  @override
  Iterable<E> get reversed => delegate.reversed;

  @override
  E get single => delegate.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      delegate.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => delegate.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) =>
      delegate.skipWhile(test);

  @override
  List<E> sublist(int start, [int? end]) => delegate.sublist(start, end);

  @override
  Iterable<E> take(int count) => delegate.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) =>
      delegate.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => delegate.toList(growable: growable);

  @override
  Set<E> toSet() => delegate.toSet();

  @override
  Iterable<E> where(bool Function(E element) test) => delegate.where(test);

  @override
  Iterable<T> whereType<T>() => delegate.whereType<T>();
}
