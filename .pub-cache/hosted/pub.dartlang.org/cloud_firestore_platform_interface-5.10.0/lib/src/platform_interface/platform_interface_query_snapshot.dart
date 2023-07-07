// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A interface that contains zero or more [DocumentSnapshotPlatform] objects
/// representing the results of a query.
///
/// The documents can be accessed as a list by calling [docs()] and the number of documents
/// can be determined by calling [size()].
class QuerySnapshotPlatform extends PlatformInterface {
  /// Create a [QuerySnapshotPlatform]
  QuerySnapshotPlatform(
    this.docs,
    this.docChanges,
    this.metadata,
  ) : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [QuerySnapshotPlatform].
  ///
  /// This is used by the app-facing [QuerySnapshot] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(QuerySnapshotPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// Gets a list of all the documents included in this [QuerySnapshotPlatform]
  final List<DocumentSnapshotPlatform> docs;

  /// An array of the documents that changed since the last snapshot. If this
  /// is the first snapshot, all documents will be in the list as Added changes.
  final List<DocumentChangePlatform> docChanges;

  /// Metadata for the document
  final SnapshotMetadataPlatform metadata;

  /// The number of documents in this [QuerySnapshotPlatform].
  int get size => docs.length;
}
