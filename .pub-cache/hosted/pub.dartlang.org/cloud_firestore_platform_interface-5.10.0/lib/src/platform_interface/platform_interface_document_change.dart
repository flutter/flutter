// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// An enumeration of document change types.
enum DocumentChangeType {
  /// Indicates a new document was added to the set of documents matching the
  /// query.
  added,

  /// Indicates a document within the query was modified.
  modified,

  /// Indicates a document within the query was removed (either deleted or no
  /// longer matches the query.
  removed,
}

/// A change to the documents matching a query.
///
/// It contains the document affected and the type of change that occurred
/// (added, modified, or removed).
class DocumentChangePlatform extends PlatformInterface {
  /// Create a [DocumentChangePlatform]
  DocumentChangePlatform(
    this.type,
    this.oldIndex,
    this.newIndex,
    this.document,
  ) : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [DocumentChangePlatform].
  ///
  /// This is used by the app-facing [DocumentChange] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(DocumentChangePlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// The type of change that occurred (added, modified, or removed).
  final DocumentChangeType type;

  /// The index of the changed document in the result set immediately prior to
  /// this [DocumentChangePlatform] (i.e. supposing that all prior DocumentChange objects
  /// have been applied).
  ///
  /// -1 for [DocumentChangeType.added] events.
  final int oldIndex;

  /// The index of the changed document in the result set immediately after this
  /// DocumentChange (i.e. supposing that all prior [DocumentChangePlatform] objects
  /// and the current [DocumentChangePlatform] object have been applied).
  ///
  /// -1 for [DocumentChangeType.removed] events.
  final int newIndex;

  /// The document affected by this change.
  final DocumentSnapshotPlatform document;
}
