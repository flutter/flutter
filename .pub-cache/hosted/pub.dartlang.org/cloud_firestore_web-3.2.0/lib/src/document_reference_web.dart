// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import 'internals.dart';
import 'interop/firestore.dart' as firestore_interop;
import 'utils/encode_utility.dart';
import 'utils/web_utils.dart';

/// Web implementation for Firestore [DocumentReferencePlatform].
class DocumentReferenceWeb extends DocumentReferencePlatform {
  /// instance of Firestore from the web plugin
  final firestore_interop.Firestore firestoreWeb;

  /// instance of DocumentReference from the web plugin
  final firestore_interop.DocumentReference _delegate;

  /// Creates an instance of [DocumentReferenceWeb] which represents path
  /// at [pathComponents] and uses implementation of [firestoreWeb]
  DocumentReferenceWeb(
    FirebaseFirestorePlatform firestore,
    this.firestoreWeb,
    String path,
  )   : _delegate = firestoreWeb.doc(path),
        super(firestore, path);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) {
    return convertWebExceptions(
      () => _delegate.set(
        EncodeUtility.encodeMapData(data)!,
        convertSetOptions(options),
      ),
    );
  }

  @override
  Future<void> update(Map<String, dynamic> data) {
    return convertWebExceptions(
        () => _delegate.update(EncodeUtility.encodeMapData(data)!));
  }

  @override
  Future<DocumentSnapshotPlatform> get(
      [GetOptions options = const GetOptions()]) async {
    firestore_interop.DocumentSnapshot documentSnapshot =
        await convertWebExceptions(
      () => _delegate.get(convertGetOptions(options)),
    );

    return convertWebDocumentSnapshot(
      firestore,
      documentSnapshot,
      getServerTimestampBehaviorString(options.serverTimestampBehavior),
    );
  }

  @override
  Future<void> delete() {
    return convertWebExceptions(_delegate.delete);
  }

  @override
  Stream<DocumentSnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
  }) {
    Stream<firestore_interop.DocumentSnapshot> querySnapshots =
        _delegate.onSnapshot;
    if (includeMetadataChanges) {
      querySnapshots = _delegate.onMetadataChangesSnapshot;
    }

    return convertWebExceptions(
      () => querySnapshots.map((webSnapshot) {
        return convertWebDocumentSnapshot(
          firestore,
          webSnapshot,
          ServerTimestampBehavior.none.name,
        );
      }),
    );
  }
}
