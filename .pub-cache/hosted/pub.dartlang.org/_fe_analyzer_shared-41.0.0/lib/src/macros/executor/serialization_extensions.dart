import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';

import 'remote_instance.dart';
import 'serialization.dart';
import '../api.dart';

extension DeserializerExtensions on Deserializer {
  T expectRemoteInstance<T>() {
    int id = expectInt();

    // Server side we just return the cached remote instance by ID.
    if (!serializationMode.isClient) {
      return RemoteInstance.cached(id) as T;
    }

    moveNext();
    RemoteInstanceKind kind = RemoteInstanceKind.values[expectInt()];
    switch (kind) {
      case RemoteInstanceKind.typeIntrospector:
      case RemoteInstanceKind.identifierResolver:
      case RemoteInstanceKind.namedStaticType:
      case RemoteInstanceKind.staticType:
      case RemoteInstanceKind.typeDeclarationResolver:
      case RemoteInstanceKind.typeResolver:
      case RemoteInstanceKind.typeInferrer:
        // These are simple wrappers, just pass in the kind
        return new RemoteInstanceImpl(id: id, kind: kind) as T;
      case RemoteInstanceKind.classDeclaration:
        moveNext();
        return _expectClassDeclaration(id) as T;
      case RemoteInstanceKind.constructorDeclaration:
        moveNext();
        return _expectConstructorDeclaration(id) as T;
      case RemoteInstanceKind.fieldDeclaration:
        moveNext();
        return _expectFieldDeclaration(id) as T;
      case RemoteInstanceKind.functionDeclaration:
        moveNext();
        return _expectFunctionDeclaration(id) as T;
      case RemoteInstanceKind.functionTypeAnnotation:
        moveNext();
        return _expectFunctionTypeAnnotation(id) as T;
      case RemoteInstanceKind.functionTypeParameter:
        moveNext();
        return _expectFunctionTypeParameter(id) as T;
      case RemoteInstanceKind.identifier:
        moveNext();
        return _expectIdentifier(id) as T;
      case RemoteInstanceKind.introspectableClassDeclaration:
        moveNext();
        return _expectIntrospectableClassDeclaration(id) as T;
      case RemoteInstanceKind.methodDeclaration:
        moveNext();
        return _expectMethodDeclaration(id) as T;
      case RemoteInstanceKind.namedTypeAnnotation:
        moveNext();
        return _expectNamedTypeAnnotation(id) as T;
      case RemoteInstanceKind.omittedTypeAnnotation:
        moveNext();
        return _expectOmittedTypeAnnotation(id) as T;
      case RemoteInstanceKind.parameterDeclaration:
        moveNext();
        return _expectParameterDeclaration(id) as T;
      case RemoteInstanceKind.typeAliasDeclaration:
        moveNext();
        return _expectTypeAliasDeclaration(id) as T;
      case RemoteInstanceKind.typeParameterDeclaration:
        moveNext();
        return _expectTypeParameterDeclaration(id) as T;
      case RemoteInstanceKind.variableDeclaration:
        moveNext();
        return _expectVariableDeclaration(id) as T;
    }
  }

  Uri expectUri() => Uri.parse(expectString());

  /// Helper method to read a list of [RemoteInstance]s.
  List<T> _expectRemoteInstanceList<T extends RemoteInstance>() {
    expectList();
    return [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];
  }

  NamedTypeAnnotation _expectNamedTypeAnnotation(int id) =>
      new NamedTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        identifier: RemoteInstance.deserialize(this),
        typeArguments: (this..moveNext())._expectRemoteInstanceList(),
      );

  OmittedTypeAnnotation _expectOmittedTypeAnnotation(int id) {
    expectBool(); // Always `false`.
    return new OmittedTypeAnnotationImpl(
      id: id,
    );
  }

  FunctionTypeAnnotation _expectFunctionTypeAnnotation(int id) =>
      new FunctionTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        returnType: RemoteInstance.deserialize(this),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  FunctionTypeParameter _expectFunctionTypeParameter(int id) =>
      new FunctionTypeParameterImpl(
        id: id,
        isNamed: expectBool(),
        isRequired: (this..moveNext()).expectBool(),
        name: (this..moveNext()).expectNullableString(),
        type: RemoteInstance.deserialize(this),
      );

  Identifier _expectIdentifier(int id) => new IdentifierImpl(
        id: id,
        name: expectString(),
      );

  ParameterDeclaration _expectParameterDeclaration(int id) =>
      new ParameterDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isNamed: (this..moveNext()).expectBool(),
        isRequired: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
      );

  TypeParameterDeclaration _expectTypeParameterDeclaration(int id) =>
      new TypeParameterDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        bound: (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  FunctionDeclaration _expectFunctionDeclaration(int id) =>
      new FunctionDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isOperator: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  MethodDeclaration _expectMethodDeclaration(int id) =>
      new MethodDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isOperator: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        definingClass: RemoteInstance.deserialize(this),
        isStatic: (this..moveNext()).expectBool(),
      );

  ConstructorDeclaration _expectConstructorDeclaration(int id) =>
      new ConstructorDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isOperator: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        definingClass: RemoteInstance.deserialize(this),
        // There is an extra boolean here representing the `isStatic` field
        // which we just skip past.
        isFactory: (this
              ..moveNext()
              ..expectBool()
              ..moveNext())
            .expectBool(),
      );

  VariableDeclaration _expectVariableDeclaration(int id) =>
      new VariableDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isExternal: (this..moveNext()).expectBool(),
        isFinal: (this..moveNext()).expectBool(),
        isLate: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
      );

  FieldDeclaration _expectFieldDeclaration(int id) => new FieldDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isExternal: (this..moveNext()).expectBool(),
        isFinal: (this..moveNext()).expectBool(),
        isLate: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
        definingClass: RemoteInstance.deserialize(this),
        isStatic: (this..moveNext()).expectBool(),
      );

  ClassDeclaration _expectClassDeclaration(int id) => new ClassDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
        superclass:
            (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  IntrospectableClassDeclaration _expectIntrospectableClassDeclaration(
          int id) =>
      new IntrospectableClassDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
        superclass:
            (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  TypeAliasDeclaration _expectTypeAliasDeclaration(int id) =>
      new TypeAliasDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        aliasedType: RemoteInstance.deserialize(this),
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

    switch (kind) {
      case CodeKind.raw:
        return new Code.fromParts(_readParts()) as T;
      case CodeKind.declaration:
        return new DeclarationCode.fromParts(_readParts()) as T;
      case CodeKind.expression:
        return new ExpressionCode.fromParts(_readParts()) as T;
      case CodeKind.functionBody:
        return new FunctionBodyCode.fromParts(_readParts()) as T;
      case CodeKind.functionTypeAnnotation:
        return new FunctionTypeAnnotationCode(
            namedParameters: _readCodeList(),
            positionalParameters: _readCodeList(),
            returnType: (this..moveNext()).expectNullableCode(),
            typeParameters: _readCodeList()) as T;
      case CodeKind.namedTypeAnnotation:
        return new NamedTypeAnnotationCode(
            name: RemoteInstance.deserialize(this),
            typeArguments: _readCodeList()) as T;
      case CodeKind.nullableTypeAnnotation:
        return new NullableTypeAnnotationCode((this..moveNext()).expectCode())
            as T;
      case CodeKind.omittedTypeAnnotation:
        return new OmittedTypeAnnotationCode(RemoteInstance.deserialize(this))
            as T;
      case CodeKind.parameter:
        return new ParameterCode(
            defaultValue: (this..moveNext()).expectNullableCode(),
            keywords: _readStringList(),
            name: (this..moveNext()).expectNullableString(),
            type: (this..moveNext()).expectNullableCode()) as T;
      case CodeKind.typeParameter:
        return new TypeParameterCode(
            bound: (this..moveNext()).expectNullableCode(),
            name: (this..moveNext()).expectString()) as T;
    }
  }

  T? expectNullableCode<T extends Code>() {
    if (checkNull()) return null;
    return expectCode();
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
        serializer..endList();
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
      default:
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
            throw new StateError('Unrecognized code part $part');
          }
        }
        serializer.endList();
        return;
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
