// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_flutterfire_internals/_flutterfire_internals.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

import 'method_channel_aggregate_query.dart';
import 'method_channel_firestore.dart';
import 'method_channel_query_snapshot.dart';
import 'utils/exception.dart';
import 'utils/source.dart';

/// An implementation of [QueryPlatform] that uses [MethodChannel] to
/// communicate with Firebase plugins.
class MethodChannelQuery extends QueryPlatform {
  /// Create a [MethodChannelQuery] from a [path] and optional [parameters]
  MethodChannelQuery(
    FirebaseFirestorePlatform _firestore,
    String path, {
    Map<String, dynamic>? parameters,
    this.isCollectionGroupQuery = false,
  })  : _pointer = Pointer(path),
        super(_firestore, parameters);

  /// Flags whether the current query is for a collection group.
  @override
  final bool isCollectionGroupQuery;

  final Pointer _pointer;

  /// Returns the Document path that that this query relates to.
  String get path {
    return _pointer.path;
  }

  /// Creates a new instance of [MethodChannelQuery], however overrides
  /// any existing [parameters].
  ///
  /// This is in place to ensure that changes to a query don't mutate
  /// other queries.
  MethodChannelQuery _copyWithParameters(Map<String, dynamic> parameters) {
    return MethodChannelQuery(
      firestore,
      _pointer.path,
      isCollectionGroupQuery: isCollectionGroupQuery,
      parameters: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(this.parameters)..addAll(parameters),
      ),
    );
  }

  @override
  QueryPlatform endAtDocument(List<dynamic> orders, List<dynamic> values) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
      'endAt': values,
      'endBefore': null,
    });
  }

  @override
  QueryPlatform endAt(List<dynamic> fields) {
    return _copyWithParameters(<String, dynamic>{
      'endAt': fields,
      'endBefore': null,
    });
  }

  @override
  QueryPlatform endBeforeDocument(List<dynamic> orders, List<dynamic> values) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
      'endAt': null,
      'endBefore': values,
    });
  }

  @override
  QueryPlatform endBefore(List<dynamic> fields) {
    return _copyWithParameters(<String, dynamic>{
      'endAt': null,
      'endBefore': fields,
    });
  }

  /// Fetch the documents for this query
  @override
  Future<QuerySnapshotPlatform> get(
      [GetOptions options = const GetOptions()]) async {
    try {
      final Map<String, dynamic>? data = await MethodChannelFirebaseFirestore
          .channel
          .invokeMapMethod<String, dynamic>(
        'Query#get',
        <String, dynamic>{
          'query': this,
          'firestore': firestore,
          'source': getSourceString(options.source),
          'serverTimestampBehavior': getServerTimestampBehaviorString(
            options.serverTimestampBehavior,
          ),
        },
      );

      return MethodChannelQuerySnapshot(firestore, data!);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  QueryPlatform limit(int limit) {
    return _copyWithParameters(<String, dynamic>{
      'limit': limit,
      'limitToLast': null,
    });
  }

  @override
  QueryPlatform limitToLast(int limit) {
    return _copyWithParameters(<String, dynamic>{
      'limit': null,
      'limitToLast': limit,
    });
  }

  @override
  Stream<QuerySnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
    ServerTimestampBehavior serverTimestampBehavior =
        ServerTimestampBehavior.none,
  }) {
    // It's fine to let the StreamController be garbage collected once all the
    // subscribers have cancelled; this analyzer warning is safe to ignore.
    late StreamController<QuerySnapshotPlatform>
        controller; // ignore: close_sinks

    StreamSubscription<dynamic>? snapshotStreamSubscription;

    controller = StreamController<QuerySnapshotPlatform>.broadcast(
      onListen: () async {
        final observerId = await MethodChannelFirebaseFirestore.channel
            .invokeMethod<String>('Query#snapshots');

        snapshotStreamSubscription =
            MethodChannelFirebaseFirestore.querySnapshotChannel(observerId!)
                .receiveGuardedBroadcastStream(
          arguments: <String, dynamic>{
            'query': this,
            'includeMetadataChanges': includeMetadataChanges,
            'serverTimestampBehavior': getServerTimestampBehaviorString(
              serverTimestampBehavior,
            ),
          },
          onError: convertPlatformException,
        ).listen(
          (snapshot) {
            controller.add(MethodChannelQuerySnapshot(firestore, snapshot));
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        snapshotStreamSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  QueryPlatform orderBy(List<List<dynamic>> orders) {
    return _copyWithParameters(<String, dynamic>{'orderBy': orders});
  }

  @override
  QueryPlatform startAfterDocument(List<dynamic> orders, List<dynamic> values) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
      'startAt': null,
      'startAfter': values,
    });
  }

  @override
  QueryPlatform startAfter(List<dynamic> fields) {
    return _copyWithParameters(<String, dynamic>{
      'startAt': null,
      'startAfter': fields,
    });
  }

  @override
  QueryPlatform startAtDocument(List<dynamic> orders, List<dynamic> values) {
    return _copyWithParameters(<String, dynamic>{
      'orderBy': orders,
      'startAt': values,
      'startAfter': null,
    });
  }

  @override
  QueryPlatform startAt(List<dynamic> fields) {
    return _copyWithParameters(<String, dynamic>{
      'startAt': fields,
      'startAfter': null,
    });
  }

  @override
  QueryPlatform where(List<List<dynamic>> conditions) {
    return _copyWithParameters(<String, dynamic>{
      'where': conditions,
    });
  }

  @override
  AggregateQueryPlatform count() {
    return MethodChannelAggregateQuery(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is MethodChannelQuery &&
        other.firestore == firestore &&
        other._pointer == _pointer &&
        other.isCollectionGroupQuery == isCollectionGroupQuery &&
        const DeepCollectionEquality().equals(other.parameters, parameters);
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        firestore,
        _pointer,
        isCollectionGroupQuery,
        const DeepCollectionEquality().hash(parameters),
      );
}
