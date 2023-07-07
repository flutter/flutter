// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A write batch, used to perform multiple writes as a single atomic unit.
///
///A [WriteBatch] provides methods for adding writes to the write batch.
///
/// Operations done on a [WriteBatch] do not take effect until you [commit()].
///
/// Once committed, no further operations can be performed on the [WriteBatch],
/// nor can it be committed again.
abstract class WriteBatchPlatform extends PlatformInterface {
  /// Overridable constructor
  WriteBatchPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [WriteBatchPlatform].
  /// This is used by the app-facing [WriteBatch] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(WriteBatchPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// Commits all of the writes in this write batch as a single atomic unit.
  ///
  /// Calling this method prevents any future operations from being added.
  Future<void> commit() async {
    throw UnimplementedError('commit() is not implemented');
  }

  /// Deletes the document referred to by a [documentPath].
  void delete(String documentPath) {
    throw UnimplementedError('delete() is not implemented');
  }

  /// Writes to the document referred to by [document].
  ///
  /// If the document does not yet exist, it will be created.
  ///
  /// If [SetOptions] are provided, the [data] will be merged into an existing
  /// document instead of overwriting.
  void set(String documentPath, Map<String, dynamic> data,
      [SetOptions? options]) {
    throw UnimplementedError('set() is not implemented');
  }

  /// Updates fields in the document referred to by [document].
  ///
  /// If the document does not exist, the operation will fail.
  void update(
    String documentPath,
    Map<String, dynamic> data,
  ) {
    throw UnimplementedError('update() is not implemented');
  }
}
