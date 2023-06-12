// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'serialization.dart';
import 'serialization_extensions.dart';

/// The key used to store the remote instance cache in the current serialization
/// zone (in server mode only).
const Symbol remoteInstanceZoneKey = #remoteInstanceCache;

/// On the server side we keep track of remote instances by their ID.
///
/// These are a part of the current serialization zone, which all serialization
/// and deserialization must be done in.
///
/// This means the cache lifetime is that of the serialization zone it is run
/// in.
Map<int, RemoteInstance> get _remoteInstanceCache =>
    Zone.current[remoteInstanceZoneKey];

/// Base class for types that need to be able to be traced back to a specific
/// instance on the server side.
abstract class RemoteInstance implements Serializable {
  /// The unique ID for this instance.
  final int id;

  /// The type of instance being encoded.
  RemoteInstanceKind get kind;

  /// Static, incrementing ids.
  static int _nextId = 0;

  /// Gets the next unique identifier.
  static int get uniqueId => _nextId++;

  /// On the client side [id]s are given and you should reconstruct objects with
  /// the given ID. On the server side ids should be created using
  /// [RemoteInstance.uniqueId].
  RemoteInstance(this.id);

  /// Retrieves a cached instance by ID.
  static T cached<T>(int id) => _remoteInstanceCache[id] as T;

  /// Deserializes an instance based on the current [serializationMode].
  static T deserialize<T>(Deserializer deserializer) =>
      (deserializer..moveNext()).expectRemoteInstance();

  /// This method should be overridden by all subclasses, which should on their
  /// first line call this super function.
  ///
  /// They should then return immediately if [serializationMode] is
  /// [SerializationMode.client], so that only an ID is sent.
  @mustCallSuper
  void serialize(Serializer serializer) {
    serializer.addInt(id);
    // We only send the ID from the client side.
    if (serializationMode.isClient) return;

    serializer.addInt(kind.index);
    _remoteInstanceCache[id] = this;
  }

  @override
  bool operator ==(Object other) => other is RemoteInstance && id == other.id;
}

/// A remote instance which is just a pointer to some server side instance of
/// a generic object.
///
/// The wrapped object is not serialized.
class RemoteInstanceImpl extends RemoteInstance {
  /// Always null on the client side, has an actual instance on the server side.
  final Object? instance;

  @override
  final RemoteInstanceKind kind;

  RemoteInstanceImpl({
    required int id,
    this.instance,
    required this.kind,
  }) : super(id);
}

// The kinds of instances.
enum RemoteInstanceKind {
  classDeclaration,
  constructorDeclaration,
  fieldDeclaration,
  functionDeclaration,
  functionTypeAnnotation,
  functionTypeParameter,
  identifier,
  identifierResolver,
  typeIntrospector,
  introspectableClassDeclaration,
  namedStaticType,
  methodDeclaration,
  namedTypeAnnotation,
  omittedTypeAnnotation,
  parameterDeclaration,
  staticType,
  typeAliasDeclaration,
  typeParameterDeclaration,
  typeResolver,
  typeDeclarationResolver,
  typeInferrer,
  variableDeclaration,
}
