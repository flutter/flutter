// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_query.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/utils/firestore_message_codec.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import './mock.dart';

int kCount = 4;

void main() {
  setupCloudFirestoreMocks();
  MethodChannelFirebaseFirestore.channel = const MethodChannel(
    'plugins.flutter.io/firebase_firestore',
    StandardMethodCodec(AggregateQueryMessageCodec()),
  );

  MethodChannelFirebaseFirestore.channel.setMockMethodCallHandler((call) async {
    if (call.method == 'AggregateQuery#count') {
      return {
        'count': kCount,
      };
    }

    return null;
  });

  FirebaseFirestore? firestore;

  group('$AggregateQuery', () {
    setUpAll(() async {
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
    });

    test('returns the correct `AggregateQuerySnapshot` with correct `count`',
        () async {
      Query query = firestore!.collection('flutter-tests');
      AggregateQuery aggregateQuery = query.count();

      expect(query, aggregateQuery.query);
      AggregateQuerySnapshot snapshot = await aggregateQuery.get();

      expect(snapshot.count, equals(kCount));
    });
  });
}

class AggregateQueryMessageCodec extends FirestoreMessageCodec {
  /// Constructor.
  const AggregateQueryMessageCodec();
  static const int _kFirestoreInstance = 144;
  static const int _kFirestoreQuery = 145;
  static const int _kFirestoreSettings = 146;

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      // The following cases are only used by unit tests, and not by actual application
      // code paths.
      case _kFirestoreInstance:
        String appName = readValue(buffer)! as String;
        readValue(buffer);
        final FirebaseApp app = Firebase.app(appName);
        return MethodChannelFirebaseFirestore(app: app);
      case _kFirestoreQuery:
        Map<dynamic, dynamic> values =
            readValue(buffer)! as Map<dynamic, dynamic>;
        final FirebaseApp app = Firebase.app();
        return MethodChannelQuery(
          MethodChannelFirebaseFirestore(app: app),
          values['path'],
        );
      case _kFirestoreSettings:
        readValue(buffer);
        return const Settings();
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}
