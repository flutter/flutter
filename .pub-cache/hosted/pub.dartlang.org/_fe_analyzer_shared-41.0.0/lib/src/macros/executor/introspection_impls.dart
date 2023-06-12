// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'remote_instance.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';
import '../api.dart';

class IdentifierImpl extends RemoteInstance implements Identifier {
  final String name;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.identifier;

  IdentifierImpl({required int id, required this.name}) : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer.addString(name);
  }
}

abstract class TypeAnnotationImpl extends RemoteInstance
    implements TypeAnnotation {
  final bool isNullable;

  TypeAnnotationImpl({required int id, required this.isNullable}) : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer.addBool(isNullable);
  }
}

class NamedTypeAnnotationImpl extends TypeAnnotationImpl
    implements NamedTypeAnnotation {
  @override
  TypeAnnotationCode get code {
    NamedTypeAnnotationCode underlyingType =
        new NamedTypeAnnotationCode(name: identifier, typeArguments: [
      for (TypeAnnotation typeArg in typeArguments) typeArg.code,
    ]);
    return isNullable ? underlyingType.asNullable : underlyingType;
  }

  @override
  final IdentifierImpl identifier;

  @override
  final List<TypeAnnotationImpl> typeArguments;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.namedTypeAnnotation;

  NamedTypeAnnotationImpl({
    required int id,
    required bool isNullable,
    required this.identifier,
    required this.typeArguments,
  }) : super(id: id, isNullable: isNullable);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    identifier.serialize(serializer);
    serializer.startList();
    for (TypeAnnotationImpl typeArg in typeArguments) {
      typeArg.serialize(serializer);
    }
    serializer.endList();
  }
}

class FunctionTypeAnnotationImpl extends TypeAnnotationImpl
    implements FunctionTypeAnnotation {
  @override
  TypeAnnotationCode get code {
    FunctionTypeAnnotationCode underlyingType = new FunctionTypeAnnotationCode(
      returnType: returnType.code,
      typeParameters: [
        for (TypeParameterDeclaration typeParam in typeParameters)
          typeParam.code,
      ],
      positionalParameters: [
        for (FunctionTypeParameter positional in positionalParameters)
          positional.code,
      ],
      namedParameters: [
        for (FunctionTypeParameter named in namedParameters) named.code,
      ],
    );
    return isNullable ? underlyingType.asNullable : underlyingType;
  }

  @override
  final List<FunctionTypeParameterImpl> namedParameters;

  @override
  final List<FunctionTypeParameterImpl> positionalParameters;

  @override
  final TypeAnnotationImpl returnType;

  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.functionTypeAnnotation;

  FunctionTypeAnnotationImpl({
    required int id,
    required bool isNullable,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  }) : super(id: id, isNullable: isNullable);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    returnType.serialize(serializer);

    serializer.startList();
    for (FunctionTypeParameterImpl param in positionalParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (FunctionTypeParameterImpl param in namedParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (TypeParameterDeclarationImpl typeParam in typeParameters) {
      typeParam.serialize(serializer);
    }
    serializer.endList();
  }
}

class OmittedTypeAnnotationImpl extends TypeAnnotationImpl
    implements OmittedTypeAnnotation {
  OmittedTypeAnnotationImpl({required int id})
      : super(id: id, isNullable: false);

  @override
  TypeAnnotationCode get code => new OmittedTypeAnnotationCode(this);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.omittedTypeAnnotation;
}

abstract class DeclarationImpl extends RemoteInstance implements Declaration {
  final IdentifierImpl identifier;

  DeclarationImpl({required int id, required this.identifier}) : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    identifier.serialize(serializer);
  }
}

class ParameterDeclarationImpl extends DeclarationImpl
    implements ParameterDeclaration {
  @override
  final bool isNamed;

  @override
  final bool isRequired;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.parameterDeclaration;

  ParameterDeclarationImpl({
    required int id,
    required IdentifierImpl identifier,
    required this.isNamed,
    required this.isRequired,
    required this.type,
  }) : super(id: id, identifier: identifier);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer.addBool(isNamed);
    serializer.addBool(isRequired);
    type.serialize(serializer);
  }

  @override
  ParameterCode get code =>
      new ParameterCode(name: identifier.name, type: type.code, keywords: [
        if (isNamed && isRequired) 'required',
      ]);
}

class FunctionTypeParameterImpl extends RemoteInstance
    implements FunctionTypeParameter {
  @override
  final bool isNamed;

  @override
  final bool isRequired;

  @override
  final String? name;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.functionTypeParameter;

  FunctionTypeParameterImpl({
    required int id,
    required this.isNamed,
    required this.isRequired,
    required this.name,
    required this.type,
  }) : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer.addBool(isNamed);
    serializer.addBool(isRequired);
    serializer.addNullableString(name);
    type.serialize(serializer);
  }

  @override
  ParameterCode get code =>
      new ParameterCode(name: name, type: type.code, keywords: [
        if (isNamed && isRequired) 'required',
      ]);
}

class TypeParameterDeclarationImpl extends DeclarationImpl
    implements TypeParameterDeclaration {
  @override
  final TypeAnnotationImpl? bound;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeParameterDeclaration;

  TypeParameterDeclarationImpl({
    required int id,
    required IdentifierImpl identifier,
    required this.bound,
  }) : super(id: id, identifier: identifier);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    TypeAnnotationImpl? bound = this.bound;
    if (bound == null) {
      serializer.addNull();
    } else {
      bound.serialize(serializer);
    }
  }

  @override
  TypeParameterCode get code =>
      new TypeParameterCode(name: identifier.name, bound: bound?.code);
}

class FunctionDeclarationImpl extends DeclarationImpl
    implements FunctionDeclaration {
  @override
  final bool isAbstract;

  @override
  final bool isExternal;

  @override
  final bool isGetter;

  @override
  final bool isOperator;

  @override
  final bool isSetter;

  @override
  final List<ParameterDeclarationImpl> namedParameters;

  @override
  final List<ParameterDeclarationImpl> positionalParameters;

  @override
  final TypeAnnotationImpl returnType;

  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.functionDeclaration;

  FunctionDeclarationImpl({
    required int id,
    required IdentifierImpl identifier,
    required this.isAbstract,
    required this.isExternal,
    required this.isGetter,
    required this.isOperator,
    required this.isSetter,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  }) : super(id: id, identifier: identifier);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer
      ..addBool(isAbstract)
      ..addBool(isExternal)
      ..addBool(isGetter)
      ..addBool(isOperator)
      ..addBool(isSetter)
      ..startList();
    for (ParameterDeclarationImpl named in namedParameters) {
      named.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (ParameterDeclarationImpl positional in positionalParameters) {
      positional.serialize(serializer);
    }
    serializer.endList();
    returnType.serialize(serializer);
    serializer.startList();
    for (TypeParameterDeclarationImpl param in typeParameters) {
      param.serialize(serializer);
    }
    serializer.endList();
  }
}

class MethodDeclarationImpl extends FunctionDeclarationImpl
    implements MethodDeclaration {
  @override
  final IdentifierImpl definingClass;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.methodDeclaration;

  @override
  final bool isStatic;

  MethodDeclarationImpl({
    // Declaration fields
    required int id,
    required IdentifierImpl identifier,
    // Function fields
    required bool isAbstract,
    required bool isExternal,
    required bool isGetter,
    required bool isOperator,
    required bool isSetter,
    required List<ParameterDeclarationImpl> namedParameters,
    required List<ParameterDeclarationImpl> positionalParameters,
    required TypeAnnotationImpl returnType,
    required List<TypeParameterDeclarationImpl> typeParameters,
    // Method fields
    required this.definingClass,
    required this.isStatic,
  }) : super(
          id: id,
          identifier: identifier,
          isAbstract: isAbstract,
          isExternal: isExternal,
          isGetter: isGetter,
          isOperator: isOperator,
          isSetter: isSetter,
          namedParameters: namedParameters,
          positionalParameters: positionalParameters,
          returnType: returnType,
          typeParameters: typeParameters,
        );

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    definingClass.serialize(serializer);
    serializer.addBool(isStatic);
  }
}

class ConstructorDeclarationImpl extends MethodDeclarationImpl
    implements ConstructorDeclaration {
  @override
  final bool isFactory;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.constructorDeclaration;

  ConstructorDeclarationImpl({
    // Declaration fields
    required int id,
    required IdentifierImpl identifier,
    // Function fields
    required bool isAbstract,
    required bool isExternal,
    required bool isGetter,
    required bool isOperator,
    required bool isSetter,
    required List<ParameterDeclarationImpl> namedParameters,
    required List<ParameterDeclarationImpl> positionalParameters,
    required TypeAnnotationImpl returnType,
    required List<TypeParameterDeclarationImpl> typeParameters,
    // Method fields
    required IdentifierImpl definingClass,
    // Constructor fields
    required this.isFactory,
  }) : super(
          id: id,
          identifier: identifier,
          isAbstract: isAbstract,
          isExternal: isExternal,
          isGetter: isGetter,
          isOperator: isOperator,
          isSetter: isSetter,
          namedParameters: namedParameters,
          positionalParameters: positionalParameters,
          returnType: returnType,
          typeParameters: typeParameters,
          definingClass: definingClass,
          isStatic: true,
        );

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer.addBool(isFactory);
  }
}

class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  @override
  final bool isExternal;

  @override
  final bool isFinal;

  @override
  final bool isLate;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.variableDeclaration;

  VariableDeclarationImpl({
    required int id,
    required IdentifierImpl identifier,
    required this.isExternal,
    required this.isFinal,
    required this.isLate,
    required this.type,
  }) : super(id: id, identifier: identifier);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer
      ..addBool(isExternal)
      ..addBool(isFinal)
      ..addBool(isLate);
    type.serialize(serializer);
  }
}

class FieldDeclarationImpl extends VariableDeclarationImpl
    implements FieldDeclaration {
  @override
  final IdentifierImpl definingClass;

  @override
  final bool isStatic;

  FieldDeclarationImpl({
    // Declaration fields
    required int id,
    required IdentifierImpl identifier,
    // Variable fields
    required bool isExternal,
    required bool isFinal,
    required bool isLate,
    required TypeAnnotationImpl type,
    // Field fields
    required this.definingClass,
    required this.isStatic,
  }) : super(
            id: id,
            identifier: identifier,
            isExternal: isExternal,
            isFinal: isFinal,
            isLate: isLate,
            type: type);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.fieldDeclaration;

  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    definingClass.serialize(serializer);
    serializer.addBool(isStatic);
  }
}

abstract class ParameterizedTypeDeclarationImpl extends DeclarationImpl
    implements ParameterizedTypeDeclaration {
  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  ParameterizedTypeDeclarationImpl({
    required int id,
    required IdentifierImpl identifier,
    required this.typeParameters,
  }) : super(id: id, identifier: identifier);

  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer..startList();
    for (TypeParameterDeclarationImpl param in typeParameters) {
      param.serialize(serializer);
    }
    serializer.endList();
  }
}

class IntrospectableClassDeclarationImpl = ClassDeclarationImpl
    with IntrospectableType
    implements IntrospectableClassDeclaration;

class ClassDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements ClassDeclaration {
  @override
  final List<NamedTypeAnnotationImpl> interfaces;

  @override
  final bool isAbstract;

  @override
  final bool isExternal;

  @override
  final List<NamedTypeAnnotationImpl> mixins;

  @override
  final NamedTypeAnnotationImpl? superclass;

  @override
  RemoteInstanceKind get kind => this is IntrospectableClassDeclaration
      ? RemoteInstanceKind.introspectableClassDeclaration
      : RemoteInstanceKind.classDeclaration;

  ClassDeclarationImpl({
    // Declaration fields
    required int id,
    required IdentifierImpl identifier,
    // TypeDeclaration fields
    required List<TypeParameterDeclarationImpl> typeParameters,
    // ClassDeclaration fields
    required this.interfaces,
    required this.isAbstract,
    required this.isExternal,
    required this.mixins,
    required this.superclass,
  }) : super(id: id, identifier: identifier, typeParameters: typeParameters);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    serializer.startList();
    for (NamedTypeAnnotationImpl interface in interfaces) {
      interface.serialize(serializer);
    }
    serializer
      ..endList()
      ..addBool(isAbstract)
      ..addBool(isExternal)
      ..startList();
    for (NamedTypeAnnotationImpl mixin in mixins) {
      mixin.serialize(serializer);
    }
    serializer..endList();
    superclass.serializeNullable(serializer);
  }
}

class TypeAliasDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements TypeAliasDeclaration {
  /// The type being aliased.
  final TypeAnnotationImpl aliasedType;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeAliasDeclaration;

  TypeAliasDeclarationImpl({
    // Declaration fields
    required int id,
    required IdentifierImpl identifier,
    // TypeDeclaration fields
    required List<TypeParameterDeclarationImpl> typeParameters,
    // TypeAlias fields
    required this.aliasedType,
  }) : super(id: id, identifier: identifier, typeParameters: typeParameters);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    aliasedType.serialize(serializer);
  }
}
