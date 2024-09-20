// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:_macros/src/api.dart';
import 'package:_macros/src/executor.dart';
import 'package:_macros/src/executor/introspection_impls.dart';
import 'package:_macros/src/executor/remote_instance.dart';
import 'package:test/test.dart';

class TestTypePhaseIntrospector implements TypePhaseIntrospector {
  @override
  Future<Identifier> resolveIdentifier(Uri library, String name) async {
    if (library == Uri.parse('dart:core') && name == 'String') {
      return Fixtures.stringType.identifier;
    }
    if (library == Uri.parse('dart:core') && name == 'List') {
      return Fixtures.listIdentifier;
    }
    if (library == Fixtures.library.uri &&
        name == Fixtures.mySuperclass.identifier.name) {
      return Fixtures.mySuperclass.identifier;
    }
    throw UnimplementedError('Cannot resolve the identifier $library:$name');
  }
}

class TestDeclarationPhaseIntrospector extends TestTypePhaseIntrospector
    implements DeclarationPhaseIntrospector {
  final Map<TypeDeclaration, List<ConstructorDeclaration>> constructors;
  final Map<EnumDeclaration, List<EnumValueDeclaration>> enumValues;
  final Map<TypeDeclaration, List<FieldDeclaration>> fields;
  final Map<TypeDeclaration, List<MethodDeclaration>> methods;
  final Map<Library, List<TypeDeclaration>> libraryTypes;
  final Map<Identifier, StaticType> staticTypes;
  final Map<Identifier, Declaration> identifierDeclarations;

  TestDeclarationPhaseIntrospector(
      {required this.constructors,
      required this.enumValues,
      required this.fields,
      required this.methods,
      required this.libraryTypes,
      required this.staticTypes,
      required this.identifierDeclarations});

  @override
  Future<TypeDeclaration> typeDeclarationOf(
      covariant Identifier identifier) async {
    var declaration = identifierDeclarations[identifier];
    if (declaration != null) return declaration as TypeDeclaration;
    throw 'No declaration found for ${identifier.name}';
  }

  @override
  Future<StaticType> resolve(covariant TypeAnnotationCode type) async {
    assert(type.parts.length == 1);
    return staticTypes[type.parts.first]!;
  }

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(
          covariant TypeDeclaration type) async =>
      constructors[type]!;

  @override
  Future<List<EnumValueDeclaration>> valuesOf(
          covariant EnumDeclaration enuum) async =>
      enumValues[enuum]!;

  @override
  Future<List<FieldDeclaration>> fieldsOf(
          covariant TypeDeclaration clazz) async =>
      fields[clazz]!;

  @override
  Future<List<MethodDeclaration>> methodsOf(
          covariant TypeDeclaration clazz) async =>
      methods[clazz]!;

  @override
  Future<List<TypeDeclaration>> typesOf(covariant Library library) async =>
      libraryTypes[library]!;
}

/// Doesn't handle generics etc but thats ok for now
class TestNamedStaticType extends NamedStaticTypeImpl {
  final List<TestNamedStaticType> superTypes;

  TestNamedStaticType(
    super.id, {
    required this.superTypes,
    required super.declaration,
    required super.typeArguments,
  });

  @override
  Future<bool> isExactly(TestNamedStaticType other) async => _isExactly(other);

  @override
  Future<bool> isSubtypeOf(TestNamedStaticType other) async =>
      _isExactly(other) ||
      superTypes.any((superType) => superType._isExactly(other));

  bool _isExactly(TestNamedStaticType other) =>
      identical(other, this) ||
      (declaration.library == other.declaration.library &&
          declaration.identifier == other.declaration.identifier);

  @override
  Future<NamedStaticType?> asInstanceOf(TypeDeclaration declaration) async {
    for (TestNamedStaticType superType in superTypes) {
      if (superType.declaration.identifier == declaration.identifier) {
        return superType;
      }
    }
    return null;
  }
}

/// Assumes all omitted types are [TestOmittedTypeAnnotation]s and just returns
/// the inferred type directly.
class TestDefinitionsPhaseIntrospector extends TestDeclarationPhaseIntrospector
    implements DefinitionPhaseIntrospector {
  final Map<Library, List<Declaration>> libraryDeclarations;

  TestDefinitionsPhaseIntrospector(
      {required this.libraryDeclarations,
      required super.constructors,
      required super.enumValues,
      required super.fields,
      required super.methods,
      required super.libraryTypes,
      required super.staticTypes,
      required super.identifierDeclarations});
  @override
  Future<Declaration> declarationOf(Identifier identifier) async =>
      identifierDeclarations[identifier]!;

  @override
  Future<TypeAnnotation> inferType(
          TestOmittedTypeAnnotation omittedType) async =>
      omittedType.inferredType!;

  @override
  Future<List<Declaration>> topLevelDeclarationsOf(Library library) async =>
      libraryDeclarations[library]!;

  @override
  Future<TypeDeclaration> typeDeclarationOf(Identifier identifier) async =>
      await super.typeDeclarationOf(identifier);
}

/// Knows its inferred type ahead of time.
class TestOmittedTypeAnnotation extends OmittedTypeAnnotationImpl {
  final TypeAnnotation? inferredType;

  TestOmittedTypeAnnotation([this.inferredType])
      : super(id: RemoteInstance.uniqueId);
}

/// An identifier that knows the resolved version of itself.
class TestIdentifier extends IdentifierImpl {
  final ResolvedIdentifier resolved;

  TestIdentifier({
    required super.id,
    required super.name,
    required IdentifierKind kind,
    required Uri? uri,
    required String? staticScope,
  }) : resolved = ResolvedIdentifier(
            kind: kind, name: name, staticScope: staticScope, uri: uri);
}

extension DebugCodeString on Code {
  StringBuffer debugString([StringBuffer? buffer]) {
    buffer ??= StringBuffer();
    for (var part in parts) {
      if (part is Code) {
        part.debugString(buffer);
      } else if (part is IdentifierImpl) {
        buffer.write(part.name);
      } else if (part is TestOmittedTypeAnnotation) {
        if (part.inferredType != null) {
          buffer.write('/*inferred*/');
          part.inferredType!.code.debugString(buffer);
        } else {
          buffer.write('/*omitted*/');
        }
      } else {
        buffer.write(part as String);
      }
    }
    return buffer;
  }
}

extension IterableToDebugCodeString on Iterable<Code> {
  Iterable<String> mapToDebugCodeString() =>
      map((a) => a.debugString().toString())
          // Avoid doing this repeatedly when used in unorderedEquals etc.
          .toList();
}

extension MapValuesToDebugCodeString<K> on Map<K, Iterable<Code>> {
  Map<K, Iterable<String>> mapValuesToDebugCodeString() =>
      map((key, values) => MapEntry(key, values.mapToDebugCodeString()));
}

/// Checks if two [Code] objects are of the same type and all their fields are
/// equal.
Matcher deepEqualsCode(Code other) => _DeepEqualityMatcher(other);

/// Checks if two [Declaration]s are of the same type and all their fields are
/// equal.
Matcher deepEqualsDeclaration(Declaration declaration) =>
    _DeepEqualityMatcher(declaration);

/// Checks if two [TypeAnnotation]s are of the same type and all their fields
/// are equal.
Matcher deepEqualsTypeAnnotation(TypeAnnotation declaration) =>
    _DeepEqualityMatcher(declaration);

/// Checks if two [Arguments]s are identical
Matcher deepEqualsArguments(Arguments arguments) =>
    _DeepEqualityMatcher(arguments);

/// Checks if two [MacroException]s are identical
Matcher deepEqualsMacroException(MacroException macroException) =>
    _DeepEqualityMatcher(macroException);

/// Checks if two [MetadataAnnotation]s are identical
Matcher deepEqualsMetadataAnnotation(MetadataAnnotation metadata) =>
    _DeepEqualityMatcher(metadata);

/// Checks if two [StaticType]s are identical
Matcher deepEqualsStaticType(StaticType type) => _DeepEqualityMatcher(type);

/// Checks if two [Declaration]s, [TypeAnnotation]s, [Code]s or
/// [MacroException]s are of the same type and all their fields are equal.
class _DeepEqualityMatcher extends Matcher {
  final Object? instance;

  _DeepEqualityMatcher(this.instance);

  @override
  Description describe(Description description) => description;

  @override
  bool matches(item, Map matchState) {
    // For type promotion.
    final instance = this.instance;
    if (!equals(item.runtimeType).matches(instance.runtimeType, matchState)) {
      return false;
    }
    if (instance is Declaration ||
        instance is TypeAnnotation ||
        instance is MetadataAnnotation ||
        instance is MacroException ||
        instance is StaticType) {
      var instanceReflector = reflect(instance);
      var itemReflector = reflect(item);

      var type = instanceReflector.type;
      for (var getter
          in type.instanceMembers.values.where((member) => member.isGetter)) {
        // We only care about synthetic field getters
        if (!getter.isSynthetic) continue;

        var instanceField = instanceReflector.getField(getter.simpleName);
        var itemField = itemReflector.getField(getter.simpleName);
        var instanceValue = instanceField.reflectee;
        var itemValue = itemField.reflectee;

        if (!_DeepEqualityMatcher(instanceValue)
            .matches(itemValue, matchState)) {
          return false;
        }
      }
    } else if (instance is Code) {
      item as Code;
      if (!_DeepEqualityMatcher(instance.parts)
          .matches(item.parts, matchState)) {
        return false;
      }
    } else if (instance is Arguments) {
      item as Arguments;
      if (!equals(instance.positional.length)
          .matches(item.positional.length, matchState)) {
        return false;
      }
      for (var i = 0; i < instance.positional.length; i++) {
        if (!_DeepEqualityMatcher(instance.positional[i].value)
            .matches(item.positional[i].value, matchState)) {
          return false;
        }
      }
      if (instance.named.length != item.named.length) return false;
      if (!equals(instance.named.keys).matches(item.named.keys, matchState)) {
        return false;
      }
      for (var key in instance.named.keys) {
        if (!_DeepEqualityMatcher(instance.named[key]!.value)
            .matches(item.named[key]!.value, matchState)) {
          return false;
        }
      }
    } else if (instance is List) {
      item as List;
      if (!equals(instance.length).matches(item.length, matchState)) {
        return false;
      }
      for (var i = 0; i < instance.length; i++) {
        if (!_DeepEqualityMatcher(instance[i]).matches(item[i], matchState)) {
          return false;
        }
      }
    } else if (instance is Map) {
      item as Map;
      if (!equals(instance.length).matches(item.length, matchState)) {
        return false;
      }
      for (var key in instance.keys) {
        // Key sets are same size, so they are equal if every key in `instance`
        // is also a key in `item`.
        if (!contains(key).matches(item, matchState)) {
          return false;
        }
        // Maps are equal if keys are equal and every value is equal.
        if (!_DeepEqualityMatcher(instance[key])
            .matches(item[key], matchState)) {
          return false;
        }
      }
    } else {
      // Handles basic values and identity
      if (!equals(instance).matches(item, matchState)) {
        return false;
      }
    }
    return true;
  }
}

class Fixtures {
  static final library = LibraryImpl(
      id: RemoteInstance.uniqueId,
      languageVersion: LanguageVersionImpl(3, 0),
      metadata: [],
      uri: Uri.parse('package:foo/bar.dart'));
  static final listIdentifier =
      IdentifierImpl(id: RemoteInstance.uniqueId, name: 'List');
  static final nullableBoolType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bool'),
      isNullable: true,
      typeArguments: const []);
  static final stringType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'String'),
      isNullable: false,
      typeArguments: const []);
  static final stringClass = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: stringType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      interfaces: [],
      hasAbstract: false,
      hasBase: false,
      hasExternal: false,
      hasFinal: false,
      hasInterface: false,
      hasMixin: false,
      hasSealed: false,
      mixins: [],
      superclass: null);
  static final inferredStringType = TestOmittedTypeAnnotation(stringType);
  static final voidType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'void'),
      isNullable: false,
      typeArguments: const []);
  static final recordType = RecordTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      isNullable: false,
      namedFields: [
        RecordFieldImpl(
            id: RemoteInstance.uniqueId, name: 'world', type: stringType),
      ],
      positionalFields: [
        RecordFieldImpl(
            id: RemoteInstance.uniqueId, name: null, type: stringType),
        RecordFieldImpl(
            id: RemoteInstance.uniqueId, name: 'hello', type: nullableBoolType),
      ]);

  // Top level, non-class declarations.
  static final myFunction = FunctionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myFunction'),
      library: Fixtures.library,
      metadata: [],
      hasBody: true,
      hasExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: stringType,
      typeParameters: []);
  static final myVariable = VariableDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: '_myVariable'),
      library: Fixtures.library,
      metadata: [],
      hasConst: false,
      hasExternal: false,
      hasFinal: true,
      hasInitializer: false,
      hasLate: false,
      type: inferredStringType);
  static final myVariableGetter = FunctionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myVariable'),
      library: Fixtures.library,
      metadata: [],
      hasBody: true,
      hasExternal: false,
      isGetter: true,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: stringType,
      typeParameters: []);
  static final myVariableSetter = FunctionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myVariable'),
      library: Fixtures.library,
      metadata: [],
      hasBody: true,
      hasExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: true,
      namedParameters: [],
      positionalParameters: [
        FormalParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'value'),
            library: Fixtures.library,
            metadata: [],
            isNamed: false,
            isRequired: true,
            type: stringType)
      ],
      returnType: voidType,
      typeParameters: []);

  static final libraryVariable = VariableDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'library'),
      library: Fixtures.library,
      metadata: [],
      hasConst: false,
      hasExternal: false,
      hasFinal: true,
      hasInitializer: false,
      hasLate: false,
      type: NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'LibraryInfo'),
          typeArguments: []));

  // Class and member declarations
  static final myInterfaceType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyInterface'),
      isNullable: false,
      typeArguments: const []);
  static final myMixinType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyMixin'),
      isNullable: false,
      typeArguments: const []);
  static final mySuperclassType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MySuperclass'),
      isNullable: false,
      typeArguments: const []);
  static final myClassType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyClass'),
      isNullable: false,
      typeArguments: const []);
  static final myClass = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myClassType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      interfaces: [myInterfaceType],
      hasAbstract: false,
      hasBase: false,
      hasExternal: false,
      hasFinal: false,
      hasInterface: false,
      hasMixin: false,
      hasSealed: false,
      mixins: [myMixinType],
      superclass: mySuperclassType);
  static final myConstructor = ConstructorDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myConstructor'),
      library: Fixtures.library,
      metadata: [],
      hasBody: false, // we will augment with one
      hasExternal: false,
      namedParameters: [],
      positionalParameters: [
        FormalParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myField'),
            library: Fixtures.library,
            metadata: [],
            isNamed: false,
            isRequired: true,
            type: TestOmittedTypeAnnotation(myField.type))
      ],
      returnType: myClassType,
      typeParameters: [],
      definingType: myClassType.identifier,
      isFactory: false);
  static final myField = FieldDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myField'),
      library: Fixtures.library,
      metadata: [],
      hasAbstract: false,
      hasConst: false,
      hasExternal: false,
      hasFinal: false,
      hasInitializer: false,
      hasLate: false,
      type: stringType,
      definingType: myClassType.identifier,
      hasStatic: false);
  static final myInterface = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myInterfaceType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      interfaces: [],
      hasAbstract: false,
      hasBase: false,
      hasExternal: false,
      hasFinal: false,
      hasInterface: true,
      hasMixin: false,
      hasSealed: false,
      mixins: [],
      superclass: null);
  static final myMethod = MethodDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myMethod'),
      library: Fixtures.library,
      metadata: [],
      hasBody: true,
      hasExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: recordType,
      typeParameters: [],
      definingType: myClassType.identifier,
      hasStatic: false);
  static final mySuperclass = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: mySuperclassType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [
        TypeParameterDeclarationImpl(
          id: RemoteInstance.uniqueId,
          identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'T'),
          library: library,
          metadata: const [],
          bound: null,
        ),
      ],
      interfaces: [],
      hasAbstract: false,
      hasBase: false,
      hasExternal: false,
      hasFinal: false,
      hasInterface: false,
      hasMixin: false,
      hasSealed: false,
      mixins: [],
      superclass: null);
  static final mySuperTypeInstantiatedWithString = TestNamedStaticType(
    RemoteInstance.uniqueId,
    declaration: mySuperclass,
    typeArguments: [],
    superTypes: [
      TestNamedStaticType(
        RemoteInstance.uniqueId,
        declaration: stringClass,
        superTypes: [],
        typeArguments: [],
      )
    ],
  );
  static final myClassStaticType = TestNamedStaticType(
    RemoteInstance.uniqueId,
    declaration: myClass,
    typeArguments: [],
    superTypes: [
      mySuperTypeInstantiatedWithString,
    ],
  );

  static final myEnumType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      isNullable: false,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyEnum'),
      typeArguments: []);
  static final myEnum = EnumDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myEnumType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      interfaces: [],
      mixins: []);
  static final myEnumValues = [
    EnumValueDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'a'),
      library: Fixtures.library,
      metadata: [],
      definingEnum: myEnum.identifier,
    ),
  ];
  static final myEnumConstructor = ConstructorDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(
          id: RemoteInstance.uniqueId, name: 'myEnumConstructor'),
      library: Fixtures.library,
      metadata: [],
      hasBody: false, // We will augment with one
      hasExternal: false,
      namedParameters: [],
      positionalParameters: [
        FormalParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myField'),
            library: Fixtures.library,
            metadata: [],
            isNamed: false,
            isRequired: true,
            type: stringType)
      ],
      returnType: myEnumType,
      typeParameters: [],
      definingType: myEnum.identifier,
      isFactory: false);

  static final myMixin = MixinDeclarationImpl(
    id: RemoteInstance.uniqueId,
    identifier: myMixinType.identifier,
    library: Fixtures.library,
    metadata: [],
    typeParameters: [],
    hasBase: false,
    interfaces: [],
    superclassConstraints: [myClassType],
  );
  static final myMixinMethod = MethodDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myMixinMethod'),
      library: Fixtures.library,
      metadata: [],
      hasBody: true,
      hasExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: recordType,
      typeParameters: [],
      definingType: myMixinType.identifier,
      hasStatic: false);

  static final myExtension = ExtensionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyExtension'),
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      onType: myClassType);

  static final myExtensionType = ExtensionTypeDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyExtensionType'),
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      representationType: myClassType);

  static final myTypeAlias = TypeAliasDeclarationImpl(
    id: RemoteInstance.uniqueId,
    identifier: IdentifierImpl(
      id: RemoteInstance.uniqueId,
      name: 'MyTypeAlias',
    ),
    library: Fixtures.library,
    metadata: [],
    typeParameters: [],
    aliasedType: myClassType,
  );

  static final myGeneratedExtensionMethod = MethodDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'onTypeFieldNames'),
      library: library,
      metadata: [],
      hasBody: true,
      hasExternal: false,
      isGetter: true,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          identifier: listIdentifier,
          typeArguments: [stringType]),
      typeParameters: [],
      definingType: myExtension.identifier,
      // TODO: This is a bit weird, the method is actually static, but doesn't
      // have the keyword because it is implicit.
      hasStatic: false);

  static final myGeneratedExtensionTypeMethod = MethodDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'onTypeFieldNames'),
      library: library,
      metadata: [],
      hasBody: true,
      hasExternal: false,
      isGetter: true,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          identifier: listIdentifier,
          typeArguments: [stringType]),
      typeParameters: [],
      definingType: myExtensionType.identifier,
      // TODO: This is a bit weird, the method is actually static, but doesn't
      // have the keyword because it is implicit.
      hasStatic: false);

  static final testDeclarationPhaseIntrospector =
      TestDeclarationPhaseIntrospector(constructors: {
    myClass: [myConstructor],
    myEnum: [myEnumConstructor],
    myMixin: [],
  }, enumValues: {
    myEnum: myEnumValues,
  }, fields: {
    myClass: [myField],
    myMixin: [],
    myEnum: [],
  }, methods: {
    myClass: [myMethod],
    myMixin: [myMixinMethod],
    myEnum: [],
    myExtension: [myGeneratedExtensionMethod],
    myExtensionType: [myGeneratedExtensionTypeMethod],
  }, libraryTypes: {
    Fixtures.library: [
      myClass,
      myEnum,
      myExtension,
      myMixin,
    ],
  }, staticTypes: {
    stringType.identifier: TestNamedStaticType(
      RemoteInstance.uniqueId,
      declaration: stringClass,
      superTypes: [],
      typeArguments: [],
    ),
    myClass.identifier: myClassStaticType,
    mySuperclass.identifier: TestNamedStaticType(
      RemoteInstance.uniqueId,
      declaration: mySuperclass,
      superTypes: [],
      typeArguments: [],
    ),
  }, identifierDeclarations: {
    myClass.identifier: myClass,
    myEnum.identifier: myEnum,
    myExtension.identifier: myExtension,
    mySuperclass.identifier: mySuperclass,
    myInterface.identifier: myInterface,
    myMixin.identifier: myMixin,
    myConstructor.identifier: myConstructor,
    myEnumConstructor.identifier: myEnumConstructor,
    for (EnumValueDeclaration value in myEnumValues) value.identifier: value,
    myField.identifier: myField,
    myMixinMethod.identifier: myMixinMethod,
    myMethod.identifier: myMethod,
  });

  static final testDefinitionPhaseIntrospector =
      TestDefinitionsPhaseIntrospector(
          constructors: testDeclarationPhaseIntrospector.constructors,
          enumValues: testDeclarationPhaseIntrospector.enumValues,
          fields: testDeclarationPhaseIntrospector.fields,
          methods: testDeclarationPhaseIntrospector.methods,
          libraryDeclarations: {
            Fixtures.library: [
              myClass,
              myEnum,
              myMixin,
              myFunction,
              myVariable,
              libraryVariable,
            ],
          },
          libraryTypes: testDeclarationPhaseIntrospector.libraryTypes,
          staticTypes: testDeclarationPhaseIntrospector.staticTypes,
          identifierDeclarations:
              testDeclarationPhaseIntrospector.identifierDeclarations);
}
