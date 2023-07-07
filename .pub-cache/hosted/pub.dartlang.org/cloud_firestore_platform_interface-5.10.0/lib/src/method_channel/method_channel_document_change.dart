// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

/// An implementation of [DocumentChangePlatform] that uses [MethodChannel] to
/// communicate with Firebase plugins.
class MethodChannelDocumentChange extends DocumentChangePlatform {
  /// Creates a [MethodChannelDocumentChange] from the given [data]
  MethodChannelDocumentChange(
      FirebaseFirestorePlatform firestore, Map<String, dynamic> data)
      : super(DocumentChangeType.values.firstWhere((DocumentChangeType type) {
          return type.toString() == data['type'];
        }),
            data['oldIndex'],
            data['newIndex'],
            DocumentSnapshotPlatform(
              firestore,
              data['path'],
              <String, dynamic>{
                'data': Map<String, dynamic>.from(data['data']),
                'metadata': Map<String, dynamic>.from(data['metadata']),
              },
            ));
}
