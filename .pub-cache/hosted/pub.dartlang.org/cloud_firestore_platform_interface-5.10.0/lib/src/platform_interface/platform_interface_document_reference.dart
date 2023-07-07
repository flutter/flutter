// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A [DocumentReferencePlatform] refers to a document location in a Firestore database
/// and can be used to write, read, or listen to the location.
///
/// The document at the referenced location may or may not exist.
/// A [DocumentReferencePlatform] can also be used to create a
/// [CollectionReferencePlatform] to a subcollection.
abstract class DocumentReferencePlatform extends PlatformInterface {
  /// Create instance of [DocumentReferencePlatform]
  DocumentReferencePlatform(
    this.firestore,
    String path,
  )   : _pointer = Pointer(path),
        super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [DocumentReferencePlatform].
  ///
  /// This is used by the app-facing [DocumentReference] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(DocumentReferencePlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// The Firestore instance associated with this document reference
  final FirebaseFirestorePlatform firestore;

  final Pointer _pointer;

  /// Slash-delimited path representing the database location of this query.
  String get path => _pointer.path;

  /// This document's given or generated ID in the collection.
  String get id => _pointer.id;

  /// Return the parent [CollectionReferencePlatform] of this document.
  CollectionReferencePlatform get parent {
    return firestore.collection(_pointer.parentPath()!);
  }

  /// Returns a [CollectionReferencePlatform] starting from the current
  /// document pointer.
  CollectionReferencePlatform collection(String collectionPath) {
    return firestore.collection(_pointer.collectionPath(collectionPath));
  }

  /// Deletes the document referred to by this [DocumentReferencePlatform].
  Future<void> delete() {
    throw UnimplementedError('delete() is not implemented');
  }

  /// Reads the document referenced by this [DocumentReferencePlatform].
  ///
  /// If no document exists, the read will return null.
  Future<DocumentSnapshotPlatform> get(
      [GetOptions options = const GetOptions()]) async {
    throw UnimplementedError('get() is not implemented');
  }

  /// Notifies of documents at this location
  Stream<DocumentSnapshotPlatform> snapshots(
      {bool includeMetadataChanges = false}) {
    throw UnimplementedError('snapshots() is not implemented');
  }

  /// Writes to the document referred to by this [DocumentReferencePlatform].
  ///
  /// If the document does not yet exist, it will be created.
  ///
  /// If [merge] is true, the provided data will be merged into an
  /// existing document instead of overwriting.
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) {
    throw UnimplementedError('set() is not implemented');
  }

  /// Updates fields in the document referred to by this [DocumentReferencePlatform].
  ///
  /// Values in [data] may be of any supported Firestore type as well as
  /// special sentinel [FieldValuePlatform] type.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> update(Map<String, dynamic> data) {
    throw UnimplementedError('update() is not implemented');
  }

  @override
  //ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is DocumentReferencePlatform &&
      other.firestore == firestore &&
      other.path == path;

  @override
  //ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => path.hashCode;

  @override
  String toString() => '$DocumentReferencePlatform($path)';
}
