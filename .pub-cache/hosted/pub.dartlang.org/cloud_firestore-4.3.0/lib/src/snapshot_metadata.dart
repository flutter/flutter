// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// Metadata about a snapshot, describing the state of the snapshot.
class SnapshotMetadata {
  SnapshotMetadataPlatform _delegate;

  SnapshotMetadata._(this._delegate);

  /// Whether the snapshot contains the result of local writes that have not yet
  /// been committed to the backend.
  ///
  /// If you called [DocumentReference.snapshots] or [Query.snapshots] with
  /// `includeMetadataChanges` parameter set to `true` you will receive another
  /// snapshot with `hasPendingWrites` equal to `false` once the writes have been
  /// committed to the backend.
  bool get hasPendingWrites => _delegate.hasPendingWrites;

  /// Whether the snapshot was created from cached data rather than guaranteed
  /// up-to-date server data.
  ///
  /// If you called [DocumentReference.snapshots] or [Query.snapshots] with
  /// `includeMetadataChanges` parameter set to `true` you will receive another
  /// snapshot with `isFromCache` equal to `false` once the client has received
  /// up-to-date data from the backend.
  bool get isFromCache => _delegate.isFromCache;
}
