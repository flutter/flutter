import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image_platform_interface'
    '/cached_network_image_platform_interface.dart' hide ImageLoader;
import 'package:cached_network_image_web/cached_network_image_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;
import 'package:file/file.dart';

void main() {
  test('loadAsync returns a stream', () {
    var imageLoader = ImageLoader();
    var stream = imageLoader.loadAsync(
        'test.com/image',
        null,
        StreamController<ImageChunkEvent>(),
        decoder,
        MockCacheManager(),
        null,
        null,
        null,
        null,
        ImageRenderMethodForWeb.HttpGet,
        () => {});
    expect(stream, isNotNull);
  });
}

Future<ui.Codec> decoder(
  Uint8List bytes, {
  int? cacheWidth,
  int? cacheHeight,
  bool allowUpscaling = false,
}) {
  throw UnimplementedError();
}

class MockCacheManager implements BaseCacheManager {
  @override
  Future<void> dispose() {
    throw UnimplementedError();
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> emptyCache() {
    throw UnimplementedError();
  }

  @override
  Stream<FileInfo> getFile(String url,
      {String? key, Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<FileInfo?> getFileFromCache(String key,
      {bool ignoreMemCache = false}) {
    throw UnimplementedError();
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) {
    throw UnimplementedError();
  }

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress = false}) {
    throw UnimplementedError();
  }

  @override
  Future<File> getSingleFile(String url,
      {String? key, Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<File> putFile(String url, Uint8List fileBytes,
      {String? key,
      String? eTag,
      Duration maxAge = const Duration(days: 30),
      String fileExtension = 'file'}) {
    throw UnimplementedError();
  }

  @override
  Future<File> putFileStream(String url, Stream<List<int>> source,
      {String? key,
      String? eTag,
      Duration maxAge = const Duration(days: 30),
      String fileExtension = 'file'}) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeFile(String key) {
    throw UnimplementedError();
  }
}
