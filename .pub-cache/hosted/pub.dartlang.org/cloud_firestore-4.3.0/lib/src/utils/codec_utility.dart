// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

class _CodecUtility {
  static Map<String, dynamic>? replaceValueWithDelegatesInMap(
    Map<dynamic, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }
    Map<String, dynamic> output = Map.from(data);
    output.updateAll((_, value) => valueEncode(value));
    return output;
  }

  static List<dynamic>? replaceValueWithDelegatesInArray(List<dynamic>? data) {
    if (data == null) {
      return null;
    }
    return List.from(data).map(valueEncode).toList();
  }

  static Map<String, dynamic>? replaceDelegatesWithValueInMap(
    Map<dynamic, dynamic>? data,
    FirebaseFirestore firestore,
  ) {
    if (data == null) {
      return null;
    }
    Map<String, dynamic> output = Map.from(data);
    output.updateAll((_, value) => valueDecode(value, firestore));
    return output;
  }

  static List<dynamic>? replaceDelegatesWithValueInArray(
    List<dynamic>? data,
    FirebaseFirestore firestore,
  ) {
    if (data == null) {
      return null;
    }
    return List.from(data)
        .map((value) => valueDecode(value, firestore))
        .toList();
  }

  static dynamic valueEncode(dynamic value) {
    if (value is DocumentReference) {
      return value._delegate;
    } else if (value is List) {
      return replaceValueWithDelegatesInArray(value);
    } else if (value is Map<dynamic, dynamic>) {
      return replaceValueWithDelegatesInMap(value);
    }
    return value;
  }

  static dynamic valueDecode(dynamic value, FirebaseFirestore firestore) {
    if (value is DocumentReferencePlatform) {
      return _JsonDocumentReference(firestore, value);
    } else if (value is List) {
      return replaceDelegatesWithValueInArray(value, firestore);
    } else if (value is Map<dynamic, dynamic>) {
      return replaceDelegatesWithValueInMap(value, firestore);
    }
    return value;
  }
}
