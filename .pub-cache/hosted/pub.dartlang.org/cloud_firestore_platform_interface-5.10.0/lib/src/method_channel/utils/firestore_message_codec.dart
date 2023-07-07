// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(Lyokone): remove once we bump Flutter SDK min version to 3.3
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/field_path_type.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_field_value.dart';
import 'package:firebase_core/firebase_core.dart';
// TODO(Lyokone): remove once we bump Flutter SDK min version to 3.3
// ignore: unnecessary_import
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../method_channel_firestore.dart';
import '../method_channel_query.dart';

/// The codec utilized to encode data back and forth between
/// the Dart application and the native platform.
class FirestoreMessageCodec extends StandardMessageCodec {
  /// Constructor.
  const FirestoreMessageCodec();

  static const int _kDateTime = 128;
  static const int _kGeoPoint = 129;
  static const int _kDocumentReference = 130;
  static const int _kBlob = 131;
  static const int _kArrayUnion = 132;
  static const int _kArrayRemove = 133;
  static const int _kDelete = 134;
  static const int _kServerTimestamp = 135;
  static const int _kTimestamp = 136;
  static const int _kIncrementDouble = 137;
  static const int _kIncrementInteger = 138;
  static const int _kDocumentId = 139;
  static const int _kFieldPath = 140;
  static const int _kNaN = 141;
  static const int _kInfinity = 142;
  static const int _kNegativeInfinity = 143;
  static const int _kFirestoreInstance = 144;
  static const int _kFirestoreQuery = 145;
  static const int _kFirestoreSettings = 146;

  static const Map<FieldValueType, int> _kFieldValueCodes =
      <FieldValueType, int>{
    FieldValueType.arrayUnion: _kArrayUnion,
    FieldValueType.arrayRemove: _kArrayRemove,
    FieldValueType.delete: _kDelete,
    FieldValueType.serverTimestamp: _kServerTimestamp,
    FieldValueType.incrementDouble: _kIncrementDouble,
    FieldValueType.incrementInteger: _kIncrementInteger,
  };

  static const Map<FieldPathType, int> _kFieldPathCodes = <FieldPathType, int>{
    FieldPathType.documentId: _kDocumentId,
  };

  @override
  void writeValue(WriteBuffer buffer, dynamic value) {
    if (value is DateTime) {
      buffer.putUint8(_kDateTime);
      buffer.putInt64(value.millisecondsSinceEpoch);
    } else if (value is Timestamp) {
      buffer.putUint8(_kTimestamp);
      buffer.putInt64(value.seconds);
      buffer.putInt32(value.nanoseconds);
    } else if (value is GeoPoint) {
      buffer.putUint8(_kGeoPoint);
      buffer.putFloat64(value.latitude);
      buffer.putFloat64(value.longitude);
    } else if (value is DocumentReferencePlatform) {
      buffer.putUint8(_kDocumentReference);
      writeValue(buffer, value.firestore);
      writeValue(buffer, value.path);
    } else if (value is Blob) {
      buffer.putUint8(_kBlob);
      writeSize(buffer, value.bytes.length);
      buffer.putUint8List(value.bytes);
    } else if (value is FieldValuePlatform) {
      MethodChannelFieldValue delegate = FieldValuePlatform.getDelegate(value);
      final int code = _kFieldValueCodes[delegate.type]!;
      buffer.putUint8(code);
      if (delegate.value != null) writeValue(buffer, delegate.value);
    } else if (value is FieldPathType) {
      final int code = _kFieldPathCodes[value]!;
      buffer.putUint8(code);
    } else if (value is FieldPath) {
      buffer.putUint8(_kFieldPath);
      writeSize(buffer, value.components.length);
      for (final String item in value.components) {
        writeValue(buffer, item);
      }
    } else if (value is MethodChannelFirebaseFirestore) {
      buffer.putUint8(_kFirestoreInstance);
      writeValue(buffer, value.app.name);
      writeValue(buffer, value.settings);
    } else if (value is MethodChannelQuery) {
      buffer.putUint8(_kFirestoreQuery);
      writeValue(buffer, <String, dynamic>{
        'firestore': value.firestore,
        'path': value.path,
        'isCollectionGroup': value.isCollectionGroupQuery,
        'parameters': value.parameters,
      });
    } else if (value is Settings) {
      buffer.putUint8(_kFirestoreSettings);
      writeValue(buffer, value.asMap);
    } else if (value == double.nan) {
      buffer.putUint8(_kNaN);
    } else if (value == double.infinity) {
      buffer.putUint8(_kInfinity);
    } else if (value == double.negativeInfinity) {
      buffer.putUint8(_kNegativeInfinity);
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case _kDateTime:
        return DateTime.fromMillisecondsSinceEpoch(buffer.getInt64());
      case _kTimestamp:
        return Timestamp(buffer.getInt64(), buffer.getInt32());
      case _kGeoPoint:
        return GeoPoint(buffer.getFloat64(), buffer.getFloat64());
      case _kDocumentReference:
        final String appName = readValue(buffer)! as String;
        final String path = readValue(buffer)! as String;
        final FirebaseApp app = Firebase.app(appName);
        final FirebaseFirestorePlatform firestore =
            FirebaseFirestorePlatform.instanceFor(app: app);
        return firestore.doc(path);
      case _kBlob:
        final int length = readSize(buffer);
        final List<int> bytes = buffer.getUint8List(length);
        return Blob(bytes as Uint8List);
      case _kDocumentId:
        return FieldPath.documentId;
      case _kNaN:
        return double.nan;
      case _kInfinity:
        return double.infinity;
      case _kNegativeInfinity:
        return double.negativeInfinity;
      // These cases are only needed on tests, and therefore handled
      // by [TestFirestoreMessageCodec], a subclass of this codec.
      case _kFirestoreInstance:
      case _kFirestoreQuery:
      case _kFirestoreSettings:
      case _kArrayUnion:
      case _kArrayRemove:
      case _kDelete:
      case _kServerTimestamp:
      case _kIncrementDouble:
      case _kIncrementInteger:
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}
