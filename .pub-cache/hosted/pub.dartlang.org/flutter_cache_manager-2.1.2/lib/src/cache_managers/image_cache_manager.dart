import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart';

const supportedFileNames = ['jpg', 'jpeg', 'png', 'tga', 'gif', 'cur', 'ico'];
mixin ImageCacheManager on BaseCacheManager {
  /// Returns a resized image file to fit within maxHeight and maxWidth. It
  /// tries to keep the aspect ratio. It stores the resized image by adding
  /// the size to the key or url. For example when resizing
  /// https://via.placeholder.com/150 to max width 100 and height 75 it will
  /// store it with cacheKey resized_w100_h75_https://via.placeholder.com/150.
  ///
  /// When the resized file is not found in the cache the original is fetched
  /// from the cache or online and stored in the cache. Then it is resized
  /// and returned to the caller.
  Stream<FileResponse> getImageFile(
    String url, {
    String key,
    Map<String, String> headers,
    bool withProgress,
    int maxHeight,
    int maxWidth,
  }) async* {
    if (maxHeight == null && maxWidth == null) {
      yield* getFileStream(url,
          key: key, headers: headers, withProgress: withProgress);
      return;
    }
    key ??= url;
    var resizedKey = 'resized';
    if (maxWidth != null) resizedKey += '_w$maxWidth';
    if (maxHeight != null) resizedKey += '_h$maxHeight';
    resizedKey += '_$key';

    var fromCache = await getFileFromCache(resizedKey);
    if (fromCache != null) {
      yield fromCache;
      if (fromCache.validTill.isAfter(DateTime.now())) {
        return;
      }
      withProgress = false;
    }
    if (!_runningResizes.containsKey(resizedKey)) {
      _runningResizes[resizedKey] = _fetchedResizedFile(
        url,
        key,
        resizedKey,
        headers,
        withProgress,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
    yield* _runningResizes[resizedKey];
    _runningResizes.remove(resizedKey);
  }

  final Map<String, Stream<FileResponse>> _runningResizes = {};
  Future<FileInfo> _resizeImageFile(
    FileInfo originalFile,
    String key,
    int maxWidth,
    int maxHeight,
  ) async {
    var originalFileName = originalFile.file.path;
    var fileExtension = originalFileName.split('.').last;
    if (!supportedFileNames.contains(fileExtension)) {
      return originalFile;
    }

    var image = decodeImage(await originalFile.file.readAsBytes());
    if (maxWidth != null && maxHeight != null) {
      var resizeFactorWidth = image.width / maxWidth;
      var resizeFactorHeight = image.height / maxHeight;
      var resizeFactor = max(resizeFactorHeight, resizeFactorWidth);

      maxWidth = (image.width / resizeFactor).round();
      maxHeight = (image.height / resizeFactor).round();
    }

    var resized = copyResize(image, width: maxWidth, height: maxHeight);
    var resizedFile = encodeNamedImage(resized, originalFileName);
    var maxAge = originalFile.validTill.difference(DateTime.now());

    var file = await putFile(
      originalFile.originalUrl,
      Uint8List.fromList(resizedFile),
      key: key,
      maxAge: maxAge,
      fileExtension: fileExtension,
    );

    return FileInfo(
      file,
      originalFile.source,
      originalFile.validTill,
      originalFile.originalUrl,
    );
  }

  Stream<FileResponse> _fetchedResizedFile(
    String url,
    String originalKey,
    String resizedKey,
    Map<String, String> headers,
    bool withProgress, {
    int maxWidth,
    int maxHeight,
  }) async* {
    await for (var response in getFileStream(
      url,
      key: originalKey,
      headers: headers,
      withProgress: withProgress,
    )) {
      if (response is DownloadProgress) {
        yield response;
      }
      if (response is FileInfo) {
        yield await _resizeImageFile(
          response,
          resizedKey,
          maxWidth,
          maxHeight,
        );
      }
    }
  }
}
