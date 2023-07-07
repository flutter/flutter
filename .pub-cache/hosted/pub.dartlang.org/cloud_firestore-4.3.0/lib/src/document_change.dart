// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A [DocumentChange] represents a change to the documents matching a query.
///
/// It contains the document affected and the type of change that occurred
/// (added, modified, or removed).
abstract class DocumentChange<T extends Object?> {
  /// The type of change that occurred (added, modified, or removed).
  DocumentChangeType get type;

  /// The index of the changed document in the result set immediately prior to
  /// this [DocumentChange] (i.e. supposing that all prior [DocumentChange] objects
  /// have been applied).
  ///
  /// -1 is returned for [DocumentChangeType.added] events.
  int get oldIndex;

  /// The index of the changed document in the result set immediately after this
  /// [DocumentChange] (i.e. supposing that all prior [DocumentChange] objects
  /// and the current [DocumentChange] object have been applied).
  ///
  /// -1 is returned for [DocumentChangeType.removed] events.
  int get newIndex;

  /// Returns the [DocumentSnapshot] for this instance.
  DocumentSnapshot<T> get doc;
}

class _JsonDocumentChange implements DocumentChange<Map<String, dynamic>> {
  _JsonDocumentChange(this._firestore, this._delegate) {
    DocumentChangePlatform.verify(_delegate);
  }

  final DocumentChangePlatform _delegate;
  final FirebaseFirestore _firestore;

  @override
  DocumentChangeType get type => _delegate.type;

  @override
  int get oldIndex => _delegate.oldIndex;

  @override
  int get newIndex => _delegate.newIndex;

  @override
  DocumentSnapshot<Map<String, dynamic>> get doc {
    return _JsonDocumentSnapshot(_firestore, _delegate.document);
  }
}

class _WithConverterDocumentChange<T extends Object?>
    implements DocumentChange<T> {
  _WithConverterDocumentChange(
    this._originalDocumentChange,
    this._fromFirestore,
    this._toFirestore,
  );

  final DocumentChange<Map<String, dynamic>> _originalDocumentChange;
  final FromFirestore<T> _fromFirestore;
  final ToFirestore<T> _toFirestore;

  @override
  DocumentChangeType get type => _originalDocumentChange.type;

  @override
  int get oldIndex => _originalDocumentChange.oldIndex;

  @override
  int get newIndex => _originalDocumentChange.newIndex;

  @override
  DocumentSnapshot<T> get doc {
    return _WithConverterDocumentSnapshot<T>(
      _originalDocumentChange.doc,
      _fromFirestore,
      _toFirestore,
    );
  }
}
