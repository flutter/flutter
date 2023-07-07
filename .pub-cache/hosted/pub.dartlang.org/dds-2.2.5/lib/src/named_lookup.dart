// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Originally pulled from dart:_vmservice.

import 'dart:collection';

/// [Set]-like containers which automatically generate [String] IDs for its
/// items.
class NamedLookup<E> with IterableMixin<E> {
  final IdGenerator _generator;
  final Map<String, E> _elements = {};
  final Map<E, String> _ids = {};

  NamedLookup({String prologue = ''})
      : _generator = IdGenerator(prologue: prologue);

  void add(E e) {
    final id = _generator.newId();
    _elements[id] = e;
    _ids[e] = id;
  }

  void remove(E e) {
    final id = _ids.remove(e)!;
    _elements.remove(id);
    _generator.release(id);
  }

  E? operator [](String id) => _elements[id];

  String? keyOf(E e) => _ids[e];

  Iterator<E> get iterator => _ids.keys.iterator;
}

/// Generator for unique IDs which recycles expired ones.
class IdGenerator {
  /// Fixed initial part of the ID
  final String prologue;

  // IDs in use.
  final Set<String> _used = {};

  /// IDs to be recycled (use these before generate new ones).
  final Set<String> _free = {};

  /// Next ID to generate when no recycled IDs are available.
  int _next = 0;

  IdGenerator({this.prologue = ''});

  /// Returns a new ID (possibly recycled).
  String newId() {
    String id;
    if (_free.isEmpty) {
      id = prologue + (_next++).toString();
    } else {
      id = _free.first;
    }
    _free.remove(id);
    _used.add(id);
    return id;
  }

  /// Releases the ID and mark it for recycling.
  void release(String id) {
    if (_used.remove(id)) {
      _free.add(id);
    }
  }
}
