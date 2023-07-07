// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart'
    as core_interop;
import 'package:js/js.dart';
import 'package:js/js_util.dart' as util;

import '../firestore.dart';

/// Returns Dart representation from JS Object.
dynamic dartify(Object? jsObject) {
  return core_interop.dartify(jsObject, (Object? object) {
    if (object == null) {
      return null;
    }
    if (util.instanceof(object, DocumentReferenceJsConstructor)) {
      return DocumentReference.getInstance(object as DocumentReferenceJsImpl);
    }
    if (util.instanceof(object, GeoPointConstructor)) {
      return object;
    }
    if (util.instanceof(object, TimestampJsConstructor)) {
      return Timestamp((object as TimestampJsImpl).seconds, object.nanoseconds);
    }
    if (util.instanceof(object, BytesConstructor)) {
      return object as BytesJsImpl;
    }
    return null;
  });
}

/// Returns the JS implementation from Dart Object.
dynamic jsify(Object? dartObject) {
  if (dartObject == null) {
    return null;
  }

  return core_interop.jsify(dartObject, (Object? object) {
    if (object is DateTime) {
      return TimestampJsImpl.fromMillis(object.millisecondsSinceEpoch);
    }

    if (object is Timestamp) {
      return TimestampJsImpl.fromMillis(object.millisecondsSinceEpoch);
    }

    if (object is DocumentReference) {
      return object.jsObject;
    }

    if (object is FieldValue) {
      return jsifyFieldValue(object);
    }

    if (object is BytesJsImpl) {
      return object;
    }

    // NOTE: if the firestore JS lib is not imported, we'll get a DDC warning here
    if (object is GeoPointJsImpl) {
      return dartObject;
    }

    if (object is Function) {
      return allowInterop(object);
    }

    return null;
  });
}
