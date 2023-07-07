// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The [TransactionHandler] may be executed multiple times, it should be able
/// to handle multiple executions.
typedef TransactionHandler<T extends dynamic> = Future<T?>? Function(
    TransactionPlatform);

/// A [TransactionPlatform] is a set of read and write operations on one or more documents.
abstract class TransactionPlatform extends PlatformInterface {
  /// Constructor.
  TransactionPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [TransactionPlatform].
  ///
  /// This is used by the app-facing [Transaction] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(TransactionPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// Returns all transaction commands for the current instance.
  List<Map<String, dynamic>> get commands {
    throw UnimplementedError('commands is not implemented');
  }

  /// Reads the document referenced by the provided [documentPath].
  ///
  /// If the document changes whilst the transaction is in progress, it will
  /// be re-tried up to five times.
  Future<DocumentSnapshotPlatform> get(String documentPath) {
    throw UnimplementedError('get() is not implemented');
  }

  /// Deletes the document referred to by the provided [documentPath].
  TransactionPlatform delete(String documentPath) {
    throw UnimplementedError('delete() is not implemented');
  }

  /// Updates fields in the document referred to by [documentPath].
  /// The update will fail if applied to a document that does not exist.
  TransactionPlatform update(
    String documentPath,
    Map<String, dynamic> data,
  ) {
    throw UnimplementedError('update() is not implemented');
  }

  /// Writes to the document referred to by the provided [documentPath].
  /// If the document does not exist yet, it will be created. If you pass
  /// [SetOptions], the provided [data] can be merged into the existing document.
  TransactionPlatform set(String documentPath, Map<String, dynamic> data,
      [SetOptions? options]) {
    throw UnimplementedError('set() is not implemented');
  }
}
