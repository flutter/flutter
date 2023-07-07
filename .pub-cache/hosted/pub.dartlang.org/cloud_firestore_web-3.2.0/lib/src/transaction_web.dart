// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import 'internals.dart';
import 'interop/firestore.dart' as firestore_interop;
import 'utils/encode_utility.dart';
import 'utils/web_utils.dart';

/// A web specific implementation of [Transaction].
class TransactionWeb extends TransactionPlatform {
  final firestore_interop.Firestore _webFirestoreDelegate;
  final firestore_interop.Transaction _webTransactionDelegate;

  FirebaseFirestorePlatform _firestore;

  /// Constructor.
  TransactionWeb(
      this._firestore, this._webFirestoreDelegate, this._webTransactionDelegate)
      : super();

  @override
  TransactionWeb delete(String documentPath) {
    _webTransactionDelegate.delete(_webFirestoreDelegate.doc(documentPath));
    return this;
  }

  @override
  Future<DocumentSnapshotPlatform> get(String documentPath) {
    return convertWebExceptions(
      () async {
        final webDocumentSnapshot = await _webTransactionDelegate
            .get(_webFirestoreDelegate.doc(documentPath));
        return convertWebDocumentSnapshot(
          _firestore,
          webDocumentSnapshot,
          ServerTimestampBehavior.none.name,
        );
      },
    );
  }

  @override
  TransactionWeb set(
    String documentPath,
    Map<String, dynamic> data, [
    SetOptions? options,
  ]) {
    _webTransactionDelegate.set(
      _webFirestoreDelegate.doc(documentPath),
      EncodeUtility.encodeMapData(data)!,
      convertSetOptions(options),
    );
    return this;
  }

  @override
  TransactionWeb update(
    String documentPath,
    Map<String, dynamic> data,
  ) {
    _webTransactionDelegate.update(
      _webFirestoreDelegate.doc(documentPath),
      EncodeUtility.encodeMapData(data)!,
    );
    return this;
  }
}
