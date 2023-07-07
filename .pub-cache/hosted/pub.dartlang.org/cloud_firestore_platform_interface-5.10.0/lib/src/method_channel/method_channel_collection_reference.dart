// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';

import 'method_channel_document_reference.dart';
import 'method_channel_query.dart';
import 'utils/auto_id_generator.dart';

/// A `CollectionReference` object can be used for adding documents, getting
/// document references, and querying for documents (using the methods
/// inherited from [QueryPlatform]).
///
/// Note that this class *should* extend [CollectionReferencePlatform], but
/// it doesn't because of the extensive changes required to [MethodChannelQuery]
/// (which *does* extend its Platform class). If you changed
/// [CollectionReferencePlatform] and this class started throwing compilation
/// errors, now you know why.
class MethodChannelCollectionReference extends MethodChannelQuery
    implements
// ignore: avoid_implementing_value_types
        CollectionReferencePlatform {
  /// Create a [MethodChannelCollectionReference] instance.
  MethodChannelCollectionReference(
      FirebaseFirestorePlatform firestore, String path)
      : _pointer = Pointer(path),
        super(firestore, path);

  final Pointer _pointer;

  /// Returns the identifier of this referenced collection.
  @override
  String get id => _pointer.id;

  /// A string containing the slash-separated path to this instance
  /// (relative to the root of the database).
  @override
  DocumentReferencePlatform? get parent {
    String? parentPath = _pointer.parentPath();
    return parentPath == null
        ? null
        : MethodChannelDocumentReference(firestore, parentPath);
  }

  /// Returns the path of this referenced collection.
  @override
  String get path => _pointer.path;

  @override
  DocumentReferencePlatform doc([String? path]) {
    String documentPath;

    if (path != null) {
      documentPath = _pointer.documentPath(path);
    } else {
      final String autoId = AutoIdGenerator.autoId();
      documentPath = _pointer.documentPath(autoId);
    }

    return MethodChannelDocumentReference(firestore, documentPath);
  }
}
