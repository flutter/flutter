/// A [List] proxy that you can subclass.
library list_proxy;

import 'dart:collection';

abstract class ListProxy<E> extends ListBase<E> {
  /// The inner [List<T>] with the actual storage.
  final List<E> _list = <E>[];

  @override
  bool remove(Object? element) => _list.remove(element);

  @override
  int get length => _list.length;

  // From Iterable
  @override
  Iterator<E> get iterator => _list.iterator;

  // From List
  @override
  E operator [](int index) => _list[index];

  @override
  operator []=(int index, E value) {
    _list[index] = value;
  }

  @override
  set length(int value) {
    _list.length = value;
  }

  @override
  void add(E element) {
    _list.add(element);
  }

  @override
  void insert(int index, E element) => _list.insert(index, element);

  @override
  void addAll(Iterable<E> iterable) {
    _list.addAll(iterable);
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _list.insertAll(index, iterable);
  }

  @override
  E removeAt(int index) => _list.removeAt(index);

  @override
  void removeRange(int start, int end) {
    _list.removeRange(start, end);
  }
}
