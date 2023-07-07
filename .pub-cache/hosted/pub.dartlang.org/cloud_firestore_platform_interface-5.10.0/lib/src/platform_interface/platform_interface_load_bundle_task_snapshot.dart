// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../cloud_firestore_platform_interface.dart';

/// The interface a load bundle task snapshot must extend.
class LoadBundleTaskSnapshotPlatform extends PlatformInterface {
  // ignore: public_member_api_docs
  LoadBundleTaskSnapshotPlatform(this.taskState, data)
      : bytesLoaded = data['bytesLoaded'],
        documentsLoaded = data['documentsLoaded'],
        totalBytes = data['totalBytes'],
        totalDocuments = data['totalDocuments'],
        super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [LoadBundleTaskSnapshotPlatform].
  ///
  /// This is used by the app-facing [LoadBundleTaskSnapshot] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(LoadBundleTaskSnapshotPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  final LoadBundleTaskState taskState;

  /// The current bytes loaded of this task.
  final int bytesLoaded;

  /// How many documents have been loaded.
  final int documentsLoaded;

  /// Total amount of bytes in the bundle being loaded.
  final int totalBytes;

  /// How many documents are in the bundle being loaded.
  final int totalDocuments;
}
