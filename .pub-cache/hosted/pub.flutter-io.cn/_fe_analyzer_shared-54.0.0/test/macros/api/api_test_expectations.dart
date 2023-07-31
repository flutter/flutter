// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

const Map<String, ClassData> expectedClassData = {
  'Class1': ClassData(fieldsOf: ['field1'], constructorsOf: ['']),
  'Class2': ClassData(isAbstract: true, superclass: 'Object'),
  'Class3': ClassData(
      superclass: 'Class2',
      superSuperclass: 'Object',
      interfaces: [
        'Interface1'
      ],
      // TODO(johnniwinther): Should we require a specific order?
      fieldsOf: [
        'field1',
        'field2',
        'staticField1',
      ],
      // TODO(johnniwinther): Should we require a specific order?
      methodsOf: [
        'method1',
        'method2',
        'getter1',
        'property1',
        'staticMethod1',
        'setter1',
        'property1',
      ],
      // TODO(johnniwinther): Should we require a specific order?
      constructorsOf: [
        // TODO(johnniwinther): Should we normalize no-name constructor names?
        '',
        'named',
        'fact',
        'redirect',
      ]),
  'Class4': ClassData(superclass: 'Class1', mixins: ['Mixin1']),
  'Class5': ClassData(
      superclass: 'Class2',
      superSuperclass: 'Object',
      mixins: ['Mixin1', 'Mixin2'],
      interfaces: ['Interface1', 'Interface2']),
  'Interface1': ClassData(isAbstract: true),
  'Interface2': ClassData(isAbstract: true),
};

const Map<String, FunctionData> expectedFunctionData = {
  'topLevelFunction1': FunctionData(
      returnType: NamedTypeData(name: 'void'),
      positionalParameters: [
        ParameterData('a',
            type: NamedTypeData(name: 'Class1'), isRequired: true),
      ],
      namedParameters: [
        ParameterData('b',
            type: NamedTypeData(name: 'Class1', isNullable: true),
            isNamed: true,
            isRequired: false),
        ParameterData('c',
            type: NamedTypeData(name: 'Class2', isNullable: true),
            isNamed: true,
            isRequired: true),
      ]),
  'topLevelFunction2': FunctionData(
    isExternal: true,
    returnType: NamedTypeData(name: 'Class2'),
    positionalParameters: [
      ParameterData('a', type: NamedTypeData(name: 'Class1'), isRequired: true),
      ParameterData('b', type: NamedTypeData(name: 'Class2', isNullable: true)),
    ],
  ),
};

expect(expected, actual, property) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual on $property';
  }
}

Future<void> throws(Future<void> Function() f, property,
    {String? Function(Object)? expectedError}) async {
  try {
    await f();
  } catch (e) {
    if (expectedError != null) {
      String? errorMessage = expectedError(e);
      if (errorMessage != null) {
        throw 'Unexpected exception on $property: $errorMessage';
      }
    }
    return;
  }
  throw 'Expected throws on $property';
}

void checkTypeAnnotation(
    TypeData expected, TypeAnnotation typeAnnotation, String context) {
  expect(expected.isNullable, typeAnnotation.isNullable, '$context.isNullable');
  expect(expected is NamedTypeData, typeAnnotation is NamedTypeAnnotation,
      '$context is NamedTypeAnnotation');
  if (expected is NamedTypeData && typeAnnotation is NamedTypeAnnotation) {
    expect(expected.name, typeAnnotation.identifier.name, '$context.name');
    // TODO(johnniwinther): Test more properties.
  }
}

void checkParameterDeclaration(
    ParameterData expected, ParameterDeclaration declaration, String context) {
  expect(
      expected.name, declaration.identifier.name, '$context.identifier.name');
  expect(expected.isNamed, declaration.isNamed, '$context.isNamed');
  expect(expected.isRequired, declaration.isRequired, '$context.isRequired');
  checkTypeAnnotation(expected.type, declaration.type, '$context.type');
}

Future<void> checkClassDeclaration(ClassDeclaration declaration,
    {TypeDeclarationResolver? typeDeclarationResolver,
    TypeIntrospector? typeIntrospector}) async {
  String name = declaration.identifier.name;
  ClassData? expected = expectedClassData[name];
  if (expected != null) {
    expect(expected.isAbstract, declaration.isAbstract, '$name.isAbstract');
    expect(expected.isExternal, declaration.isExternal, '$name.isExternal');
    if (typeDeclarationResolver != null) {
      TypeDeclaration? superclass = declaration.superclass == null
          ? null
          : await typeDeclarationResolver
              .declarationOf(declaration.superclass!.identifier);
      expect(
          expected.superclass, superclass?.identifier.name, '$name.superclass');
      if (superclass is ClassDeclaration) {
        TypeDeclaration? superSuperclass = superclass.superclass == null
            ? null
            : await typeDeclarationResolver
                .declarationOf(superclass.superclass!.identifier);
        expect(expected.superSuperclass, superSuperclass?.identifier.name,
            '$name.superSuperclass');
      }
      List<TypeDeclaration> mixins = [
        for (NamedTypeAnnotation mixin in declaration.mixins)
          await typeDeclarationResolver.declarationOf(mixin.identifier),
      ];
      expect(expected.mixins.length, mixins.length, '$name.mixins.length');
      for (int i = 0; i < mixins.length; i++) {
        expect(
            expected.mixins[i], mixins[i].identifier.name, '$name.mixins[$i]');
      }

      List<TypeDeclaration> interfaces = [
        for (NamedTypeAnnotation interface in declaration.interfaces)
          await typeDeclarationResolver.declarationOf(interface.identifier),
      ];
      expect(expected.interfaces.length, interfaces.length,
          '$name.interfaces.length');
      for (int i = 0; i < interfaces.length; i++) {
        expect(expected.interfaces[i], interfaces[i].identifier.name,
            '$name.interfaces[$i]');
      }
    }
    if (typeIntrospector != null &&
        declaration is IntrospectableClassDeclaration) {
      List<FieldDeclaration> fieldsOf =
          await typeIntrospector.fieldsOf(declaration);
      expect(
          expected.fieldsOf.length, fieldsOf.length, '$name.fieldsOf.length');
      for (int i = 0; i < fieldsOf.length; i++) {
        expect(expected.fieldsOf[i], fieldsOf[i].identifier.name,
            '$name.fieldsOf[$i]');
      }

      List<MethodDeclaration> methodsOf =
          await typeIntrospector.methodsOf(declaration);
      expect(expected.methodsOf.length, methodsOf.length,
          '$name.methodsOf.length');
      for (int i = 0; i < methodsOf.length; i++) {
        expect(expected.methodsOf[i], methodsOf[i].identifier.name,
            '$name.methodsOf[$i]');
      }

      List<ConstructorDeclaration> constructorsOf =
          await typeIntrospector.constructorsOf(declaration);
      expect(expected.constructorsOf.length, constructorsOf.length,
          '$name.constructorsOf.length');
      for (int i = 0; i < constructorsOf.length; i++) {
        expect(expected.constructorsOf[i], constructorsOf[i].identifier.name,
            '$name.constructorsOf[$i]');
      }
    }
    // TODO(johnniwinther): Test more properties when there are supported.
  } else {
    throw 'Unexpected class declaration "${name}"';
  }
}

void checkFunctionDeclaration(FunctionDeclaration actual) {
  String name = actual.identifier.name;
  FunctionData? expected = expectedFunctionData[name];
  if (expected != null) {
    expect(expected.isAbstract, actual.isAbstract, '$name.isAbstract');
    expect(expected.isExternal, actual.isExternal, '$name.isExternal');
    expect(expected.isOperator, actual.isOperator, '$name.isOperator');
    expect(expected.isGetter, actual.isGetter, '$name.isGetter');
    expect(expected.isSetter, actual.isSetter, '$name.isSetter');
    checkTypeAnnotation(
        expected.returnType, actual.returnType, '$name.returnType');
    expect(
        expected.positionalParameters.length,
        actual.positionalParameters.length,
        '$name.positionalParameters.length');
    for (int i = 0; i < expected.positionalParameters.length; i++) {
      checkParameterDeclaration(
          expected.positionalParameters[i],
          actual.positionalParameters.elementAt(i),
          '$name.positionalParameters[$i]');
    }
    expect(expected.namedParameters.length, actual.namedParameters.length,
        '$name.namedParameters.length');
    for (int i = 0; i < expected.namedParameters.length; i++) {
      checkParameterDeclaration(expected.namedParameters[i],
          actual.namedParameters.elementAt(i), '$name.namedParameters[$i]');
    }
    // TODO(johnniwinther): Test more properties.
  } else {
    throw 'Unexpected function declaration "${name}"';
  }
}

Future<void> checkIdentifierResolver(
    IdentifierResolver identifierResolver) async {
  Uri dartCore = Uri.parse('dart:core');
  Uri macroApiData = Uri.parse('package:macro_api_test/api_test_data.dart');

  Future<void> check(Uri uri, String name, {bool expectThrows = false}) async {
    if (expectThrows) {
      await throws(() async {
        await identifierResolver.resolveIdentifier(uri, name);
      }, '$name from $uri');
    } else {
      Identifier result = await identifierResolver.resolveIdentifier(uri, name);
      expect(name, result.name, '$name from $uri');
    }
  }

  await check(dartCore, 'Object');
  await check(dartCore, 'String');
  await check(dartCore, 'override');

  await check(macroApiData, 'Class1');
  await check(macroApiData, 'getter');
  await check(macroApiData, 'setter=');
  await check(macroApiData, 'field');

  await check(macroApiData, 'non-existing', expectThrows: true);
  await check(macroApiData, 'getter=', expectThrows: true);
  await check(macroApiData, 'setter', expectThrows: true);
  await check(macroApiData, 'field=', expectThrows: true);
}

Future<void> checkTypeDeclarationResolver(
    TypeDeclarationResolver typeDeclarationResolver,
    Map<Identifier, String?> test) async {
  Future<void> check(Identifier identifier, String name,
      {bool expectThrows = false}) async {
    if (expectThrows) {
      await throws(() async {
        await typeDeclarationResolver.declarationOf(identifier);
      }, '$name from $identifier',
          expectedError: (e) => e is! ArgumentError
              ? 'Expected ArgumentError, got ${e.runtimeType}: $e'
              : null);
    } else {
      TypeDeclaration result =
          await typeDeclarationResolver.declarationOf(identifier);
      expect(name, result.identifier.name, '$name from $identifier');
    }
  }

  test.forEach((Identifier identifier, String? expectedName) {
    check(identifier, expectedName ?? identifier.name,
        expectThrows: expectedName == null);
  });
}

class ClassData {
  final bool isAbstract;
  final bool isExternal;
  final String? superclass;
  final String? superSuperclass;
  final List<String> interfaces;
  final List<String> mixins;
  final List<String> fieldsOf;
  final List<String> methodsOf;
  final List<String> constructorsOf;

  const ClassData(
      {this.isAbstract = false,
      this.isExternal = false,
      this.superclass,
      this.superSuperclass,
      this.interfaces = const [],
      this.mixins = const [],
      this.fieldsOf = const [],
      this.methodsOf = const [],
      this.constructorsOf = const []});
}

class FunctionData {
  final bool isAbstract;
  final bool isExternal;
  final bool isOperator;
  final bool isGetter;
  final bool isSetter;
  final TypeData returnType;
  final List<ParameterData> positionalParameters;
  final List<ParameterData> namedParameters;

  const FunctionData(
      {this.isAbstract = false,
      this.isExternal = false,
      this.isOperator = false,
      this.isGetter = false,
      this.isSetter = false,
      required this.returnType,
      this.positionalParameters = const [],
      this.namedParameters = const []});
}

class TypeData {
  final bool isNullable;

  const TypeData({this.isNullable = false});
}

class NamedTypeData extends TypeData {
  final String? name;
  final List<TypeData>? typeArguments;

  const NamedTypeData({bool isNullable = false, this.name, this.typeArguments})
      : super(isNullable: isNullable);
}

class ParameterData {
  final String name;
  final TypeData type;
  final bool isRequired;
  final bool isNamed;

  const ParameterData(this.name,
      {required this.type, this.isNamed = false, this.isRequired = false});
}
