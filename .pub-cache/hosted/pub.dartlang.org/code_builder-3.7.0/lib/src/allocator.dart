// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'specs/directive.dart';
import 'specs/reference.dart';

/// Collects references and automatically allocates prefixes and imports.
///
/// `Allocator` takes out the manual work of deciding whether a symbol will
/// clash with other imports in your generated code, or what imports are needed
/// to resolve all symbols in your generated code.
abstract class Allocator {
  /// An allocator that does not prefix symbols nor collects imports.
  static const Allocator none = _NullAllocator();

  /// Creates a new default allocator that applies no prefixing.
  factory Allocator() = _Allocator;

  /// Creates a new allocator that applies naive prefixing to avoid conflicts.
  ///
  /// This implementation is not optimized for any particular code generation
  /// style and instead takes a conservative approach of prefixing _every_
  /// import except references to `dart:core` (which are considered always
  /// imported).
  ///
  /// The prefixes are not guaranteed to be stable and cannot be expected to
  /// have any particular value.
  factory Allocator.simplePrefixing() = _PrefixedAllocator;

  /// Returns a reference string given a [reference] object.
  ///
  /// For example, a no-op implementation:
  /// ```dart
  /// allocate(const Reference('List', 'dart:core')); // Returns 'List'.
  /// ```
  ///
  /// Where-as an implementation that prefixes imports might output:
  /// ```dart
  /// allocate(const Reference('Foo', 'package:foo')); // Returns '_i1.Foo'.
  /// ```
  String allocate(Reference reference);

  /// All imports that have so far been added implicitly via [allocate].
  Iterable<Directive> get imports;
}

class _Allocator implements Allocator {
  final _imports = <String>{};

  @override
  String allocate(Reference reference) {
    if (reference.url != null) {
      _imports.add(reference.url);
    }
    return reference.symbol;
  }

  @override
  Iterable<Directive> get imports => _imports.map((u) => Directive.import(u));
}

class _NullAllocator implements Allocator {
  const _NullAllocator();

  @override
  String allocate(Reference reference) => reference.symbol;

  @override
  Iterable<Directive> get imports => const [];
}

class _PrefixedAllocator implements Allocator {
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};
  var _keys = 1;

  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol;
    if (reference.url == null || _doNotPrefix.contains(reference.url)) {
      return symbol;
    }
    return '_i${_imports.putIfAbsent(reference.url, _nextKey)}.$symbol';
  }

  int _nextKey() => _keys++;

  @override
  Iterable<Directive> get imports => _imports.keys.map(
        (u) => Directive.import(u, as: '_i${_imports[u]}'),
      );
}
