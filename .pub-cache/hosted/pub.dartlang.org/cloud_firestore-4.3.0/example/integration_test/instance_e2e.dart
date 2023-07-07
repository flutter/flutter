// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runInstanceTests() {
  group(
    '$FirebaseFirestore.instance',
    () {
      late FirebaseFirestore /*?*/ firestore;

      setUpAll(() async {
        firestore = FirebaseFirestore.instance;
      });

      test(
        'snapshotsInSync()',
        () async {
          DocumentReference<Map<String, dynamic>> documentReference =
              firestore.doc('flutter-tests/insync');

          // Ensure deleted
          await documentReference.delete();

          StreamController controller = StreamController();
          StreamSubscription insync;
          StreamSubscription snapshots;

          int inSyncCount = 0;

          insync = firestore.snapshotsInSync().listen((_) {
            controller.add('insync=$inSyncCount');
            inSyncCount++;
          });

          snapshots = documentReference.snapshots().listen((ds) {
            controller.add('snapshot-exists=${ds.exists}');
          });

          // Allow the snapshots to trigger...
          await Future.delayed(const Duration(seconds: 1));

          await documentReference.set({'foo': 'bar'});

          await expectLater(
            controller.stream,
            emitsInOrder([
              'insync=0', // No other snapshots
              'snapshot-exists=false',
              'insync=1',
              'snapshot-exists=true',
              'insync=2',
            ]),
          );

          await controller.close();
          await insync.cancel();
          await snapshots.cancel();
        },
        skip: kIsWeb,
      );

      test(
        'enableNetwork()',
        () async {
          // Write some data while online
          await firestore.enableNetwork();
          DocumentReference<Map<String, dynamic>> documentReference =
              firestore.doc('flutter-tests/enable-network');
          await documentReference.set({'foo': 'bar'});

          // Disable the network
          await firestore.disableNetwork();

          StreamController controller = StreamController();

          // Set some data while offline
          // ignore: unawaited_futures
          documentReference.set({'foo': 'baz'}).then((_) async {
            // Only when back online will this trigger
            controller.add(true);
          });

          // Go back online
          await firestore.enableNetwork();

          await expectLater(controller.stream, emits(true));
          await controller.close();
        },
        skip: kIsWeb,
      );

      test(
        'disableNetwork()',
        () async {
          // Write some data while online
          await firestore.enableNetwork();
          DocumentReference<Map<String, dynamic>> documentReference =
              firestore.doc('flutter-tests/disable-network');
          await documentReference.set({'foo': 'bar'});

          // Disable the network
          await firestore.disableNetwork();

          // Get data from cache
          DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
              await documentReference.get();
          expect(documentSnapshot.metadata.isFromCache, isTrue);
          expect(documentSnapshot.data()!['foo'], equals('bar'));

          // Go back online once test complete
          await firestore.enableNetwork();
        },
        skip: kIsWeb,
      );

      test(
        'waitForPendingWrites()',
        () async {
          await firestore.waitForPendingWrites();
        },
        skip: kIsWeb,
      );

      test(
        'terminate() / clearPersistence()',
        () async {
          // Since the firestore instance has already been used,
          // calling `clearPersistence` will throw a native error.
          // We first check it does throw as expected, then terminate
          // the instance, and then check whether clearing succeeds.
          try {
            await firestore.clearPersistence();
            fail('Should have thrown');
          } on FirebaseException catch (e) {
            expect(e.code, equals('failed-precondition'));
          } catch (e) {
            fail('$e');
          }

          await firestore.terminate();
          await firestore.clearPersistence();
        },
        skip: kIsWeb,
      );

      test('setIndexConfiguration()', () async {
        Index index1 = Index(
          collectionGroup: 'bar',
          queryScope: QueryScope.collectionGroup,
          fields: [
            IndexField(
              fieldPath: 'fieldPath',
              order: Order.ascending,
              arrayConfig: ArrayConfig.contains,
            )
          ],
        );

        Index index2 = Index(
          collectionGroup: 'baz',
          queryScope: QueryScope.collection,
          fields: [
            IndexField(
              fieldPath: 'foo',
              arrayConfig: ArrayConfig.contains,
            ),
            IndexField(
              fieldPath: 'bar',
              order: Order.descending,
              arrayConfig: ArrayConfig.contains,
            ),
            IndexField(
              fieldPath: 'baz',
              order: Order.descending,
              arrayConfig: ArrayConfig.contains,
            ),
          ],
        );

        FieldOverrides fieldOverride1 = FieldOverrides(
          fieldPath: 'fieldPath',
          indexes: [
            FieldOverrideIndex(
              queryScope: 'foo',
              order: Order.ascending,
              arrayConfig: ArrayConfig.contains,
            ),
            FieldOverrideIndex(
              queryScope: 'bar',
              order: Order.descending,
              arrayConfig: ArrayConfig.contains,
            ),
            FieldOverrideIndex(
              queryScope: 'baz',
              order: Order.descending,
            ),
          ],
          collectionGroup: 'bar',
        );
        FieldOverrides fieldOverride2 = FieldOverrides(
          fieldPath: 'anotherField',
          indexes: [
            FieldOverrideIndex(
              queryScope: 'foo',
              order: Order.ascending,
              arrayConfig: ArrayConfig.contains,
            ),
            FieldOverrideIndex(
              queryScope: 'bar',
              order: Order.descending,
              arrayConfig: ArrayConfig.contains,
            ),
            FieldOverrideIndex(
              queryScope: 'baz',
              order: Order.descending,
            ),
          ],
          collectionGroup: 'collectiongroup',
        );

        await firestore.setIndexConfiguration(
          indexes: [index1, index2],
          fieldOverrides: [fieldOverride1, fieldOverride2],
        );
      });

      test('setIndexConfigurationFromJSON()', () async {
        final json = jsonEncode({
          'indexes': [
            {
              'collectionGroup': 'posts',
              'queryScope': 'COLLECTION',
              'fields': [
                {'fieldPath': 'author', 'arrayConfig': 'CONTAINS'},
                {'fieldPath': 'timestamp', 'order': 'DESCENDING'}
              ]
            }
          ],
          'fieldOverrides': [
            {
              'collectionGroup': 'posts',
              'fieldPath': 'myBigMapField',
              'indexes': []
            }
          ]
        });

        await firestore.setIndexConfigurationFromJSON(json);
      });
    },
  );
}
