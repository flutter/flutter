// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.storage;

import 'dart:async';
import 'dart:convert';

import 'package:gcloud/storage.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../common.dart';
import '../common_e2e.dart';

const _hostName = 'storage.googleapis.com';
const _rootPath = '/storage/v1/';

MockClient mockClient() => MockClient(_hostName, _rootPath);

void withMockClient(Function(MockClient client, Storage storage) function) {
  var mock = mockClient();
  function(mock, Storage(mock, testProject));
}

Future withMockClientAsync(
    Future Function(MockClient client, Storage storage) function) async {
  var mock = mockClient();
  await function(mock, Storage(mock, testProject));
}

void main() {
  group('bucket', () {
    var bucketName = 'test-bucket';

    test('create', () {
      withMockClient((mock, api) {
        mock.register('POST', 'b', expectAsync1((http.Request request) {
          var requestBucket =
              storage.Bucket.fromJson(jsonDecode(request.body) as Map);
          expect(requestBucket.name, bucketName);
          return mock.respond(storage.Bucket()..name = bucketName);
        }));

        expect(api.createBucket(bucketName), completion(isNull));
      });
    });

    test('create-with-predefined-acl', () {
      var predefined = [
        [PredefinedAcl.authenticatedRead, 'authenticatedRead'],
        [PredefinedAcl.private, 'private'],
        [PredefinedAcl.projectPrivate, 'projectPrivate'],
        [PredefinedAcl.publicRead, 'publicRead'],
        [PredefinedAcl.publicReadWrite, 'publicReadWrite']
      ];

      withMockClient((mock, api) {
        var count = 0;

        mock.register(
            'POST',
            'b',
            expectAsync1((http.Request request) {
              var requestBucket =
                  storage.Bucket.fromJson(jsonDecode(request.body) as Map);
              expect(requestBucket.name, bucketName);
              expect(requestBucket.acl, isNull);
              expect(request.url.queryParameters['predefinedAcl'],
                  predefined[count++][1]);
              return mock.respond(storage.Bucket()..name = bucketName);
            }, count: predefined.length));

        var futures = <Future>[];
        for (var i = 0; i < predefined.length; i++) {
          futures.add(api.createBucket(bucketName,
              predefinedAcl: predefined[i][0] as PredefinedAcl));
        }
        return Future.wait(futures);
      });
    });

    test('create-with-acl', () {
      var acl1 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
      ]);
      var acl2 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
        AclEntry(GroupScope('group@example.com'), AclPermission.WRITE),
      ]);
      var acl3 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
        AclEntry(GroupScope('group@example.com'), AclPermission.WRITE),
        AclEntry(DomainScope('example.com'), AclPermission.READ),
      ]);

      var acls = [acl1, acl2, acl3];

      withMockClient((mock, api) {
        var count = 0;

        mock.register(
            'POST',
            'b',
            expectAsync1((http.Request request) {
              var requestBucket =
                  storage.Bucket.fromJson(jsonDecode(request.body) as Map);
              expect(requestBucket.name, bucketName);
              expect(request.url.queryParameters['predefinedAcl'], isNull);
              expect(requestBucket.acl, isNotNull);
              expect(requestBucket.acl!.length, count + 1);
              expect(requestBucket.acl![0].entity, 'user-user@example.com');
              expect(requestBucket.acl![0].role, 'OWNER');
              if (count > 0) {
                expect(requestBucket.acl![1].entity, 'group-group@example.com');
                expect(requestBucket.acl![1].role, 'WRITER');
              }
              if (count > 2) {
                expect(requestBucket.acl![2].entity, 'domain-example.com');
                expect(requestBucket.acl![2].role, 'READER');
              }
              count++;
              return mock.respond(storage.Bucket()..name = bucketName);
            }, count: acls.length));

        var futures = <Future>[];
        for (var i = 0; i < acls.length; i++) {
          futures.add(api.createBucket(bucketName, acl: acls[i]));
        }
        return Future.wait(futures);
      });
    });

    test('create-with-acl-and-predefined-acl', () {
      var predefined = [
        [PredefinedAcl.authenticatedRead, 'authenticatedRead'],
        [PredefinedAcl.private, 'private'],
        [PredefinedAcl.projectPrivate, 'projectPrivate'],
        [PredefinedAcl.publicRead, 'publicRead'],
        [PredefinedAcl.publicReadWrite, 'publicReadWrite']
      ];

      var acl1 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
      ]);
      var acl2 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
        AclEntry(GroupScope('group@example.com'), AclPermission.WRITE),
      ]);
      var acl3 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
        AclEntry(GroupScope('group@example.com'), AclPermission.WRITE),
        AclEntry(DomainScope('example.com'), AclPermission.READ),
      ]);

      var acls = [acl1, acl2, acl3];

      withMockClient((mock, api) {
        var count = 0;

        mock.register(
            'POST',
            'b',
            expectAsync1((http.Request request) {
              var requestBucket =
                  storage.Bucket.fromJson(jsonDecode(request.body) as Map);
              var predefinedIndex = count ~/ acls.length;
              var aclIndex = count % acls.length;
              expect(requestBucket.name, bucketName);
              expect(request.url.queryParameters['predefinedAcl'],
                  predefined[predefinedIndex][1]);
              expect(requestBucket.acl, isNotNull);
              expect(requestBucket.acl!.length, aclIndex + 1);
              expect(requestBucket.acl![0].entity, 'user-user@example.com');
              expect(requestBucket.acl![0].role, 'OWNER');
              if (aclIndex > 0) {
                expect(requestBucket.acl![1].entity, 'group-group@example.com');
                expect(requestBucket.acl![1].role, 'WRITER');
              }
              if (aclIndex > 2) {
                expect(requestBucket.acl![2].entity, 'domain-example.com');
                expect(requestBucket.acl![2].role, 'READER');
              }
              count++;
              return mock.respond(storage.Bucket()..name = bucketName);
            }, count: predefined.length * acls.length));

        var futures = <Future>[];
        for (var i = 0; i < predefined.length; i++) {
          for (var j = 0; j < acls.length; j++) {
            futures.add(api.createBucket(bucketName,
                predefinedAcl: predefined[i][0] as PredefinedAcl,
                acl: acls[j]));
          }
        }
        return Future.wait(futures);
      });
    });

    test('delete', () {
      withMockClient((mock, api) {
        mock.register('DELETE', RegExp(r'b/[a-z/-]*$'), expectAsync1((request) {
          expect(request.url.path, '${_rootPath}b/$bucketName');
          expect(request.body.length, 0);
          return mock.respond(storage.Bucket()..name = bucketName);
        }));

        expect(api.deleteBucket(bucketName), completion(isNull));
      });
    });

    test('exists', () {
      var exists = true;

      withMockClient((mock, api) {
        mock.register(
            'GET',
            RegExp(r'b/[a-z/-]*$'),
            expectAsync1((request) {
              expect(request.url.path, '${_rootPath}b/$bucketName');
              expect(request.body.length, 0);
              if (exists) {
                return mock.respond(storage.Bucket()..name = bucketName);
              } else {
                return mock.respondError(404);
              }
            }, count: 2));

        return api.bucketExists(bucketName).then(expectAsync1((result) {
          expect(result, isTrue);
          exists = false;
          expect(api.bucketExists(bucketName), completion(isFalse));
        }));
      });
    });

    test('stat', () {
      withMockClient((mock, api) {
        mock.register('GET', RegExp(r'b/[a-z/-]*$'), expectAsync1((request) {
          expect(request.url.path, '${_rootPath}b/$bucketName');
          expect(request.body.length, 0);
          return mock.respond(storage.Bucket()
            ..name = bucketName
            ..timeCreated = DateTime.utc(2014));
        }));

        return api.bucketInfo(bucketName).then(expectAsync1((result) {
          expect(result.bucketName, bucketName);
          expect(result.created, DateTime.utc(2014));
        }));
      });
    });

    group('list', () {
      test('empty', () {
        withMockClient((mock, api) {
          mock.register('GET', 'b', expectAsync1((request) {
            expect(request.body.length, 0);
            return mock.respond(storage.Buckets());
          }));

          api
              .listBucketNames()
              .listen((_) => throw 'Unexpected', onDone: expectAsync0(() {}));
        });
      });

      test('immediate-cancel', () {
        withMockClient((mock, api) {
          api
              .listBucketNames()
              .listen((_) => throw 'Unexpected',
                  onDone: () => throw 'Unexpected')
              .cancel();
        });
      });

      test('list', () {
        // TODO: Test list.
      });

      test('page', () {
        // TODO: Test page.
      });
    });

    test('copy', () {
      withMockClient((mock, api) {
        mock.register(
            'POST', 'b/srcBucket/o/srcObject/copyTo/b/destBucket/o/destObject',
            expectAsync1((request) {
          return mock.respond(storage.Object()..name = 'destObject');
        }));
        expect(
            api.copyObject(
                'gs://srcBucket/srcObject', 'gs://destBucket/destObject'),
            completion(isNull));
      });
    });

    test('copy-invalid-args', () {
      withMockClient((mock, api) {
        expect(() => api.copyObject('a', 'b'), throwsA(isFormatException));
        expect(() => api.copyObject('a/b', 'c/d'), throwsA(isFormatException));
        expect(() => api.copyObject('gs://a/b', 'gs://c/'),
            throwsA(isFormatException));
        expect(() => api.copyObject('gs://a/b', 'gs:///c'),
            throwsA(isFormatException));
      });
    });
  });

  group('object', () {
    var bucketName = 'test-bucket';
    var objectName = 'test-object';

    var bytesNormalUpload = [1, 2, 3];

    // Generate a list just above the limit when changing to resumable upload.
    const mb = 1024 * 1024;
    const maxNormalUpload = 1 * mb;
    const minResumableUpload = maxNormalUpload + 1;
    var bytesResumableUpload =
        List.generate(minResumableUpload, (e) => e & 255);

    final isDetailedApiError = isA<storage.DetailedApiRequestError>();

    void expectNormalUpload(MockClient mock, data, String objectName) {
      var bytes = data.fold([], (p, e) => p..addAll(e));
      mock.registerUpload('POST', 'b/$bucketName/o', expectAsync1((request) {
        return mock
            .processNormalMediaUpload(request)
            .then(expectAsync1((mediaUpload) {
          var object =
              storage.Object.fromJson(jsonDecode(mediaUpload.json) as Map);
          expect(object.name, objectName);
          expect(mediaUpload.bytes, bytes);
          expect(mediaUpload.contentType, 'application/octet-stream');
          return mock.respond(storage.Object()..name = objectName);
        }));
      }));
    }

    void expectResumableUpload(MockClient mock, data, String objectName) {
      var bytes = data.fold([], (p, e) => p..addAll(e));
      expect(bytes.length, bytesResumableUpload.length);
      var count = 0;
      mock.registerResumableUpload('POST', 'b/$bucketName/o',
          expectAsync1((request) {
        var requestObject =
            storage.Object.fromJson(jsonDecode(request.body) as Map);
        expect(requestObject.name, objectName);
        return mock.respondInitiateResumableUpload(testProject);
      }));
      mock.registerResumableUpload(
          'PUT',
          'b/$testProject/o',
          expectAsync1((request) {
            count++;
            if (count == 1) {
              expect(request.bodyBytes.length, mb);
              return mock.respondContinueResumableUpload();
            } else {
              expect(request.bodyBytes.length, 1);
              return mock.respond(storage.Object()..name = objectName);
            }
          }, count: 2));
    }

    void checkResult(result) {
      expect(result.name, objectName);
    }

    Future pipeToSink(StreamSink<List<int>> sink, List<List<int>> data) {
      sink.done.then(expectAsync1(checkResult));
      sink.done.catchError((e) => throw 'Unexpected $e');
      return Stream.fromIterable(data)
          .pipe(sink)
          .then(expectAsync1(checkResult))
          .catchError((e) => throw 'Unexpected $e');
    }

    Future addStreamToSink(StreamSink<List<int>> sink, List<List<int>> data) {
      sink.done.then(expectAsync1(checkResult));
      sink.done.catchError((e) => throw 'Unexpected $e');
      return sink
          .addStream(Stream.fromIterable(data))
          .then((_) => sink.close())
          .then(expectAsync1(checkResult))
          .catchError((e) => throw 'Unexpected $e');
    }

    Future addToSink(StreamSink<List<int>> sink, List<List<int>> data) {
      sink.done.then(expectAsync1(checkResult));
      sink.done.catchError((e) => throw 'Unexpected $e');
      for (var bytes in data) {
        sink.add(bytes);
      }
      return sink
          .close()
          .then(expectAsync1(checkResult))
          .catchError((e) => throw 'Unexpected $e');
    }

    Future runTest(
        MockClient mock, Storage api, List<List<int>> data, int length) {
      var bucket = api.bucket(bucketName);

      Future upload(
          Future Function(StreamSink<List<int>> sink, List<List<int>> data) fn,
          bool sendLength) {
        mock.clear();
        if (length <= maxNormalUpload) {
          expectNormalUpload(mock, data, objectName);
        } else {
          expectResumableUpload(mock, data, objectName);
        }
        StreamSink<List<int>> sink;
        if (sendLength) {
          sink = bucket.write(objectName, length: length);
        } else {
          sink = bucket.write(objectName);
        }
        return fn(sink, data);
      }

      return upload(pipeToSink, true)
          .then(expectAsync1((_) => upload(pipeToSink, false)))
          .then(expectAsync1((_) => upload(addStreamToSink, true)))
          .then(expectAsync1((_) => upload(addStreamToSink, false)))
          .then(expectAsync1((_) => upload(addToSink, true)))
          .then(expectAsync1((_) => upload(addToSink, false)));
    }

    test('write-short-1', () {
      withMockClient((mock, api) {
        runTest(mock, api, [bytesNormalUpload], bytesNormalUpload.length);
      });
    });

    test('write-short-2', () {
      withMockClient((mock, api) {
        runTest(mock, api, [bytesNormalUpload, bytesNormalUpload],
            bytesNormalUpload.length * 2);
      });
    });

    test('write-long', () {
      withMockClient((mock, api) {
        runTest(mock, api, [bytesResumableUpload], bytesResumableUpload.length);
      });
    });

    test('write-short-error', () {
      withMockClient((MockClient mock, api) {
        Future test(int? length) {
          mock.clear();
          mock.registerUpload('POST', 'b/$bucketName/o',
              expectAsync1((request) {
            return mock.respondError(500);
          }));

          var bucket = api.bucket(bucketName);
          var sink = bucket.write(bucketName, length: length);
          expect(sink.done, throwsA(isDetailedApiError));
          return expectLater(
              Stream.fromIterable([bytesNormalUpload]).pipe(sink),
              throwsA(isDetailedApiError));
        }

        test(null) // Unknown length.
            .then(expectAsync1((_) => test(1)))
            .then(expectAsync1((_) => test(10)))
            .then(expectAsync1((_) => test(maxNormalUpload)));
      });
    });

    // TODO: Mock the resumable upload timeout.
    test('write-long-error', () {
      withMockClient((mock, api) {
        Future test(length) {
          mock.clear();
          mock.registerResumableUpload('POST', 'b/$bucketName/o',
              expectAsync1((request) {
            return mock.respondInitiateResumableUpload(testProject);
          }));
          mock.registerResumableUpload(
              'PUT',
              'b/$testProject/o',
              expectAsync1((request) {
                return mock.respondError(502);
              }, count: 3)); // Default 3 retries in googleapis library.

          var bucket = api.bucket(bucketName);
          var sink = bucket.write(bucketName);
          expect(sink.done, throwsA(isDetailedApiError));
          return expectLater(
              Stream.fromIterable([bytesResumableUpload]).pipe(sink),
              throwsA(isDetailedApiError));
        }

        test(null) // Unknown length.
            .then(expectAsync1((_) => test(minResumableUpload)));
      });
    });

    test('write-long-wrong-length', () {
      withMockClient((mock, api) {
        Future test(List<List<int>> data, int length) {
          mock.clear();
          mock.registerResumableUpload('POST', 'b/$bucketName/o',
              expectAsync1((request) {
            return mock.respondInitiateResumableUpload(testProject);
          }));
          mock.registerResumableUpload('PUT', 'b/$testProject/o',
              expectAsync1((request) {
            return mock.respondContinueResumableUpload();
          })); // Default 3 retries in googleapis library.

          var bucket = api.bucket(bucketName);
          var sink = bucket.write(bucketName, length: length);
          expect(sink.done,
              throwsA(anyOf(isA<String>(), isA<storage.ApiRequestError>())));
          return expectLater(Stream<List<int>>.fromIterable(data).pipe(sink),
              throwsA(anyOf(isA<String>(), isA<storage.ApiRequestError>())));
        }

        test([bytesResumableUpload], bytesResumableUpload.length + 1)
            .then(expectAsync1((_) => test([
                  bytesResumableUpload,
                  [1, 2]
                ], bytesResumableUpload.length + 1)));
      });
    });

    test('write-add-error', () {
      withMockClient((mock, api) {
        var bucket = api.bucket(bucketName);
        var sink = bucket.write(bucketName);
        expect(sink.done, throwsArgumentError);
        var stream = Stream.fromIterable([
          [1, 2, 3]
        ]);
        sink.addStream(stream).then((_) {
          sink.addError(ArgumentError());
          expect(sink.close(), throwsArgumentError);
        });
      });
    });

    test('write-long-add-error', () {
      withMockClient((mock, api) {
        mock.registerResumableUpload('POST', 'b/$bucketName/o',
            expectAsync1((request) {
          return mock.respondInitiateResumableUpload(testProject);
        }));
        // The resumable upload will buffer until either close or a full chunk,
        // so when we add an error the last byte is never sent. Therefore this
        // PUT is only called once.
        mock.registerResumableUpload('PUT', 'b/$testProject/o',
            expectAsync1((request) {
          expect(request.bodyBytes.length, 1024 * 1024);
          return mock.respondContinueResumableUpload();
        }));

        var bucket = api.bucket(bucketName);
        var sink = bucket.write(bucketName);
        expect(sink.done, throwsArgumentError);
        var stream = Stream.fromIterable([bytesResumableUpload]);
        sink.addStream(stream).then((_) {
          sink.addError(ArgumentError());
          expect(sink.close(), throwsArgumentError);
        });
      });
    });

    test('write-with-metadata-short', () {
      var metadata = [
        ObjectMetadata(contentType: 'mime/type'),
        ObjectMetadata(contentType: 'type/mime', cacheControl: 'control-cache'),
        ObjectMetadata(cacheControl: 'control-cache'),
        ObjectMetadata(
            cacheControl: 'control-cache', contentDisposition: 'disp-content'),
        ObjectMetadata(
            contentDisposition: 'disp-content',
            contentEncoding: 'encoding',
            contentLanguage: 'language'),
        ObjectMetadata(custom: {'x': 'y'}),
        ObjectMetadata(custom: {'a': 'b', 'x': 'y'})
      ];

      withMockClient((mock, api) {
        var count = 0;
        var bytes = [1, 2, 3];

        mock.registerUpload(
            'POST',
            'b/$bucketName/o',
            expectAsync1((request) {
              return mock
                  .processNormalMediaUpload(request)
                  .then(expectAsync1((mediaUpload) {
                var object = storage.Object.fromJson(
                    jsonDecode(mediaUpload.json) as Map);
                var m = metadata[count];
                expect(object.name, objectName);
                expect(mediaUpload.bytes, bytes);
                var contentType = m.contentType ?? 'application/octet-stream';
                expect(mediaUpload.contentType, contentType);
                expect(object.cacheControl, m.cacheControl);
                expect(object.contentDisposition, m.contentDisposition);
                expect(object.contentEncoding, m.contentEncoding);
                expect(object.contentLanguage, m.contentLanguage);
                expect(object.metadata, m.custom);
                count++;
                return mock.respond(storage.Object()..name = objectName);
              }));
            }, count: metadata.length));

        var bucket = api.bucket(bucketName);
        var futures = <Future>[];
        for (var i = 0; i < metadata.length; i++) {
          futures
              .add(bucket.writeBytes(objectName, bytes, metadata: metadata[i]));
        }
        return Future.wait(futures);
      });
    });

    test('write-with-metadata-long', () {
      var metadata = [
        ObjectMetadata(contentType: 'mime/type'),
        ObjectMetadata(contentType: 'type/mime', cacheControl: 'control-cache'),
        ObjectMetadata(cacheControl: 'control-cache'),
        ObjectMetadata(
            cacheControl: 'control-cache', contentDisposition: 'disp-content'),
        ObjectMetadata(
            contentDisposition: 'disp-content',
            contentEncoding: 'encoding',
            contentLanguage: 'language'),
        ObjectMetadata(custom: {'x': 'y'}),
        ObjectMetadata(custom: {'a': 'b', 'x': 'y'})
      ];

      withMockClient((mock, api) {
        var countInitial = 0;
        var countData = 0;

        mock.registerResumableUpload(
            'POST',
            'b/$bucketName/o',
            expectAsync1((request) {
              var object =
                  storage.Object.fromJson(jsonDecode(request.body) as Map);
              var m = metadata[countInitial];
              expect(object.name, objectName);
              expect(object.cacheControl, m.cacheControl);
              expect(object.contentDisposition, m.contentDisposition);
              expect(object.contentEncoding, m.contentEncoding);
              expect(object.contentLanguage, m.contentLanguage);
              expect(object.metadata, m.custom);
              countInitial++;
              return mock.respondInitiateResumableUpload(testProject);
            }, count: metadata.length));
        mock.registerResumableUpload(
            'PUT',
            'b/$testProject/o',
            expectAsync1((request) {
              var m = metadata[countData % metadata.length];
              var contentType = m.contentType ?? 'application/octet-stream';
              expect(request.headers['content-type'], contentType);
              var firstPart = countData < metadata.length;
              countData++;
              if (firstPart) {
                expect(request.bodyBytes.length, mb);
                return mock.respondContinueResumableUpload();
              } else {
                expect(request.bodyBytes.length, 1);
                return mock.respond(storage.Object()..name = objectName);
              }
            }, count: metadata.length * 2));

        var bucket = api.bucket(bucketName);
        var futures = <Future>[];
        for (var i = 0; i < metadata.length; i++) {
          futures.add(bucket.writeBytes(objectName, bytesResumableUpload,
              metadata: metadata[i]));
        }
        return Future.wait(futures);
      });
    });

    test('write-with-predefined-acl', () {
      var predefined = [
        [PredefinedAcl.authenticatedRead, 'authenticatedRead'],
        [PredefinedAcl.private, 'private'],
        [PredefinedAcl.projectPrivate, 'projectPrivate'],
        [PredefinedAcl.publicRead, 'publicRead'],
        [PredefinedAcl.bucketOwnerFullControl, 'bucketOwnerFullControl'],
        [PredefinedAcl.bucketOwnerRead, 'bucketOwnerRead']
      ];

      withMockClient((mock, api) {
        var count = 0;
        var bytes = [1, 2, 3];

        mock.registerUpload(
            'POST',
            'b/$bucketName/o',
            expectAsync1((request) {
              return mock
                  .processNormalMediaUpload(request)
                  .then(expectAsync1((mediaUpload) {
                var object = storage.Object.fromJson(
                    jsonDecode(mediaUpload.json) as Map);
                expect(object.name, objectName);
                expect(mediaUpload.bytes, bytes);
                expect(mediaUpload.contentType, 'application/octet-stream');
                expect(request.url.queryParameters['predefinedAcl'],
                    predefined[count++][1]);
                expect(object.acl, isNull);
                return mock.respond(storage.Object()..name = objectName);
              }));
            }, count: predefined.length));

        var bucket = api.bucket(bucketName);
        var futures = <Future>[];
        for (var i = 0; i < predefined.length; i++) {
          futures.add(bucket.writeBytes(objectName, bytes,
              predefinedAcl: predefined[i][0] as PredefinedAcl));
        }
        return Future.wait(futures);
      });
    });

    test('write-with-acl', () {
      var acl1 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
      ]);
      var acl2 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
        AclEntry(GroupScope('group@example.com'), AclPermission.WRITE),
      ]);
      var acl3 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
        AclEntry(GroupScope('group@example.com'), AclPermission.WRITE),
        AclEntry(DomainScope('example.com'), AclPermission.READ),
      ]);

      var acls = [acl1, acl2, acl3];

      withMockClient((mock, api) {
        var count = 0;
        var bytes = [1, 2, 3];

        mock.registerUpload(
            'POST',
            'b/$bucketName/o',
            expectAsync1((request) {
              return mock
                  .processNormalMediaUpload(request)
                  .then(expectAsync1((mediaUpload) {
                var object = storage.Object.fromJson(
                    jsonDecode(mediaUpload.json) as Map);
                expect(object.name, objectName);
                expect(mediaUpload.bytes, bytes);
                expect(mediaUpload.contentType, 'application/octet-stream');
                expect(request.url.queryParameters['predefinedAcl'], isNull);
                expect(object.acl, isNotNull);
                expect(object.acl!.length, count + 1);
                expect(object.acl![0].entity, 'user-user@example.com');
                expect(object.acl![0].role, 'OWNER');
                if (count > 0) {
                  expect(object.acl![1].entity, 'group-group@example.com');
                  expect(object.acl![1].role, 'OWNER');
                }
                if (count > 2) {
                  expect(object.acl![2].entity, 'domain-example.com');
                  expect(object.acl![2].role, 'READER');
                }
                count++;
                return mock.respond(storage.Object()..name = objectName);
              }));
            }, count: acls.length));

        var bucket = api.bucket(bucketName);
        var futures = <Future>[];
        for (var i = 0; i < acls.length; i++) {
          futures.add(bucket.writeBytes(objectName, bytes, acl: acls[i]));
        }
        return Future.wait(futures);
      });
    });

    test('write-with-acl-and-predefined-acl', () {
      var predefined = [
        [PredefinedAcl.authenticatedRead, 'authenticatedRead'],
        [PredefinedAcl.private, 'private'],
        [PredefinedAcl.projectPrivate, 'projectPrivate'],
        [PredefinedAcl.publicRead, 'publicRead'],
        [PredefinedAcl.bucketOwnerFullControl, 'bucketOwnerFullControl'],
        [PredefinedAcl.bucketOwnerRead, 'bucketOwnerRead']
      ];

      var acl1 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
      ]);
      var acl2 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
        AclEntry(GroupScope('group@example.com'), AclPermission.WRITE),
      ]);
      var acl3 = Acl([
        AclEntry(AccountScope('user@example.com'), AclPermission.FULL_CONTROL),
        AclEntry(GroupScope('group@example.com'), AclPermission.WRITE),
        AclEntry(DomainScope('example.com'), AclPermission.READ),
      ]);

      var acls = [acl1, acl2, acl3];

      withMockClient((mock, api) {
        var count = 0;
        var bytes = [1, 2, 3];

        mock.registerUpload(
            'POST',
            'b/$bucketName/o',
            expectAsync1((request) {
              return mock
                  .processNormalMediaUpload(request)
                  .then(expectAsync1((mediaUpload) {
                var predefinedIndex = count ~/ acls.length;
                var aclIndex = count % acls.length;
                var object = storage.Object.fromJson(
                    jsonDecode(mediaUpload.json) as Map);
                expect(object.name, objectName);
                expect(mediaUpload.bytes, bytes);
                expect(mediaUpload.contentType, 'application/octet-stream');
                expect(request.url.queryParameters['predefinedAcl'],
                    predefined[predefinedIndex][1]);
                expect(object.acl, isNotNull);
                expect(object.acl!.length, aclIndex + 1);
                expect(object.acl![0].entity, 'user-user@example.com');
                expect(object.acl![0].role, 'OWNER');
                if (aclIndex > 0) {
                  expect(object.acl![1].entity, 'group-group@example.com');
                  expect(object.acl![1].role, 'OWNER');
                }
                if (aclIndex > 2) {
                  expect(object.acl![2].entity, 'domain-example.com');
                  expect(object.acl![2].role, 'READER');
                }
                count++;
                return mock.respond(storage.Object()..name = objectName);
              }));
            }, count: predefined.length * acls.length));

        var bucket = api.bucket(bucketName);
        var futures = <Future>[];
        for (var i = 0; i < predefined.length; i++) {
          for (var j = 0; j < acls.length; j++) {
            futures.add(bucket.writeBytes(objectName, bytes,
                acl: acls[j],
                predefinedAcl: predefined[i][0] as PredefinedAcl));
          }
        }
        return Future.wait(futures);
      });
    });

    group('read', () {
      test('success', () async {
        await withMockClientAsync((MockClient mock, Storage api) async {
          mock.register('GET', 'b/$bucketName/o/$objectName',
              expectAsync1(mock.respondBytes));

          var bucket = api.bucket(bucketName);
          var data = [];

          await bucket.read(objectName).forEach(data.addAll);
          expect(data, MockClient.bytes);
        });
      });

      test('with offset, without length', () async {
        await withMockClientAsync((MockClient mock, Storage api) async {
          var bucket = api.bucket(bucketName);

          try {
            await bucket.read(objectName, offset: 1).toList();
            fail('An exception should be thrown');
          } on ArgumentError catch (e) {
            expect(
                e.message, 'length must have a value if offset is non-zero.');
          }
        });
      });

      test('with offset and length zero', () async {
        await withMockClientAsync((MockClient mock, Storage api) async {
          var bucket = api.bucket(bucketName);

          try {
            await bucket.read(objectName, offset: 1, length: 0).toList();
            fail('An exception should be thrown');
          } on ArgumentError catch (e) {
            expect(e.message, 'If provided, length must greater than zero.');
          }
        });
      });

      test('with invalid length', () async {
        await withMockClientAsync((MockClient mock, Storage api) async {
          var bucket = api.bucket(bucketName);

          try {
            await bucket.read(objectName, length: -1).toList();
            fail('An exception should be thrown');
          } on ArgumentError catch (e) {
            expect(e.message, 'If provided, length must greater than zero.');
          }
        });
      });

      test('with length', () async {
        await withMockClientAsync((MockClient mock, Storage api) async {
          mock.register('GET', 'b/$bucketName/o/$objectName',
              expectAsync1(mock.respondBytes));

          var bucket = api.bucket(bucketName);
          var data = [];

          await bucket.read(objectName, length: 4).forEach(data.addAll);
          expect(data, MockClient.bytes.sublist(0, 4));
        });
      });

      test('with offset and length', () async {
        await withMockClientAsync((MockClient mock, Storage api) async {
          mock.register('GET', 'b/$bucketName/o/$objectName',
              expectAsync1(mock.respondBytes));

          var bucket = api.bucket(bucketName);
          var data = [];

          await bucket
              .read(objectName, offset: 1, length: 3)
              .forEach(data.addAll);
          expect(data, MockClient.bytes.sublist(1, 4));
        });
      });

      test('file does not exist', () async {
        await withMockClientAsync((MockClient mock, Storage api) async {
          mock.register('GET', 'b/$bucketName/o/$objectName',
              expectAsync1((request) {
            expect(request.url.queryParameters['alt'], 'media');
            return mock.respondError(404);
          }));

          var bucket = api.bucket(bucketName);

          try {
            await bucket.read(objectName).toList();
            fail('An exception should be thrown');
          } on storage.DetailedApiRequestError catch (e) {
            expect(e.status, 404);
          }
        });
      });
    });

    test('stat', () {
      withMockClient((mock, api) {
        mock.register('GET', 'b/$bucketName/o/$objectName',
            expectAsync1((request) {
          expect(request.url.queryParameters['alt'], 'json');
          return mock.respond(storage.Object()
            ..name = objectName
            ..updated = DateTime.utc(2014)
            ..contentType = 'mime/type');
        }));

        var api = Storage(mock, testProject);
        var bucket = api.bucket(bucketName);
        bucket.info(objectName).then(expectAsync1((stat) {
          expect(stat.name, objectName);
          expect(stat.updated, DateTime.utc(2014));
          expect(stat.metadata.contentType, 'mime/type');
        }));
      });
    });

    test('stat-acl', () {
      withMockClient((mock, api) {
        mock.register('GET', 'b/$bucketName/o/$objectName',
            expectAsync1((request) {
          expect(request.url.queryParameters['alt'], 'json');
          var acl1 = storage.ObjectAccessControl();
          acl1.entity = 'user-1234567890';
          acl1.role = 'OWNER';
          var acl2 = storage.ObjectAccessControl();
          acl2.entity = 'user-xxx@yyy.zzz';
          acl2.role = 'OWNER';
          var acl3 = storage.ObjectAccessControl();
          acl3.entity = 'xxx-1234567890';
          acl3.role = 'OWNER';
          return mock.respond(storage.Object()
            ..name = objectName
            ..acl = [acl1, acl2, acl3]);
        }));

        var api = Storage(mock, testProject);
        var bucket = api.bucket(bucketName);
        bucket.info(objectName).then(expectAsync1((ObjectInfo info) {
          expect(info.name, objectName);
          expect(info.metadata.acl!.entries.length, 3);
          expect(info.metadata.acl!.entries[0].scope is StorageIdScope, isTrue);
          expect(info.metadata.acl!.entries[1].scope is AccountScope, isTrue);
          expect(info.metadata.acl!.entries[2].scope is OpaqueScope, isTrue);
        }));
      });
    });

    group('list', () {
      test('empty', () {
        withMockClient((mock, api) {
          mock.register('GET', 'b/$bucketName/o', expectAsync1((request) {
            expect(request.body.length, 0);
            return mock.respond(storage.Objects());
          }));

          var bucket = api.bucket(bucketName);
          bucket
              .list()
              .listen((_) => throw 'Unexpected', onDone: expectAsync0(() {}));
        });
      });

      test('immediate-cancel', () {
        withMockClient((mock, api) {
          var bucket = api.bucket(bucketName);
          bucket
              .list()
              .listen((_) => throw 'Unexpected',
                  onDone: () => throw 'Unexpected')
              .cancel();
        });
      });

      test('list', () {
        // TODO: Test list.
      });

      test('page', () {
        // TODO: Test page.
      });
    });
  });

  group('acl', () {
    var id = StorageIdScope('1234567890');
    var user = AccountScope('sgjesse@google.com');
    var group = GroupScope('dart');
    var domain = DomainScope('dartlang.org');

    var userRead = AclEntry(user, AclPermission.READ);
    var groupWrite = AclEntry(group, AclPermission.WRITE);
    var domainFullControl = AclEntry(domain, AclPermission.FULL_CONTROL);

    test('compare-scope', () {
      expect(id, StorageIdScope('1234567890'));
      expect(user, AccountScope('sgjesse@google.com'));
      expect(group, GroupScope('dart'));
      expect(domain, DomainScope('dartlang.org'));
      expect(AclScope.allAuthenticated, AllAuthenticatedScope());
      expect(AclScope.allUsers, AllUsersScope());
    });

    test('compare-entries', () {
      expect(userRead, AclEntry(user, AclPermission.READ));
      expect(groupWrite, AclEntry(group, AclPermission.WRITE));
      expect(domainFullControl, AclEntry(domain, AclPermission.FULL_CONTROL));
    });

    test('compare-acls', () {
      var acl = Acl([userRead, groupWrite, domainFullControl]);
      expect(
          acl,
          Acl([
            AclEntry(user, AclPermission.READ),
            AclEntry(group, AclPermission.WRITE),
            AclEntry(domain, AclPermission.FULL_CONTROL)
          ]));
      expect(
          acl,
          isNot(equals(Acl([
            AclEntry(group, AclPermission.WRITE),
            AclEntry(user, AclPermission.READ),
            AclEntry(domain, AclPermission.FULL_CONTROL)
          ]))));
    });

    test('compare-predefined-acls', () {
      expect(PredefinedAcl.private, PredefinedAcl.private);
      expect(PredefinedAcl.private, isNot(equals(PredefinedAcl.publicRead)));
    });
  });
}
