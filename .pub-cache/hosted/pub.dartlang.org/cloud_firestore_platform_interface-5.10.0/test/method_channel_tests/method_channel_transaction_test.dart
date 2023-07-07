// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_transaction.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_field_value_factory.dart';

import '../utils/test_common.dart';

const String mockId = 'mock-id';
const String mockPath = 'foo/bar';

//ignore: avoid_implementing_value_types
class MockDocumentReference extends Mock implements DocumentReferencePlatform {
  @override
  String get path => super.noSuchMethod(Invocation.getter(#path),
      returnValue: mockPath, returnValueForMissingStub: mockPath);
  @override
  String get id => super.noSuchMethod(Invocation.getter(#id),
      returnValue: mockId, returnValueForMissingStub: mockId);
}

const _kTransactionId = '1022';
const Map<String, dynamic> kMockSnapshotMetadata = <String, dynamic>{
  'hasPendingWrites': false,
  'isFromCache': false,
};
void main() {
  initializeMethodChannel();

  final FieldValuePlatform mockFieldValue =
      FieldValuePlatform(MethodChannelFieldValueFactory().increment(2.0));

  bool isMethodCalled = false;

  group('$MethodChannelTransaction', () {
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
      handleMethodCall((call) {
        switch (call.method) {
          case 'Transaction#get':
            isMethodCalled = true;
            return <String, dynamic>{
              'path': 'foo/bar',
              'data': <String, dynamic>{'key1': 'val1'},
              'metadata': kMockSnapshotMetadata,
            };
          default:
            return null;
        }
      });
    });
    TransactionPlatform? transaction;
    final mockDocumentReference = MockDocumentReference();
    when(mockDocumentReference.path).thenReturn('$kCollectionId/$kDocumentId');
    when(mockDocumentReference.id).thenReturn(kDocumentId);
    setUp(() {
      transaction = MethodChannelTransaction(
          _kTransactionId, FirebaseFirestorePlatform.instance.app.name);
      isMethodCalled = false;
    });

    group('commands', () {
      test('returns with equal checks', () async {
        await transaction!.get(mockDocumentReference.path);
        transaction!.set(mockDocumentReference.path, {'foo': 'bar'});
        expect(transaction!.commands.length, equals(1));
      });
    });

    group('get()', () {
      test('should throw if get is called after a command', () async {
        transaction!.set(mockDocumentReference.path, {'foo': 'bar'});
        expect(transaction!.commands.length, 1);
        expect(() => transaction!.get(mockDocumentReference.path),
            throwsAssertionError);
      });

      test('returns a [DocumentSnapshotPlatform] ', () async {
        DocumentSnapshotPlatform result =
            await transaction!.get(mockDocumentReference.path);
        expect(isMethodCalled, isTrue,
            reason: 'Transaction.get was not called');
        expect(result, isInstanceOf<DocumentSnapshotPlatform>());
        expect(result.data(), equals(<String, dynamic>{'key1': 'val1'}));
      });
    });

    test('delete()', () {
      transaction!.delete(mockDocumentReference.path);

      expect(transaction!.commands.length, 1);

      Map<String, dynamic> command = transaction!.commands[0];
      expect(command['type'], 'DELETE');
      expect(command['path'], 'foo/bar');
      expect(command['data'], equals(null));
    });

    test('update()', () {
      final Map<String, dynamic> data = {
        'test': 'test',
        'fieldValue': mockFieldValue
      };
      transaction!.update(mockDocumentReference.path, data);

      expect(transaction!.commands.length, 1);

      Map<String, dynamic> command = transaction!.commands[0];
      expect(command['type'], 'UPDATE');
      expect(command['path'], 'foo/bar');
      expect(command['data'], equals(data));
    });

    test('set()', () {
      final Map<String, dynamic> data = {
        'test': 'test',
        'fieldValue': mockFieldValue
      };
      final SetOptions options = SetOptions(merge: true);

      transaction!.set(mockDocumentReference.path, data, options);
      expect(transaction!.commands.length, 1);

      Map<String, dynamic> command = transaction!.commands[0];
      expect(command['type'], 'SET');
      expect(command['path'], 'foo/bar');
      expect(command['data'], equals(data));
      expect(command['options'], equals({'merge': true, 'mergeFields': null}));
    });
  });
}
