// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import 'interop/firestore.dart' as firestore_interop;

/// Web implementation for Firestore [AggregateQueryPlatform].
class AggregateQueryWeb extends AggregateQueryPlatform {
  /// instance of [AggregateQuery] from the web plugin
  final firestore_interop.AggregateQuery _delegate;

  /// [AggregateQueryWeb] represents the data at a particular location for retrieving metadata
  /// without retrieving the actual documents.
  AggregateQueryWeb(QueryPlatform query, _webQuery)
      : _delegate = firestore_interop.AggregateQuery(_webQuery),
        super(query);

  /// Returns an [AggregateQuerySnapshotPlatform] with the count of the documents that match the query.
  @override
  Future<AggregateQuerySnapshotPlatform> get({
    required AggregateSource source,
  }) async {
    // Note: There isn't a source option on the web platform
    firestore_interop.AggregateQuerySnapshot snapshot = await _delegate.get();

    return AggregateQuerySnapshotPlatform(count: snapshot.count);
  }
}
