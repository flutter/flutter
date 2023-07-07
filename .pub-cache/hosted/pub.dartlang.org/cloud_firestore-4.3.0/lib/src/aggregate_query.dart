// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// [AggregateQuery] represents the data at a particular location for retrieving metadata
/// without retrieving the actual documents.
class AggregateQuery {
  AggregateQuery._(this._delegate, this.query) {
    AggregateQueryPlatform.verify(_delegate);
  }

  /// [Query] represents the query over the data at a particular location used by the [AggregateQuery] to
  /// retrieve the metadata.
  final Query query;

  final AggregateQueryPlatform _delegate;

  /// Returns an [AggregateQuerySnapshot] with the count of the documents that match the query.
  Future<AggregateQuerySnapshot> get({
    AggregateSource source = AggregateSource.server,
  }) async {
    return AggregateQuerySnapshot._(await _delegate.get(source: source), query);
  }
}
