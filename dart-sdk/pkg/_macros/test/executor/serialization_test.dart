// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:_macros/src/api.dart';
import 'package:_macros/src/executor.dart';
import 'package:_macros/src/executor/exception_impls.dart';
import 'package:_macros/src/executor/introspection_impls.dart';
import 'package:_macros/src/executor/remote_instance.dart';
import 'package:_macros/src/executor/serialization.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  // We randomize fields which should make the tests more likely to catch issues
  // related to serialization ordering.
  final seed = Random().nextInt(1000);
  print('Nondeterministic test ran with seed: $seed, change to this seed to '
      'repro.');
  final rand = Random(seed);

  for (var mode in [SerializationMode.json, SerializationMode.byteData]) {
    test('$mode can serialize and deserialize basic data', () {
      withSerializationMode(mode, () {
        var serializer = serializerFactory();
        serializer
          ..addInt(0)
          ..addInt(1)
          ..addInt(0xff)
          ..addInt(0xffff)
          ..addInt(0xffffffff)
          ..addInt(0xffffffffffffffff)
          ..addInt(-1)
          ..addInt(-0x80)
          ..addInt(-0x8000)
          ..addInt(-0x80000000)
          ..addInt(-0x8000000000000000)
          ..addNullableInt(null)
          ..addString('hello')
          ..addString('€') // Requires a two byte string
          ..addString('𐐷') // Requires two, 16 bit code units
          ..addNullableString(null)
          ..startList()
          ..addBool(true)
          ..startList()
          ..addNull()
          ..endList()
          ..addNullableBool(null)
          ..endList()
          ..addDouble(1.0)
          ..startList()
          ..endList();
        var deserializer = deserializerFactory(serializer.result);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 1);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0xff);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0xffff);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0xffffffff);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0xffffffffffffffff);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -1);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -0x80);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -0x8000);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -0x80000000);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -0x8000000000000000);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectNullableInt(), null);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectString(), 'hello');
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectString(), '€');
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectString(), '𐐷');
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectNullableString(), null);
        expect(deserializer.moveNext(), true);

        deserializer.expectList();
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectBool(), true);
        expect(deserializer.moveNext(), true);

        deserializer.expectList();
        expect(deserializer.moveNext(), true);
        expect(deserializer.checkNull(), true);
        expect(deserializer.moveNext(), false);

        expect(deserializer.moveNext(), true);
        expect(deserializer.expectNullableBool(), null);
        expect(deserializer.moveNext(), false);

        // Have to move the parent again to advance it past the list entry.
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectDouble(), 1.0);
        expect(deserializer.moveNext(), true);

        deserializer.expectList();
        expect(deserializer.moveNext(), false);

        expect(deserializer.moveNext(), false);
      });
    });
  }

  for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
    test('remote instances in $mode', () async {
      var string = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'String'),
          typeArguments: const []);
      var foo = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
          typeArguments: [string]);

      withSerializationMode(mode, () {
        final int zoneId = newRemoteInstanceZone();
        withRemoteInstanceZone(zoneId, () {
          var serializer = serializerFactory();
          foo.serialize(serializer);
          // This is a fake client, we don't want to actually share the cache,
          // so we negate the zone id and use that.
          var response = roundTrip(serializer.result, -zoneId);
          var deserializer = deserializerFactory(response);
          var instance = RemoteInstance.deserialize(deserializer);
          expect(instance, foo);
        });
      });
    });
  }

  group('declarations', () {
    final barType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        isNullable: rand.nextBool(),
        identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Bar'),
        typeArguments: []);
    final fooType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        isNullable: rand.nextBool(),
        identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
        typeArguments: [barType]);

    for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
      group('with mode $mode', () {
        test('NamedTypeAnnotation', () {
          expectSerializationEquality<TypeAnnotationImpl>(
              fooType, mode, RemoteInstance.deserialize);
        });

        final fooNamedParam = FormalParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            isNamed: rand.nextBool(),
            isRequired: rand.nextBool(),
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'foo'),
            library: Fixtures.library,
            metadata: [],
            type: fooType);
        final fooNamedFunctionTypeParam = FormalParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: rand.nextBool(),
            isRequired: rand.nextBool(),
            metadata: [],
            name: 'foo',
            type: fooType);

        final barPositionalParam = FormalParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            isNamed: rand.nextBool(),
            isRequired: rand.nextBool(),
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            library: Fixtures.library,
            metadata: [],
            type: barType);
        final barPositionalFunctionTypeParam = FormalParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: rand.nextBool(),
            isRequired: rand.nextBool(),
            metadata: [],
            name: 'bar',
            type: fooType);

        final unnamedFunctionTypeParam = FormalParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: rand.nextBool(),
            isRequired: rand.nextBool(),
            metadata: [],
            name: rand.nextBool() ? null : 'zip',
            type: fooType);

        final zapTypeParam = TypeParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Zap'),
            library: Fixtures.library,
            metadata: [],
            bound: barType);

        // Transitively tests `TypeParameterDeclaration` and
        // `ParameterDeclaration`.
        test('FunctionTypeAnnotation', () {
          var functionType = FunctionTypeAnnotationImpl(
            id: RemoteInstance.uniqueId,
            isNullable: rand.nextBool(),
            namedParameters: [
              fooNamedFunctionTypeParam,
              unnamedFunctionTypeParam
            ],
            positionalParameters: [barPositionalFunctionTypeParam],
            returnType: fooType,
            typeParameters: [
              TypeParameterImpl(
                  id: RemoteInstance.uniqueId,
                  metadata: [],
                  name: 'Zip',
                  bound: barType)
            ],
          );
          expectSerializationEquality<TypeAnnotationImpl>(
              functionType, mode, RemoteInstance.deserialize);
        });

        test('FunctionDeclaration', () {
          var function = FunctionDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'name'),
              library: Fixtures.library,
              metadata: [],
              hasBody: rand.nextBool(),
              hasExternal: rand.nextBool(),
              isGetter: rand.nextBool(),
              isOperator: rand.nextBool(),
              isSetter: rand.nextBool(),
              namedParameters: [],
              positionalParameters: [],
              returnType: fooType,
              typeParameters: []);
          expectSerializationEquality<DeclarationImpl>(
              function, mode, RemoteInstance.deserialize);
        });

        test('MethodDeclaration', () {
          var method = MethodDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'zorp'),
              library: Fixtures.library,
              metadata: [],
              hasBody: rand.nextBool(),
              hasExternal: rand.nextBool(),
              isGetter: rand.nextBool(),
              isOperator: rand.nextBool(),
              isSetter: rand.nextBool(),
              namedParameters: [fooNamedParam],
              positionalParameters: [barPositionalParam],
              returnType: fooType,
              typeParameters: [zapTypeParam],
              definingType: fooType.identifier,
              hasStatic: rand.nextBool());
          expectSerializationEquality<DeclarationImpl>(
              method, mode, RemoteInstance.deserialize);
        });

        test('ConstructorDeclaration', () {
          var constructor = ConstructorDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'new'),
            library: Fixtures.library,
            metadata: [],
            hasBody: rand.nextBool(),
            hasExternal: rand.nextBool(),
            namedParameters: [fooNamedParam],
            positionalParameters: [barPositionalParam],
            returnType: fooType,
            typeParameters: [zapTypeParam],
            definingType: fooType.identifier,
            isFactory: rand.nextBool(),
          );
          expectSerializationEquality<DeclarationImpl>(
              constructor, mode, RemoteInstance.deserialize);
        });

        test('VariableDeclaration', () {
          var bar = VariableDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            library: Fixtures.library,
            metadata: [],
            hasConst: rand.nextBool(),
            hasExternal: rand.nextBool(),
            hasFinal: rand.nextBool(),
            hasInitializer: rand.nextBool(),
            hasLate: rand.nextBool(),
            type: barType,
          );
          expectSerializationEquality<DeclarationImpl>(
              bar, mode, RemoteInstance.deserialize);
        });

        test('FieldDeclaration', () {
          var bar = FieldDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            library: Fixtures.library,
            metadata: [],
            hasAbstract: rand.nextBool(),
            hasConst: rand.nextBool(),
            hasExternal: rand.nextBool(),
            hasFinal: rand.nextBool(),
            hasInitializer: rand.nextBool(),
            hasLate: rand.nextBool(),
            type: barType,
            definingType: fooType.identifier,
            hasStatic: rand.nextBool(),
          );
          expectSerializationEquality<DeclarationImpl>(
              bar, mode, RemoteInstance.deserialize);
        });

        var objectType = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Object'),
          isNullable: false,
          typeArguments: [],
        );
        var serializableType = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Serializable'),
          isNullable: rand.nextBool(),
          typeArguments: [],
        );

        test('ClassDeclaration', () {
          var fooClass = ClassDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
            library: Fixtures.library,
            metadata: [],
            interfaces: [barType],
            hasAbstract: rand.nextBool(),
            hasBase: rand.nextBool(),
            hasExternal: rand.nextBool(),
            hasFinal: rand.nextBool(),
            hasInterface: rand.nextBool(),
            hasMixin: rand.nextBool(),
            hasSealed: rand.nextBool(),
            mixins: [serializableType],
            superclass: objectType,
            typeParameters: [zapTypeParam],
          );
          expectSerializationEquality<DeclarationImpl>(
              fooClass, mode, RemoteInstance.deserialize);
        });

        test('EnumDeclaration', () {
          var fooEnum = EnumDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyEnum'),
            library: Fixtures.library,
            metadata: [],
            interfaces: [barType],
            mixins: [serializableType],
            typeParameters: [zapTypeParam],
          );
          expectSerializationEquality<DeclarationImpl>(
              fooEnum, mode, RemoteInstance.deserialize);
        });

        test('EnumValueDeclaration', () {
          var entry = EnumValueDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'a'),
            library: Fixtures.library,
            metadata: [],
            definingEnum:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyEnum'),
          );
          expectSerializationEquality<DeclarationImpl>(
              entry, mode, RemoteInstance.deserialize);
        });

        test('ExtensionDeclaration', () {
          var extension = ExtensionDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier: IdentifierImpl(
                  id: RemoteInstance.uniqueId, name: 'MyExtension'),
              library: Fixtures.library,
              metadata: [],
              typeParameters: [],
              onType: Fixtures.myClassType);
          expectSerializationEquality<DeclarationImpl>(
              extension, mode, RemoteInstance.deserialize);
        });

        test('ExtensionTypeDeclaration', () {
          var extensionType = ExtensionTypeDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier: IdentifierImpl(
                  id: RemoteInstance.uniqueId, name: 'MyExtensionType'),
              library: Fixtures.library,
              metadata: [],
              typeParameters: [],
              representationType: Fixtures.myClassType);
          expectSerializationEquality<DeclarationImpl>(
              extensionType, mode, RemoteInstance.deserialize);
        });

        test('MixinDeclaration', () {
          var mixin = MixinDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyMixin'),
            library: Fixtures.library,
            metadata: [],
            hasBase: rand.nextBool(),
            interfaces: [barType],
            superclassConstraints: [serializableType],
            typeParameters: [zapTypeParam],
          );
          expectSerializationEquality<DeclarationImpl>(
              mixin, mode, RemoteInstance.deserialize);
        });

        test('TypeAliasDeclaration', () {
          var typeAlias = TypeAliasDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'FooOfBar'),
            library: Fixtures.library,
            metadata: [],
            typeParameters: [zapTypeParam],
            aliasedType: NamedTypeAnnotationImpl(
                id: RemoteInstance.uniqueId,
                isNullable: rand.nextBool(),
                identifier:
                    IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
                typeArguments: [barType]),
          );
          expectSerializationEquality<DeclarationImpl>(
              typeAlias, mode, RemoteInstance.deserialize);
        });

        /// Transitively tests [RecordField]
        test('RecordTypeAnnotation', () {
          var recordType = RecordTypeAnnotationImpl(
            id: RemoteInstance.uniqueId,
            isNullable: rand.nextBool(),
            namedFields: [
              RecordFieldImpl(
                id: RemoteInstance.uniqueId,
                name: 'hello',
                type: barType,
              ),
            ],
            positionalFields: [
              RecordFieldImpl(
                id: RemoteInstance.uniqueId,
                name: rand.nextBool() ? null : 'zoiks',
                type: fooType,
              ),
            ],
          );
          expectSerializationEquality<TypeAnnotationImpl>(
              recordType, mode, RemoteInstance.deserialize);
        });
      });
    }
  });

  group('Arguments', () {
    test('can create properly typed collections', () {
      withSerializationMode(SerializationMode.json, () {
        final parsed = Arguments.deserialize(deserializerFactory([
          // positional args
          [
            // int
            ArgumentKind.int.index,
            1,
            // List<int>
            ArgumentKind.list.index,
            [ArgumentKind.int.index],
            [
              ArgumentKind.int.index,
              1,
              ArgumentKind.int.index,
              2,
              ArgumentKind.int.index,
              3,
            ],
            // List<Set<String>>
            ArgumentKind.list.index,
            [ArgumentKind.set.index, ArgumentKind.string.index],
            [
              // Set<String>
              ArgumentKind.set.index,
              [ArgumentKind.string.index],
              [
                ArgumentKind.string.index,
                'hello',
                ArgumentKind.string.index,
                'world',
              ]
            ],
            // Map<int, List<String>>
            ArgumentKind.map.index,
            [
              ArgumentKind.int.index,
              ArgumentKind.nullable.index,
              ArgumentKind.list.index,
              ArgumentKind.string.index
            ],
            [
              // key: int
              ArgumentKind.int.index,
              4,
              // value: List<String>
              ArgumentKind.list.index,
              [ArgumentKind.string.index],
              [
                ArgumentKind.string.index,
                'zip',
              ],
              ArgumentKind.int.index,
              5,
              ArgumentKind.nil.index,
            ]
          ],
          // named args
          [],
        ]));
        expect(parsed.positional.length, 4);
        expect(parsed.positional.first.value, 1);
        expect(parsed.positional[1].value, [1, 2, 3]);
        expect(parsed.positional[1].value, isA<List<int>>());
        expect(parsed.positional[2].value, [
          {'hello', 'world'}
        ]);
        expect(parsed.positional[2].value, isA<List<Set<String>>>());
        expect(
          parsed.positional[3].value,
          {
            4: ['zip'],
            5: null,
          },
        );
        expect(parsed.positional[3].value, isA<Map<int, List<String>?>>());
      });
    });

    group('can be serialized and deserialized', () {
      for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
        test('with mode $mode', () {
          final arguments = Arguments([
            MapArgument({
              StringArgument('hello'): ListArgument(
                  [BoolArgument(rand.nextBool()), NullArgument()],
                  [ArgumentKind.nullable, ArgumentKind.bool]),
            }, [
              ArgumentKind.string,
              ArgumentKind.list,
              ArgumentKind.nullable,
              ArgumentKind.bool
            ]),
            CodeArgument(ExpressionCode.fromParts([
              '1 + ',
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'a')
            ])),
            ListArgument([
              TypeAnnotationArgument(Fixtures.myClassType),
              TypeAnnotationArgument(Fixtures.myEnumType),
              TypeAnnotationArgument(NamedTypeAnnotationImpl(
                  id: RemoteInstance.uniqueId,
                  isNullable: false,
                  identifier:
                      IdentifierImpl(id: RemoteInstance.uniqueId, name: 'List'),
                  typeArguments: [Fixtures.stringType])),
            ], [
              ArgumentKind.typeAnnotation
            ])
          ], {
            'a': SetArgument([
              MapArgument({
                IntArgument(1): StringArgument('1'),
              }, [
                ArgumentKind.int,
                ArgumentKind.string
              ])
            ], [
              ArgumentKind.map,
              ArgumentKind.int,
              ArgumentKind.string
            ])
          });
          expectSerializationEquality(arguments, mode, Arguments.deserialize);
        });
      }
    });
  });

  group('Exceptions', () {
    group('can be serialized and deserialized', () {
      for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
        test('with mode $mode', () {
          final exception = UnexpectedMacroExceptionImpl('something happened',
              stackTrace: 'here');
          expectSerializationEquality<UnexpectedMacroExceptionImpl>(
              exception, mode, RemoteInstance.deserialize);
        });
      }
    });
  });

  group('metadata annotations can be serialized and deserialized', () {
    for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
      group('with mode $mode', () {
        test('identifiers', () {
          final identifierMetadata = IdentifierMetadataAnnotationImpl(
              id: RemoteInstance.uniqueId,
              identifier: IdentifierImpl(
                  id: RemoteInstance.uniqueId, name: 'singleton'));

          expectSerializationEquality<IdentifierMetadataAnnotationImpl>(
              identifierMetadata, mode, RemoteInstance.deserialize);
        });

        test('constructor invocations', () {
          final constructorMetadata = ConstructorMetadataAnnotationImpl(
              id: RemoteInstance.uniqueId,
              type: NamedTypeAnnotationImpl(
                  id: RemoteInstance.uniqueId,
                  identifier: IdentifierImpl(
                      id: RemoteInstance.uniqueId, name: 'Singleton'),
                  isNullable: false,
                  typeArguments: []),
              constructor:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'someName'),
              positionalArguments: [
                ExpressionCode.fromString("'foo'"),
                ExpressionCode.fromString('12'),
              ],
              namedArguments: {
                'bar': ExpressionCode.fromString("'bar'"),
                'foobar': ExpressionCode.fromString('13'),
              });

          expectSerializationEquality<ConstructorMetadataAnnotationImpl>(
              constructorMetadata, mode, RemoteInstance.deserialize);
        });
      });
    }
  });

  group('static types can be serialized and deserialized', () {
    for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
      group('with mode $mode', () {
        test('named static type', () async {
          final staticType = NamedStaticTypeImpl(
            RemoteInstance.uniqueId,
            declaration: ClassDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
              library: Fixtures.library,
              metadata: [],
              interfaces: [],
              hasAbstract: false,
              hasBase: false,
              hasExternal: false,
              hasFinal: false,
              hasInterface: false,
              hasMixin: false,
              hasSealed: false,
              mixins: [],
              superclass: null,
              typeParameters: [
                TypeParameterDeclarationImpl(
                  id: RemoteInstance.uniqueId,
                  identifier:
                      IdentifierImpl(id: RemoteInstance.uniqueId, name: 'T'),
                  library: Fixtures.library,
                  metadata: const [],
                  bound: null,
                ),
              ],
            ),
            typeArguments: [
              NamedStaticTypeImpl(
                RemoteInstance.uniqueId,
                declaration: Fixtures.stringClass,
                typeArguments: const [],
              ),
            ],
          );
          expectSerializationEquality<NamedStaticTypeImpl>(
              staticType, mode, RemoteInstance.deserialize);
        });
      });
    }
  });
}

/// Serializes [serializable] in server mode, then deserializes it in client
/// mode, and checks that all the fields are the same.
void expectSerializationEquality<T extends Serializable>(T serializable,
    SerializationMode mode, T Function(Deserializer deserializer) deserialize) {
  withSerializationMode(mode, () {
    late Object? serialized;
    final int zoneId = newRemoteInstanceZone();
    withRemoteInstanceZone(zoneId, () {
      var serializer = serializerFactory();
      serializable.serialize(serializer);
      serialized = serializer.result;
    });

    // This is a fake client, we don't want to actually share the cache,
    // so we negate the zone id and use that.
    withRemoteInstanceZone(-zoneId, () {
      var deserializer = deserializerFactory(serialized);
      var deserialized = deserialize(deserializer);

      expect(
          serializable,
          switch (deserialized) {
            Declaration() => deepEqualsDeclaration(deserialized as Declaration),
            TypeAnnotation() =>
              deepEqualsTypeAnnotation(deserialized as TypeAnnotation),
            Arguments() => deepEqualsArguments(deserialized),
            MacroExceptionImpl() => deepEqualsMacroException(deserialized),
            MetadataAnnotation() =>
              deepEqualsMetadataAnnotation(deserialized as MetadataAnnotation),
            NamedStaticTypeImpl() =>
              deepEqualsStaticType(deserialized as NamedStaticTypeImpl),
            _ =>
              throw UnsupportedError('Unsupported object type $deserialized'),
          });
    }, createIfMissing: true);
  });
}

/// Deserializes [serialized] in its own remote instance cache and sends it
/// back.
Object? roundTrip<Declaration>(Object? serialized, int zoneId) {
  return withRemoteInstanceZone(zoneId, () {
    var deserializer = deserializerFactory(serialized);
    var instance = RemoteInstance.deserialize(deserializer) as Serializable;
    var serializer = serializerFactory();
    instance.serialize(serializer);
    return serializer.result;
  }, createIfMissing: true);
}
