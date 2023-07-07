// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// The [TransactionHandler] may be executed multiple times; it should be able
/// to handle multiple executions.
typedef TransactionHandler<T> = Future<T> Function(Transaction transaction);

/// Transaction class which is created from a call to [runTransaction()].
class Transaction {
  final FirebaseFirestore _firestore;
  final TransactionPlatform _delegate;

  Transaction._(this._firestore, this._delegate) {
    TransactionPlatform.verify(_delegate);
  }

  /// Reads the document referenced by the provided [DocumentReference].
  ///
  /// If the document changes whilst the transaction is in progress, it will
  /// be re-tried up to five times.
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async {
    DocumentSnapshotPlatform documentSnapshotPlatform =
        await _delegate.get(documentReference.path);

    final snapshot =
        _JsonDocumentSnapshot(_firestore, documentSnapshotPlatform);

    if (snapshot is DocumentSnapshot<T>) {
      return snapshot as DocumentSnapshot<T>;
    }

    final withConverterDocRef =
        documentReference as _WithConverterDocumentReference<T>;

    return _WithConverterDocumentSnapshot<T>(
      snapshot,
      withConverterDocRef._fromFirestore,
      withConverterDocRef._toFirestore,
    );
  }

  /// Deletes the document referred to by the provided [documentReference].
  Transaction delete(DocumentReference documentReference) {
    assert(
      documentReference.firestore == _firestore,
      'the document provided is from a different Firestore instance',
    );

    return Transaction._(
      _firestore,
      _delegate.delete(documentReference.path),
    );
  }

  /// Updates fields in the document referred to by [documentReference].
  /// The update will fail if applied to a document that does not exist.
  Transaction update(
    DocumentReference documentReference,
    Map<String, dynamic> data,
  ) {
    assert(
      documentReference.firestore == _firestore,
      'the document provided is from a different Firestore instance',
    );

    return Transaction._(
      _firestore,
      _delegate.update(
        documentReference.path,
        _CodecUtility.replaceValueWithDelegatesInMap(data)!,
      ),
    );
  }

  /// Writes to the document referred to by the provided [DocumentReference].
  /// If the document does not exist yet, it will be created. If you pass
  /// [SetOptions], the provided data can be merged into the existing document.
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    assert(
      documentReference.firestore == _firestore,
      'the document provided is from a different Firestore instance',
    );

    Map<String, dynamic> firestoreData;
    if (documentReference is _JsonDocumentReference) {
      firestoreData = data as Map<String, dynamic>;
    } else {
      final withConverterDoc =
          documentReference as _WithConverterDocumentReference<T>;
      firestoreData = withConverterDoc._toFirestore(data, options);
    }

    return Transaction._(
      _firestore,
      _delegate.set(
        documentReference.path,
        _CodecUtility.replaceValueWithDelegatesInMap(firestoreData)!,
        options,
      ),
    );
  }
}
