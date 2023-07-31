// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization_extensions.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  for (var mode in [
    SerializationMode.jsonClient,
    SerializationMode.jsonServer,
    SerializationMode.byteDataClient,
    SerializationMode.byteDataServer,
  ]) {
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

  for (var mode in [
    SerializationMode.byteDataServer,
    SerializationMode.jsonServer
  ]) {
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
        var serializer = serializerFactory();
        foo.serialize(serializer);
        var response = roundTrip(serializer.result);
        var deserializer = deserializerFactory(response);
        var instance = RemoteInstance.deserialize(deserializer);
        expect(instance, foo);
      });
    });
  }

  group('declarations', () {
    final barType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        isNullable: false,
        identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Bar'),
        typeArguments: []);
    final fooType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        isNullable: true,
        identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
        typeArguments: [barType]);

    for (var mode in [
      SerializationMode.byteDataServer,
      SerializationMode.jsonServer
    ]) {
      group('with mode $mode', () {
        test('NamedTypeAnnotation', () {
          expectSerializationEquality(fooType, mode);
        });

        final fooNamedParam = ParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            isNamed: true,
            isRequired: true,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'foo'),
            type: fooType);
        final fooNamedFunctionTypeParam = FunctionTypeParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: true,
            isRequired: true,
            name: 'foo',
            type: fooType);

        final barPositionalParam = ParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            isNamed: false,
            isRequired: false,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            type: barType);
        final barPositionalFunctionTypeParam = FunctionTypeParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: true,
            isRequired: true,
            name: 'bar',
            type: fooType);

        final unnamedFunctionTypeParam = FunctionTypeParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: true,
            isRequired: true,
            name: null,
            type: fooType);

        final zapTypeParam = TypeParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Zap'),
            bound: barType);

        // Transitively tests `TypeParameterDeclaration` and
        // `ParameterDeclaration`.
        test('FunctionTypeAnnotation', () {
          var functionType = FunctionTypeAnnotationImpl(
            id: RemoteInstance.uniqueId,
            isNullable: true,
            namedParameters: [
              fooNamedFunctionTypeParam,
              unnamedFunctionTypeParam
            ],
            positionalParameters: [barPositionalFunctionTypeParam],
            returnType: fooType,
            typeParameters: [zapTypeParam],
          );
          expectSerializationEquality(functionType, mode);
        });

        test('FunctionDeclaration', () {
          var function = FunctionDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'name'),
              isAbstract: true,
              isExternal: false,
              isGetter: true,
              isOperator: false,
              isSetter: false,
              namedParameters: [],
              positionalParameters: [],
              returnType: fooType,
              typeParameters: []);
          expectSerializationEquality(function, mode);
        });

        test('MethodDeclaration', () {
          var method = MethodDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'zorp'),
              isAbstract: false,
              isExternal: false,
              isGetter: false,
              isOperator: false,
              isSetter: true,
              namedParameters: [fooNamedParam],
              positionalParameters: [barPositionalParam],
              returnType: fooType,
              typeParameters: [zapTypeParam],
              definingClass: fooType.identifier,
              isStatic: false);
          expectSerializationEquality(method, mode);
        });

        test('ConstructorDeclaration', () {
          var constructor = ConstructorDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'new'),
            isAbstract: false,
            isExternal: false,
            isGetter: false,
            isOperator: true,
            isSetter: false,
            namedParameters: [fooNamedParam],
            positionalParameters: [barPositionalParam],
            returnType: fooType,
            typeParameters: [zapTypeParam],
            definingClass: fooType.identifier,
            isFactory: true,
          );
          expectSerializationEquality(constructor, mode);
        });

        test('VariableDeclaration', () {
          var bar = VariableDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            isExternal: true,
            isFinal: false,
            isLate: true,
            type: barType,
          );
          expectSerializationEquality(bar, mode);
        });

        test('FieldDeclaration', () {
          var bar = FieldDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            isExternal: false,
            isFinal: true,
            isLate: false,
            type: barType,
            definingClass: fooType.identifier,
            isStatic: false,
          );
          expectSerializationEquality(bar, mode);
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
          isNullable: false,
          typeArguments: [],
        );

        test('ClassDeclaration', () {
          var fooClass = ClassDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
            interfaces: [barType],
            isAbstract: true,
            isExternal: false,
            mixins: [serializableType],
            superclass: objectType,
            typeParameters: [zapTypeParam],
          );
          expectSerializationEquality(fooClass, mode);
        });

        test('TypeAliasDeclaration', () {
          var typeAlias = TypeAliasDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'FooOfBar'),
            typeParameters: [zapTypeParam],
            aliasedType: NamedTypeAnnotationImpl(
                id: RemoteInstance.uniqueId,
                isNullable: false,
                identifier:
                    IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
                typeArguments: [barType]),
          );
          expectSerializationEquality(typeAlias, mode);
        });
      });
    }
  });
}

/// Serializes [serializable] in server mode, then deserializes it in client
/// mode, and checks that all the fields are the same.
void expectSerializationEquality(
    Serializable serializable, SerializationMode serverMode) {
  late Object? serialized;
  withSerializationMode(serverMode, () {
    var serializer = serializerFactory();
    serializable.serialize(serializer);
    serialized = serializer.result;
  });
  withSerializationMode(_clientModeForServerMode(serverMode), () {
    var deserializer = deserializerFactory(serialized);
    var deserialized = (deserializer..moveNext()).expectRemoteInstance();
    if (deserialized is Declaration) {
      expect(serializable, deepEqualsDeclaration(deserialized));
    } else if (deserialized is TypeAnnotation) {
      expect(serializable, deepEqualsTypeAnnotation(deserialized));
    } else {
      throw new UnsupportedError('Unsupported object type $deserialized');
    }
  });
}

/// Deserializes [serialized] in client mode and sends it back.
Object? roundTrip<Declaration>(Object? serialized) {
  return withSerializationMode(_clientModeForServerMode(serializationMode), () {
    var deserializer = deserializerFactory(serialized);
    var instance =
        RemoteInstance.deserialize<NamedTypeAnnotationImpl>(deserializer);
    var serializer = serializerFactory();
    instance.serialize(serializer);
    return serializer.result;
  });
}

SerializationMode _clientModeForServerMode(SerializationMode serverMode) {
  switch (serverMode) {
    case SerializationMode.byteDataServer:
      return SerializationMode.byteDataClient;
    case SerializationMode.jsonServer:
      return SerializationMode.jsonClient;
    default:
      throw StateError('Expected to be running in a server mode');
  }
}
