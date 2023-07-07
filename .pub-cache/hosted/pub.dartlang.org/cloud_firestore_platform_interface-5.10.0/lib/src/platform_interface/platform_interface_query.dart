// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

Map<String, dynamic> _initialParameters = Map<String, dynamic>.unmodifiable({
  'where': List<List<dynamic>>.unmodifiable([]),
  'orderBy': List<List<dynamic>>.unmodifiable([]),
  'startAt': null,
  'startAfter': null,
  'endAt': null,
  'endBefore': null,
  'limit': null,
  'limitToLast': null,
});

/// Represents a query over the data at a particular location.
@immutable
abstract class QueryPlatform extends PlatformInterface {
  /// Create a [QueryPlatform] instance
  QueryPlatform(this.firestore, Map<String, dynamic>? params)
      : parameters = params ?? _initialParameters,
        super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [QueryPlatform].
  ///
  /// This is used by the app-facing [Query] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(QueryPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// The [FirebaseFirestorePlatform] interface for this current query.
  final FirebaseFirestorePlatform firestore;

  /// Stores the instances query modifier filters.
  final Map<String, dynamic> parameters;

  /// Returns whether the current query is targetted at a collection group.
  bool get isCollectionGroupQuery {
    throw UnimplementedError('isCollectionGroupQuery is not implemented');
  }

  /// Creates and returns a new [QueryPlatform] that ends at the provided document
  /// (inclusive). The end position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Cannot be used in combination with [endBefore], [endBeforeDocument], or
  /// [endAt], but can be used in combination with [startAt],
  /// [startAfter], [startAtDocument] and [startAfterDocument].
  ///
  /// See also:
  ///
  ///  * [startAfterDocument] for a query that starts after a document.
  ///  * [startAtDocument] for a query that starts at a document.
  ///  * [endBeforeDocument] for a query that ends before a document.
  QueryPlatform endAtDocument(List<dynamic> orders, List<dynamic> values) {
    throw UnimplementedError('endAtDocument() is not implemented');
  }

  /// Takes a list of [fields], creates and returns a new [QueryPlatform] that ends at the
  /// provided fields relative to the order of the query.
  ///
  /// The [fields] must be in order of [orderBy] filters.
  ///
  /// Cannot be used in combination with [endBefore], [endBeforeDocument], or
  /// [endAtDocument], but can be used in combination with [startAt],
  /// [startAfter], [startAtDocument] and [startAfterDocument].
  QueryPlatform endAt(List<dynamic> fields) {
    throw UnimplementedError('endAt() is not implemented');
  }

  /// Creates and returns a new [QueryPlatform] that ends before the provided document
  /// (exclusive). The end position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Cannot be used in combination with [endAt], [endBefore], or
  /// [endAtDocument], but can be used in combination with [startAt],
  /// [startAfter], [startAtDocument] and [startAfterDocument].
  ///
  /// See also:
  ///
  ///  * [startAfterDocument] for a query that starts after document.
  ///  * [startAtDocument] for a query that starts at a document.
  ///  * [endAtDocument] for a query that ends at a document.
  QueryPlatform endBeforeDocument(List<dynamic> orders, List<dynamic> values) {
    throw UnimplementedError('endBeforeDocument() is not implemented');
  }

  /// Takes a list of [fields], creates and returns a new [QueryPlatform] that ends before
  /// the provided fields relative to the order of the query.
  ///
  /// The [fields] must be in order of [orderBy] filters.
  ///
  /// Cannot be used in combination with [endAt], [endBeforeDocument], or
  /// [endBeforeDocument], but can be used in combination with [startAt],
  /// [startAfter], [startAtDocument] and [startAfterDocument].
  QueryPlatform endBefore(List<dynamic> fields) {
    throw UnimplementedError('endBefore() is not implemented');
  }

  /// Performs a query and returns a [QuerySnapshotPlatform] containing
  /// all documents which match the query.
  Future<QuerySnapshotPlatform> get([GetOptions options = const GetOptions()]) {
    throw UnimplementedError('get() is not implemented');
  }

  /// Creates and returns a new Query that's additionally limited to only return up
  /// to the specified number of documents.
  QueryPlatform limit(int limit) {
    throw UnimplementedError('limit() is not implemented');
  }

  /// Creates and returns a new Query that only returns the last matching documents.
  ///
  /// You must specify at least one orderBy clause for limitToLast queries,
  /// otherwise an exception will be thrown during execution.
  QueryPlatform limitToLast(int limit) {
    throw UnimplementedError('limitToLast() is not implemented');
  }

  /// Notifies of query results at this location
  Stream<QuerySnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
  }) {
    throw UnimplementedError('snapshots() is not implemented');
  }

  /// Creates and returns a new [QueryPlatform] that's additionally sorted by the specified
  /// [field].
  /// The field may be a [String] representing a single field name or a [FieldPath].
  ///
  /// After a [FieldPath.documentId] order by call, you cannot add any more [orderBy]
  /// calls.
  /// Furthermore, you may not use [orderBy] on the [FieldPath.documentId] [field] when
  /// using [startAfterDocument], [startAtDocument], [endBeforeDocument],
  /// or [endAtDocument] because the order by clause on the document id
  /// is added by these methods implicitly.
  QueryPlatform orderBy(List<List<dynamic>> orders) {
    throw UnimplementedError('orderBy() is not implemented');
  }

  /// Creates and returns a new [QueryPlatform] that starts after the provided document
  /// (exclusive). The starting position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Cannot be used in combination with [startAtDocument], [startAt], or
  /// [startAfter], but can be used in combination with [endAt],
  /// [endBefore], [endAtDocument] and [endBeforeDocument].
  ///
  /// See also:
  ///
  ///  * [endBeforeDocument] for a query that ends after a document.
  ///  * [startAtDocument] for a query that starts at a document.
  ///  * [endAtDocument] for a query that ends at a document.
  QueryPlatform startAfterDocument(List<dynamic> orders, List<dynamic> values) {
    throw UnimplementedError('startAfterDocument() is not implemented');
  }

  /// Takes a list of [fields], creates and returns a new [QueryPlatform] that starts
  /// after the provided fields relative to the order of the query.
  ///
  /// The [fields] must be in order of [orderBy] filters.
  ///
  /// Cannot be used in combination with [startAt], [startAfterDocument], or
  /// [startAtDocument], but can be used in combination with [endAt],
  /// [endBefore], [endAtDocument] and [endBeforeDocument].
  QueryPlatform startAfter(List<dynamic> fields) {
    throw UnimplementedError('startAfter() is not implemented');
  }

  /// Creates and returns a new [QueryPlatform] that starts at the provided document
  /// (inclusive). The starting position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Cannot be used in combination with [startAfterDocument], [startAfter], or
  /// [startAt], but can be used in combination with [endAt],
  /// [endBefore], [endAtDocument] and [endBeforeDocument].
  ///
  /// See also:
  ///
  ///  * [startAfterDocument] for a query that starts after a document.
  ///  * [endAtDocument] for a query that ends at a document.
  ///  * [endBeforeDocument] for a query that ends before a document.
  QueryPlatform startAtDocument(List<dynamic> orders, List<dynamic> values) {
    throw UnimplementedError('startAtDocument() is not implemented');
  }

  /// Takes a list of [fields], creates and returns a new [QueryPlatform] that starts at
  /// the provided fields relative to the order of the query.
  ///
  /// The [fields] must be in order of [orderBy] filters.
  ///
  /// Cannot be used in combination with [startAfter], [startAfterDocument],
  /// or [startAtDocument], but can be used in combination with [endAt],
  /// [endBefore], [endAtDocument] and [endBeforeDocument].
  QueryPlatform startAt(List<dynamic> fields) {
    throw UnimplementedError('startAt() is not implemented');
  }

  /// Creates and returns a new [QueryPlatform] with additional filter on specified
  /// [field]. [field] refers to a field in a document.
  ///
  /// The [field] may be a [String] consisting of a single field name
  /// (referring to a top level field in the document),
  /// or a series of field names separated by dots '.'
  /// (referring to a nested field in the document).
  /// Alternatively, the [field] can also be a [FieldPath].
  ///
  /// Only documents satisfying provided condition are included in the result
  /// set.
  QueryPlatform where(List<List<dynamic>> conditions) {
    throw UnimplementedError('where() is not implemented');
  }

  /// Returns an [AggregateQueryPlatform] which uses the [QueryPlatform] to query for
  /// metadata
  AggregateQueryPlatform count() {
    throw UnimplementedError('count() is not implemented');
  }
}
