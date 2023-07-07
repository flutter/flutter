// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_query.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/utils/firestore_message_codec.dart';

/// This codec is able to decode FieldValues.
/// This ability is only required in tests, hence why
/// those values are only decoded in tests.
class TestFirestoreMessageCodec extends FirestoreMessageCodec {
  /// Constructor.
  const TestFirestoreMessageCodec();
  static const int _kDocumentReference = 130;
  static const int _kArrayUnion = 132;
  static const int _kArrayRemove = 133;
  static const int _kDelete = 134;
  static const int _kServerTimestamp = 135;
  static const int _kFirestoreInstance = 144;
  static const int _kFirestoreQuery = 145;
  static const int _kFirestoreSettings = 146;

  static const int _kIncrementDouble = 137;
  static const int _kIncrementInteger = 138;

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      // The following cases are only used by unit tests, and not by actual application
      // code paths.
      case _kArrayUnion:
        final List<dynamic> value = readValue(buffer)! as List<dynamic>;
        return FieldValuePlatform(
          FieldValueFactoryPlatform.instance.arrayUnion(value),
        );
      case _kArrayRemove:
        final List<dynamic> value = readValue(buffer)! as List<dynamic>;
        return FieldValuePlatform(
          FieldValueFactoryPlatform.instance.arrayRemove(value),
        );
      case _kDelete:
        return FieldValuePlatform(FieldValueFactoryPlatform.instance.delete());
      case _kServerTimestamp:
        return FieldValuePlatform(
          FieldValueFactoryPlatform.instance.serverTimestamp(),
        );
      case _kIncrementDouble:
        final double value = readValue(buffer)! as double;
        return FieldValuePlatform(
          FieldValueFactoryPlatform.instance.increment(value),
        );
      case _kIncrementInteger:
        final int value = readValue(buffer)! as int;
        return FieldValuePlatform(
          FieldValueFactoryPlatform.instance.increment(value),
        );
      case _kFirestoreInstance:
        String appName = readValue(buffer)! as String;
        readValue(buffer);
        final FirebaseApp app = Firebase.app(appName);
        return MethodChannelFirebaseFirestore(app: app);
      case _kFirestoreQuery:
        String appName = readValue(buffer)! as String;
        Map<dynamic, dynamic> values =
            readValue(buffer)! as Map<dynamic, dynamic>;
        final FirebaseApp app = Firebase.app(appName);
        return MethodChannelQuery(
          MethodChannelFirebaseFirestore(app: app),
          values['path'],
        );
      case _kFirestoreSettings:
        readValue(buffer);
        return const Settings();
      case _kDocumentReference:
        MethodChannelFirebaseFirestore firestore =
            readValue(buffer)! as MethodChannelFirebaseFirestore;
        String path = readValue(buffer)! as String;
        return firestore.doc(path);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}
