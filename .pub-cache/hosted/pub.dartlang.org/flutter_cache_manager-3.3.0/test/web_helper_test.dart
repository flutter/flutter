import 'dart:async';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/config/config.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_cache_manager/src/web/web_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'helpers/config_extensions.dart';
import 'helpers/mock_cache_store.dart';
import 'helpers/mock_file_fetcher_response.dart';
import 'helpers/mock_file_service.dart';
import 'helpers/test_configuration.dart';

void main() {
  group('Test status codes', () {
    test('200 is OK', () async {
      const imageUrl = 'baseflow.com/testimage';

      var config = createTestConfig();
      var store = CacheStore(config);

      final fileService = MockFileService();
      when(fileService.get(imageUrl, headers: anyNamed('headers')))
          .thenAnswer((_) {
        return Future.value(MockFileFetcherResponse(
            Stream.value([0, 1, 2, 3, 4, 5]),
            0,
            'testv1',
            '.jpg',
            200,
            DateTime.now()));
      });

      var webHelper = WebHelper(store, fileService);
      var result = await webHelper
          .downloadFile(imageUrl)
          .firstWhere((r) => r is FileInfo, orElse: null);
      expect(result, isNotNull);
    });

    test('404 throws', () async {
      const imageUrl = 'baseflow.com/testimage';

      var config = createTestConfig();
      var store = CacheStore(config);

      final fileService = MockFileService();
      when(fileService.get(imageUrl, headers: anyNamed('headers')))
          .thenAnswer((_) {
        return Future.value(MockFileFetcherResponse(
            Stream.value([]), 0, null, '', 404, DateTime.now()));
      });

      var webHelper = WebHelper(store, fileService);

      expect(
          () async => webHelper.downloadFile(imageUrl).toList(),
          throwsA(predicate(
              (e) => e is HttpExceptionWithStatus && e.statusCode == 404)));
    });

    test('304 ignores content', () async {
      const imageUrl = 'baseflow.com/testimage';

      var config = createTestConfig();
      var store = CacheStore(config);

      final fileService = MockFileService();
      when(fileService.get(imageUrl, headers: anyNamed('headers')))
          .thenAnswer((_) {
        return Future.value(MockFileFetcherResponse(
            Stream.value([]), 0, 'testv1', '.jpg', 304, DateTime.now()));
      });

      var webHelper = WebHelper(store, fileService);
      var result = await webHelper
          .downloadFile(imageUrl)
          .firstWhere((r) => r is FileInfo, orElse: null);
      expect(result, isNotNull);
    });
  });

  group('Parallel logic', () {
    test('Calling webhelper twice excecutes once', () async {
      const imageUrl = 'baseflow.com/testimage';

      var config = createTestConfig();
      var store = _createStore(config);

      final fileService = MockFileService();
      when(fileService.get(imageUrl, headers: anyNamed('headers')))
          .thenAnswer((_) {
        return Future.value(MockFileFetcherResponse(
            Stream.value([0, 1, 2, 3, 4, 5]),
            6,
            'testv1',
            '.jpg',
            200,
            DateTime.now()));
      });

      var webHelper = WebHelper(store, fileService);

      var call1 = webHelper.downloadFile(imageUrl).toList();
      var call2 = webHelper.downloadFile(imageUrl).toList();
      await Future.wait([call1, call2]);

      verify(store.retrieveCacheData(any)).called(1);
    });

    test('Calling webhelper twice excecutes twice when memcache ignored',
        () async {
      const imageUrl = 'baseflow.com/testimage';

      var config = createTestConfig();
      var store = _createStore(config);

      final fileService = MockFileService();
      when(fileService.get(imageUrl, headers: anyNamed('headers')))
          .thenAnswer((_) {
        return Future.value(MockFileFetcherResponse(
            Stream.value([0, 1, 2, 3, 4, 5]),
            6,
            'testv1',
            '.jpg',
            200,
            DateTime.now()));
      });

      var webHelper = WebHelper(store, fileService);
      var call1 = webHelper.downloadFile(imageUrl).toList();
      var call2 =
          webHelper.downloadFile(imageUrl, ignoreMemCache: true).toList();
      await Future.wait([call1, call2]);

      verify(store.retrieveCacheData(any)).called(2);
    });

    test('No more concurrent calls than defined in fileService', () async {
      const url1 = 'baseflow.com/testimage1';
      const url2 = 'baseflow.com/testimage2';
      const url3 = 'baseflow.com/testimage3';

      var config = createTestConfig();
      var store = _createStore(config);
      final fileService = MockFileService();

      var completer1 = Completer<FileServiceResponse>();
      var completer2 = Completer<FileServiceResponse>();
      var completer3 = Completer<FileServiceResponse>();

      when(fileService.get(url1, headers: anyNamed('headers')))
          .thenAnswer((realInvocation) => completer1.future);
      when(fileService.get(url2, headers: anyNamed('headers')))
          .thenAnswer((realInvocation) => completer2.future);
      when(fileService.get(url3, headers: anyNamed('headers')))
          .thenAnswer((realInvocation) => completer3.future);

      var webHelper = WebHelper(store, fileService);
      webHelper.downloadFile(url1);
      webHelper.downloadFile(url2);
      webHelper.downloadFile(url3);

      await Future.delayed(const Duration(microseconds: 1));

      verify(fileService.get(url1, headers: anyNamed('headers'))).called(1);
      verify(fileService.get(url2, headers: anyNamed('headers'))).called(1);
      verifyNever(fileService.get(url3, headers: anyNamed('headers')));

      completer1.complete(MockFileFetcherResponse.basic());

      await Future.delayed(const Duration(microseconds: 1));
      verify(fileService.get(url3, headers: anyNamed('headers'))).called(1);
    });
  });

  group('Miscellaneous', () {
    test('When not yet cached, new cacheobject should be made', () async {
      const imageUrl = 'baseflow.com/testimage';
      const fileName = 'testv1.jpg';
      final validTill = DateTime.now();

      var config = createTestConfig();
      var store = _createStore(config);
      config.returnsCacheObject(imageUrl, fileName, validTill);

      final fileService = MockFileService();
      when(fileService.get(imageUrl, headers: anyNamed('headers')))
          .thenAnswer((_) {
        return Future.value(MockFileFetcherResponse(
            Stream.value([0, 1, 2, 3, 4, 5]),
            6,
            'testv1',
            '.jpg',
            200,
            DateTime.now()));
      });

      var webHelper = WebHelper(store, fileService);
      var result = await webHelper
          .downloadFile(imageUrl)
          .firstWhere((r) => r is FileInfo, orElse: null);
      expect(result, isNotNull);
      verify(store.putFile(any)).called(1);
    });

    test('File should be removed if extension changed', () async {
      const imageUrl = 'baseflow.com/testimage';
      var imageName = 'image.png';

      var config = createTestConfig();
      var store = CacheStore(config);
      var file = await config.returnsFile(imageName);
      config.returnsCacheObject(imageUrl, imageName, DateTime.now());

      final fileService = MockFileService();
      var webHelper = WebHelper(store, fileService);

      expect(await file.exists(), true);
      var _ = await webHelper
          .downloadFile(imageUrl)
          .firstWhere((r) => r is FileInfo, orElse: null);
      expect(await file.exists(), false);
    });
  });
}

MockCacheStore _createStore(Config config) {
  final store = MockCacheStore();
  when(store.putFile(argThat(anything)))
      .thenAnswer((_) => Future.value(VoidCallback));
  when(store.retrieveCacheData(argThat(anything)))
      .thenAnswer((invocation) => Future.value(CacheObject(
            invocation.positionalArguments.first as String,
            relativePath: 'test.png',
            validTill: clock.now().add(const Duration(days: 7)),
          )));
  when(store.fileSystem).thenReturn(config.fileSystem);
  return store;
}

class MockStore extends Mock implements CacheStore {}
