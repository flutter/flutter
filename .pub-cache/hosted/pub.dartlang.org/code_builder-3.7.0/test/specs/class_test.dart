// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  useDartfmt();

  test('should create a class', () {
    expect(
      Class((b) => b..name = 'Foo'),
      equalsDart(r'''
        class Foo {}
      '''),
    );
  });

  test('should create an abstract class', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..abstract = true),
      equalsDart(r'''
        abstract class Foo {}
      '''),
    );
  });

  test('should create a class with documentations', () {
    expect(
      Class(
        (b) => b
          ..name = 'Foo'
          ..docs.addAll(
            const [
              '/// My favorite class.',
            ],
          ),
      ),
      equalsDart(r'''
        /// My favorite class.
        class Foo {}
      '''),
    );
  });

  test('should create a class with annotations', () {
    expect(
      Class(
        (b) => b
          ..name = 'Foo'
          ..annotations.addAll([
            refer('deprecated'),
            refer('Deprecated').call([literalString('This is an old class')])
          ]),
      ),
      equalsDart(r'''
        @deprecated
        @Deprecated('This is an old class')
        class Foo {}
      '''),
    );
  });

  test('should create a class with a generic type', () {
    expect(
      Class((b) => b
        ..name = 'List'
        ..types.add(refer('T'))),
      equalsDart(r'''
        class List<T> {}
      '''),
    );
  });

  test('should create a class with multiple generic types', () {
    expect(
      Class(
        (b) => b
          ..name = 'Map'
          ..types.addAll([
            refer('K'),
            refer('V'),
          ]),
      ),
      equalsDart(r'''
        class Map<K, V> {}
      '''),
    );
  });

  test('should create a class with a bound generic type', () {
    expect(
      Class((b) => b
        ..name = 'Comparable'
        ..types.add(TypeReference((b) => b
          ..symbol = 'T'
          ..bound = TypeReference((b) => b
            ..symbol = 'Comparable'
            ..types.add(refer('T').type))))),
      equalsDart(r'''
        class Comparable<T extends Comparable<T>> {}
      '''),
    );
  });

  test('should create a class extending another class', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..extend = TypeReference((b) => b.symbol = 'Bar')),
      equalsDart(r'''
        class Foo extends Bar {}
      '''),
    );
  });

  test('should create a class mixing in another class', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..extend = TypeReference((b) => b.symbol = 'Bar')
        ..mixins.add(TypeReference((b) => b.symbol = 'Foo'))),
      equalsDart(r'''
        class Foo extends Bar with Foo {}
      '''),
    );
  });

  test('should create a class implementing another class', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..extend = TypeReference((b) => b.symbol = 'Bar')
        ..implements.add(TypeReference((b) => b.symbol = 'Foo'))),
      equalsDart(r'''
        class Foo extends Bar implements Foo {}
      '''),
    );
  });

  test('should create a class with a constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor())),
      equalsDart(r'''
        class Foo {
          Foo();
        }
      '''),
    );
  });

  test('should create a class with a constructor with initializers', () {
    expect(
      Class(
        (b) => b
          ..name = 'Foo'
          ..constructors.add(
            Constructor(
              (b) => b
                ..initializers.addAll([
                  const Code('a = 5'),
                  const Code('super()'),
                ]),
            ),
          ),
      ),
      equalsDart(r'''
        class Foo {
          Foo() : a = 5, super();
        }
      '''),
    );
  });

  test('should create a class with a annotated constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors
            .add(Constructor((b) => b..annotations.add(refer('deprecated'))))),
      equalsDart(r'''
        class Foo {
          @deprecated
          Foo();
        }
      '''),
    );
  });

  test('should create a class with a named constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b..name = 'named'))),
      equalsDart(r'''
        class Foo {
          Foo.named();
        }
      '''),
    );
  });

  test('should create a class with a const constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b..constant = true))),
      equalsDart(r'''
        class Foo {
          const Foo();
        }
      '''),
    );
  });

  test('should create a class with an external constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b..external = true))),
      equalsDart(r'''
        class Foo {
          external Foo();
        }
      '''),
    );
  });

  test('should create a class with a factory constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b
          ..factory = true
          ..redirect = refer('_Foo')))),
      equalsDart(r'''
        class Foo {
          factory Foo() = _Foo;
        }
      '''),
    );
  });

  test('should create a class with a const factory constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b
          ..factory = true
          ..constant = true
          ..redirect = refer('_Foo')))),
      equalsDart(r'''
        class Foo {
          const factory Foo() = _Foo;
        }
      '''),
    );
  });

  test('should create a class with a factory lambda constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b
          ..factory = true
          ..lambda = true
          ..body = const Code('_Foo()')))),
      equalsDart(r'''
        class Foo {
          factory Foo() => _Foo();
        }
      '''),
    );
  });

  test('should create a class with an implicit factory lambda constructor', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b
          ..factory = true
          ..body = refer('_Foo').newInstance([]).code))),
      equalsDart(r'''
        class Foo {
          factory Foo() => _Foo();
        }
      '''),
    );
  });

  test('should create a class with a constructor with a body', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b
          ..factory = true
          ..body = const Code('return _Foo();')))),
      equalsDart(r'''
        class Foo {
          factory Foo() {
            return _Foo();
          }
        }
      '''),
    );
  });

  test('should create a class with method parameters', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b
          ..requiredParameters.addAll([
            Parameter((b) => b..name = 'a'),
            Parameter((b) => b..name = 'b'),
          ])
          ..optionalParameters.addAll([
            Parameter((b) => b
              ..name = 'c'
              ..named = true),
          ])))),
      equalsDart(r'''
        class Foo {
          Foo(a, b, {c});
        }
      '''),
    );
  });

  test('should create a class with a constructor+field-formal parameters', () {
    expect(
      Class((b) => b
        ..name = 'Foo'
        ..constructors.add(Constructor((b) => b
          ..requiredParameters.addAll([
            Parameter((b) => b
              ..name = 'a'
              ..toThis = true),
            Parameter((b) => b
              ..name = 'b'
              ..toThis = true),
          ])
          ..optionalParameters.addAll([
            Parameter((b) => b
              ..name = 'c'
              ..named = true
              ..toThis = true),
          ])))),
      equalsDart(r'''
        class Foo {
          Foo(this.a, this.b, {this.c});
        }
      '''),
    );
  });
}
