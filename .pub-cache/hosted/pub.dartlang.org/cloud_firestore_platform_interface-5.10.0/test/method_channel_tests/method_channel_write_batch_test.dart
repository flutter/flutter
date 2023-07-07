// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_write_batch.dart';

import 'package:firebase_core/firebase_core.dart';

import '../utils/test_common.dart';

void main() {
  initializeMethodChannel();
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;
  MethodChannelFirebaseFirestore? firestore;

  final List<MethodCall> log = <MethodCall>[];

  setUpAll(() async {
    firestore = MethodChannelFirebaseFirestore();
    await Firebase.initializeApp();

    handleMethodCall((MethodCall call) {
      log.add(call);
      switch (call.method) {
        case 'WriteBatch#commit':
          if (mockExceptionThrown) {
            throw Exception();
          } else if (mockPlatformExceptionThrown) {
            throw PlatformException(code: 'UNKNOWN');
          }

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
  setUp(() {
    mockPlatformExceptionThrown = false;
    mockExceptionThrown = false;
    log.clear();
  });

  group('$MethodChannelWriteBatch', () {
    group('commit()', () {
      test('throw [StateError] if batch has already been commited', () async {
        final MethodChannelWriteBatch batch =
            firestore!.batch() as MethodChannelWriteBatch;
        await batch.commit();

        try {
          await batch.commit();
        } on StateError catch (e) {
          expect(
              e.message,
              equals(
                  'This batch has already been committed and can no longer be changed.'));
          return;
        }

        fail('Should have thrown a [StateError]');
      });

      test('return before invoking method call if writes is empty', () {
        final MethodChannelWriteBatch batch =
            firestore!.batch() as MethodChannelWriteBatch;
        batch.commit();
        expect(log.length, 0);
      });

      test('invokes native method WriteBatch#commit', () async {
        final MethodChannelWriteBatch batch =
            firestore!.batch() as MethodChannelWriteBatch;
        batch.set('foo/bar', {});
        await batch.commit();
        expect(log.length, 1);
        expect(
          log,
          <Matcher>[
            isMethodCall('WriteBatch#commit', arguments: <String, dynamic>{
              'firestore': firestore,
              'writes': [
                {
                  'path': 'foo/bar',
                  'type': 'SET',
                  'data': {},
                  'options': <String, bool?>{
                    'merge': null,
                    'mergeFields': null
                  },
                }
              ]
            }),
          ],
        );
      });

      test(
          'catches [PlatformException] from WriteBatch#commit and throws a [FirebaseException]',
          () async {
        final MethodChannelWriteBatch batch =
            firestore!.batch() as MethodChannelWriteBatch;
        batch.set('foo/bar', {});
        mockPlatformExceptionThrown = true;

        try {
          await batch.commit();
        } on FirebaseException catch (_) {
          return;
        } catch (_) {
          fail('WriteBatch threw invalid exeption');
        }
        fail('WriteBatch should have thrown an exception');
      });

      test('catches and throws a [Exception] from WriteBatch#commit', () async {
        final MethodChannelWriteBatch batch =
            firestore!.batch() as MethodChannelWriteBatch;
        mockExceptionThrown = true;
        batch.set('foo/bar', {});

        try {
          await batch.commit();
        } on Exception catch (_) {
          return;
        } catch (_) {
          fail('WriteBatch threw invalid exeption');
        }
        fail('WriteBatch should have thrown an exception');
      });
    });

    group('set()', () {
      test('invokes native method WriteBatch#commit with no merge ', () async {
        final MethodChannelWriteBatch batch =
            firestore!.batch() as MethodChannelWriteBatch;
        batch.set(
          'foo/bar',
          <String, String>{'bazKey': 'quxValue'},
        );
        await batch.commit();
        expect(
          log,
          <Matcher>[
            isMethodCall('WriteBatch#commit', arguments: <String, dynamic>{
              'firestore': firestore,
              'writes': [
                {
                  'path': 'foo/bar',
                  'type': 'SET',
                  'data': <String, String>{'bazKey': 'quxValue'},
                  'options': <String, bool?>{
                    'merge': null,
                    'mergeFields': null
                  },
                }
              ]
            }),
          ],
        );
      });

      test('invokes native method WriteBatch#commit with merge ', () async {
        final MethodChannelWriteBatch batch =
            firestore!.batch() as MethodChannelWriteBatch;
        batch.set('foo/bar', <String, String>{'bazKey': 'quxValue'},
            SetOptions(merge: true));
        await batch.commit();
        expect(
          log,
          <Matcher>[
            isMethodCall('WriteBatch#commit', arguments: <String, dynamic>{
              'firestore': firestore,
              'writes': [
                {
                  'path': 'foo/bar',
                  'type': 'SET',
                  'data': <String, String>{'bazKey': 'quxValue'},
                  'options': <String, bool?>{
                    'merge': true,
                    'mergeFields': null
                  },
                }
              ]
            }),
          ],
        );
      });
    });

    test('update', () async {
      final MethodChannelWriteBatch batch =
          firestore!.batch() as MethodChannelWriteBatch;
      batch.update(
        'foo/bar',
        <String, String>{'bazKey': 'quxValue'},
      );
      await batch.commit();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'WriteBatch#commit',
            arguments: <String, dynamic>{
              'firestore': firestore,
              'writes': [
                <String, dynamic>{
                  'path': 'foo/bar',
                  'type': 'UPDATE',
                  'data': <String, String>{'bazKey': 'quxValue'}
                }
              ]
            },
          ),
        ],
      );
    });

    test('delete', () async {
      final MethodChannelWriteBatch batch =
          firestore!.batch() as MethodChannelWriteBatch;
      batch.delete('foo/bar');
      await batch.commit();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'WriteBatch#commit',
            arguments: <String, dynamic>{
              'firestore': firestore,
              'writes': [
                <String, dynamic>{'path': 'foo/bar', 'type': 'DELETE'}
              ]
            },
          ),
        ],
      );
    });
  });
}
