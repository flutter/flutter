// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the objects used for communication between the macro executor and
/// the isolate or process doing the work of macro loading and execution.
library _fe_analyzer_shared.src.macros.executor_shared.protocol;

import '../api.dart';
import '../executor.dart';
import 'exception_impls.dart';
import 'introspection_impls.dart';
import 'remote_instance.dart';
import 'response_impls.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';

/// Base class all requests extend, provides a unique id for each request.
abstract class Request implements Serializable {
  final int id;

  final int serializationZoneId;

  Request({int? id, required this.serializationZoneId}) : id = id ?? _next++;

  /// The [serializationZoneId] is a part of the header and needs to be parsed
  /// before deserializing objects, and then passed in here.
  Request.deserialize(Deserializer deserializer, this.serializationZoneId)
      : id = (deserializer..moveNext()).expectInt();

  /// The [serializationZoneId] needs to be separately serialized before the
  /// rest of the object. This is not done by the instances themselves but by
  /// the macro implementations.
  @override
  void serialize(Serializer serializer) => serializer.addInt(id);

  static int _next = 0;
}

/// A generic response object that contains either a response or an exception,
/// and a unique ID.
class Response {
  final Object? response;
  final MacroException? exception;
  final int requestId;
  final MessageType responseType;

  Response({
    this.response,
    this.exception,
    required this.requestId,
    required this.responseType,
  })  : assert(response != null || exception != null),
        assert(response == null || exception == null);
}

/// A serializable [Response], contains the message type as an enum.
class SerializableResponse implements Response, Serializable {
  @override
  final Serializable? response;
  @override
  final MessageType responseType;
  @override
  final MacroExceptionImpl? exception;
  @override
  final int requestId;
  final int serializationZoneId;

  SerializableResponse({
    this.exception,
    required this.requestId,
    this.response,
    required this.responseType,
    required this.serializationZoneId,
  });

  /// You must first parse the [serializationZoneId] yourself, and then
  /// call this function in that zone, and pass the ID.
  factory SerializableResponse.deserialize(
      Deserializer deserializer, int serializationZoneId) {
    deserializer.moveNext();

    MessageType responseType = MessageType.values[deserializer.expectInt()];
    Serializable? response;
    MacroExceptionImpl? exception;
    switch (responseType) {
      case MessageType.exception:
        deserializer.moveNext();
        exception = deserializer.expectRemoteInstance();
        break;
      case MessageType.macroInstanceIdentifier:
        response = MacroInstanceIdentifierImpl.deserialize(deserializer);
        break;
      case MessageType.macroExecutionResult:
        response = MacroExecutionResultImpl.deserialize(deserializer);
        break;
      case MessageType.staticType:
      case MessageType.namedStaticType:
        response = RemoteInstance.deserialize(deserializer);
        break;
      case MessageType.boolean:
        response = BooleanValue.deserialize(deserializer);
        break;
      case MessageType.declarationList:
        response = DeclarationList.deserialize(deserializer);
        break;
      case MessageType.remoteInstance:
        deserializer.moveNext();
        if (!deserializer.checkNull()) {
          response = deserializer.expectRemoteInstance();
        }
        break;
      default:
        throw StateError('Unexpected response type $responseType');
    }

    return SerializableResponse(
        responseType: responseType,
        response: response,
        exception: exception,
        requestId: (deserializer..moveNext()).expectInt(),
        serializationZoneId: serializationZoneId);
  }

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(serializationZoneId)
      ..addInt(MessageType.response.index)
      ..addInt(responseType.index);
    switch (responseType) {
      case MessageType.exception:
        exception!.serialize(serializer);
        break;
      default:
        response.serializeNullable(serializer);
    }
    serializer.addInt(requestId);
  }
}

class BooleanValue implements Serializable {
  final bool value;

  BooleanValue(this.value);

  BooleanValue.deserialize(Deserializer deserializer)
      : value = (deserializer..moveNext()).expectBool();

  @override
  void serialize(Serializer serializer) => serializer..addBool(value);
}

/// A serialized list of [Declaration]s.
class DeclarationList<T extends DeclarationImpl> implements Serializable {
  final List<T> declarations;

  DeclarationList(this.declarations);

  DeclarationList.deserialize(Deserializer deserializer)
      : declarations = [
          for (bool hasNext = (deserializer
                    ..moveNext()
                    ..expectList())
                  .moveNext();
              hasNext;
              hasNext = deserializer.moveNext())
            deserializer.expectRemoteInstance(),
        ];

  @override
  void serialize(Serializer serializer) {
    serializer.startList();
    for (DeclarationImpl declaration in declarations) {
      declaration.serialize(serializer);
    }
    serializer.endList();
  }
}

/// A request to load a macro in this isolate.
class LoadMacroRequest extends Request {
  final Uri library;
  final String name;

  LoadMacroRequest(this.library, this.name,
      {required super.serializationZoneId});

  LoadMacroRequest.deserialize(super.deserializer, super.serializationZoneId)
      : library = Uri.parse((deserializer..moveNext()).expectString()),
        name = (deserializer..moveNext()).expectString(),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(MessageType.loadMacroRequest.index)
      ..addString(library.toString())
      ..addString(name);
    super.serialize(serializer);
  }
}

/// A request to instantiate a macro instance.
class InstantiateMacroRequest extends Request {
  final Uri library;
  final String name;
  final String constructor;
  final Arguments arguments;

  /// The ID to assign to the identifier, this needs to come from the requesting
  /// side so that it is unique.
  final int instanceId;

  InstantiateMacroRequest(this.library, this.name, this.constructor,
      this.arguments, this.instanceId,
      {required super.serializationZoneId});

  InstantiateMacroRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : library = (deserializer..moveNext()).expectUri(),
        name = (deserializer..moveNext()).expectString(),
        constructor = (deserializer..moveNext()).expectString(),
        arguments = Arguments.deserialize(deserializer),
        instanceId = (deserializer..moveNext()).expectInt(),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(MessageType.instantiateMacroRequest.index)
      ..addUri(library)
      ..addString(name)
      ..addString(constructor)
      ..addSerializable(arguments)
      ..addInt(instanceId);
    super.serialize(serializer);
  }
}

/// A request to dispose a macro instance by ID.
class DisposeMacroRequest extends Request {
  final MacroInstanceIdentifier identifier;

  DisposeMacroRequest(this.identifier, {required super.serializationZoneId});

  DisposeMacroRequest.deserialize(super.deserializer, super.serializationZoneId)
      : identifier = MacroInstanceIdentifierImpl.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(MessageType.disposeMacroRequest.index)
      ..addSerializable(identifier);
    super.serialize(serializer);
  }
}

/// Base class for the requests to execute a macro in a certain phase.
abstract class ExecutePhaseRequest extends Request {
  final MacroInstanceIdentifier macro;
  final RemoteInstance target;
  final RemoteInstanceImpl introspector;

  MessageType get kind;

  ExecutePhaseRequest(this.macro, this.target, this.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ExecutePhaseRequest.deserialize(super.deserializer, super.serializationZoneId)
      : macro = MacroInstanceIdentifierImpl.deserialize(deserializer),
        target = RemoteInstance.deserialize(deserializer),
        introspector = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(kind.index);
    macro.serialize(serializer);
    target.serialize(serializer);
    introspector.serialize(serializer);

    super.serialize(serializer);
  }
}

/// A request to execute a macro on a particular declaration in the types phase.
class ExecuteTypesPhaseRequest extends ExecutePhaseRequest {
  @override
  MessageType get kind => MessageType.executeTypesPhaseRequest;

  ExecuteTypesPhaseRequest(super.macro, super.target, super.identifierResolver,
      {required super.serializationZoneId});

  ExecuteTypesPhaseRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : super.deserialize();
}

/// A request to execute a macro on a particular declaration in the types phase.
class ExecuteDeclarationsPhaseRequest extends ExecutePhaseRequest {
  @override
  MessageType get kind => MessageType.executeDeclarationsPhaseRequest;

  ExecuteDeclarationsPhaseRequest(
      super.macro, super.target, super.identifierResolver,
      {required super.serializationZoneId});

  ExecuteDeclarationsPhaseRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : super.deserialize();
}

/// A request to execute a macro on a particular declaration in the types phase.
class ExecuteDefinitionsPhaseRequest extends ExecutePhaseRequest {
  @override
  MessageType get kind => MessageType.executeDefinitionsPhaseRequest;

  ExecuteDefinitionsPhaseRequest(
      super.macro, super.target, super.identifierResolver,
      {required super.serializationZoneId});

  ExecuteDefinitionsPhaseRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : super.deserialize();
}

/// A request to destroy a remote instance zone by id.
class DestroyRemoteInstanceZoneRequest extends Request {
  DestroyRemoteInstanceZoneRequest({required super.serializationZoneId});

  DestroyRemoteInstanceZoneRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.destroyRemoteInstanceZoneRequest.index);
    super.serialize(serializer);
  }
}

class IntrospectionRequest extends Request {
  final RemoteInstanceImpl introspector;

  IntrospectionRequest(this.introspector, {required super.serializationZoneId});

  IntrospectionRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : introspector = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    introspector.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to create a resolved identifier.
class ResolveIdentifierRequest extends IntrospectionRequest {
  final Uri library;
  final String name;

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ResolveIdentifierRequest(this.library, this.name, super.introspector,
      {required super.serializationZoneId});

  ResolveIdentifierRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : library = Uri.parse((deserializer..moveNext()).expectString()),
        name = (deserializer..moveNext()).expectString(),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(MessageType.resolveIdentifierRequest.index)
      ..addString(library.toString())
      ..addString(name);

    super.serialize(serializer);
  }
}

/// A request to resolve on a type annotation code object
class ResolveTypeRequest extends IntrospectionRequest {
  final TypeAnnotationCode typeAnnotationCode;

  ResolveTypeRequest(this.typeAnnotationCode, super.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ResolveTypeRequest.deserialize(super.deserializer, super.serializationZoneId)
      : typeAnnotationCode = (deserializer..moveNext()).expectCode(),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.resolveTypeRequest.index);
    typeAnnotationCode.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to check if a type is exactly another type.
class IsExactlyTypeRequest extends Request {
  final RemoteInstance leftType;
  final RemoteInstance rightType;

  IsExactlyTypeRequest(this.leftType, this.rightType,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  IsExactlyTypeRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : leftType = RemoteInstance.deserialize(deserializer),
        rightType = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.isExactlyTypeRequest.index);
    leftType.serialize(serializer);
    rightType.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to check if a type is exactly another type.
class IsSubtypeOfRequest extends Request {
  final RemoteInstance leftType;
  final RemoteInstance rightType;

  IsSubtypeOfRequest(this.leftType, this.rightType,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  IsSubtypeOfRequest.deserialize(super.deserializer, super.serializationZoneId)
      : leftType = RemoteInstance.deserialize(deserializer),
        rightType = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.isSubtypeOfRequest.index);
    leftType.serialize(serializer);
    rightType.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to check if a type is a subtype of the type defined by an
/// identifier, and, if so, also obtain the matching instantiation.
class AsInstanceOfRequest extends Request {
  final RemoteInstance left;
  final TypeDeclarationImpl right;
  AsInstanceOfRequest(this.left, this.right,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  AsInstanceOfRequest.deserialize(super.deserializer, super.serializationZoneId)
      : left = RemoteInstance.deserialize(deserializer),
        right = RemoteInstance.deserialize(deserializer),
        super.deserialize();
  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.asInstanceOfRequest.index);
    left.serialize(serializer);
    right.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A general request class for all requests coming from methods on the
/// [DeclarationPhaseIntrospector] interface that are related to a single type.
class TypeIntrospectorRequest extends IntrospectionRequest {
  final Object declaration;
  final MessageType requestKind;

  TypeIntrospectorRequest(
      this.declaration, super.introspector, this.requestKind,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again and it should instead be passed in here.
  TypeIntrospectorRequest.deserialize(
      Deserializer deserializer, this.requestKind, int serializationZoneId)
      : declaration = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(requestKind.index);
    (declaration as Serializable).serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to get a [Declaration] for an [identifier].
///
/// Used for both the `typeDeclarationOf` and `declarationOf` requests. A cast
/// is done on the client side to ensure only [TypeDeclaration]s are returned
/// from `typeDeclarationOf`.
class DeclarationOfRequest extends IntrospectionRequest {
  final IdentifierImpl identifier;
  final MessageType kind;

  DeclarationOfRequest(this.identifier, this.kind, super.introspector,
      {required super.serializationZoneId})
      : assert(kind == MessageType.typeDeclarationOfRequest ||
            kind == MessageType.declarationOfRequest);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  DeclarationOfRequest.deserialize(
      super.deserializer, super.serializationZoneId, this.kind)
      : assert(kind == MessageType.typeDeclarationOfRequest ||
            kind == MessageType.declarationOfRequest),
        identifier = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(kind.index);
    identifier.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to get an inferred [TypeAnnotation] for an
/// [OmittedTypeAnnotation].
class InferTypeRequest extends IntrospectionRequest {
  final OmittedTypeAnnotationImpl omittedType;

  InferTypeRequest(this.omittedType, super.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  InferTypeRequest.deserialize(super.deserializer, super.serializationZoneId)
      : omittedType = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.inferTypeRequest.index);
    omittedType.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to get all the top level [Declaration]s in a [Library].
class DeclarationsOfRequest extends IntrospectionRequest {
  final LibraryImpl library;

  DeclarationsOfRequest(this.library, super.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  DeclarationsOfRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : library = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.topLevelDeclarationsOfRequest.index);
    library.serialize(serializer);
    super.serialize(serializer);
  }
}

/// Signature of a function able to send requests and return a response using
/// an arbitrary communication channel.
typedef SendRequest = Future<Response> Function(Request request);

/// The base class for the client side introspectors from any phase, as well as
/// client side [StaticType]s.
///
/// These convert all method calls into RPCs, sent via [_sendRequest].
base class ClientIntrospector {
  /// The actual remote instance to call methods on.
  final RemoteInstanceImpl remoteInstance;

  /// The ID of the zone in which to find the original builder.
  final int serializationZoneId;

  /// A function that can send a request and return a response using an
  /// arbitrary communication channel.
  final SendRequest _sendRequest;

  ClientIntrospector(this._sendRequest,
      {required this.remoteInstance, required this.serializationZoneId});
}

/// Client side implementation of an [TypeBuilder], which creates converts all
/// method calls to remote procedure calls and sends them using [_sendRequest].
final class ClientTypePhaseIntrospector extends ClientIntrospector
    implements TypePhaseIntrospector {
  ClientTypePhaseIntrospector(super._sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});

  @override
  Future<Identifier> resolveIdentifier(Uri library, String name) async {
    ResolveIdentifierRequest request = ResolveIdentifierRequest(
        library, name, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse(await _sendRequest(request));
  }
}

/// Client side implementation of a [DeclarationBuilder].
final class ClientDeclarationPhaseIntrospector
    extends ClientTypePhaseIntrospector
    implements DeclarationPhaseIntrospector {
  static final _constructorsCache =
      Expando<Future<List<ConstructorDeclaration>>>();
  static final _enumValuesCache = Expando<Future<List<EnumValueDeclaration>>>();
  static final _fieldsCache = Expando<Future<List<FieldDeclaration>>>();
  static final _methodsCache = Expando<Future<List<MethodDeclaration>>>();
  static final _typeDeclarationCache = Expando<Future<TypeDeclaration>>();

  ClientDeclarationPhaseIntrospector(super._sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});

  @override
  Future<StaticType> resolve(TypeAnnotationCode typeAnnotation) async {
    ResolveTypeRequest request = ResolveTypeRequest(
        typeAnnotation, remoteInstance,
        serializationZoneId: serializationZoneId);
    StaticTypeImpl remoteType = _handleResponse(await _sendRequest(request));
    return ClientStaticTypeImpl.ofRemote(
      instance: remoteType,
      serializationZoneId: serializationZoneId,
      sendRequest: _sendRequest,
    );
  }

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(TypeDeclaration type) {
    return _constructorsCache[type] ??= Future(() async {
      final request = TypeIntrospectorRequest(
          type, remoteInstance, MessageType.constructorsOfRequest,
          serializationZoneId: serializationZoneId);
      return _handleResponse<DeclarationList>(await _sendRequest(request))
          .declarations
          // TODO: Refactor so we can remove this cast
          .cast();
    });
  }

  @override
  Future<List<EnumValueDeclaration>> valuesOf(EnumDeclaration type) {
    return _enumValuesCache[type] ??= Future(() async {
      final request = TypeIntrospectorRequest(
          type, remoteInstance, MessageType.valuesOfRequest,
          serializationZoneId: serializationZoneId);
      return _handleResponse<DeclarationList>(await _sendRequest(request))
          .declarations
          // TODO: Refactor so we can remove this cast
          .cast();
    });
  }

  @override
  Future<List<FieldDeclaration>> fieldsOf(TypeDeclaration type) {
    return _fieldsCache[type] ??= Future(() async {
      final request = TypeIntrospectorRequest(
          type, remoteInstance, MessageType.fieldsOfRequest,
          serializationZoneId: serializationZoneId);
      return _handleResponse<DeclarationList>(await _sendRequest(request))
          .declarations
          // TODO: Refactor so we can remove this cast
          .cast();
    });
  }

  @override
  Future<List<MethodDeclaration>> methodsOf(TypeDeclaration type) {
    return _methodsCache[type] ??= Future(() async {
      final request = TypeIntrospectorRequest(
          type, remoteInstance, MessageType.methodsOfRequest,
          serializationZoneId: serializationZoneId);
      return _handleResponse<DeclarationList>(await _sendRequest(request))
          .declarations
          // TODO: Refactor so we can remove this cast
          .cast();
    });
  }

  @override
  Future<List<TypeDeclaration>> typesOf(Library library) async {
    TypeIntrospectorRequest request = TypeIntrospectorRequest(
        library, remoteInstance, MessageType.typesOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await _sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast.
        .cast();
  }

  @override
  Future<TypeDeclaration> typeDeclarationOf(IdentifierImpl identifier) async {
    return _typeDeclarationCache[identifier] ??= Future(() async {
      final request = DeclarationOfRequest(
          identifier, MessageType.typeDeclarationOfRequest, remoteInstance,
          serializationZoneId: serializationZoneId);
      return _handleResponse<TypeDeclaration>(await _sendRequest(request));
    });
  }
}

/// Client side implementation of a [StaticType].
base class ClientStaticTypeImpl extends ClientIntrospector
    implements StaticType {
  ClientStaticTypeImpl(super._sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});

  factory ClientStaticTypeImpl.ofRemote({
    required StaticTypeImpl instance,
    required SendRequest sendRequest,
    required int serializationZoneId,
  }) {
    RemoteInstanceImpl remoteInstance =
        RemoteInstanceImpl(id: instance.id, kind: instance.kind);
    return switch (instance.kind) {
      RemoteInstanceKind.namedStaticType => ClientNamedStaticTypeImpl(
          sendRequest,
          staticType: instance as NamedStaticTypeImpl,
          remoteInstance: remoteInstance,
          serializationZoneId: serializationZoneId),
      RemoteInstanceKind.staticType => ClientStaticTypeImpl(sendRequest,
          remoteInstance: remoteInstance,
          serializationZoneId: serializationZoneId),
      _ => throw StateError(
          'Expected either a StaticType or NamedStaticType but got '
          '${instance.kind}'),
    };
  }

  @override
  Future<bool> isExactly(ClientStaticTypeImpl other) async {
    IsExactlyTypeRequest request = IsExactlyTypeRequest(
        remoteInstance, other.remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<BooleanValue>(await _sendRequest(request)).value;
  }

  @override
  Future<bool> isSubtypeOf(ClientStaticTypeImpl other) async {
    IsSubtypeOfRequest request = IsSubtypeOfRequest(
        remoteInstance, other.remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<BooleanValue>(await _sendRequest(request)).value;
  }

  @override
  Future<NamedStaticType?> asInstanceOf(TypeDeclaration declaration) async {
    AsInstanceOfRequest request = AsInstanceOfRequest(
        remoteInstance, declaration as TypeDeclarationImpl,
        serializationZoneId: serializationZoneId);
    return _handleResponse<NamedStaticType?>(await _sendRequest(request));
  }
}

/// Named variant of the [ClientStaticTypeImpl].
final class ClientNamedStaticTypeImpl extends ClientStaticTypeImpl
    implements NamedStaticType {
  @override
  final ParameterizedTypeDeclaration declaration;

  @override
  final List<StaticType> typeArguments;

  ClientNamedStaticTypeImpl(
    super.sendRequest, {
    required NamedStaticTypeImpl staticType,
    required super.serializationZoneId,
    required super.remoteInstance,
  })  : declaration = staticType.declaration,
        typeArguments = staticType.typeArguments
            .map((raw) => ClientStaticTypeImpl.ofRemote(
                instance: raw,
                sendRequest: sendRequest,
                serializationZoneId: serializationZoneId))
            .toList();
}

/// Client side implementation of a [DeclarationBuilder].
final class ClientDefinitionPhaseIntrospector
    extends ClientDeclarationPhaseIntrospector
    implements DefinitionPhaseIntrospector {
  ClientDefinitionPhaseIntrospector(super._sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});

  @override
  Future<Declaration> declarationOf(IdentifierImpl identifier) async {
    DeclarationOfRequest request = DeclarationOfRequest(
        identifier, MessageType.declarationOfRequest, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<Declaration>(await _sendRequest(request));
  }

  @override
  Future<TypeAnnotation> inferType(
      OmittedTypeAnnotationImpl omittedType) async {
    InferTypeRequest request = InferTypeRequest(omittedType, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<TypeAnnotation>(await _sendRequest(request));
  }

  @override
  Future<List<Declaration>> topLevelDeclarationsOf(LibraryImpl library) async {
    DeclarationsOfRequest request = DeclarationsOfRequest(
        library, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await _sendRequest(request))
        .declarations;
  }
}

/// Either returns the actual response from [response], casted to [T], or throws
/// a [MacroException].
T _handleResponse<T>(Response response) {
  if (response.responseType == MessageType.exception) {
    throw response.exception!;
  }

  return response.response as T;
}

enum MessageType {
  boolean,
  constructorsOfRequest,
  declarationOfRequest,
  declarationList,
  destroyRemoteInstanceZoneRequest,
  disposeMacroRequest,
  exception,
  valuesOfRequest,
  fieldsOfRequest,
  methodsOfRequest,
  executeDeclarationsPhaseRequest,
  executeDefinitionsPhaseRequest,
  executeTypesPhaseRequest,
  instantiateMacroRequest,
  resolveIdentifierRequest,
  resolveTypeRequest,
  inferTypeRequest,
  isExactlyTypeRequest,
  isSubtypeOfRequest,
  asInstanceOfRequest,
  loadMacroRequest,
  remoteInstance,
  macroInstanceIdentifier,
  macroExecutionResult,
  namedStaticType,
  response,
  staticType,
  topLevelDeclarationsOfRequest,
  typeDeclarationOfRequest,
  typesOfRequest,
}
