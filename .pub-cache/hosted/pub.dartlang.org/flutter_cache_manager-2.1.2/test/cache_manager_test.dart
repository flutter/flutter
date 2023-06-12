import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_managers/image_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/config/config.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_cache_manager/src/web/web_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'helpers/config_extensions.dart';
import 'helpers/mock_file_fetcher_response.dart';
import 'helpers/test_configuration.dart';

void main() {
  group('Tests for getSingleFile', () {
    test('Valid cacheFile should not call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var validTill = DateTime.now().add(const Duration(days: 1));

      var config = createTestConfig();
      await config.returnsFile(fileName);
      config.returnsCacheObject(fileUrl, fileName, validTill);

      var cacheManager = TestCacheManager(config);
      var result = await cacheManager.getSingleFile(fileUrl);
      expect(result, isNotNull);
      config.verifyNoDownloadCall();
    });

    test('Outdated cacheFile should call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var validTill = DateTime.now().subtract(const Duration(days: 1));

      var config = createTestConfig();
      await config.returnsFile(fileName);
      config.returnsCacheObject(fileUrl, fileName, validTill);

      var cacheManager = TestCacheManager(config);

      var result = await cacheManager.getSingleFile(fileUrl);
      expect(result, isNotNull);
      await config.waitForDownload();
      config.verifyDownloadCall();
    });

    test('Non-existing cacheFile should call to web', () async {
      var fileUrl = 'baseflow.com/test';

      var config = createTestConfig();
      config.returnsNoCacheObject(fileUrl);

      var cacheManager = TestCacheManager(config);

      var result = await cacheManager.getSingleFile(fileUrl);
      expect(result, isNotNull);
      config.verifyDownloadCall();
    });
  });

  group('Explicit key', () {
    test('Valid cacheFile should not call to web', () async {
      var config = createTestConfig();

      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var fileKey = 'test1234';
      var validTill = DateTime.now().add(const Duration(days: 1));

      await config.returnsFile(fileName);
      config.returnsCacheObject(fileUrl, fileName, validTill, key: fileKey);
      var cacheManager = TestCacheManager(config);

      var result = await cacheManager.getSingleFile(fileUrl, key: fileKey);
      expect(result, isNotNull);
      config.verifyNoDownloadCall();
    });

    test('Outdated cacheFile should call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var fileKey = 'test1234';
      var validTill = DateTime.now().subtract(const Duration(days: 1));

      var config = createTestConfig();
      config.returnsCacheObject(fileUrl, fileName, validTill, key: fileKey);
      await config.returnsFile(fileName);

      var cacheManager = TestCacheManager(config);

      var result = await cacheManager.getSingleFile(fileUrl, key: fileKey);
      await config.waitForDownload();
      expect(result, isNotNull);
      config.verifyDownloadCall();
    });

    test('Non-existing cacheFile should call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var fileKey = 'test1234';
      var validTill = DateTime.now().subtract(const Duration(days: 1));

      var config = createTestConfig();
      config.returnsCacheObject(fileUrl, fileName, validTill, key: fileKey);

      var cacheManager = TestCacheManager(config);

      var result = await cacheManager.getSingleFile(fileUrl, key: fileKey);
      expect(result, isNotNull);
      config.verifyDownloadCall();
    });
  });

  group('Tests for getFile', () {
    test('Valid cacheFile should not call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var validTill = DateTime.now().add(const Duration(days: 1));

      var config = createTestConfig();
      config.returnsCacheObject(fileUrl, fileName, validTill);
      await config.returnsFile(fileName);

      var store = MockStore();
      var file = await createTestConfig().fileSystem.createFile(fileName);
      var fileInfo = FileInfo(file, FileSource.Cache, validTill, fileUrl);
      when(store.getFile(fileUrl)).thenAnswer((_) => Future.value(fileInfo));

      var cacheManager = TestCacheManager(config, store: store);

      // ignore: deprecated_member_use_from_same_package
      var fileStream = cacheManager.getFile(fileUrl);
      expect(fileStream, emits(fileInfo));
      config.verifyNoDownloadCall();
    });

    test('Outdated cacheFile should call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var validTill = DateTime.now().subtract(const Duration(days: 1));

      var store = MockStore();
      var file = await createTestConfig().fileSystem.createFile(fileName);
      var cachedInfo = FileInfo(file, FileSource.Cache, validTill, fileUrl);
      when(store.getFile(fileUrl)).thenAnswer((_) => Future.value(cachedInfo));

      var webHelper = MockWebHelper();
      var downloadedInfo = FileInfo(file, FileSource.Online,
          DateTime.now().add(const Duration(days: 1)), fileUrl);
      when(webHelper.downloadFile(fileUrl, key: anyNamed('key')))
          .thenAnswer((_) => Stream.value(downloadedInfo));

      var cacheManager = TestCacheManager(createTestConfig(),
          store: store, webHelper: webHelper);

      // ignore: deprecated_member_use_from_same_package
      var fileStream = cacheManager.getFile(fileUrl);
      await expectLater(fileStream, emitsInOrder([cachedInfo, downloadedInfo]));

      verify(webHelper.downloadFile(any, key: anyNamed('key'))).called(1);
    });

    test('Non-existing cacheFile should call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var validTill = DateTime.now().subtract(const Duration(days: 1));

      var store = MockStore();
      var file = await createTestConfig().fileSystem.createFile(fileName);
      var fileInfo = FileInfo(file, FileSource.Cache, validTill, fileUrl);

      when(store.getFile(fileUrl)).thenAnswer((_) => Future.value(null));

      var webHelper = MockWebHelper();
      when(webHelper.downloadFile(fileUrl, key: anyNamed('key')))
          .thenAnswer((_) => Stream.value(fileInfo));

      var cacheManager = TestCacheManager(
        createTestConfig(),
        store: store,
        webHelper: webHelper,
      );

      // ignore: deprecated_member_use_from_same_package
      var fileStream = cacheManager.getFile(fileUrl);
      await expectLater(fileStream, emitsInOrder([fileInfo]));
      verify(webHelper.downloadFile(any, key: anyNamed('key'))).called(1);
    });

    test('Errors should be passed to the stream', () async {
      var fileUrl = 'baseflow.com/test';

      var store = MockStore();
      when(store.getFile(fileUrl)).thenAnswer((_) => Future.value(null));

      var webHelper = MockWebHelper();
      var error = HttpExceptionWithStatus(404, 'Invalid statusCode: 404',
          uri: Uri.parse(fileUrl));
      when(webHelper.downloadFile(fileUrl, key: anyNamed('key')))
          .thenThrow(error);

      var cacheManager = TestCacheManager(
        createTestConfig(),
        store: store,
        webHelper: webHelper,
      );

      // ignore: deprecated_member_use_from_same_package
      var fileStream = cacheManager.getFile(fileUrl);
      await expectLater(fileStream, emitsError(error));
      verify(webHelper.downloadFile(any, key: anyNamed('key'))).called(1);
    });
  });
  group('explicit key', () {
    test('Valid cacheFile should not call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var fileKey = 'test1234';
      var validTill = DateTime.now().add(const Duration(days: 1));

      var config = createTestConfig();
      config.returnsCacheObject(fileUrl, fileName, validTill, key: fileKey);
      await config.returnsFile(fileName);

      var cacheManager = TestCacheManager(config);

      // ignore: deprecated_member_use_from_same_package
      await cacheManager.getFile(fileUrl, key: fileKey).toList();
      config.verifyNoDownloadCall();
    });

    test('Outdated cacheFile should call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var fileKey = 'test1234';
      var validTill = DateTime.now().subtract(const Duration(days: 1));

      var config = createTestConfig();
      config.returnsCacheObject(fileUrl, fileName, validTill, key: fileKey);
      await config.returnsFile(fileName);

      var cacheManager = TestCacheManager(config);
      // ignore: deprecated_member_use_from_same_package
      await cacheManager.getFile(fileUrl, key: fileKey).toList();

      config.verifyDownloadCall(1);
    });

    test('Non-existing cacheFile should call to web', () async {
      var fileName = 'test.jpg';
      var fileUrl = 'baseflow.com/test';
      var fileKey = 'test1234';
      var validTill = DateTime.now().subtract(const Duration(days: 1));

      var config = createTestConfig();
      config.returnsCacheObject(fileUrl, fileName, validTill, key: fileKey);
      await config.returnsFile(fileName);

      var cacheManager = TestCacheManager(config);

      // ignore: deprecated_member_use_from_same_package
      await cacheManager.getFile(fileUrl, key: fileKey).toList();
      config.verifyDownloadCall(1);
    });
  });

  group('Testing putting files in cache', () {
    test('Check if file is written and info is stored', () async {
      var fileUrl = 'baseflow.com/test';
      var fileBytes = Uint8List(16);
      var extension = 'jpg';

      var store = MockStore();
      var cacheManager = TestCacheManager(createTestConfig(), store: store);

      var file = await cacheManager.putFile(fileUrl, fileBytes,
          fileExtension: extension);
      expect(await file.exists(), true);
      expect(await file.readAsBytes(), fileBytes);
      verify(store.putFile(any)).called(1);
    });

    test('Check if file is written and info is stored, explicit key', () async {
      var fileUrl = 'baseflow.com/test';
      var fileBytes = Uint8List(16);
      var fileKey = 'test1234';
      var extension = 'jpg';

      var store = MockStore();
      var cacheManager = TestCacheManager(createTestConfig(), store: store);

      var file = await cacheManager.putFile(fileUrl, fileBytes,
          key: fileKey, fileExtension: extension);
      expect(await file.exists(), true);
      expect(await file.readAsBytes(), fileBytes);
      final arg =
          verify(store.putFile(captureAny)).captured.first as CacheObject;
      expect(arg.key, fileKey);
      expect(arg.url, fileUrl);
    });

    test('Check if file is written and info is stored', () async {
      var fileUrl = 'baseflow.com/test';
      var extension = 'jpg';
      var memorySystem =
          await MemoryFileSystem().systemTempDirectory.createTemp('origin');

      var existingFile = memorySystem.childFile('testfile.jpg');
      var fileBytes = Uint8List(16);
      await existingFile.writeAsBytes(fileBytes);

      var store = MockStore();
      var cacheManager = TestCacheManager(createTestConfig(), store: store);

      var file = await cacheManager.putFileStream(fileUrl, existingFile.openRead(),
          fileExtension: extension);
      expect(await file.exists(), true);
      expect(await file.readAsBytes(), fileBytes);
      verify(store.putFile(any)).called(1);
    });

    test('Check if file is written and info is stored, explicit key', () async {
      var fileUrl = 'baseflow.com/test';
      var fileKey = 'test1234';
      var extension = 'jpg';
      var memorySystem =
          await MemoryFileSystem().systemTempDirectory.createTemp('origin');

      var existingFile = memorySystem.childFile('testfile.jpg');
      var fileBytes = Uint8List(16);
      await existingFile.writeAsBytes(fileBytes);

      var store = MockStore();
      var cacheManager = TestCacheManager(createTestConfig(), store: store);

      var file = await cacheManager.putFileStream(fileUrl, existingFile.openRead(),
          key: fileKey, fileExtension: extension);
      expect(await file.exists(), true);
      expect(await file.readAsBytes(), fileBytes);
      final arg =
          verify(store.putFile(captureAny)).captured.first as CacheObject;
      expect(arg.key, fileKey);
      expect(arg.url, fileUrl);
    });
  });

  group('Testing remove files from cache', () {
    test('Remove existing file from cache', () async {
      var fileUrl = 'baseflow.com/test';

      var store = MockStore();
      when(store.retrieveCacheData(fileUrl))
          .thenAnswer((_) => Future.value(CacheObject(fileUrl)));

      var cacheManager = TestCacheManager(createTestConfig(), store: store);

      await cacheManager.removeFile(fileUrl);
      verify(store.removeCachedFile(any)).called(1);
    });

    test("Don't remove files not in cache", () async {
      var fileUrl = 'baseflow.com/test';

      var store = MockStore();
      when(store.retrieveCacheData(fileUrl)).thenAnswer((_) => null);

      var cacheManager = TestCacheManager(createTestConfig(), store: store);

      await cacheManager.removeFile(fileUrl);
      verifyNever(store.removeCachedFile(any));
    });
  });

  test('Download file just downloads file', () async {
    var fileUrl = 'baseflow.com/test';
    var fileInfo = FileInfo(null, FileSource.Cache, DateTime.now(), fileUrl);
    var store = MockStore();
    var webHelper = MockWebHelper();
    when(webHelper.downloadFile(fileUrl, key: anyNamed('key')))
        .thenAnswer((_) => Stream.value(fileInfo));
    var cacheManager = TestCacheManager(
      createTestConfig(),
      webHelper: webHelper,
      store: store,
    );
    expect(await cacheManager.downloadFile(fileUrl), fileInfo);
  });

  test('test file from memory', () async {
    var fileUrl = 'baseflow.com/test';
    var fileInfo = FileInfo(null, FileSource.Cache, DateTime.now(), fileUrl);

    var store = MockStore();
    when(store.getFileFromMemory(fileUrl))
        .thenAnswer((realInvocation) async => fileInfo);
    var webHelper = MockWebHelper();
    var cacheManager = TestCacheManager(createTestConfig(),
        store: store, webHelper: webHelper);
    var result = await cacheManager.getFileFromMemory(fileUrl);
    expect(result, fileInfo);
  });

  test('Empty cache empties cache in store', () async {
    var store = MockStore();
    var cacheManager = TestCacheManager(createTestConfig(), store: store);
    await cacheManager.emptyCache();
    verify(store.emptyCache()).called(1);
  });

  group('Progress tests', () {
    test('Test progress from download', () async {
      var fileUrl = 'baseflow.com/test';

      var config = createTestConfig();
      var fileService = config.fileService;
      var downloadStreamController = StreamController<List<int>>();
      when(fileService.get(fileUrl, headers: anyNamed('headers')))
          .thenAnswer((_) {
        return Future.value(MockFileFetcherResponse(
            downloadStreamController.stream,
            6,
            'testv1',
            '.jpg',
            200,
            DateTime.now()));
      });

      var cacheManager = TestCacheManager(config);

      var fileStream = cacheManager.getFileStream(fileUrl, withProgress: true);
      downloadStreamController.add([0]);
      downloadStreamController.add([1]);
      downloadStreamController.add([2, 3]);
      downloadStreamController.add([4]);
      downloadStreamController.add([5]);
      await downloadStreamController.close();
      expect(
          fileStream,
          emitsInOrder([
            isA<DownloadProgress>().having((p) => p.progress, '1/6', 1 / 6),
            isA<DownloadProgress>().having((p) => p.progress, '2/6', 2 / 6),
            isA<DownloadProgress>().having((p) => p.progress, '4/6', 4 / 6),
            isA<DownloadProgress>().having((p) => p.progress, '5/6', 5 / 6),
            isA<DownloadProgress>().having((p) => p.progress, '6/6', 1),
            isA<FileInfo>(),
          ]));
    });

    test("Don't get progress when not asked", () async {
      var config = createTestConfig();

      var fileUrl = 'baseflow.com/test';

      var store = MockStore();
      when(store.putFile(argThat(anything)))
          .thenAnswer((_) => Future.value(VoidCallback));

      when(store.getFile(fileUrl)).thenAnswer((_) => Future.value(null));

      var downloadStreamController = StreamController<List<int>>();
      when(config.fileService.get(fileUrl, headers: anyNamed('headers')))
          .thenAnswer((_) {
        return Future.value(MockFileFetcherResponse(
            downloadStreamController.stream,
            6,
            'testv1',
            '.jpg',
            200,
            DateTime.now()));
      });

      var cacheManager = TestCacheManager(config);

      var fileStream = cacheManager.getFileStream(fileUrl);
      downloadStreamController.add([0]);
      downloadStreamController.add([1]);
      downloadStreamController.add([2, 3]);
      downloadStreamController.add([4]);
      downloadStreamController.add([5]);
      await downloadStreamController.close();

      // Only expect a FileInfo Result and no DownloadProgress status objects.
      expect(
          fileStream,
          emitsInOrder([
            isA<FileInfo>(),
          ]));
    });
  });
}

class TestCacheManager extends CacheManager with ImageCacheManager {
  TestCacheManager(
    Config config, {
    CacheStore store,
    WebHelper webHelper,
  }) : super.custom(config ?? createTestConfig(),
            cacheStore: store, webHelper: webHelper);
}

class MockStore extends Mock implements CacheStore {}

class MockWebHelper extends Mock implements WebHelper {}
