// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import 'interop/firestore.dart' as firestore_interop;
import 'document_reference_web.dart';
import 'query_web.dart';

/// Web implementation for Firestore [CollectionReferencePlatform].
class CollectionReferenceWeb extends QueryWeb
    implements
//ignore: avoid_implementing_value_types
        CollectionReferencePlatform {
  /// instance of Firestore from the web plugin
  final firestore_interop.Firestore _webFirestore;

  final FirebaseFirestorePlatform _firestorePlatform;

  /// instance of DocumentReference from the web plugin
  final firestore_interop.CollectionReference _delegate;

  /// Creates an instance of [CollectionReferenceWeb] which represents path
  /// at [pathComponents] and uses implementation of [webFirestore]
  CollectionReferenceWeb(
      this._firestorePlatform, this._webFirestore, String path)
      : _delegate = _webFirestore.collection(path),
        super(_firestorePlatform, path, _webFirestore.collection(path));

  @override
  String get path => _delegate.path;

  @override
  DocumentReferencePlatform doc([String? path]) {
    firestore_interop.DocumentReference documentReference = _delegate.doc(path);
    return DocumentReferenceWeb(
        _firestorePlatform, _webFirestore, documentReference.path);
  }

  @override
  String get id => _delegate.id;

  @override
  DocumentReferencePlatform? get parent {
    firestore_interop.DocumentReference? documentReference = _delegate.parent;

    if (documentReference == null) {
      return null;
    }

    return DocumentReferenceWeb(
        _firestorePlatform, _webFirestore, documentReference.path);
  }
}
