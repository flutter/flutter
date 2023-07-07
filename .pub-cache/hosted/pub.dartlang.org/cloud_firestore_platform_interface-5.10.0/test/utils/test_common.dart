// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_firestore_message_codec.dart';

typedef MethodCallCallback = dynamic Function(MethodCall methodCall);

const kCollectionId = 'foo';
const kDocumentId = 'bar';

const Map<String, dynamic> kMockSnapshotMetadata = <String, dynamic>{
  'hasPendingWrites': false,
  'isFromCache': false,
};

const Map<String, dynamic> kMockDocumentSnapshotData = <String, dynamic>{
  '1': 2
};

int mockHandleId = 0;

int get nextMockHandleId => mockHandleId++;

void initializeMethodChannel() {
  // Install the Codec that is able to decode FieldValues.
  MethodChannelFirebaseFirestore.channel = const MethodChannel(
    'plugins.flutter.io/firebase_firestore',
    StandardMethodCodec(TestFirestoreMessageCodec()),
  );

  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

void handleMethodCall(MethodCallCallback methodCallCallback) =>
    MethodChannelFirebaseFirestore.channel
        .setMockMethodCallHandler((call) async {
      return await methodCallCallback(call);
    });

void handleDocumentSnapshotsEventChannel(
    final String id, List<MethodCall> log) {
  final name = 'plugins.flutter.io/firebase_firestore/document/$id';
  const codec = StandardMethodCodec(TestFirestoreMessageCodec());

  MethodChannel(name, codec)
      .setMockMethodCallHandler((MethodCall methodCall) async {
    log.add(methodCall);
    switch (methodCall.method) {
      case 'listen':
        await ServicesBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          name,
          codec.encodeSuccessEnvelope(
            {
              'path': 'document/1',
              'data': {'name': 'value'},
              'metadata': {},
              'documents': [],
              'documentChanges': []
            },
          ),
          (_) {},
        );
        break;
      case 'cancel':
      default:
        return null;
    }
  });
}

void handleQuerySnapshotsEventChannel(final String id, List<MethodCall> log) {
  final name = 'plugins.flutter.io/firebase_firestore/query/$id';
  const codec = StandardMethodCodec(TestFirestoreMessageCodec());

  MethodChannel(name, codec)
      .setMockMethodCallHandler((MethodCall methodCall) async {
    log.add(methodCall);
    switch (methodCall.method) {
      case 'listen':
        await ServicesBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          name,
          codec.encodeSuccessEnvelope(
            {
              'path': 'document/1',
              'data': {'name': 'value'},
              'metadata': {'hasPendingWrites': false, 'isFromCache': false},
              'documents': [],
              'documentChanges': []
            },
          ),
          (_) {},
        );
        break;
      case 'cancel':
      default:
        return null;
    }
  });
}

void handleSnapshotsInSyncEventChannel(final String id) {
  final name = 'plugins.flutter.io/firebase_firestore/snapshotsInSync/$id';
  const codec = StandardMethodCodec(TestFirestoreMessageCodec());

  MethodChannel(name, codec)
      .setMockMethodCallHandler((MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'listen':
        await ServicesBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
                name, codec.encodeSuccessEnvelope({}), (_) {});
        break;
      case 'cancel':
      default:
        return null;
    }
  });
}

void handleTransactionEventChannel(
  final String id, {
  final FirebaseAppPlatform? app,
  bool? throwException,
}) {
  final name = 'plugins.flutter.io/firebase_firestore/transaction/$id';
  const codec = StandardMethodCodec(TestFirestoreMessageCodec());

  MethodChannel(name, codec)
      .setMockMethodCallHandler((MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'listen':
        await ServicesBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          name,
          codec.encodeSuccessEnvelope({
            'appName': app!.name,
          }),
          (_) {},
        );

        if (throwException!) {
          await ServicesBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(
            name,
            codec.encodeSuccessEnvelope({
              'appName': app.name,
              'error': {
                'code': 'unknown',
              },
            }),
            (_) {},
          );
        }
        await ServicesBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          name,
          codec.encodeSuccessEnvelope({
            'complete': true,
          }),
          (_) {},
        );

        break;
      case 'cancel':
      default:
        return null;
    }
  });
}
