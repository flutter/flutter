// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import '../../common.dart';

void main() {
  useDartfmt();

  test('should emit a simple expression', () {
    expect(literalNull, equalsDart('null'));
  });

  test('should emit a String', () {
    expect(literalString(r'$monkey'), equalsDart(r"'$monkey'"));
  });

  test('should emit a raw String', () {
    expect(literalString(r'$monkey', raw: true), equalsDart(r"r'$monkey'"));
  });

  test('should escape single quotes in a String', () {
    expect(literalString(r"don't"), equalsDart(r"'don\'t'"));
  });

  test('does not allow single quote in raw string', () {
    expect(() => literalString(r"don't", raw: true), throwsArgumentError);
  });

  test('should escape a newline in a string', () {
    expect(literalString('some\nthing'), equalsDart(r"'some\nthing'"));
  });

  test('should emit a && expression', () {
    expect(literalTrue.and(literalFalse), equalsDart('true && false'));
  });

  test('should emit a || expression', () {
    expect(literalTrue.or(literalFalse), equalsDart('true || false'));
  });

  test('should emit a ! expression', () {
    expect(literalTrue.negate(), equalsDart('!true'));
  });

  test('should emit a list', () {
    expect(literalList([]), equalsDart('[]'));
  });

  test('should emit a const list', () {
    expect(literalConstList([]), equalsDart('const []'));
  });

  test('should emit an explicitly typed list', () {
    expect(literalList([], refer('int')), equalsDart('<int>[]'));
  });

  test('should emit a set', () {
    // ignore: prefer_collection_literals
    expect(literalSet(Set()), equalsDart('{}'));
  });

  test('should emit a const set', () {
    // ignore: prefer_collection_literals
    expect(literalConstSet(Set()), equalsDart('const {}'));
  });

  test('should emit an explicitly typed set', () {
    // ignore: prefer_collection_literals
    expect(literalSet(Set(), refer('int')), equalsDart('<int>{}'));
  });

  test('should emit a map', () {
    expect(literalMap({}), equalsDart('{}'));
  });

  test('should emit a const map', () {
    expect(literalConstMap({}), equalsDart('const {}'));
  });

  test('should emit an explicitly typed map', () {
    expect(
      literalMap({}, refer('int'), refer('bool')),
      equalsDart('<int, bool>{}'),
    );
  });

  test('should emit a map of other literals and expressions', () {
    expect(
      literalMap({
        1: 'one',
        2: refer('two'),
        refer('three'): 3,
        refer('Map').newInstance([]): null,
      }),
      equalsDart(r"{1: 'one', 2: two, three: 3, Map(): null}"),
    );
  });

  test('should emit a list of other literals and expressions', () {
    expect(
      literalList([
        <dynamic>[],
        // ignore: prefer_collection_literals
        Set<dynamic>(),
        true,
        null,
        refer('Map').newInstance([])
      ]),
      equalsDart('[[], {}, true, null, Map()]'),
    );
  });

  test('should emit a set of other literals and expressions', () {
    expect(
      // ignore: prefer_collection_literals
      literalSet([
        <dynamic>[],
        // ignore: prefer_collection_literals
        Set<dynamic>(),
        true,
        null,
        refer('Map').newInstance([])
      ]),
      equalsDart('{[], {}, true, null, Map()}'),
    );
  });

  test('should emit a type as an expression', () {
    expect(refer('Map'), equalsDart('Map'));
  });

  test('should emit a scoped type as an expression', () {
    expect(
      refer('Foo', 'package:foo/foo.dart'),
      equalsDart('_i1.Foo', DartEmitter(Allocator.simplePrefixing())),
    );
  });

  test('should emit invoking Type()', () {
    expect(
      refer('Map').newInstance([]),
      equalsDart('Map()'),
    );
  });

  test('should emit invoking named constructor', () {
    expect(
      refer('Foo').newInstanceNamed('bar', []),
      equalsDart('Foo.bar()'),
    );
  });

  test('should emit invoking const Type()', () {
    expect(
      refer('Object').constInstance([]),
      equalsDart('const Object()'),
    );
  });

  test('should emit invoking a property accessor', () {
    expect(refer('foo').property('bar'), equalsDart('foo.bar'));
  });

  test('should emit invoking a cascade property accessor', () {
    expect(refer('foo').cascade('bar'), equalsDart('foo..bar'));
  });

  test('should emit invoking a null safe property accessor', () {
    expect(refer('foo').nullSafeProperty('bar'), equalsDart('foo?.bar'));
  });

  test('should emit invoking a method with a single positional argument', () {
    expect(
      refer('foo').call([
        literal(1),
      ]),
      equalsDart('foo(1)'),
    );
  });

  test('should emit invoking a method with positional arguments', () {
    expect(
      refer('foo').call([
        literal(1),
        literal(2),
        literal(3),
      ]),
      equalsDart('foo(1, 2, 3)'),
    );
  });

  test('should emit invoking a method with a single named argument', () {
    expect(
      refer('foo').call([], {
        'bar': literal(1),
      }),
      equalsDart('foo(bar: 1)'),
    );
  });

  test('should emit invoking a method with named arguments', () {
    expect(
      refer('foo').call([], {
        'bar': literal(1),
        'baz': literal(2),
      }),
      equalsDart('foo(bar: 1, baz: 2)'),
    );
  });

  test('should emit invoking a method with positional and named arguments', () {
    expect(
      refer('foo').call([
        literal(1)
      ], {
        'bar': literal(2),
        'baz': literal(3),
      }),
      equalsDart('foo(1, bar: 2, baz: 3)'),
    );
  });

  test('should emit invoking a method with a single type argument', () {
    expect(
      refer('foo').call(
        [],
        {},
        [
          refer('String'),
        ],
      ),
      equalsDart('foo<String>()'),
    );
  });

  test('should emit invoking a method with type arguments', () {
    expect(
      refer('foo').call(
        [],
        {},
        [
          refer('String'),
          refer('int'),
        ],
      ),
      equalsDart('foo<String, int>()'),
    );
  });

  test('should emit a function type', () {
    expect(
      FunctionType((b) => b.returnType = refer('void')),
      equalsDart('void Function()'),
    );
  });

  test('should emit a typedef statement', () {
    expect(
      FunctionType((b) => b.returnType = refer('void')).toTypeDef('Void0'),
      equalsDart('typedef Void0 = void Function();'),
    );
  });

  test('should emit a function type with type parameters', () {
    expect(
      FunctionType((b) => b
        ..returnType = refer('T')
        ..types.add(refer('T'))),
      equalsDart('T Function<T>()'),
    );
  });

  test('should emit a function type a single parameter', () {
    expect(
      FunctionType((b) => b..requiredParameters.add(refer('String'))),
      equalsDart('Function(String)'),
    );
  });

  test('should emit a function type with parameters', () {
    expect(
      FunctionType((b) => b
        ..requiredParameters.add(refer('String'))
        ..optionalParameters.add(refer('int'))),
      equalsDart('Function(String, [int])'),
    );
  });

  test('should emit a function type with named parameters', () {
    expect(
      FunctionType((b) => b
        ..namedParameters.addAll({
          'x': refer('int'),
          'y': refer('int'),
        })),
      equalsDart('Function({int x, int y})'),
    );
  });

  test('should emit a nullable function type in a Null Safety library', () {
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);
    expect(
      FunctionType((b) => b
        ..requiredParameters.add(refer('String'))
        ..isNullable = true),
      equalsDart('Function(String)?', emitter),
    );
  });

  test('should emit a nullable function type in pre-Null Safety library', () {
    expect(
      FunctionType((b) => b
        ..requiredParameters.add(refer('String'))
        ..isNullable = true),
      equalsDart('Function(String)'),
    );
  });

  test('should emit a non-nullable function type in a Null Safety library', () {
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);
    expect(
      FunctionType((b) => b
        ..requiredParameters.add(refer('String'))
        ..isNullable = false),
      equalsDart('Function(String)', emitter),
    );
  });

  test('should emit a non-nullable function type in pre-Null Safety library',
      () {
    expect(
      FunctionType((b) => b
        ..requiredParameters.add(refer('String'))
        ..isNullable = false),
      equalsDart('Function(String)'),
    );
  });

  test('should emit a closure', () {
    expect(
      refer('map').property('putIfAbsent').call([
        literalString('foo'),
        Method((b) => b..body = literalTrue.code).closure,
      ]),
      equalsDart("map.putIfAbsent('foo', () => true)"),
    );
  });

  test('should emit a generic closure', () {
    expect(
      refer('map').property('putIfAbsent').call([
        literalString('foo'),
        Method((b) => b
          ..types.add(refer('T'))
          ..body = literalTrue.code).genericClosure,
      ]),
      equalsDart("map.putIfAbsent('foo', <T>() => true)"),
    );
  });

  test('should emit an assignment', () {
    expect(
      refer('foo').assign(literalTrue),
      equalsDart('foo = true'),
    );
  });

  test('should emit an if null assignment', () {
    expect(
      refer('foo').ifNullThen(literalTrue),
      equalsDart('foo ?? true'),
    );
  });

  test('should emit an if null index operator set', () {
    expect(
      refer('bar')
          .index(literalTrue)
          .ifNullThen(literalFalse)
          .assignVar('foo')
          .statement,
      equalsDart('var foo = bar[true] ?? false;'),
    );
  });

  test('should emit a null-aware assignment', () {
    expect(
      refer('foo').assignNullAware(literalTrue),
      equalsDart('foo ??= true'),
    );
  });

  test('should emit an index operator', () {
    expect(
      refer('bar').index(literalString('key')).assignVar('foo').statement,
      equalsDart("var foo = bar['key'];"),
    );
  });

  test('should emit an index operator set', () {
    expect(
      refer('bar')
          .index(literalString('key'))
          .assign(literalFalse)
          .assignVar('foo')
          .statement,
      equalsDart("var foo = bar['key'] = false;"),
    );
  });

  test('should emit a null-aware index operator set', () {
    expect(
      refer('bar')
          .index(literalTrue)
          .assignNullAware(literalFalse)
          .assignVar('foo')
          .statement,
      equalsDart('var foo = bar[true] ??= false;'),
    );
  });

  test('should emit assigning to a var', () {
    expect(
      literalTrue.assignVar('foo'),
      equalsDart('var foo = true'),
    );
  });

  test('should emit assigning to a type', () {
    expect(
      literalTrue.assignVar('foo', refer('bool')),
      equalsDart('bool foo = true'),
    );
  });

  test('should emit assigning to a final', () {
    expect(
      literalTrue.assignFinal('foo'),
      equalsDart('final foo = true'),
    );
  });

  test('should emit assigning to a const', () {
    expect(
      literalTrue.assignConst('foo'),
      equalsDart('const foo = true'),
    );
  });

  test('should emit await', () {
    expect(
      refer('future').awaited,
      equalsDart('await future'),
    );
  });

  test('should emit return', () {
    expect(
      literalNull.returned,
      equalsDart('return null'),
    );
  });

  test('should emit throw', () {
    expect(
      literalNull.thrown,
      equalsDart('throw null'),
    );
  });

  test('should emit an explicit cast', () {
    expect(
      refer('foo').asA(refer('String')).property('length'),
      equalsDart('( foo as String ).length'),
    );
  });

  test('should emit an is check', () {
    expect(
      refer('foo').isA(refer('String')),
      equalsDart('foo is String'),
    );
  });

  test('should emit an is! check', () {
    expect(
      refer('foo').isNotA(refer('String')),
      equalsDart('foo is! String'),
    );
  });

  test('should emit an equality check', () {
    expect(
      refer('foo').equalTo(literalString('bar')),
      equalsDart("foo == 'bar'"),
    );
  });

  test('should emit an inequality check', () {
    expect(
      refer('foo').notEqualTo(literalString('bar')),
      equalsDart("foo != 'bar'"),
    );
  });

  test('should emit an greater than check', () {
    expect(
      refer('foo').greaterThan(literalString('bar')),
      equalsDart("foo > 'bar'"),
    );
  });

  test('should emit an less than check', () {
    expect(
      refer('foo').lessThan(literalString('bar')),
      equalsDart("foo < 'bar'"),
    );
  });

  test('should emit an greater or equals check', () {
    expect(
      refer('foo').greaterOrEqualTo(literalString('bar')),
      equalsDart("foo >= 'bar'"),
    );
  });

  test('should emit an less or equals check', () {
    expect(
      refer('foo').lessOrEqualTo(literalString('bar')),
      equalsDart("foo <= 'bar'"),
    );
  });

  test('should emit a conditional', () {
    expect(
      refer('foo').conditional(literal(1), literal(2)),
      equalsDart('foo ? 1 : 2'),
    );
  });

  test('should emit an operator add call', () {
    expect(refer('foo').operatorAdd(refer('foo2')), equalsDart('foo + foo2'));
  });

  test('should emit an operator substract call', () {
    expect(refer('foo').operatorSubstract(refer('foo2')),
        equalsDart('foo - foo2'));
  });

  test('should emit an operator divide call', () {
    expect(
        refer('foo').operatorDivide(refer('foo2')), equalsDart('foo / foo2'));
  });

  test('should emit an operator multiply call', () {
    expect(
        refer('foo').operatorMultiply(refer('foo2')), equalsDart('foo * foo2'));
  });

  test('should emit an euclidean modulo operator call', () {
    expect(refer('foo').operatorEuclideanModulo(refer('foo2')),
        equalsDart('foo % foo2'));
  });
}
