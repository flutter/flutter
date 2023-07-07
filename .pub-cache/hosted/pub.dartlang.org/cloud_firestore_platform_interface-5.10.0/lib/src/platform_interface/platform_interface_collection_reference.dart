// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';

/// A [CollectionReferencePlatform] can be used for adding documents, getting
/// document references, and querying for documents (using the methods
/// inherited from [QueryPlatform]).
/// Note: QueryPlatform extends PlatformInterface already.
abstract class CollectionReferencePlatform extends QueryPlatform {
  final Pointer _pointer;

  /// Create a [CollectionReferencePlatform] from a [path]
  CollectionReferencePlatform(
    FirebaseFirestorePlatform firestore,
    String path,
  )   : _pointer = Pointer(path),
        super(firestore, <String, dynamic>{});

  /// Identifier of the referenced collection.
  String get id => _pointer.id;

  /// For subcollections, parent returns the containing [DocumentReferencePlatform].
  ///
  /// For root collections, `null` is returned.
  DocumentReferencePlatform? get parent {
    String? parentPath = _pointer.parentPath();

    if (parentPath == null) {
      return null;
    }

    return firestore.doc(parentPath);
  }

  /// A string containing the slash-separated path to this [CollectionReferencePlatform]
  /// (relative to the root of the database).
  String get path => _pointer.path;

  /// Returns a [DocumentReferencePlatform] with the provided [path].
  ///
  /// If no [path] is provided, an auto-generated ID is used.
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  DocumentReferencePlatform doc([String? path]) {
    throw UnimplementedError('doc() is not implemented');
  }

  @override
  //ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is CollectionReferencePlatform &&
      other.firestore == firestore &&
      other.path == path;

  @override
  //ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => path.hashCode;

  @override
  String toString() => '$CollectionReferencePlatform($path)';
}
