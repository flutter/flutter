// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
import 'dart:collection';

import 'package:js/js.dart';

/// Create a new identity [Map].
///
/// This cannot be used with classes that override [Object.hashCode] or
/// [Object.==].
///
/// On the web this will be backed by a JavaScript Map, which is more
/// performant if the type of `K` is not a [String], [int], [double], or [bool].
///
/// On Mobile and desktop this returns an identity [HashMap].
Map<K, V> createIdentityMap<K, V>() {
  return _WebMapLike<K, V>();
}

/// Create a new identity [Set].
///
/// This cannot be used with classes that override [Object.hashCode] or
/// [Object.==].
///
/// On the web this will be backed by a JavaScript Set, which is more
/// performant if the type of `V` is not a [String], [int], [double], or [bool].
///
/// On Mobile and desktop this returns an identity [HashMap].
Set<V> createIdentitySet<V>() {
  return _WebSetLike<V>();
}

// Classes required to treat a JavaScript `Map` object as a Dart Map and a JavaScript
// `Set` as a Dart `Set`. This only supports identity hash codes and equality and will
// not work with objects that override either.

@JS('Map')
class _JavaScriptMap {
  external _JavaScriptMap();

  external void set(Object? key, Object? value);

  external Object? get(Object? key);

  external void delete(Object? key);

  external void clear();

  external bool has(Object? key);

  external int size;

  external _JavaScriptKeyIterator keys();
}

@JS('Set')
class _JavaScriptSet {
  external _JavaScriptSet();

  external void add(Object? value);

  external void clear();

  external bool has(Object? value);

  external bool delete(Object? value);

  external _JavaScriptKeyIterator keys();

  external int size;
}

@JS()
@anonymous
class _JavaScriptKeyIterator {
  external _JavaScriptIteratorValue next();
}

@JS()
@anonymous
class _JavaScriptIteratorValue {
  external Object? value;

  external bool done;
}

class _WebSetLike<V> extends SetBase<V> {
  _WebSetLike();

  final _JavaScriptSet _javaScriptSet = _JavaScriptSet();

  @override
  void clear() {
    _javaScriptSet.clear();
  }

  @override
  bool add(V value) {
    if (_javaScriptSet.has(value)) {
      return false;
    }
    _javaScriptSet.add(value);
    return true;
  }

  @override
  bool contains(Object? element) {
    return _javaScriptSet.has(element);
  }

  @override
  Iterator<V> get iterator => _WebSetLikeIterable<V>(_javaScriptSet).iterator;

  @override
  int get length => _javaScriptSet.size;

  @override
  V? lookup(Object? element) {
    // Because this class only supports identity operation, if the set
    // contains the provided element it must be exactly that element.
    if (_javaScriptSet.has(element)) {
      return element as V;
    }
    return null;
  }

  @override
  bool remove(Object? value) {
    return _javaScriptSet.delete(value);
  }

  @override
  Set<V> toSet() {
    final _WebSetLike<V> other = _WebSetLike<V>();
    forEach(other.add);
    return other;
  }
}

class _WebMapLike<K, V> extends MapBase<K, V> {
  _WebMapLike();

  final _JavaScriptMap _javascriptMap = _JavaScriptMap();

  @override
  V? operator[](Object? key) => _javascriptMap.get(key) as V?;

  @override
  void operator[]=(K key, V value) => _javascriptMap.set(key, value);

  @override
  bool get isEmpty => _javascriptMap.size == 0;

  @override
  bool get isNotEmpty => _javascriptMap.size != 0;

  @override
  V? remove(Object? key) {
    final V? value = _javascriptMap.get(key) as V?;
    _javascriptMap.delete(key);
    return value;
  }

  @override
  Iterable<K> get keys {
    return _WebMapLikeIterable<K>(_javascriptMap);
  }

  @override
  void clear() {
    _javascriptMap.clear();
  }
}

class _WebSetLikeIterable<T> extends Iterable<T> {
  _WebSetLikeIterable(this._javascriptSet);

  final _JavaScriptSet _javascriptSet;

  @override
  bool contains(Object? element) {
    return _javascriptSet.has(element);
  }

  @override
  int get length => _javascriptSet.size;

  @override
  Iterator<T> get iterator {
    final _JavaScriptKeyIterator backing = _javascriptSet.keys();
    return _WebMapLikeIterator<T>(backing);
  }
}

class _WebMapLikeIterable<T> extends Iterable<T> {
  _WebMapLikeIterable(this._javascriptMap);

  final _JavaScriptMap _javascriptMap;

  @override
  bool contains(Object? element) {
    return _javascriptMap.has(element);
  }

  @override
  int get length => _javascriptMap.size;

  @override
  Iterator<T> get iterator {
    final _JavaScriptKeyIterator backing = _javascriptMap.keys();
    return _WebMapLikeIterator<T>(backing);
  }
}

class _WebMapLikeIterator<T> extends Iterator<T> {
  _WebMapLikeIterator(this._backing);

  final _JavaScriptKeyIterator _backing;
  late _JavaScriptIteratorValue _value;

  @override
  T get current => _value.value as T;

  @override
  bool moveNext() {
    _value = _backing.next();
    return !_value.done;
  }
}
