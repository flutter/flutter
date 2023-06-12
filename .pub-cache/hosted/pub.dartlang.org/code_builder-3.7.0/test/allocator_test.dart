// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  useDartfmt();

  group('Allocator', () {
    Allocator allocator;

    test('should return the exact (non-prefixed) symbol', () {
      allocator = Allocator();
      expect(allocator.allocate(refer('Foo', 'package:foo')), 'Foo');
    });

    test('should collect import URLs', () {
      allocator = Allocator()
        ..allocate(refer('List', 'dart:core'))
        ..allocate(refer('LinkedHashMap', 'dart:collection'))
        ..allocate(refer('someSymbol'));
      expect(allocator.imports.map((d) => d.url), [
        'dart:core',
        'dart:collection',
      ]);
    });

    test('.none should do nothing', () {
      allocator = Allocator.none;
      expect(allocator.allocate(refer('Foo', 'package:foo')), 'Foo');
      expect(allocator.imports, isEmpty);
    });

    test('.simplePrefixing should add import prefixes', () {
      allocator = Allocator.simplePrefixing();
      expect(
        allocator.allocate(refer('List', 'dart:core')),
        'List',
      );
      expect(
        allocator.allocate(refer('LinkedHashMap', 'dart:collection')),
        '_i1.LinkedHashMap',
      );
      expect(allocator.imports.map((d) => '${d.url} as ${d.as}'), [
        'dart:collection as _i1',
      ]);
    });
  });
}
