// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Tags(['e2e'])

library gcloud.storage;

import 'dart:async';

import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage_api;
import 'package:test/test.dart';

import '../common_e2e.dart';

String generateBucketName() {
  var id = DateTime.now().millisecondsSinceEpoch;
  return 'dart-e2e-test-$id';
}

bool testDetailedApiError(e) => e is storage_api.DetailedApiRequestError;

// Generate a list just above the limit when changing to resumable upload.
const int mb = 1024 * 1024;
const int maxNormalUpload = 1 * mb;
const int minResumableUpload = maxNormalUpload + 1;
final bytesResumableUpload =
    List<int>.generate(minResumableUpload, (e) => e & 255);

void main() {
  var didSetUp = false;
  late Storage storage;
  late String testBucketName;
  late Bucket testBucket;

  setUpAll(() {
    return withAuthClient(Storage.SCOPES, (String project, httpClient) {
      testBucketName = generateBucketName();

      // Share the same storage connection for all tests.
      storage = Storage(httpClient, project);

      // Create a shared bucket for all object tests.
      return storage.createBucket(testBucketName).then((_) {
        testBucket = storage.bucket(testBucketName);
        didSetUp = true;
      });
    });
  });

  tearDownAll(() async {
    // Don't cleanup if setup failed
    if (!didSetUp) {
      return;
    }
    // Deleting a bucket relies on eventually consistent behaviour, hence
    // the delay in attempt to prevent test flakiness.
    await Future.delayed(storageListDelay);
    await storage.deleteBucket(testBucketName);
  });

  group('bucket', () {
    test('create-info-delete', () {
      var bucketName = generateBucketName();
      return storage.createBucket(bucketName).then(expectAsync1((result) {
        expect(result, isNull);
        return storage.bucketInfo(bucketName).then(expectAsync1((info) {
          expect(info.bucketName, bucketName);
          expect(info.etag, isNotNull);
          expect(info.id, isNotNull);
          return storage.deleteBucket(bucketName).then(expectAsync1((result) {
            expect(result, isNull);
          }));
        }));
      }));
    });

    test('create-with-predefined-acl-delete', () async {
      final cases = <PredefinedAcl, int>{
        // See documentation:
        // https://cloud.google.com/storage/docs/access-control/lists
        PredefinedAcl.authenticatedRead: 2,
        PredefinedAcl.private: 1,
        PredefinedAcl.projectPrivate: 3,
        PredefinedAcl.publicRead: 2,
        PredefinedAcl.publicReadWrite: 2,
      };
      for (var e in cases.entries) {
        var predefinedAcl = e.key;
        var expectedLength = e.value;
        var bucketName = generateBucketName();
        // Sleep for 2 seconds to avoid bucket request limit, see:
        // https://cloud.google.com/storage/quotas#buckets
        await Future.delayed(Duration(seconds: 2));
        var r1 = await storage.createBucket(bucketName,
            predefinedAcl: predefinedAcl);
        expect(r1, isNull);
        var info = await storage.bucketInfo(bucketName);
        expect(info.bucketName, bucketName);
        expect(info.acl.entries.length, expectedLength);
        var r2 = await storage.deleteBucket(bucketName);
        expect(r2, isNull);
      }
    }, skip: 'unable to test with uniform buckets enforced for account');

    test('create-error', () {
      storage.createBucket('goog-reserved').catchError(expectAsync1((e) {
        expect(e, isNotNull);
      }), test: testDetailedApiError);
    });
  });

  group('object', () {
    // Run all object tests in the same bucket to try to avoid the rate-limit
    // for creating and deleting buckets while testing.
    Future withTestBucket(Future Function(Bucket bucket) function) {
      return function(testBucket).whenComplete(() {
        // TODO: Clean the bucket.
      });
    }

    test('create-read-delete', () {
      Future test(name, List<int> bytes) {
        return withTestBucket((Bucket bucket) {
          return bucket.writeBytes('test', bytes).then(expectAsync1((info) {
            expect(info, isNotNull);
            return bucket.read('test').fold<List<int>>(
                [], (p, e) => p..addAll(e)).then(expectAsync1((result) {
              expect(result, bytes);
              return bucket.delete('test').then(expectAsync1((result) {
                expect(result, isNull);
              }));
            }));
          }));
        });
      }

      return Future.forEach([
        () => test('test-1', [1, 2, 3]),
        () => test('test-2', bytesResumableUpload)
      ], (Function f) => f().then(expectAsync1((_) {})));
    });

    test('create-with-predefined-acl-delete', () {
      return withTestBucket((Bucket bucket) {
        Future test(
            String objectName, PredefinedAcl predefinedAcl, expectedLength) {
          return bucket
              .writeBytes(objectName, [1, 2, 3], predefinedAcl: predefinedAcl)
              .then(expectAsync1((result) {
            expect(result, isNotNull);
            return bucket.info(objectName).then(expectAsync1((info) {
              var acl = info.metadata.acl;
              expect(info.name, objectName);
              expect(info.etag, isNotNull);
              expect(acl!.entries.length, expectedLength);
              return bucket.delete(objectName).then(expectAsync1((result) {
                expect(result, isNull);
              }));
            }));
          }));
        }

        return Future.forEach([
          () => test('test-1', PredefinedAcl.authenticatedRead, 2),
          () => test('test-2', PredefinedAcl.private, 1),
          () => test('test-3', PredefinedAcl.projectPrivate, 4),
          () => test('test-4', PredefinedAcl.publicRead, 2),
          () => test('test-5', PredefinedAcl.bucketOwnerFullControl, 2),
          () => test('test-6', PredefinedAcl.bucketOwnerRead, 2)
        ], (Function f) => f().then(expectAsync1((_) {})));
      });
    }, skip: 'unable to test with uniform buckets enforced for account');

    test('create-with-acl-delete', () {
      return withTestBucket((Bucket bucket) {
        Future test(String objectName, Acl acl, expectedLength) {
          return bucket
              .writeBytes(objectName, [1, 2, 3], acl: acl)
              .then(expectAsync1((result) {
            expect(result, isNotNull);
            return bucket.info(objectName).then(expectAsync1((info) {
              var acl = info.metadata.acl;
              expect(info.name, objectName);
              expect(info.etag, isNotNull);
              expect(acl!.entries.length, expectedLength);
              return bucket.delete(objectName).then(expectAsync1((result) {
                expect(result, isNull);
              }));
            }));
          }));
        }

        var acl1 =
            Acl([AclEntry(AclScope.allAuthenticated, AclPermission.WRITE)]);
        var acl2 = Acl([
          AclEntry(AclScope.allUsers, AclPermission.WRITE),
          AclEntry(AccountScope('sgjesse@google.com'), AclPermission.WRITE)
        ]);
        var acl3 = Acl([
          AclEntry(AclScope.allUsers, AclPermission.WRITE),
          AclEntry(AccountScope('sgjesse@google.com'), AclPermission.WRITE),
          AclEntry(GroupScope('misc@dartlang.org'), AclPermission.READ)
        ]);
        var acl4 = Acl([
          AclEntry(AclScope.allUsers, AclPermission.WRITE),
          AclEntry(AccountScope('sgjesse@google.com'), AclPermission.WRITE),
          AclEntry(GroupScope('misc@dartlang.org'), AclPermission.READ),
          AclEntry(DomainScope('dartlang.org'), AclPermission.FULL_CONTROL)
        ]);

        // The expected length of the returned ACL is one longer than the one
        // use during creation as an additional 'used-ID' ACL entry is added
        // by cloud storage during creation.
        return Future.forEach([
          () => test('test-1', acl1, acl1.entries.length + 1),
          () => test('test-2', acl2, acl2.entries.length + 1),
          () => test('test-3', acl3, acl3.entries.length + 1),
          () => test('test-4', acl4, acl4.entries.length + 1)
        ], (Function f) => f().then(expectAsync1((_) {})));
      });
    }, skip: 'unable to test with uniform buckets enforced for account');

    test('create-with-metadata-delete', () {
      return withTestBucket((Bucket bucket) {
        Future test(
            String objectName, ObjectMetadata metadata, List<int> bytes) {
          return bucket
              .writeBytes(objectName, bytes, metadata: metadata)
              .then(expectAsync1((result) {
            expect(result, isNotNull);
            return bucket.info(objectName).then(expectAsync1((info) {
              expect(info.name, objectName);
              expect(info.length, bytes.length);
              expect(info.md5Hash, isNotNull);
              expect(info.crc32CChecksum, isNotNull);
              expect(info.generation.objectGeneration, isNotNull);
              expect(info.generation.metaGeneration, 1);
              expect(info.metadata.contentType, metadata.contentType);
              expect(info.metadata.cacheControl, metadata.cacheControl);
              expect(info.metadata.contentDisposition,
                  metadata.contentDisposition);
              expect(info.metadata.contentEncoding, metadata.contentEncoding);
              expect(info.metadata.contentLanguage, metadata.contentLanguage);
              expect(info.metadata.custom, metadata.custom);
              return bucket.delete(objectName).then(expectAsync1((result) {
                expect(result, isNull);
              }));
            }));
          }));
        }

        var metadata1 = ObjectMetadata(contentType: 'text/plain');
        var metadata2 = ObjectMetadata(
            contentType: 'text/plain',
            cacheControl: 'no-cache',
            contentDisposition: 'attachment; filename="test.txt"',
            contentEncoding: 'gzip',
            contentLanguage: 'da',
            custom: {'a': 'b', 'c': 'd'});

        return Future.forEach([
          () => test('test-1', metadata1, [65, 66, 67]),
          () => test('test-2', metadata2, [65, 66, 67]),
          () => test('test-3', metadata1, bytesResumableUpload),
          () => test('test-4', metadata2, bytesResumableUpload)
        ], (Function f) => f().then(expectAsync1((_) {})));
      });
    });
  });
}
