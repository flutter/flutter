// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// Contains the results of a query.
/// It can contain zero or more [DocumentSnapshot] objects.
abstract class QuerySnapshot<T extends Object?> {
  /// Gets a list of all the documents included in this snapshot.
  List<QueryDocumentSnapshot<T>> get docs;

  /// An array of the documents that changed since the last snapshot. If this
  /// is the first snapshot, all documents will be in the list as Added changes.
  List<DocumentChange<T>> get docChanges;

  /// Returns the [SnapshotMetadata] for this snapshot.
  SnapshotMetadata get metadata;

  /// Returns the size (number of documents) of this snapshot.
  int get size;
}

/// Contains the results of a query.
/// It can contain zero or more [DocumentSnapshot] objects.
class _JsonQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _JsonQuerySnapshot(this._firestore, this._delegate) {
    QuerySnapshotPlatform.verify(_delegate);
  }

  final FirebaseFirestore _firestore;
  final QuerySnapshotPlatform _delegate;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _delegate.docs
      .map(
        (documentDelegate) =>
            _JsonQueryDocumentSnapshot(_firestore, documentDelegate),
      )
      .toList();

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges {
    return _delegate.docChanges.map((documentDelegate) {
      return _JsonDocumentChange(_firestore, documentDelegate);
    }).toList();
  }

  @override
  SnapshotMetadata get metadata => SnapshotMetadata._(_delegate.metadata);

  @override
  int get size => _delegate.size;
}

/// Contains the results of a query.
/// It can contain zero or more [DocumentSnapshot] objects.
class _WithConverterQuerySnapshot<T extends Object?>
    implements QuerySnapshot<T> {
  _WithConverterQuerySnapshot(
    this._originalQuerySnapshot,
    this._fromFirestore,
    this._toFirestore,
  );

  final QuerySnapshot<Map<String, dynamic>> _originalQuerySnapshot;
  final FromFirestore<T> _fromFirestore;
  final ToFirestore<T> _toFirestore;

  @override
  List<QueryDocumentSnapshot<T>> get docs {
    return [
      for (final snapshot in _originalQuerySnapshot.docs)
        _WithConverterQueryDocumentSnapshot<T>(
          snapshot,
          _fromFirestore,
          _toFirestore,
        ),
    ];
  }

  @override
  List<DocumentChange<T>> get docChanges {
    return [
      for (final change in _originalQuerySnapshot.docChanges)
        _WithConverterDocumentChange<T>(
          change,
          _fromFirestore,
          _toFirestore,
        ),
    ];
  }

  @override
  SnapshotMetadata get metadata => _originalQuerySnapshot.metadata;

  @override
  int get size => _originalQuerySnapshot.size;
}
