// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import 'remote_instance.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';

class IdentifierImpl extends RemoteInstance implements Identifier {
  @override
  final String name;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.identifier;

  IdentifierImpl({required int id, required this.name}) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addString(name);
  }

  @override
  bool operator ==(Object other) => other is IdentifierImpl && other.id == id;

  @override
  int get hashCode => id;
}

abstract class TypeAnnotationImpl extends RemoteInstance
    implements TypeAnnotation {
  @override
  final bool isNullable;

  TypeAnnotationImpl({required int id, required this.isNullable}) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addBool(isNullable);
  }
}

class NamedTypeAnnotationImpl extends TypeAnnotationImpl
    implements NamedTypeAnnotation {
  @override
  TypeAnnotationCode get code {
    NamedTypeAnnotationCode underlyingType =
        NamedTypeAnnotationCode(name: identifier, typeArguments: [
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
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    identifier.serialize(serializer);
    serializer.startList();
    for (TypeAnnotationImpl typeArg in typeArguments) {
      typeArg.serialize(serializer);
    }
    serializer.endList();
  }
}

class StaticTypeImpl extends RemoteInstance implements StaticType {
  StaticTypeImpl(super.id);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.staticType;

  // When used by the client, requests need to made through the
  // ClientStaticTypeImpl wrapper which will issue RPC requests to implement
  // these methods.
  @override
  Future<NamedStaticType?> asInstanceOf(TypeDeclaration declaration) {
    throw UnsupportedError('use ClientStaticTypeImpl');
  }

  @override
  Future<bool> isExactly(covariant StaticType other) {
    throw UnsupportedError('use ClientStaticTypeImpl');
  }

  @override
  Future<bool> isSubtypeOf(covariant StaticType other) {
    throw UnsupportedError('use ClientStaticTypeImpl');
  }
}

class NamedStaticTypeImpl extends StaticTypeImpl implements NamedStaticType {
  @override
  final ParameterizedTypeDeclarationImpl declaration;

  @override
  final List<StaticTypeImpl> typeArguments;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.namedStaticType;

  NamedStaticTypeImpl(
    super.id, {
    required this.declaration,
    required this.typeArguments,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);
    declaration.serialize(serializer);
    serializer.startList();
    for (StaticTypeImpl typeArg in typeArguments) {
      typeArg.serialize(serializer);
    }
    serializer.endList();
  }
}

class RecordTypeAnnotationImpl extends TypeAnnotationImpl
    implements RecordTypeAnnotation {
  @override
  TypeAnnotationCode get code {
    RecordTypeAnnotationCode underlyingType = RecordTypeAnnotationCode(
      namedFields: [for (RecordFieldImpl field in namedFields) field.code],
      positionalFields: [
        for (RecordFieldImpl field in positionalFields) field.code
      ],
    );
    return isNullable ? underlyingType.asNullable : underlyingType;
  }

  @override
  final List<RecordFieldImpl> namedFields;

  @override
  final List<RecordFieldImpl> positionalFields;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.recordTypeAnnotation;

  RecordTypeAnnotationImpl({
    required super.id,
    required super.isNullable,
    required this.namedFields,
    required this.positionalFields,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.startList();
    for (RecordFieldImpl field in namedFields) {
      field.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (RecordFieldImpl field in positionalFields) {
      field.serialize(serializer);
    }
    serializer.endList();
  }
}

class RecordFieldImpl extends RemoteInstance implements RecordField {
  @override
  RecordFieldCode get code {
    return RecordFieldCode(type: type.code, name: name);
  }

  @override
  final String? name;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.recordField;

  RecordFieldImpl({
    required int id,
    required this.name,
    required this.type,
  }) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addNullableString(name);
    type.serialize(serializer);
  }
}

class FunctionTypeAnnotationImpl extends TypeAnnotationImpl
    implements FunctionTypeAnnotation {
  @override
  TypeAnnotationCode get code {
    FunctionTypeAnnotationCode underlyingType = FunctionTypeAnnotationCode(
      returnType: returnType.code,
      typeParameters: [
        for (TypeParameter typeParam in typeParameters) typeParam.code,
      ],
      positionalParameters: [
        for (FormalParameter positional in positionalParameters)
          if (positional.isRequired) positional.code,
      ],
      optionalPositionalParameters: [
        for (FormalParameter positional in positionalParameters)
          if (!positional.isRequired) positional.code,
      ],
      namedParameters: [
        for (FormalParameter named in namedParameters) named.code,
      ],
    );
    return isNullable ? underlyingType.asNullable : underlyingType;
  }

  @override
  final List<FormalParameterImpl> namedParameters;

  @override
  final List<FormalParameterImpl> positionalParameters;

  @override
  final TypeAnnotationImpl returnType;

  @override
  final List<TypeParameterImpl> typeParameters;

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
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    returnType.serialize(serializer);

    serializer.startList();
    for (FormalParameterImpl param in positionalParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (FormalParameterImpl param in namedParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (TypeParameterImpl typeParam in typeParameters) {
      typeParam.serialize(serializer);
    }
    serializer.endList();
  }
}

class OmittedTypeAnnotationImpl extends TypeAnnotationImpl
    implements OmittedTypeAnnotation {
  OmittedTypeAnnotationImpl({required super.id}) : super(isNullable: false);

  @override
  TypeAnnotationCode get code => OmittedTypeAnnotationCode(this);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.omittedTypeAnnotation;
}

abstract class MetadataAnnotationImpl extends RemoteInstance
    implements MetadataAnnotation {
  MetadataAnnotationImpl(super.id);
}

class IdentifierMetadataAnnotationImpl extends MetadataAnnotationImpl
    implements IdentifierMetadataAnnotation {
  @override
  final IdentifierImpl identifier;

  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.identifierMetadataAnnotation;

  IdentifierMetadataAnnotationImpl({required int id, required this.identifier})
      : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    identifier.serialize(serializer);
  }
}

class ConstructorMetadataAnnotationImpl extends MetadataAnnotationImpl
    implements ConstructorMetadataAnnotation {
  @override
  final IdentifierImpl constructor;

  @override
  final NamedTypeAnnotationImpl type;

  @override
  final List<ExpressionCode> positionalArguments;

  @override
  final Map<String, ExpressionCode> namedArguments;

  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.constructorMetadataAnnotation;

  ConstructorMetadataAnnotationImpl(
      {required int id,
      required this.constructor,
      required this.type,
      required this.positionalArguments,
      required this.namedArguments})
      : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    constructor.serialize(serializer);
    type.serialize(serializer);
    serializer.startList();
    for (ExpressionCode positionalArgument in positionalArguments) {
      positionalArgument.serialize(serializer);
    }
    serializer.endList();
    serializer.startList();
    for (MapEntry<String, ExpressionCode> entry in namedArguments.entries) {
      serializer.addString(entry.key);
      entry.value.serialize(serializer);
    }
    serializer.endList();
  }
}

abstract class DeclarationImpl extends RemoteInstance implements Declaration {
  @override
  final IdentifierImpl identifier;

  @override
  final LibraryImpl library;

  @override
  final List<MetadataAnnotationImpl> metadata;

  DeclarationImpl({
    required int id,
    required this.identifier,
    required this.library,
    required this.metadata,
  }) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    identifier.serialize(serializer);
    library.serialize(serializer);
    serializer.startList();
    for (MetadataAnnotationImpl annotation in metadata) {
      annotation.serialize(serializer);
    }
    serializer.endList();
  }
}

class FormalParameterDeclarationImpl extends DeclarationImpl
    implements FormalParameterDeclaration {
  @override
  final TypeAnnotationImpl type;

  @override
  final bool isNamed;

  @override
  final bool isRequired;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.formalParameterDeclaration;

  @override
  String get name => identifier.name;

  FormalParameterDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.isNamed,
    required this.isRequired,
    required this.type,
  });

  FormalParameterDeclarationImpl.fromBitMask({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required BitMask<ParameterIntrospectionBit> bitMask,
    required this.type,
  })  : isNamed = bitMask.has(ParameterIntrospectionBit.isNamed),
        isRequired = bitMask.has(ParameterIntrospectionBit.isRequired);

  /// If subclasses have their own values to add to [bitMask], they must do so
  /// before calling this function, and pass the mask here.
  @override
  void serializeUncached(Serializer serializer,
      {BitMask<ParameterIntrospectionBit>? bitMask}) {
    super.serializeUncached(serializer);

    bitMask ??= BitMask();
    if (isNamed) bitMask.add(ParameterIntrospectionBit.isNamed);
    if (isRequired) bitMask.add(ParameterIntrospectionBit.isRequired);
    bitMask.freeze();
    serializer.addInt(bitMask._mask);
    type.serialize(serializer);
  }

  @override
  ParameterCode get code =>
      ParameterCode(name: identifier.name, type: type.code, keywords: [
        if (isNamed && isRequired) 'required',
      ]);
}

class FormalParameterImpl extends RemoteInstance implements FormalParameter {
  @override
  final bool isNamed;

  @override
  final bool isRequired;

  @override
  final List<MetadataAnnotationImpl> metadata;

  @override
  final String? name;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.formalParameter;

  FormalParameterImpl({
    required int id,
    required this.isNamed,
    required this.isRequired,
    required this.metadata,
    required this.name,
    required this.type,
  }) : super(id);

  FormalParameterImpl.fromBitMask({
    required int id,
    required BitMask<ParameterIntrospectionBit> bitMask,
    required this.metadata,
    required this.name,
    required this.type,
  })  : isNamed = bitMask.has(ParameterIntrospectionBit.isNamed),
        isRequired = bitMask.has(ParameterIntrospectionBit.isRequired),
        super(id);

  /// If subclasses have their own values to add to [bitMask], they must do so
  /// before calling this function, and pass the mask here.
  @override
  void serializeUncached(Serializer serializer,
      {BitMask<ParameterIntrospectionBit>? bitMask}) {
    super.serializeUncached(serializer);

    bitMask ??= BitMask();
    if (isNamed) bitMask.add(ParameterIntrospectionBit.isNamed);
    if (isRequired) bitMask.add(ParameterIntrospectionBit.isRequired);
    bitMask.freeze();
    serializer
      ..addInt(bitMask._mask)
      ..startList();
    for (MetadataAnnotationImpl annotation in metadata) {
      annotation.serialize(serializer);
    }
    serializer.endList();
    serializer.addNullableString(name);
    type.serialize(serializer);
  }

  @override
  ParameterCode get code =>
      ParameterCode(name: name, type: type.code, keywords: [
        if (isNamed && isRequired) 'required',
      ]);
}

class TypeParameterImpl extends RemoteInstance implements TypeParameter {
  @override
  final TypeAnnotationImpl? bound;

  @override
  final List<MetadataAnnotationImpl> metadata;

  @override
  final String name;

  @override
  TypeParameterCode get code =>
      TypeParameterCode(name: name, bound: bound?.code);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeParameter;

  TypeParameterImpl({
    required int id,
    required this.bound,
    required this.metadata,
    required this.name,
  }) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    bound.serializeNullable(serializer);
    serializer.startList();
    for (MetadataAnnotationImpl annotation in metadata) {
      annotation.serialize(serializer);
    }
    serializer.endList();
    serializer.addString(name);
  }
}

class TypeParameterDeclarationImpl extends DeclarationImpl
    implements TypeParameterDeclaration {
  @override
  final TypeAnnotationImpl? bound;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeParameterDeclaration;

  @override
  String get name => identifier.name;

  TypeParameterDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.bound,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    bound.serializeNullable(serializer);
  }

  @override
  TypeParameterCode get code =>
      TypeParameterCode(name: identifier.name, bound: bound?.code);
}

class FunctionDeclarationImpl extends DeclarationImpl
    implements FunctionDeclaration {
  @override
  final bool hasBody;

  @override
  final bool hasExternal;

  @override
  final bool isGetter;

  @override
  final bool isOperator;

  @override
  final bool isSetter;

  @override
  final List<FormalParameterDeclarationImpl> namedParameters;

  @override
  final List<FormalParameterDeclarationImpl> positionalParameters;

  @override
  final TypeAnnotationImpl returnType;

  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.functionDeclaration;

  FunctionDeclarationImpl({
    // Declaration fields
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // FunctionDeclaration fields
    required this.hasBody,
    required this.hasExternal,
    required this.isGetter,
    required this.isOperator,
    required this.isSetter,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  });

  FunctionDeclarationImpl.fromBitMask({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required BitMask<FunctionIntrospectionBit> bitMask,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  })  : hasBody = bitMask.has(FunctionIntrospectionBit.hasBody),
        hasExternal = bitMask.has(FunctionIntrospectionBit.hasExternal),
        isGetter = bitMask.has(FunctionIntrospectionBit.isGetter),
        isOperator = bitMask.has(FunctionIntrospectionBit.isOperator),
        isSetter = bitMask.has(FunctionIntrospectionBit.isSetter);

  /// If subclasses have their own values to add to [bitMask], they must do so
  /// before calling this function, and pass the mask here.
  @override
  void serializeUncached(Serializer serializer,
      {BitMask<FunctionIntrospectionBit>? bitMask}) {
    super.serializeUncached(serializer);

    bitMask ??= BitMask();
    if (hasBody) bitMask.add(FunctionIntrospectionBit.hasBody);
    if (hasExternal) bitMask.add(FunctionIntrospectionBit.hasExternal);
    if (isGetter) bitMask.add(FunctionIntrospectionBit.isGetter);
    if (isOperator) bitMask.add(FunctionIntrospectionBit.isOperator);
    if (isSetter) bitMask.add(FunctionIntrospectionBit.isSetter);
    bitMask.freeze();
    serializer
      ..addInt(bitMask._mask)
      ..startList();
    for (FormalParameterDeclarationImpl named in namedParameters) {
      named.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (FormalParameterDeclarationImpl positional in positionalParameters) {
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
  final IdentifierImpl definingType;

  @override
  final bool hasStatic;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.methodDeclaration;

  MethodDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Function fields.
    required super.hasBody,
    required super.hasExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    // Method fields.
    required this.definingType,
    required this.hasStatic,
  });

  MethodDeclarationImpl.fromBitMask({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Function fields.
    required super.bitMask,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    // Method fields.
    required this.definingType,
  })  : hasStatic = bitMask.has(FunctionIntrospectionBit.hasStatic),
        super.fromBitMask();

  /// If subclasses have their own values to add to [bitMask], they must do so
  /// before calling this function, and pass the mask here.
  @override
  void serializeUncached(Serializer serializer,
      {BitMask<FunctionIntrospectionBit>? bitMask}) {
    bitMask ??= BitMask();
    if (hasStatic) bitMask.add(FunctionIntrospectionBit.hasStatic);
    super.serializeUncached(serializer, bitMask: bitMask);

    definingType.serialize(serializer);
  }
}

class ConstructorDeclarationImpl extends MethodDeclarationImpl
    implements ConstructorDeclaration {
  @override
  final bool isFactory;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.constructorDeclaration;

  ConstructorDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Function fields.
    required super.hasBody,
    required super.hasExternal,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    // Method fields.
    required super.definingType,
    // Constructor fields.
    required this.isFactory,
  }) : super(
          isGetter: false,
          isOperator: false,
          isSetter: false,
          hasStatic: true,
        );

  ConstructorDeclarationImpl.fromBitMask({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Function fields.
    required super.bitMask,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    // Method fields.
    required super.definingType,
  })  : isFactory = bitMask.has(FunctionIntrospectionBit.isFactory),
        super.fromBitMask();

  /// If subclasses have their own values to add to [bitMask], they must do so
  /// before calling this function, and pass the mask here.
  @override
  void serializeUncached(Serializer serializer,
      {BitMask<FunctionIntrospectionBit>? bitMask}) {
    bitMask ??= BitMask();
    if (isFactory) bitMask.add(FunctionIntrospectionBit.isFactory);
    super.serializeUncached(serializer, bitMask: bitMask);
  }
}

class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  @override
  final bool hasConst;

  @override
  final bool hasExternal;

  @override
  final bool hasFinal;

  @override
  final bool hasInitializer;

  @override
  final bool hasLate;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.variableDeclaration;

  VariableDeclarationImpl({
    // Declaration fields
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Variable fields
    required this.hasConst,
    required this.hasExternal,
    required this.hasFinal,
    required this.hasInitializer,
    required this.hasLate,
    required this.type,
  });

  VariableDeclarationImpl.fromBitMask({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required BitMask<VariableIntrospectionBit> bitMask,
    required this.type,
  })  : hasConst = bitMask.has(VariableIntrospectionBit.hasConst),
        hasExternal = bitMask.has(VariableIntrospectionBit.hasExternal),
        hasFinal = bitMask.has(VariableIntrospectionBit.hasFinal),
        hasInitializer = bitMask.has(VariableIntrospectionBit.hasInitializer),
        hasLate = bitMask.has(VariableIntrospectionBit.hasLate);

  /// If subclasses have their own values to add to [bitMask], they must do so
  /// before calling this function, and pass the mask here.
  @override
  void serializeUncached(Serializer serializer,
      {BitMask<VariableIntrospectionBit>? bitMask}) {
    super.serializeUncached(serializer);

    bitMask ??= BitMask();
    if (hasConst) bitMask.add(VariableIntrospectionBit.hasConst);
    if (hasExternal) bitMask.add(VariableIntrospectionBit.hasExternal);
    if (hasFinal) bitMask.add(VariableIntrospectionBit.hasFinal);
    if (hasInitializer) bitMask.add(VariableIntrospectionBit.hasInitializer);
    if (hasLate) bitMask.add(VariableIntrospectionBit.hasLate);
    bitMask.freeze();
    serializer.addInt(bitMask._mask);
    type.serialize(serializer);
  }
}

class FieldDeclarationImpl extends VariableDeclarationImpl
    implements FieldDeclaration {
  @override
  final IdentifierImpl definingType;

  @override
  final bool hasAbstract;

  @override
  final bool hasStatic;

  FieldDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Variable fields.
    required super.hasConst,
    required super.hasExternal,
    required super.hasFinal,
    required super.hasInitializer,
    required super.hasLate,
    required super.type,
    // Field fields.
    required this.definingType,
    required this.hasAbstract,
    required this.hasStatic,
  });

  FieldDeclarationImpl.fromBitMask({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Variable fields.
    required super.bitMask,
    required super.type,
    // Field fields.
    required this.definingType,
  })  : hasAbstract = bitMask.has(VariableIntrospectionBit.hasAbstract),
        hasStatic = bitMask.has(VariableIntrospectionBit.hasStatic),
        super.fromBitMask();

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.fieldDeclaration;

  /// If subclasses have their own values to add to [bitMask], they must do so
  /// before calling this function, and pass the mask here.
  @override
  void serializeUncached(Serializer serializer,
      {BitMask<VariableIntrospectionBit>? bitMask}) {
    bitMask ??= BitMask();
    if (hasAbstract) bitMask.add(VariableIntrospectionBit.hasAbstract);
    if (hasStatic) bitMask.add(VariableIntrospectionBit.hasStatic);
    super.serializeUncached(serializer, bitMask: bitMask);

    definingType.serialize(serializer);
  }
}

abstract interface class TypeDeclarationImpl
    implements DeclarationImpl, TypeDeclaration {}

abstract class ParameterizedTypeDeclarationImpl extends DeclarationImpl
    implements ParameterizedTypeDeclaration, TypeDeclarationImpl {
  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  ParameterizedTypeDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.typeParameters,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.startList();
    for (TypeParameterDeclarationImpl param in typeParameters) {
      param.serialize(serializer);
    }
    serializer.endList();
  }
}

class ClassDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements ClassDeclaration {
  @override
  final bool hasAbstract;

  @override
  final bool hasBase;

  @override
  final bool hasExternal;

  @override
  final bool hasFinal;

  @override
  final bool hasInterface;

  @override
  final bool hasMixin;

  @override
  final bool hasSealed;

  @override
  final List<NamedTypeAnnotationImpl> interfaces;

  @override
  final List<NamedTypeAnnotationImpl> mixins;

  @override
  final NamedTypeAnnotationImpl? superclass;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.classDeclaration;

  ClassDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // ClassDeclaration fields.
    required this.hasAbstract,
    required this.hasBase,
    required this.hasExternal,
    required this.hasFinal,
    required this.hasInterface,
    required this.hasMixin,
    required this.hasSealed,
    required this.interfaces,
    required this.mixins,
    required this.superclass,
  });

  ClassDeclarationImpl.fromBitMask({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // ClassDeclaration fields.
    required BitMask<ClassIntrospectionBit> bitMask,
    required this.interfaces,
    required this.mixins,
    required this.superclass,
  })  : hasAbstract = bitMask.has(ClassIntrospectionBit.hasAbstract),
        hasBase = bitMask.has(ClassIntrospectionBit.hasBase),
        hasExternal = bitMask.has(ClassIntrospectionBit.hasExternal),
        hasFinal = bitMask.has(ClassIntrospectionBit.hasFinal),
        hasInterface = bitMask.has(ClassIntrospectionBit.hasInterface),
        hasMixin = bitMask.has(ClassIntrospectionBit.hasMixin),
        hasSealed = bitMask.has(ClassIntrospectionBit.hasSealed);

  /// If subclasses have their own values to add to [bitMask], they must do so
  /// before calling this function, and pass the mask here.
  @override
  void serializeUncached(Serializer serializer, {BitMask? bitMask}) {
    super.serializeUncached(serializer);

    bitMask ??= BitMask();
    if (hasAbstract) bitMask.add(ClassIntrospectionBit.hasAbstract);
    if (hasBase) bitMask.add(ClassIntrospectionBit.hasBase);
    if (hasExternal) bitMask.add(ClassIntrospectionBit.hasExternal);
    if (hasFinal) bitMask.add(ClassIntrospectionBit.hasFinal);
    if (hasInterface) bitMask.add(ClassIntrospectionBit.hasInterface);
    if (hasMixin) bitMask.add(ClassIntrospectionBit.hasMixin);
    if (hasSealed) bitMask.add(ClassIntrospectionBit.hasSealed);
    bitMask.freeze();
    serializer
      ..addInt(bitMask._mask)
      ..startList();
    for (NamedTypeAnnotationImpl interface in interfaces) {
      interface.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (NamedTypeAnnotationImpl mixin in mixins) {
      mixin.serialize(serializer);
    }
    serializer.endList();
    superclass.serializeNullable(serializer);
  }
}

class EnumDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements EnumDeclaration {
  @override
  final List<NamedTypeAnnotationImpl> interfaces;

  @override
  final List<NamedTypeAnnotationImpl> mixins;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.enumDeclaration;

  EnumDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // EnumDeclaration fields.
    required this.interfaces,
    required this.mixins,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.startList();
    for (NamedTypeAnnotationImpl interface in interfaces) {
      interface.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (NamedTypeAnnotationImpl mixin in mixins) {
      mixin.serialize(serializer);
    }
    serializer.endList();
  }
}

class EnumValueDeclarationImpl extends DeclarationImpl
    implements EnumValueDeclaration {
  @override
  final IdentifierImpl definingEnum;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.enumValueDeclaration;

  EnumValueDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.definingEnum,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    definingEnum.serialize(serializer);
  }
}

class ExtensionDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements ExtensionDeclaration {
  @override
  final TypeAnnotationImpl onType;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.extensionDeclaration;

  ExtensionDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // ParameterizedTypeDeclaration fields.
    required super.typeParameters,
    // ExtensionDeclaration fields.
    required this.onType,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    onType.serialize(serializer);
  }
}

class ExtensionTypeDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements ExtensionTypeDeclaration {
  @override
  final TypeAnnotationImpl representationType;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.extensionTypeDeclaration;

  ExtensionTypeDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // ParameterizedTypeDeclaration fields.
    required super.typeParameters,
    // ExtensionTypeDeclaration fields.
    required this.representationType,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    representationType.serialize(serializer);
  }
}

class MixinDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements MixinDeclaration {
  @override
  final bool hasBase;

  @override
  final List<NamedTypeAnnotationImpl> interfaces;

  @override
  final List<NamedTypeAnnotationImpl> superclassConstraints;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.mixinDeclaration;

  MixinDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // MixinDeclaration fields.
    required this.hasBase,
    required this.interfaces,
    required this.superclassConstraints,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer
      ..addBool(hasBase)
      ..startList();
    for (NamedTypeAnnotationImpl interface in interfaces) {
      interface.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (NamedTypeAnnotationImpl constraint in superclassConstraints) {
      constraint.serialize(serializer);
    }
    serializer.endList();
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
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // TypeAlias fields.
    required this.aliasedType,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    aliasedType.serialize(serializer);
  }
}

class LibraryImpl extends RemoteInstance implements Library {
  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.library;

  @override
  final LanguageVersionImpl languageVersion;

  @override
  final List<MetadataAnnotationImpl> metadata;

  @override
  final Uri uri;

  LibraryImpl(
      {required int id,
      required this.languageVersion,
      required this.metadata,
      required this.uri})
      : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    languageVersion.serialize(serializer);
    serializer.startList();
    for (MetadataAnnotationImpl annotation in metadata) {
      annotation.serialize(serializer);
    }
    serializer.endList();
    serializer.addUri(uri);
  }
}

/// This class doesn't implement [RemoteInstance] as it is always attached to a
/// [Library] and doesn't need its own kind or ID.
class LanguageVersionImpl implements LanguageVersion, Serializable {
  @override
  final int major;

  @override
  final int minor;

  LanguageVersionImpl(this.major, this.minor);

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(major)
      ..addInt(minor);
  }
}

/// A general bit mask class for specific enum types.
///
/// This should always be specialized to exactly one enum type, since the mask
/// uses the enum indexes.
final class BitMask<T extends Enum> {
  int _mask;
  bool _frozen = false;

  BitMask([this._mask = 0])
      : assert(
          T is! Enum,
        );

  void add(T bit) {
    if (_frozen) throw StateError('Cannot modify a frozen BitMask');
    _mask |= bit.mask;
  }

  bool has(T bit) {
    return (_mask & bit.mask) != 0;
  }

  void freeze() => _frozen = true;
}

/// Defines the bits for the bit mask for all boolean class fields.
enum ClassIntrospectionBit {
  hasAbstract,
  hasBase,
  hasExternal,
  hasFinal,
  hasInterface,
  hasMixin,
  hasSealed;
}

/// Defines the bits for the bit mask for all boolean function fields.
enum FunctionIntrospectionBit {
  hasBody,
  hasExternal,
  hasStatic,
  isFactory,
  isGetter,
  isOperator,
  isSetter,
}

/// Defines the bits for the bit mask for all boolean parameter fields.
enum ParameterIntrospectionBit {
  isNamed,
  isRequired,
}

/// Defines the bits for the bit mask for all boolean variable fields.
enum VariableIntrospectionBit {
  hasAbstract,
  hasConst,
  hasExternal,
  hasFinal,
  hasInitializer,
  hasLate,
  hasStatic;
}

extension on Enum {
  /// The mask bit for this enum value based on its index.
  int get mask => 1 << index;
}
