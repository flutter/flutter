// Copyright 2021, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A [LoadBundleTaskSnapshot] is returned as the result or on-going process of a [LoadBundleTask].
class LoadBundleTaskSnapshot {
  LoadBundleTaskSnapshot._(this._delegate) {
    LoadBundleTaskSnapshotPlatform.verify(_delegate);
  }
  LoadBundleTaskSnapshotPlatform _delegate;

  /// How many bytes have been loaded.
  int get bytesLoaded => _delegate.bytesLoaded;

  /// How many documents have been loaded.
  int get documentsLoaded => _delegate.documentsLoaded;

  /// The current load bundle task snapshot state.
  ///
  /// The state indicates the current progress of the task, such as whether it
  /// is running, paused or completed.
  LoadBundleTaskState get taskState => _delegate.taskState;

  /// The total bytes of the load bundle task.
  int get totalBytes => _delegate.totalBytes;

  /// How many documents are in the bundle being loaded.
  int get totalDocuments => _delegate.totalDocuments;
}
