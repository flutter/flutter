// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  useDartfmt();

  test('should create a nullable type in a pre-Null Safety library', () {
    expect(
      TypeReference((b) => b
        ..symbol = 'Foo'
        ..isNullable = true),
      equalsDart(r'''
        Foo
      '''),
    );
  });

  group('in a Null Safety library', () {
    DartEmitter emitter;

    setUp(() => emitter = DartEmitter.scoped(useNullSafetySyntax: true));

    test('should create a nullable type', () {
      expect(
        TypeReference((b) => b
          ..symbol = 'Foo'
          ..isNullable = true),
        equalsDart(r'Foo?', emitter),
      );
    });

    test('should create a non-nullable type', () {
      expect(
        TypeReference((b) => b.symbol = 'Foo'),
        equalsDart(r'Foo', emitter),
      );
    });

    test('should create a type with nullable type arguments', () {
      expect(
        TypeReference((b) => b
          ..symbol = 'List'
          ..types.add(TypeReference((b) => b
            ..symbol = 'int'
            ..isNullable = true))),
        equalsDart(r'List<int?>', emitter),
      );
    });
  });
}
