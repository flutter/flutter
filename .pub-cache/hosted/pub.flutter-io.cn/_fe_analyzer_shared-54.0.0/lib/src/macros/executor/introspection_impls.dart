// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'remote_instance.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';
import '../api.dart';

class IdentifierImpl extends RemoteInstance implements Identifier {
  @override
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
  @override
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
    required super.id,
    required super.isNullable,
    required this.identifier,
    required this.typeArguments,
  });

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
    required super.id,
    required super.isNullable,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  });

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
  OmittedTypeAnnotationImpl({required super.id}) : super(isNullable: false);

  @override
  TypeAnnotationCode get code => new OmittedTypeAnnotationCode(this);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.omittedTypeAnnotation;
}

abstract class DeclarationImpl extends RemoteInstance implements Declaration {
  @override
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
    required super.id,
    required super.identifier,
    required this.isNamed,
    required this.isRequired,
    required this.type,
  });

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
    required super.id,
    required super.identifier,
    required this.bound,
  });

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
    required super.id,
    required super.identifier,
    required this.isAbstract,
    required this.isExternal,
    required this.isGetter,
    required this.isOperator,
    required this.isSetter,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  });

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
    required super.id,
    required super.identifier,
    // Function fields
    required super.isAbstract,
    required super.isExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    // Method fields
    required this.definingClass,
    required this.isStatic,
  });

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
    required super.id,
    required super.identifier,
    // Function fields
    required super.isAbstract,
    required super.isExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    // Method fields
    required super.definingClass,
    // Constructor fields
    required this.isFactory,
  }) : super(
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
    required super.id,
    required super.identifier,
    required this.isExternal,
    required this.isFinal,
    required this.isLate,
    required this.type,
  });

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
    required super.id,
    required super.identifier,
    // Variable fields
    required super.isExternal,
    required super.isFinal,
    required super.isLate,
    required super.type,
    // Field fields
    required this.definingClass,
    required this.isStatic,
  });

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.fieldDeclaration;

  @override
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
    required super.id,
    required super.identifier,
    required this.typeParameters,
  });

  @override
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
    required super.id,
    required super.identifier,
    // TypeDeclaration fields
    required super.typeParameters,
    // ClassDeclaration fields
    required this.interfaces,
    required this.isAbstract,
    required this.isExternal,
    required this.mixins,
    required this.superclass,
  });

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
  @override
  final TypeAnnotationImpl aliasedType;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeAliasDeclaration;

  TypeAliasDeclarationImpl({
    // Declaration fields
    required super.id,
    required super.identifier,
    // TypeDeclaration fields
    required super.typeParameters,
    // TypeAlias fields
    required this.aliasedType,
  });

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode.isClient) return;

    aliasedType.serialize(serializer);
  }
}
