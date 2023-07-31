/// A [List] proxy that you can subclass.
library list_proxy;

import 'dart:collection';

abstract class ListProxy<E> extends ListBase<E> {
  /// The inner [List<T>] with the actual storage.
  final List<E> _list = <E>[];

  @override
  bool remove(Object? item) => _list.remove(item);

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
  void add(E value) {
    _list.add(value);
  }

  @override
  void insert(int index, E item) => _list.insert(index, item);

  @override
  void addAll(Iterable<E> collection) {
    _list.addAll(collection);
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _list.insertAll(index, iterable);
  }

  @override
  E removeAt(int index) => _list.removeAt(index);

  @override
  void removeRange(int start, int length) {
    _list.removeRange(start, length);
  }
}
