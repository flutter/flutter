// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart'
    show FirebaseFirestoreWeb;
import 'package:cloud_firestore_web/src/interop/firestore.dart';
import 'package:js/js_util.dart' as util;

import '../interop/firestore.dart' as firestore_interop;

/// Class containing static utility methods to decode firestore data.
class DecodeUtility {
  /// Decodes the values on an incoming Map to their proper types.
  static Map<String, dynamic>? decodeMapData(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    return data..updateAll((key, value) => valueDecode(value));
  }

  /// Decodes the values on an incoming Array to their proper types.
  static List<dynamic>? decodeArrayData(List<dynamic>? data) {
    if (data == null) {
      return null;
    }
    return data.map(valueDecode).toList();
  }

  /// Decodes an incoming value to its proper type.
  static dynamic valueDecode(dynamic value) {
    if (util.instanceof(value, GeoPointConstructor)) {
      return GeoPoint(value.latitude as double, value.longitude as double);
    } else if (value is DateTime) {
      return Timestamp.fromDate(value);
    } else if (util.instanceof(value, BytesConstructor)) {
      return Blob(value.toUint8Array());
    } else if (value is firestore_interop.DocumentReference) {
      return (FirebaseFirestorePlatform.instance as FirebaseFirestoreWeb)
          .doc(value.path);
    } else if (value is Map<String, dynamic>) {
      return decodeMapData(value);
    } else if (value is List<dynamic>) {
      return decodeArrayData(value);
    }
    return value;
  }
}
