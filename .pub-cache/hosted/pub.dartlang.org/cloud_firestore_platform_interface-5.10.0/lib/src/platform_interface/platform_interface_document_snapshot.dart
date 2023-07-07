// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Contains data read from a document in your Firestore
/// database.
///
/// The data can be extracted by calling [data()] or by calling [get()]
/// to get a specific field.
class DocumentSnapshotPlatform extends PlatformInterface {
  /// Constructs a [DocumentSnapshotPlatform] using the provided [FirebaseFirestorePlatform].
  DocumentSnapshotPlatform(this._firestore, String path, this._data)
      : _pointer = Pointer(path),
        super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [DocumentSnapshotPlatform].
  ///
  /// This is used by the app-facing [DocumentSnapshot] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(DocumentSnapshotPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// The [FirebaseFirestorePlatform] used to produce this [DocumentSnapshotPlatform].
  final FirebaseFirestorePlatform _firestore;

  final Pointer _pointer;

  final Map<String, dynamic> _data;

  /// The database ID of the snapshot's document.
  String get id => _pointer.id;

  /// Metadata about this snapshot concerning its source and if it has local
  /// modifications.
  SnapshotMetadataPlatform get metadata {
    return SnapshotMetadataPlatform(
      _data['metadata']['hasPendingWrites'],
      _data['metadata']['isFromCache'],
    );
  }

  /// Signals whether or not the data exists.
  bool get exists {
    return _data['data'] != null;
  }

  /// The reference that produced this snapshot.
  DocumentReferencePlatform get reference => _firestore.doc(_pointer.path);

  /// Contains all the data of this snapshot.
  Map<String, dynamic>? data() {
    return exists ? Map<String, dynamic>.from(_data['data']) : null;
  }

  /// Gets a nested field by [String] or [FieldPath] from the snapshot.
  ///
  /// Data can be accessed by providing a dot-notated path or [FieldPath]
  /// which recursively finds the specified data. If no data could be found
  /// at the specified path, a [StateError] will be thrown.
  dynamic get(Object field) {
    assert(
      field is String || field is FieldPath,
      'Supported [field] types are [String] and [FieldPath]',
    );

    if (!exists) {
      throw StateError(
        'cannot get a field on a $DocumentSnapshotPlatform which does not exist',
      );
    }

    dynamic _findKeyValueInMap(String key, Map<String, dynamic> map) {
      if (map.containsKey(key)) {
        return map[key];
      }

      throw StateError(
        'field does not exist within the $DocumentSnapshotPlatform',
      );
    }

    FieldPath fieldPath;
    if (field is String) {
      fieldPath = FieldPath.fromString(field);
    } else {
      fieldPath = field as FieldPath;
    }

    List<String> components = fieldPath.components;

    Map<String, dynamic>? snapshotData = data();

    dynamic _findComponent(int componentIndex, Map<String, dynamic>? data) {
      bool isLast = componentIndex + 1 == components.length;
      dynamic value = _findKeyValueInMap(components[componentIndex], data!);

      if (isLast) {
        return value;
      }

      if (value is Map) {
        return _findComponent(
            componentIndex + 1, Map<String, dynamic>.from(value));
      } else {
        throw StateError(
          'field does not exist within the $DocumentSnapshotPlatform',
        );
      }
    }

    return _findComponent(0, snapshotData);
  }

  /// Gets a nested field by [String] or [FieldPath] from the snapshot.
  ///
  /// Data can be accessed by providing a dot-notated path or [FieldPath]
  /// which recursively finds the specified data. If no data could be found
  /// at the specified path, a [StateError] will be thrown.
  dynamic operator [](Object field) => get(field);
}
