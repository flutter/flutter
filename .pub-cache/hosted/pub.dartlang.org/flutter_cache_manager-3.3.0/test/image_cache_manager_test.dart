import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'cache_manager_test.dart';
import 'helpers/config_extensions.dart';

import 'helpers/test_configuration.dart';

const fileName = 'test.jpg';
const fileUrl = 'baseflow.com/test';
final validTill = DateTime.now().add(const Duration(days: 1));
void main() {
  setUp(WidgetsFlutterBinding.ensureInitialized);

  tearDown(() {
    PaintingBinding.instance?.imageCache?.clear();
    PaintingBinding.instance?.imageCache?.clearLiveImages();
  });

  group('Test image resizing', () {
    test('Test original image size', () async {
      final bytes = await getExampleImage();
      await verifySize(bytes, 120, 120);
    });

    test('File should not be modified when no height or width is given',
        () async {
      var cacheManager = await setupCacheManager();
      var result = await cacheManager.getImageFile(fileUrl).last as FileInfo;
      var image = await result.file.readAsBytes();
      await verifySize(image, 120, 120);
    });

    test('File should not be modified when height is given', () async {
      var cacheManager = await setupCacheManager();
      var result = await cacheManager
          .getImageFile(
            fileUrl,
            maxHeight: 100,
          )
          .last as FileInfo;
      var image = await result.file.readAsBytes();
      await verifySize(image, 100, 100);
    });

    test('File should not be modified when width is given', () async {
      var cacheManager = await setupCacheManager();
      var result = await cacheManager
          .getImageFile(
            fileUrl,
            maxWidth: 100,
          )
          .last as FileInfo;
      var image = await result.file.readAsBytes();
      await verifySize(image, 100, 100);
    });

    test('File should keep aspect ratio when both height and width are given',
        () async {
      var cacheManager = await setupCacheManager();
      var result = await cacheManager
          .getImageFile(fileUrl, maxWidth: 100, maxHeight: 80)
          .last as FileInfo;
      var image = await result.file.readAsBytes();
      await verifySize(image, 80, 80);
    });
  });
  group('Test resized image caching', () {
    test('Resized image should be fetched from cache', () async {
      var config = await setupConfig(cacheKey: 'resized_w100_h80_$fileUrl');
      var cacheManager = TestCacheManager(config);
      var result = await cacheManager
          .getImageFile(fileUrl, maxWidth: 100, maxHeight: 80)
          .last as FileInfo;

      expect(result, isNotNull);
      config.verifyNoDownloadCall();
    });

    test('Unsized image should be fetched from cache', () async {
      var config = await setupConfig();
      config.returnsCacheObject(
        fileUrl,
        fileName,
        validTill,
      );
      var cacheManager = TestCacheManager(config);
      var result = await cacheManager
          .getImageFile(fileUrl, maxWidth: 100, maxHeight: 80)
          .last as FileInfo;

      expect(result, isNotNull);
      config.verifyNoDownloadCall();
    });

    test('Wrongly sized image should not be fetched from cache', () async {
      var config = await setupConfig(cacheKey: 'resized_w100_h150_$fileUrl');
      var cacheManager = TestCacheManager(config);
      var result = await cacheManager
          .getImageFile(fileUrl, maxWidth: 100, maxHeight: 80)
          .last as FileInfo;

      expect(result, isNotNull);
      config.verifyDownloadCall();
    });

    test('Downloads should give progress', () async {
      var config = await setupConfig(cacheKey: 'resized_w100_h150_$fileUrl');
      var cacheManager = TestCacheManager(config);
      var results = await cacheManager
          .getImageFile(
            fileUrl,
            maxWidth: 100,
            maxHeight: 80,
            withProgress: true,
          )
          .toList();
      var progress = results.whereType<DownloadProgress>().toList();
      config.verifyDownloadCall();
      expect(progress, isNotEmpty);
    });
  });
}

Future<TestCacheManager> setupCacheManager() async {
  return TestCacheManager(await setupConfig());
}

Future<Config> setupConfig({String? cacheKey}) async {
  var validTill = DateTime.now().add(const Duration(days: 1));
  var config = createTestConfig();
  await config.returnsFile(fileName, data: await getExampleImage());
  config.returnsCacheObject(fileUrl, fileName, validTill, key: cacheKey);
  return config;
}

Future verifySize(
  Uint8List image,
  int expectedWidth,
  int expectedHeight,
) async {
  var codec = await instantiateImageCodec(image);
  var frame = await codec.getNextFrame();
  var height = frame.image.height;
  var width = frame.image.width;
  expect(width, expectedWidth);
  expect(height, expectedHeight);
}

Future<Uint8List> getExampleImage() {
  return File('test/images/image-120.png').readAsBytes();
}
