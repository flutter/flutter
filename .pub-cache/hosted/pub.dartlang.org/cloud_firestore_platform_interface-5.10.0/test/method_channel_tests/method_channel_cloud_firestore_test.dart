// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'dart:async';

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

void main() {
  initializeMethodChannel();
  MethodChannelFirebaseFirestore? firestore;
  FirebaseApp? secondaryApp;
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;
  String mockTransactionId = 'TRANSACTION1';
  String mockSnapshotInSyncId = 'ID1';
  final List<MethodCall> log = <MethodCall>[];

  setUpAll(() async {
    secondaryApp = await Firebase.initializeApp(
      name: 'testApp',
      options: const FirebaseOptions(
        appId: '1:1234567890:ios:42424242424242',
        apiKey: '123',
        projectId: '123',
        messagingSenderId: '1234567890',
      ),
    );
    await Firebase.initializeApp(
      name: 'testApp2',
      options: const FirebaseOptions(
        appId: '1:1234567890:ios:42424242424242',
        apiKey: '123',
        projectId: '123',
        messagingSenderId: '1234567890',
      ),
    );

    firestore = MethodChannelFirebaseFirestore();

    handleMethodCall((MethodCall call) {
      log.add(call);
      switch (call.method) {
        case 'Transaction#create':
          return Future.value(mockTransactionId);

        case 'SnapshotsInSync#setup':
          handleSnapshotsInSyncEventChannel(mockSnapshotInSyncId);
          return Future.value(mockSnapshotInSyncId);
        case 'Firestore#waitForPendingWrites':
        case 'Firestore#terminate':
        case 'Firestore#settings':
        case 'Firestore#enableNetwork':
        case 'Firestore#disableNetwork':
        case 'Firestore#clearPersistence':
          if (mockExceptionThrown) {
            throw Exception();
          } else if (mockPlatformExceptionThrown) {
            throw PlatformException(code: 'UNKNOWN');
          }
          return Future.delayed(Duration.zero);
        default:
          return Future.value();
      }
    });
  });

  setUp(() {
    mockPlatformExceptionThrown = false;
    mockExceptionThrown = false;
    log.clear();
  });

  group('$MethodChannelFirebaseFirestore', () {
    group('constructor', () {
      test('should create an instance with no args', () {
        MethodChannelFirebaseFirestore test = MethodChannelFirebaseFirestore();
        expect(test.app, equals(Firebase.app()));
      });

      test('create an instance with default app', () {
        MethodChannelFirebaseFirestore test =
            MethodChannelFirebaseFirestore(app: Firebase.app());
        expect(test.app, equals(Firebase.app()));
      });
      test('create an instance with a secondary app', () {
        MethodChannelFirebaseFirestore test =
            MethodChannelFirebaseFirestore(app: secondaryApp);
        expect(test.app, equals(secondaryApp));
      });

      test('allow multiple instances', () {
        MethodChannelFirebaseFirestore test1 = MethodChannelFirebaseFirestore();
        MethodChannelFirebaseFirestore test2 =
            MethodChannelFirebaseFirestore(app: secondaryApp);
        expect(test1.app, equals(Firebase.app()));
        expect(test2.app, equals(secondaryApp));
      });
    });

    group('delegateFor()', () {
      test('returns a [FirestorePlatform] with arguments', () {
        expect(firestore!.delegateFor(app: secondaryApp!),
            FirebaseFirestorePlatform.instanceFor(app: secondaryApp!));
      });
    });

    test('batch()', () {
      expect(firestore!.batch(), isInstanceOf<WriteBatchPlatform>());
    });

    group('clearPersistence()', () {
      test('invoke Firestore#clearPersistence with correct args', () {
        expect(firestore!.clearPersistence(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#clearPersistence',
              arguments: <String, dynamic>{
                'firestore': firestore,
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;
        expect(() => firestore!.clearPersistence(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    test('collection()', () {
      final collection = firestore!.collection('foo/bar');

      expect(collection, isInstanceOf<CollectionReferencePlatform>());
      expect(collection.path, equals('foo/bar'));
      expect(collection.firestore, equals(firestore));
    });

    test('collectionGroup()', () {
      final collectionGroup = firestore!.collectionGroup('foo/bar');

      expect(collectionGroup, isInstanceOf<QueryPlatform>());
      expect(collectionGroup.isCollectionGroupQuery, isTrue);
      expect(collectionGroup.firestore, equals(firestore));
    });

    group('disableNetwork()', () {
      test('invoke Firestore#disableNetwork with correct args', () {
        expect(firestore!.disableNetwork(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#disableNetwork',
              arguments: <String, dynamic>{
                'firestore': firestore,
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore!.disableNetwork(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    test('doc()', () {
      final doc = firestore!.doc('foo/bar');

      expect(doc, isInstanceOf<DocumentReferencePlatform>());
      expect(doc.path, equals('foo/bar'));
      expect(doc.firestore, equals(firestore));
    });

    group('enableNetwork()', () {
      test('invoke Firestore#enableNetwork with correct args', () {
        expect(firestore!.enableNetwork(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#enableNetwork',
              arguments: <String, dynamic>{
                'firestore': firestore,
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore!.enableNetwork(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    group('snapshotsInSync()', () {
      test('returns a [Stream]', () {
        final stream = firestore!.snapshotsInSync();

        expect(stream, isInstanceOf<Stream<void>>());
      });

      test('onListen and onCancel invokes native methods with correct args',
          () async {
        final Stream<void> stream = firestore!.snapshotsInSync();
        final Completer<void> receivedSync = Completer<void>();

        final StreamSubscription<void> subscription = stream.listen((event) {
          receivedSync.complete();
        });

        await receivedSync.future;
        await subscription.cancel();
        await Future<void>.delayed(Duration.zero);

        expect(
          log,
          equals(<Matcher>[
            isMethodCall('SnapshotsInSync#setup', arguments: null),
          ]),
        );
      });
    });

    group('runTransaction()', () {
      TransactionHandler transactionHandler = (transaction) {
        return Future.value({});
      };

      group('common', () {
        setUp(() {
          handleTransactionEventChannel(
            mockTransactionId,
            app: FirebaseAppPlatform(
                Firebase.app().name, Firebase.app().options),
            throwException: false,
          );
        });

        test('throws [AssertionError] for timeout more than 0 ms', () {
          expect(
              firestore!
                  .runTransaction(transactionHandler, timeout: Duration.zero),
              throwsAssertionError);
        });

        test('sets timeout to a default value', () async {
          final transactionFuture =
              firestore!.runTransaction(transactionHandler);
          expect(transactionFuture, isInstanceOf<Future>());
        });
      });

      group('successful', () {
        setUp(() {
          handleTransactionEventChannel(
            mockTransactionId,
            app: FirebaseAppPlatform(
                Firebase.app().name, Firebase.app().options),
            throwException: false,
          );
        });

        test('returns result of a successful transaction', () async {
          await firestore!.runTransaction((TransactionPlatform tx) async {},
              timeout: const Duration(seconds: 3));

          expect(log, <Matcher>[
            isMethodCall('Transaction#create', arguments: null),
            isMethodCall('Transaction#storeResult',
                arguments: <String, dynamic>{
                  'transactionId': 'TRANSACTION1',
                  'result': {
                    'type': 'SUCCESS',
                    'commands': <String>[],
                  }
                }),
          ]);
        });
      });

      group('errors', () {
        setUp(() {
          handleTransactionEventChannel(
            mockTransactionId,
            app: FirebaseAppPlatform(
                Firebase.app().name, Firebase.app().options),
            throwException: true,
          );
        });

        test(
            'catches exceptions thrown by handler and throws [FirebaseException]',
            () async {
          mockPlatformExceptionThrown = true;
          try {
            await firestore!.runTransaction(transactionHandler);
            fail('Should have thrown exception');
          } on FirebaseException catch (_) {
            return;
          } catch (_) {
            fail('Transaction threw invalid exeption');
          }
        });
      });
    });

    group('settings', () {
      Settings settings = const Settings();

      test('stores the settings on the Firestore instance', () {
        firestore!.settings = settings;
        expect(firestore!.settings, settings);
      });
    });

    group('terminate()', () {
      test('invoke Firestore#terminate with correct args', () {
        expect(firestore!.terminate(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#terminate',
              arguments: <String, dynamic>{
                'firestore': firestore,
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore!.terminate(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });

    group('waitForPendingWrites()', () {
      test('invoke Firestore#waitForPendingWrites with correct args', () {
        expect(firestore!.waitForPendingWrites(), isInstanceOf<Future<void>>());

        expect(
          log,
          equals(<Matcher>[
            isMethodCall(
              'Firestore#waitForPendingWrites',
              arguments: <String, dynamic>{
                'firestore': firestore,
              },
            ),
          ]),
        );
      });

      test('catch [PlatformException] error', () {
        mockPlatformExceptionThrown = true;

        expect(() => firestore!.waitForPendingWrites(),
            throwsA(isInstanceOf<FirebaseException>()));
      });
    });
  });
}
