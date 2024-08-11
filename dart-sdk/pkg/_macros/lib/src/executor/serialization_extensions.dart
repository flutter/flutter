// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import 'exception_impls.dart';
import 'introspection_impls.dart';
import 'remote_instance.dart';
import 'serialization.dart';

extension DeserializerExtensions on Deserializer {
  T expectRemoteInstance<T extends Object>() {
    int id = expectInt();

    // If cached, just return the instance. Only the ID should be sent.
    RemoteInstance? cached = RemoteInstance.cached(id);
    if (cached != null) {
      return cached as T;
    }

    moveNext();
    RemoteInstanceKind kind = RemoteInstanceKind.values[expectInt()];
    final RemoteInstance instance = switch (kind) {
      RemoteInstanceKind.declarationPhaseIntrospector ||
      RemoteInstanceKind.definitionPhaseIntrospector ||
      RemoteInstanceKind.typePhaseIntrospector =>
        // These are simple wrappers, just pass in the kind
        RemoteInstanceImpl(id: id, kind: kind),
      RemoteInstanceKind.classDeclaration =>
        (this..moveNext())._expectClassDeclaration(id),
      RemoteInstanceKind.constructorMetadataAnnotation =>
        (this..moveNext())._expectConstructorMetadataAnnotation(id),
      RemoteInstanceKind.enumDeclaration =>
        (this..moveNext())._expectEnumDeclaration(id),
      RemoteInstanceKind.enumValueDeclaration =>
        (this..moveNext())._expectEnumValueDeclaration(id),
      RemoteInstanceKind.extensionDeclaration =>
        (this..moveNext())._expectExtensionDeclaration(id),
      RemoteInstanceKind.extensionTypeDeclaration =>
        (this..moveNext())._expectExtensionTypeDeclaration(id),
      RemoteInstanceKind.mixinDeclaration =>
        (this..moveNext())._expectMixinDeclaration(id),
      RemoteInstanceKind.constructorDeclaration =>
        (this..moveNext())._expectConstructorDeclaration(id),
      RemoteInstanceKind.fieldDeclaration =>
        (this..moveNext())._expectFieldDeclaration(id),
      RemoteInstanceKind.functionDeclaration =>
        (this..moveNext())._expectFunctionDeclaration(id),
      RemoteInstanceKind.functionTypeAnnotation =>
        (this..moveNext())._expectFunctionTypeAnnotation(id),
      RemoteInstanceKind.formalParameter =>
        (this..moveNext())._expectFormalParameter(id),
      RemoteInstanceKind.identifier => (this..moveNext())._expectIdentifier(id),
      RemoteInstanceKind.identifierMetadataAnnotation =>
        (this..moveNext())._expectIdentifierMetadataAnnotation(id),
      RemoteInstanceKind.library => (this..moveNext())._expectLibrary(id),
      RemoteInstanceKind.methodDeclaration =>
        (this..moveNext())._expectMethodDeclaration(id),
      RemoteInstanceKind.namedStaticType =>
        (this..moveNext())._expectNamedStaticType(id),
      RemoteInstanceKind.namedTypeAnnotation =>
        (this..moveNext())._expectNamedTypeAnnotation(id),
      RemoteInstanceKind.omittedTypeAnnotation =>
        (this..moveNext())._expectOmittedTypeAnnotation(id),
      RemoteInstanceKind.formalParameterDeclaration =>
        (this..moveNext())._expectFormalParameterDeclaration(id),
      RemoteInstanceKind.recordField =>
        (this..moveNext())._expectRecordField(id),
      RemoteInstanceKind.recordTypeAnnotation =>
        (this..moveNext())._expectRecordTypeAnnotation(id),
      RemoteInstanceKind.staticType => StaticTypeImpl(id),
      RemoteInstanceKind.typeAliasDeclaration =>
        (this..moveNext())._expectTypeAliasDeclaration(id),
      RemoteInstanceKind.typeParameter =>
        (this..moveNext())._expectTypeParameter(id),
      RemoteInstanceKind.typeParameterDeclaration =>
        (this..moveNext())._expectTypeParameterDeclaration(id),
      RemoteInstanceKind.variableDeclaration =>
        (this..moveNext())._expectVariableDeclaration(id),

      // Exceptions.
      RemoteInstanceKind.macroImplementationException ||
      RemoteInstanceKind.macroIntrospectionCycleException ||
      RemoteInstanceKind.unexpectedMacroException =>
        (this..moveNext())._expectException(kind, id),
    };
    RemoteInstance.cache(instance);
    return instance as T;
  }

  Uri expectUri() => Uri.parse(expectString());

  /// Reads a list of [RemoteInstance]s.
  List<T> _expectRemoteInstanceList<T extends RemoteInstance>() {
    expectList();
    return [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];
  }

  /// Reads a list of [Code]s.
  List<T> _expectCodeList<T extends Code>() {
    expectList();
    return [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectCode(),
    ];
  }

  /// Reads a `Map<String, T extends Code>`.
  Map<String, T> _expectStringCodeMap<T extends Code>() {
    expectList();
    return {
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectString(): (this..moveNext()).expectCode(),
    };
  }

  NamedStaticTypeImpl _expectNamedStaticType(int id) {
    return NamedStaticTypeImpl(
      id,
      declaration: expectRemoteInstance(),
      typeArguments: (this..moveNext())._expectRemoteInstanceList(),
    );
  }

  NamedTypeAnnotationImpl _expectNamedTypeAnnotation(int id) =>
      NamedTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        identifier: RemoteInstance.deserialize(this),
        typeArguments: (this..moveNext())._expectRemoteInstanceList(),
      );

  OmittedTypeAnnotationImpl _expectOmittedTypeAnnotation(int id) {
    expectBool(); // Always `false`.
    return OmittedTypeAnnotationImpl(
      id: id,
    );
  }

  FunctionTypeAnnotationImpl _expectFunctionTypeAnnotation(int id) =>
      FunctionTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        returnType: RemoteInstance.deserialize(this),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  FormalParameterImpl _expectFormalParameter(int id) =>
      FormalParameterImpl.fromBitMask(
        id: id,
        bitMask: BitMask(expectInt()),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        name: (this..moveNext()).expectNullableString(),
        type: RemoteInstance.deserialize(this),
      );

  IdentifierImpl _expectIdentifier(int id) => IdentifierImpl(
        id: id,
        name: expectString(),
      );

  FormalParameterDeclarationImpl _expectFormalParameterDeclaration(int id) =>
      FormalParameterDeclarationImpl.fromBitMask(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        bitMask: BitMask((this..moveNext()).expectInt()),
        type: RemoteInstance.deserialize(this),
      );

  RecordFieldImpl _expectRecordField(int id) => RecordFieldImpl(
      id: id,
      name: expectNullableString(),
      type: (this..moveNext()).expectRemoteInstance());

  RecordTypeAnnotationImpl _expectRecordTypeAnnotation(int id) =>
      RecordTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        namedFields: (this..moveNext())._expectRemoteInstanceList(),
        positionalFields: (this..moveNext())._expectRemoteInstanceList(),
      );

  TypeParameterImpl _expectTypeParameter(int id) => TypeParameterImpl(
        id: id,
        bound: checkNull() ? null : expectRemoteInstance(),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        name: (this..moveNext()).expectString(),
      );

  TypeParameterDeclarationImpl _expectTypeParameterDeclaration(int id) =>
      TypeParameterDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        bound: (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  FunctionDeclarationImpl _expectFunctionDeclaration(int id) =>
      FunctionDeclarationImpl.fromBitMask(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        bitMask: BitMask((this..moveNext()).expectInt()),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  MethodDeclarationImpl _expectMethodDeclaration(int id) =>
      MethodDeclarationImpl.fromBitMask(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        bitMask: BitMask((this..moveNext()).expectInt()),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        definingType: RemoteInstance.deserialize(this),
      );

  ConstructorDeclarationImpl _expectConstructorDeclaration(int id) =>
      ConstructorDeclarationImpl.fromBitMask(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        bitMask: BitMask((this..moveNext()).expectInt()),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        definingType: RemoteInstance.deserialize(this),
      );

  VariableDeclarationImpl _expectVariableDeclaration(int id) =>
      VariableDeclarationImpl.fromBitMask(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        bitMask: BitMask((this..moveNext()).expectInt()),
        type: RemoteInstance.deserialize(this),
      );

  FieldDeclarationImpl _expectFieldDeclaration(int id) =>
      FieldDeclarationImpl.fromBitMask(
        id: id,
        // Declaration fields.
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        bitMask: BitMask((this..moveNext()).expectInt()),
        type: RemoteInstance.deserialize(this),
        // FieldDeclaration fields
        definingType: RemoteInstance.deserialize(this),
      );

  ClassDeclarationImpl _expectClassDeclaration(int id) =>
      ClassDeclarationImpl.fromBitMask(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        bitMask: BitMask((this..moveNext()).expectInt()),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
        superclass:
            (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  ConstructorMetadataAnnotationImpl _expectConstructorMetadataAnnotation(
          int id) =>
      ConstructorMetadataAnnotationImpl(
          id: id,
          constructor: expectRemoteInstance(),
          type: RemoteInstance.deserialize(this),
          positionalArguments: (this..moveNext())._expectCodeList(),
          namedArguments: (this..moveNext())._expectStringCodeMap());

  IdentifierMetadataAnnotationImpl _expectIdentifierMetadataAnnotation(
          int id) =>
      IdentifierMetadataAnnotationImpl(
        id: id,
        identifier: expectRemoteInstance(),
      );

  EnumDeclarationImpl _expectEnumDeclaration(int id) => EnumDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
      );

  MixinDeclarationImpl _expectMixinDeclaration(int id) => MixinDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        hasBase: (this..moveNext()).expectBool(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        superclassConstraints: (this..moveNext())._expectRemoteInstanceList(),
      );

  EnumValueDeclarationImpl _expectEnumValueDeclaration(int id) =>
      EnumValueDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        definingEnum: RemoteInstance.deserialize(this),
      );

  MacroExceptionImpl _expectException(RemoteInstanceKind kind, int id) =>
      MacroExceptionImpl(
        id: id,
        kind: kind,
        message: expectString(),
        stackTrace: (this..moveNext()).expectNullableString(),
      );

  ExtensionDeclarationImpl _expectExtensionDeclaration(int id) =>
      ExtensionDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        onType: RemoteInstance.deserialize(this),
      );

  ExtensionTypeDeclarationImpl _expectExtensionTypeDeclaration(int id) =>
      ExtensionTypeDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        representationType: RemoteInstance.deserialize(this),
      );

  TypeAliasDeclarationImpl _expectTypeAliasDeclaration(int id) =>
      TypeAliasDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        aliasedType: RemoteInstance.deserialize(this),
      );

  LibraryImpl _expectLibrary(int id) => LibraryImpl(
        id: id,
        languageVersion:
            LanguageVersionImpl(expectInt(), (this..moveNext()).expectInt()),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        uri: (this..moveNext()).expectUri(),
      );

  List<String> _readStringList() => [
        for (bool hasNext = (this
                  ..moveNext()
                  ..expectList())
                .moveNext();
            hasNext;
            hasNext = moveNext())
          expectString(),
      ];

  List<T> _readCodeList<T extends Code>() => [
        for (bool hasNext = (this
                  ..moveNext()
                  ..expectList())
                .moveNext();
            hasNext;
            hasNext = moveNext())
          expectCode(),
      ];

  List<Object> _readParts() {
    moveNext();
    expectList();
    List<Object> parts = [];
    while (moveNext()) {
      _CodePartKind partKind = _CodePartKind.values[expectInt()];
      moveNext();
      switch (partKind) {
        case _CodePartKind.code:
          parts.add(expectCode());
          break;
        case _CodePartKind.string:
          parts.add(expectString());
          break;
        case _CodePartKind.identifier:
          parts.add(expectRemoteInstance());
          break;
      }
    }
    return parts;
  }

  T expectCode<T extends Code>() {
    CodeKind kind = CodeKind.values[expectInt()];

    return switch (kind) {
      CodeKind.raw => RawCode.fromParts(_readParts()) as T,
      CodeKind.rawTypeAnnotation =>
        RawTypeAnnotationCode.fromParts(_readParts()) as T,
      CodeKind.comment => CommentCode.fromParts(_readParts()) as T,
      CodeKind.declaration => DeclarationCode.fromParts(_readParts()) as T,
      CodeKind.expression => ExpressionCode.fromParts(_readParts()) as T,
      CodeKind.functionBody => FunctionBodyCode.fromParts(_readParts()) as T,
      CodeKind.functionTypeAnnotation => FunctionTypeAnnotationCode(
          namedParameters: _readCodeList(),
          positionalParameters: _readCodeList(),
          returnType: (this..moveNext()).expectNullableCode(),
          typeParameters: _readCodeList()) as T,
      CodeKind.namedTypeAnnotation => NamedTypeAnnotationCode(
          name: RemoteInstance.deserialize(this) as Identifier,
          typeArguments: _readCodeList()) as T,
      CodeKind.nullableTypeAnnotation =>
        NullableTypeAnnotationCode((this..moveNext()).expectCode()) as T,
      CodeKind.omittedTypeAnnotation =>
        OmittedTypeAnnotationCode(RemoteInstance.deserialize(this)) as T,
      CodeKind.parameter => ParameterCode(
          defaultValue: (this..moveNext()).expectNullableCode(),
          keywords: _readStringList(),
          name: (this..moveNext()).expectNullableString(),
          type: (this..moveNext()).expectNullableCode()) as T,
      CodeKind.recordField => RecordFieldCode(
          name: (this..moveNext()).expectNullableString(),
          type: (this..moveNext()).expectCode()) as T,
      CodeKind.recordTypeAnnotation => RecordTypeAnnotationCode(
          namedFields: _readCodeList(), positionalFields: _readCodeList()) as T,
      CodeKind.typeParameter => TypeParameterCode(
          bound: (this..moveNext()).expectNullableCode(),
          name: (this..moveNext()).expectString()) as T,
    };
  }

  T? expectNullableCode<T extends Code>() {
    if (checkNull()) return null;
    return expectCode();
  }

  Diagnostic expectDiagnostic() {
    expectList();
    List<DiagnosticMessage> context = [
      for (; moveNext();) expectDiagnosticMessage(),
    ];

    String? correctionMessage = (this..moveNext()).expectNullableString();
    DiagnosticMessage message = (this..moveNext()).expectDiagnosticMessage();
    Severity severity = Severity.values[(this..moveNext()).expectInt()];

    return Diagnostic(message, severity,
        contextMessages: context, correctionMessage: correctionMessage);
  }

  DiagnosticMessage expectDiagnosticMessage() {
    String message = expectString();

    moveNext();
    RemoteInstance? target = checkNull() ? null : expectRemoteInstance();

    return switch (target) {
      null => DiagnosticMessage(message),
      DeclarationImpl() =>
        DiagnosticMessage(message, target: target.asDiagnosticTarget),
      TypeAnnotationImpl() =>
        DiagnosticMessage(message, target: target.asDiagnosticTarget),
      MetadataAnnotationImpl() =>
        DiagnosticMessage(message, target: target.asDiagnosticTarget),
      _ => throw UnsupportedError(
          'Unsupported target type ${target.runtimeType}, only Declarations, '
          'TypeAnnotations, and Metadata are allowed.'),
    };
  }
}

extension SerializeNullable on Serializable? {
  /// Either serializes a `null` literal or the object.
  void serializeNullable(Serializer serializer) {
    Serializable? self = this;
    if (self == null) {
      serializer.addNull();
    } else {
      self.serialize(serializer);
    }
  }
}

extension SerializeNullableCode on Code? {
  /// Either serializes a `null` literal or the code object.
  void serializeNullable(Serializer serializer) {
    Code? self = this;
    if (self == null) {
      serializer.addNull();
    } else {
      self.serialize(serializer);
    }
  }
}

extension SerializeCode on Code {
  void serialize(Serializer serializer) {
    serializer.addInt(kind.index);
    switch (kind) {
      case CodeKind.namedTypeAnnotation:
        NamedTypeAnnotationCode self = this as NamedTypeAnnotationCode;
        (self.name as IdentifierImpl).serialize(serializer);
        serializer.startList();
        for (TypeAnnotationCode typeArg in self.typeArguments) {
          typeArg.serialize(serializer);
        }
        serializer.endList();
        return;
      case CodeKind.functionTypeAnnotation:
        FunctionTypeAnnotationCode self = this as FunctionTypeAnnotationCode;
        serializer.startList();
        for (ParameterCode named in self.namedParameters) {
          named.serialize(serializer);
        }
        serializer
          ..endList()
          ..startList();
        for (ParameterCode positional in self.positionalParameters) {
          positional.serialize(serializer);
        }
        serializer.endList();
        self.returnType.serializeNullable(serializer);
        serializer.startList();
        for (TypeParameterCode typeParam in self.typeParameters) {
          typeParam.serialize(serializer);
        }
        serializer.endList();
        return;
      case CodeKind.nullableTypeAnnotation:
        NullableTypeAnnotationCode self = this as NullableTypeAnnotationCode;
        self.underlyingType.serialize(serializer);
        return;
      case CodeKind.omittedTypeAnnotation:
        OmittedTypeAnnotationCode self = this as OmittedTypeAnnotationCode;
        (self.typeAnnotation as OmittedTypeAnnotationImpl)
            .serialize(serializer);
        return;
      case CodeKind.recordField:
        RecordFieldCode self = this as RecordFieldCode;
        serializer.addNullableString(self.name);
        self.type.serialize(serializer);
        return;
      case CodeKind.recordTypeAnnotation:
        RecordTypeAnnotationCode self = this as RecordTypeAnnotationCode;
        serializer.startList();
        for (RecordFieldCode field in self.namedFields) {
          field.serialize(serializer);
        }
        serializer
          ..endList()
          ..startList();
        for (RecordFieldCode field in self.positionalFields) {
          field.serialize(serializer);
        }
        serializer.endList();
        return;
      case CodeKind.parameter:
        ParameterCode self = this as ParameterCode;
        self.defaultValue.serializeNullable(serializer);
        serializer.startList();
        for (String keyword in self.keywords) {
          serializer.addString(keyword);
        }
        serializer
          ..endList()
          ..addNullableString(self.name);
        self.type.serializeNullable(serializer);
        return;
      case CodeKind.typeParameter:
        TypeParameterCode self = this as TypeParameterCode;
        self.bound.serializeNullable(serializer);
        serializer.addString(self.name);
        return;
      case CodeKind.comment:
      case CodeKind.declaration:
      case CodeKind.expression:
      case CodeKind.raw:
      case CodeKind.rawTypeAnnotation:
      case CodeKind.functionBody:
        serializer.startList();
        for (Object part in parts) {
          if (part is String) {
            serializer
              ..addInt(_CodePartKind.string.index)
              ..addString(part);
          } else if (part is Code) {
            serializer.addInt(_CodePartKind.code.index);
            part.serialize(serializer);
          } else if (part is IdentifierImpl) {
            serializer.addInt(_CodePartKind.identifier.index);
            part.serialize(serializer);
          } else {
            throw StateError('Unrecognized code part $part');
          }
        }
        serializer.endList();
        return;
    }
  }
}

extension SerializeDiagnostic on Diagnostic {
  void serialize(Serializer serializer) {
    serializer.startList();
    for (DiagnosticMessage message in contextMessages) {
      message.serialize(serializer);
    }
    serializer.endList();

    serializer.addNullableString(correctionMessage);
    message.serialize(serializer);
    serializer.addInt(severity.index);
  }
}

extension SerializeDiagnosticMessage on DiagnosticMessage {
  void serialize(Serializer serializer) {
    serializer.addString(message);
    switch (target) {
      case null:
        serializer.addNull();
      case DeclarationDiagnosticTarget target:
        (target.declaration as DeclarationImpl).serialize(serializer);
      case TypeAnnotationDiagnosticTarget target:
        (target.typeAnnotation as TypeAnnotationImpl).serialize(serializer);
      case MetadataAnnotationDiagnosticTarget target:
        (target.metadataAnnotation as MetadataAnnotationImpl)
            .serialize(serializer);
    }
  }
}

extension Helpers on Serializer {
  void addUri(Uri uri) => addString('$uri');

  void addSerializable(Serializable serializable) =>
      serializable.serialize(this);
}

enum _CodePartKind {
  string,
  code,
  identifier,
}
