// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Metadata about a snapshot, describing the state of the snapshot.
class SnapshotMetadataPlatform {
  /// Create an instance of [SnapshotMetadataPlatform]
  SnapshotMetadataPlatform(this.hasPendingWrites, this.isFromCache);

  /// Whether the snapshot contains the result of local writes that have not yet
  /// been committed to the backend.
  ///
  /// If you called [DocumentReferencePlatform.snapshots] or [QueryPlatform.snapshots] with
  /// `includeMetadataChanges` parameter set to `true` you will receive another
  /// snapshot with `hasPendingWrites` equal to `false` once the writes have been
  /// committed to the backend.
  final bool hasPendingWrites;

  /// Whether the snapshot was created from cached data rather than guaranteed
  /// up-to-date server data.
  ///
  /// If you called [DocumentReferencePlatform.snapshots] or [QueryPlatform.snapshots] with
  /// `includeMetadataChanges` parameter set to `true` you will receive another
  /// snapshot with `isFomCache` equal to `false` once the client has received
  /// up-to-date data from the backend.
  final bool isFromCache;
}
