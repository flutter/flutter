// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'serialization.dart';
import 'serialization_extensions.dart';

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

  /// Retrieves a cached instance by ID, if present.
  static RemoteInstance? cached(int id) => _remoteInstanceCache[id];

  /// Adds [instance] to the cache for this zone.
  static void cache(RemoteInstance instance) =>
      _remoteInstanceCache[instance.id] = instance;

  /// Deserializes an instance based on the current [serializationMode].
  ///
  // TODO: Ideally this would be `T extends RemoteInstance` but that interacts
  // poorly with inference in other places, we end up with Never and null as
  // inferred types due to only the impl versions of objects extending
  // `RemoteInstance`.
  static T deserialize<T extends Object>(Deserializer deserializer) =>
      (deserializer..moveNext()).expectRemoteInstance();

  /// This method should be overridden by any subclasses, they should instead
  /// implement [serializeUncached].
  @override
  void serialize(Serializer serializer) {
    serializer.addInt(id);
    // We only send the ID if it's in the cache, it's only in our cache if it is
    // also in the remote cache.
    if (_remoteInstanceCache.containsKey(id)) return;

    serializeUncached(serializer);
  }

  /// This method should be overridden by all subclasses, which should on their
  /// first line call this super method.
  ///
  /// This method should not be directly invoked, instead only [serialize]
  /// should call it (if serializing an uncached value).
  ///
  /// Only new fields added by the subtype should be serialized here, rely on
  /// super classes to have their own implementations for their fields.
  void serializeUncached(Serializer serializer) {
    serializer.addInt(kind.index);

    // Now we can add it to the cache, we know the other side has a copy of it
    // and don't need to serialize it in the future.
    _remoteInstanceCache[id] = this;
  }

  @override
  bool operator ==(Object other) => other is RemoteInstance && id == other.id;

  @override
  int get hashCode => id;
}

/// A remote instance which is just a pointer to some server side instance of
/// a generic object.
///
/// The wrapped object is not serialized.
final class RemoteInstanceImpl extends RemoteInstance {
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
  constructorMetadataAnnotation,
  declarationPhaseIntrospector,
  definitionPhaseIntrospector,
  enumDeclaration,
  enumValueDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
  fieldDeclaration,
  formalParameter,
  formalParameterDeclaration,
  functionDeclaration,
  functionTypeAnnotation,
  identifier,
  identifierMetadataAnnotation,
  library,
  methodDeclaration,
  mixinDeclaration,
  namedStaticType,
  namedTypeAnnotation,
  omittedTypeAnnotation,
  recordField,
  recordTypeAnnotation,
  staticType,
  typeAliasDeclaration,
  typeParameter,
  typeParameterDeclaration,
  typePhaseIntrospector,
  variableDeclaration,

  // Exceptions.
  macroImplementationException,
  macroIntrospectionCycleException,
  unexpectedMacroException,
}

/// Creates a new zone with a remote instance cache and an id, which it uses to
/// avoid sending the same remote instances across the wire multiple times.
///
/// The lifecycle of one of these zones should be no longer than that of a
/// single full compile, at which point [destroyRemoteInstanceZone] should be
/// called.
///
/// In order to keep these caches in sync between the server and client, the
/// server always creates new zone IDs and passes those to the client.
int newRemoteInstanceZone<T>() {
  final int id = _nextSerializationZoneId++;
  final Zone zone = Zone.current.fork(zoneValues: {
    _remoteInstanceZoneCacheKey: <int, RemoteInstance>{},
  });
  _remoteInstanceCacheZones[id] = zone;
  return id;
}

/// Runs [fn] in the remote instance zone identified by [zoneId].
///
/// If [createIfMissing] is `true`, then a new zone will be created with
/// [zoneId] if one does not already exist (this should only be `true` in client
/// code).
T withRemoteInstanceZone<T>(int zoneId, T Function() fn,
    {bool createIfMissing = false}) {
  Zone? zone = _remoteInstanceCacheZones[zoneId];
  if (zone == null) {
    if (!createIfMissing) {
      throw StateError('No remote instance zone with id `$zoneId` exists.');
    }
    zone = _remoteInstanceCacheZones[zoneId] = Zone.current.fork(zoneValues: {
      _remoteInstanceZoneCacheKey: <int, RemoteInstance>{},
    });
  }
  return zone.run(fn);
}

/// Removes the remote instance zone identified by [zoneId] from the known list
/// of zones and forcibly clears its cache.
///
/// Throws if a zone identified by [zoneId] does not exist.
void destroyRemoteInstanceZone(int zoneId) {
  final Zone? zone = _remoteInstanceCacheZones.remove(zoneId);
  if (zone == null) {
    throw StateError('No remote instance zone with id `$zoneId` exists.');
  }
  (zone[_remoteInstanceZoneCacheKey] as Map<int, RemoteInstance>).clear();
}

/// The key used to store the remote instance cache in the current zone.
const Symbol _remoteInstanceZoneCacheKey = #_remoteInstanceCache;

/// We cache remote instances by their ID, which allows us to not repeatedly
/// send the same information over the wire.
///
/// These are a part of the current remote instance cache zone, which all
/// serialization and deserialization of remote instances must be done in.
Map<int, RemoteInstance> get _remoteInstanceCache =>
    Zone.current[_remoteInstanceZoneCacheKey] as Map<int, RemoteInstance>? ??
    (throw StateError('Not running in a remote instance cache zone, call '
        '`withRemoteInstanceZone` to set one up.'));

/// Remote instance cache zones by ID.
final _remoteInstanceCacheZones = <int, Zone>{};

/// Incrementing identifier for the serialization zone ids.
int _nextSerializationZoneId = 0;
