// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:code_builder/src/specs/extension.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  useDartfmt();

  test('should create an extension', () {
    expect(
      Extension((b) => b
        ..name = 'Foo'
        ..on = TypeReference((b) => b.symbol = 'Bar')),
      equalsDart(r'''
        extension Foo on Bar {}
      '''),
    );
  });

  test('should create an extension without an identifier', () {
    expect(
      Extension((b) => b..on = TypeReference((b) => b.symbol = 'Bar')),
      equalsDart(r'''
        extension on Bar {}
      '''),
    );
  });

  test('should create an extension with documentation', () {
    expect(
      Extension(
        (b) => b
          ..name = 'Foo'
          ..on = TypeReference((b) => b.symbol = 'Bar')
          ..docs.addAll(
            const [
              '/// My favorite extension.',
            ],
          ),
      ),
      equalsDart(r'''
        /// My favorite extension.
        extension Foo on Bar {}
      '''),
    );
  });

  test('should create an extension with annotations', () {
    expect(
      Extension(
        (b) => b
          ..name = 'Foo'
          ..on = TypeReference((b) => b.symbol = 'Bar')
          ..annotations.addAll([
            refer('deprecated'),
            refer('Deprecated')
                .call([literalString('This is an old extension')])
          ]),
      ),
      equalsDart(r'''
        @deprecated
        @Deprecated('This is an old extension')
        extension Foo on Bar {}
      '''),
    );
  });

  test('should create an extension with a generic type', () {
    expect(
      Extension((b) => b
        ..name = 'Foo'
        ..on = TypeReference((b) => b.symbol = 'Bar')
        ..types.add(refer('T'))),
      equalsDart(r'''
        extension Foo<T> on Bar {}
      '''),
    );
  });

  test('should create an extension with multiple generic types', () {
    expect(
      Extension(
        (b) => b
          ..name = 'Map'
          ..on = TypeReference((b) => b.symbol = 'Bar')
          ..types.addAll([
            refer('K'),
            refer('V'),
          ]),
      ),
      equalsDart(r'''
        extension Map<K, V> on Bar {}
      '''),
    );
  });

  test('should create an extension with a bound generic type', () {
    expect(
      Extension((b) => b
        ..name = 'Foo'
        ..on = TypeReference((b) => b.symbol = 'Bar')
        ..types.add(TypeReference((b) => b
          ..symbol = 'T'
          ..bound = TypeReference((b) => b
            ..symbol = 'Comparable'
            ..types.add(refer('T').type))))),
      equalsDart(r'''
        extension Foo<T extends Comparable<T>> on Bar {}
      '''),
    );
  });

  test('should create an extension with a method', () {
    expect(
      Extension((b) => b
        ..name = 'Foo'
        ..on = TypeReference((b) => b.symbol = 'Bar')
        ..methods.add(Method((b) => b
          ..name = 'parseInt'
          ..returns = refer('int')
          ..body = Code.scope(
            (a) => 'return int.parse(this);',
          )))),
      equalsDart(r'''
        extension Foo on Bar {
          int parseInt() {
            return int.parse(this);
          }
        }
      '''),
    );
  });

  test('should create an extension with a method', () {
    expect(
      Extension((b) => b
        ..name = 'Foo'
        ..on = TypeReference((b) => b.symbol = 'Bar')
        ..methods.add(Method((b) => b
          ..name = 'parseInt'
          ..returns = refer('int')
          ..body = Code.scope(
            (a) => 'return int.parse(this);',
          )))),
      equalsDart(r'''
        extension Foo on Bar {
          int parseInt() {
            return int.parse(this);
          }
        }
      '''),
    );
  });
}
