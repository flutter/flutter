// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A [QueryDocumentSnapshot] contains data read from a document in your [FirebaseFirestore]
/// database as part of a query.
///
/// A [QueryDocumentSnapshot] offers the same API surface as a [DocumentSnapshot].
/// Since query results contain only existing documents, the exists property
/// will always be `true` and [data()] will never return `null`.
@sealed
abstract class QueryDocumentSnapshot<T extends Object?>
    implements DocumentSnapshot<T> {
  @override
  T data();
}

class _JsonQueryDocumentSnapshot extends _JsonDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _JsonQueryDocumentSnapshot(_firestore, _delegate)
      : super(_firestore, _delegate);

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => super.data()!;
}

/// A [QueryDocumentSnapshot] contains data read from a document in your [FirebaseFirestore]
/// database as part of a query.
///
/// A [QueryDocumentSnapshot] offers the same API surface as a [DocumentSnapshot].
/// Since query results contain only existing documents, the exists property
/// will always be `true` and [data()] will never return `null`.
class _WithConverterQueryDocumentSnapshot<T extends Object?>
    extends _WithConverterDocumentSnapshot<T>
    implements QueryDocumentSnapshot<T> {
  _WithConverterQueryDocumentSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> originalQueryDocumentSnapshot,
    FromFirestore<T> fromFirestore,
    ToFirestore<T> toFirestore,
  ) : super(
          originalQueryDocumentSnapshot,
          fromFirestore,
          toFirestore,
        );

  @override
  bool get exists => true;

  @override
  T data() => super.data()!;
}
