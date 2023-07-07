// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

typedef FromFirestore<T> = T Function(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  SnapshotOptions? options,
);
typedef ToFirestore<T> = Map<String, Object?> Function(
  T value,
  SetOptions? options,
);

/// Options that configure how data is retrieved from a DocumentSnapshot
/// (e.g. the desired behavior for server timestamps that have not yet been set to their final value).
///
/// Currently unsupported by FlutterFire, but exposed to avoid breaking changes
/// in the future once this class is supported.
@sealed
class SnapshotOptions {}

/// A [DocumentSnapshot] contains data read from a document in your [FirebaseFirestore]
/// database.
///
/// The data can be extracted with the data property or by using subscript
/// syntax to access a specific field.
@sealed
abstract class DocumentSnapshot<T extends Object?> {
  /// This document's given ID for this snapshot.
  String get id;

  /// Returns the reference of this snapshot.
  DocumentReference<T> get reference;

  /// Metadata about this document concerning its source and if it has local
  /// modifications.
  SnapshotMetadata get metadata;

  /// Returns `true` if the document exists.
  bool get exists;

  /// Contains all the data of this document snapshot.
  T? data();

  /// {@template firestore.documentsnapshot.get}
  /// Gets a nested field by [String] or [FieldPath] from this [DocumentSnapshot].
  ///
  /// Data can be accessed by providing a dot-notated path or [FieldPath]
  /// which recursively finds the specified data. If no data could be found
  /// at the specified path, a [StateError] will be thrown.
  /// {@endtemplate}
  dynamic get(Object field);

  /// {@macro firestore.documentsnapshot.get}
  dynamic operator [](Object field);
}

class _JsonDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _JsonDocumentSnapshot(this._firestore, this._delegate) {
    DocumentSnapshotPlatform.verify(_delegate);
  }

  final FirebaseFirestore _firestore;
  final DocumentSnapshotPlatform _delegate;

  @override
  String get id => _delegate.id;

  @override
  late final DocumentReference<Map<String, dynamic>> reference =
      _firestore.doc(_delegate.reference.path);

  @override
  late final SnapshotMetadata metadata = SnapshotMetadata._(_delegate.metadata);

  @override
  bool get exists => _delegate.exists;

  @override
  Map<String, dynamic>? data() {
    // TODO(rrousselGit): can we cache the result, to avoid deserializing it on every read?
    return _CodecUtility.replaceDelegatesWithValueInMap(
      _delegate.data(),
      _firestore,
    );
  }

  @override
  dynamic get(Object field) {
    return _CodecUtility.valueDecode(_delegate.get(field), _firestore);
  }

  @override
  dynamic operator [](Object field) => get(field);
}

/// A [DocumentSnapshot] contains data read from a document in your [FirebaseFirestore]
/// database.
///
/// The data can be extracted with the data property or by using subscript
/// syntax to access a specific field.
class _WithConverterDocumentSnapshot<T> implements DocumentSnapshot<T> {
  _WithConverterDocumentSnapshot(
    this._originalDocumentSnapshot,
    this._fromFirestore,
    this._toFirestore,
  );

  final DocumentSnapshot<Map<String, dynamic>> _originalDocumentSnapshot;
  final FromFirestore<T> _fromFirestore;
  final ToFirestore<T> _toFirestore;

  @override
  T? data() {
    if (!_originalDocumentSnapshot.exists) return null;

    return _fromFirestore(_originalDocumentSnapshot, null);
  }

  @override
  bool get exists => _originalDocumentSnapshot.exists;

  @override
  String get id => _originalDocumentSnapshot.id;

  @override
  SnapshotMetadata get metadata => _originalDocumentSnapshot.metadata;

  @override
  DocumentReference<T> get reference => _WithConverterDocumentReference<T>(
        _originalDocumentSnapshot.reference,
        _fromFirestore,
        _toFirestore,
      );

  @override
  dynamic get(Object field) => _originalDocumentSnapshot.get(field);

  @override
  dynamic operator [](Object field) => _originalDocumentSnapshot[field];
}
