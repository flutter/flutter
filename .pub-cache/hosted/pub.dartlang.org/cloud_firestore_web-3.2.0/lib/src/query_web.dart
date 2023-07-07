// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_web/src/utils/encode_utility.dart';
import 'package:collection/collection.dart';

import 'aggregate_query_web.dart';
import 'internals.dart';
import 'interop/firestore.dart' as firestore_interop;
import 'utils/web_utils.dart';

/// Web implementation of Firestore [QueryPlatform].
class QueryWeb extends QueryPlatform {
  /// Builds an instance of [QueryWeb] delegating to a package:firebase [Query]
  /// to delegate queries to underlying firestore web plugin
  QueryWeb(
    FirebaseFirestorePlatform firestore,
    this._path,
    this._webQuery, {
    Map<String, dynamic>? parameters,
    this.isCollectionGroupQuery = false,
  }) : super(firestore, parameters);

  final firestore_interop.Query _webQuery;
  final String _path;

  /// Flags whether the current query is for a collection group.
  @override
  final bool isCollectionGroupQuery;

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is QueryWeb &&
        other.firestore == firestore &&
        other._path == _path &&
        other.isCollectionGroupQuery == isCollectionGroupQuery &&
        const DeepCollectionEquality().equals(other.parameters, parameters);
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        firestore,
        _path,
        isCollectionGroupQuery,
        const DeepCollectionEquality().hash(parameters),
      );

  QueryWeb _copyWithParameters(Map<String, dynamic> parameters) {
    return QueryWeb(
      firestore,
      _path,
      _webQuery,
      isCollectionGroupQuery: isCollectionGroupQuery,
      parameters: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(this.parameters)..addAll(parameters),
      ),
    );
  }

  /// Builds a [web.Query] from given [parameters].
  firestore_interop.Query _buildWebQueryWithParameters() {
    firestore_interop.Query query = _webQuery;

    for (final List<dynamic> order in parameters['orderBy']) {
      query = query.orderBy(
          EncodeUtility.valueEncode(order[0]), order[1] ? 'desc' : 'asc');
    }

    if (parameters['startAt'] != null) {
      query = query.startAt(
          fieldValues: EncodeUtility.valueEncode(parameters['startAt']));
    }

    if (parameters['startAfter'] != null) {
      query = query.startAfter(
          fieldValues: EncodeUtility.valueEncode(parameters['startAfter']));
    }

    if (parameters['endAt'] != null) {
      query = query.endAt(
          fieldValues: EncodeUtility.valueEncode(parameters['endAt']));
    }

    if (parameters['endBefore'] != null) {
      query = query.endBefore(
          fieldValues: EncodeUtility.valueEncode(parameters['endBefore']));
    }

    if (parameters['limit'] != null) {
      query = query.limit(parameters['limit']);
    }

    if (parameters['limitToLast'] != null) {
      query = query.limitToLast(parameters['limitToLast']);
    }

    for (final List<dynamic> condition in parameters['where']) {
      dynamic fieldPath = EncodeUtility.valueEncode(condition[0]);
      String opStr = condition[1];
      dynamic value = EncodeUtility.valueEncode(condition[2]);

      query = query.where(fieldPath, opStr, value);
    }

    return query;
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

  @override
  Future<QuerySnapshotPlatform> get([GetOptions options = const GetOptions()]) {
    return convertWebExceptions(() async {
      return convertWebQuerySnapshot(
        firestore,
        await _buildWebQueryWithParameters().get(convertGetOptions(options)),
        getServerTimestampBehaviorString(
          options.serverTimestampBehavior,
        ),
      );
    });
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
  }) {
    Stream<firestore_interop.QuerySnapshot> querySnapshots;
    if (includeMetadataChanges) {
      querySnapshots = _buildWebQueryWithParameters().onSnapshotMetadata;
    } else {
      querySnapshots = _buildWebQueryWithParameters().onSnapshot;
    }

    return convertWebExceptions(
      () => querySnapshots.map((webQuerySnapshot) {
        return convertWebQuerySnapshot(
          firestore,
          webQuerySnapshot,
          ServerTimestampBehavior.none.name,
        );
      }),
    );
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
    return AggregateQueryWeb(this, _buildWebQueryWithParameters());
  }
}
