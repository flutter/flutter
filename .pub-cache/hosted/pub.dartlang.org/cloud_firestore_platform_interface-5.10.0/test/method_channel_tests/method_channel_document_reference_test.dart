// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_document_reference.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_field_value_factory.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

void main() {
  initializeMethodChannel();

  group('$MethodChannelDocumentReference()', () {
    MethodChannelDocumentReference? _documentReference;
    FieldValuePlatform? mockFieldValue;

    setUpAll(() async {
      await Firebase.initializeApp(
        name: 'testApp',
        options: const FirebaseOptions(
          appId: '1:1234567890:ios:42424242424242',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '1234567890',
        ),
      );

      _documentReference = MethodChannelDocumentReference(
          FirebaseFirestorePlatform.instance, '$kCollectionId/$kDocumentId');
      mockFieldValue =
          FieldValuePlatform(MethodChannelFieldValueFactory().increment(2.0));
    });

    test('set', () async {
      _assertSetDataMethodCalled(_documentReference, null, null);
      _assertSetDataMethodCalled(_documentReference, true, null);
      _assertSetDataMethodCalled(_documentReference, false, null);
      _assertSetDataMethodCalled(_documentReference, false, mockFieldValue);
    });

    test('update', () async {
      bool isMethodCalled = false;
      final Map<String, dynamic> data = {
        'test': 'test',
        'fieldValue': mockFieldValue
      };
      handleMethodCall((call) {
        if (call.method == 'DocumentReference#update') {
          isMethodCalled = true;
          expect(call.arguments['data']['test'], equals(data['test']));
        }
      });
      await _documentReference!.update(data);
      expect(isMethodCalled, isTrue,
          reason: 'DocumentReference.update was not called');
    });

    test('get', () async {
      _assertGetMethodCalled(_documentReference, null, 'default');
      _assertGetMethodCalled(_documentReference, Source.cache, 'cache');
      _assertGetMethodCalled(_documentReference, Source.server, 'server');
      _assertGetMethodCalled(
          _documentReference, Source.serverAndCache, 'default');
    });

    test('delete', () async {
      bool isMethodCalled = false;
      handleMethodCall((call) {
        if (call.method == 'DocumentReference#delete') {
          isMethodCalled = true;
        }
      });
      await _documentReference!.delete();
      expect(isMethodCalled, isTrue,
          reason: 'DocumentReference.delete was not called');
    });

    group('snapshots', () {
      final List<MethodCall> log = <MethodCall>[];

      const String mockObserverId = 'DOCUMENT1';

      setUp(() {
        log.clear();

        handleMethodCall((MethodCall call) async {
          log.add(call);
          if (call.method == 'DocumentReference#snapshots') {
            handleDocumentSnapshotsEventChannel(mockObserverId, log);
            return Future.value(mockObserverId);
          }
        });
      });

      test('onListen and onCancel invokes native methods with correct args',
          () async {
        final Stream<DocumentSnapshotPlatform> stream =
            _documentReference!.snapshots();
        final StreamSubscription<DocumentSnapshotPlatform> subscription =
            stream.listen((DocumentSnapshotPlatform snapshot) {});

        await subscription.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(log[0].method, 'DocumentReference#snapshots');
        expect(log[1].method, 'listen');
        expect(log[1].arguments, <String, dynamic>{
          'reference': isInstanceOf<MethodChannelDocumentReference>(),
          'includeMetadataChanges': false,
        });
        //TODO(russellwheatley): NNBD failure. 'cancel' method not being recorded
        // expect(log[2].method, 'cancel');
      });
    });
  });
}

//ignore:avoid_void_async
void _assertGetMethodCalled(DocumentReferencePlatform? documentReference,
    Source? source, String expectedSourceString) async {
  bool isMethodCalled = false;
  handleMethodCall((call) {
    if (call.method == 'DocumentReference#get') {
      isMethodCalled = true;
      expect(call.arguments['source'], equals(expectedSourceString));
    }
    return {
      'path': 'test/test',
      'data': {},
      'metadata': {'hasPendingWrites': false, 'isFromCache': false}
    };
  });
  if (source != null) {
    await documentReference!.get(GetOptions(source: source));
  } else {
    await documentReference!.get();
  }
  expect(isMethodCalled, isTrue,
      reason: 'DocumentReference.get was not called');
}

//ignore:avoid_void_async
void _assertSetDataMethodCalled(DocumentReferencePlatform? documentReference,
    bool? expectedMergeValue, FieldValuePlatform? fieldValue) async {
  bool isMethodCalled = false;
  final Map<String, dynamic> data = {'test': 'test'};
  if (fieldValue != null) {
    data.addAll({'fieldValue': fieldValue});
  }
  handleMethodCall((call) {
    if (call.method == 'DocumentReference#set') {
      isMethodCalled = true;
      expect(call.arguments['data']['test'], equals(data['test']));
      expect(call.arguments['options']['merge'], expectedMergeValue);
    }
  });
  if (expectedMergeValue == null) {
    await documentReference!.set(data);
  } else {
    await documentReference!.set(data, SetOptions(merge: expectedMergeValue));
  }
  expect(isMethodCalled, isTrue,
      reason: 'DocumentReference.set was not called');
}
