import 'dart:typed_data';

import 'package:file/file.dart';

import '../result/file_info.dart';
import '../result/file_response.dart';

/// Interface of the CacheManager. In general [CacheManager] can be used
/// directly.
abstract class BaseCacheManager {
  /// Get the file from the cache and/or online, depending on availability and age.
  /// Downloaded form [url], [headers] can be used for example for authentication.
  /// When a file is cached it is return directly, when it is too old the file is
  /// downloaded in the background. When a cached file is not available the
  /// newly downloaded file is returned.
  Future<File> getSingleFile(
    String url, {
    String key,
    Map<String, String> headers,
  });

  /// Get the file from the cache and/or online, depending on availability and age.
  /// Downloaded form [url], [headers] can be used for example for authentication.
  /// The files are returned as stream. First the cached file if available, when the
  /// cached file is too old the newly downloaded file is returned afterwards.
  @Deprecated('Prefer to use the new getFileStream method')
  Stream<FileInfo> getFile(String url,
      {String key, Map<String, String> headers});

  /// Get the file from the cache and/or online, depending on availability and age.
  /// Downloaded form [url], [headers] can be used for example for authentication.
  /// The files are returned as stream. First the cached file if available, when the
  /// cached file is too old the newly downloaded file is returned afterwards.
  ///
  /// The [FileResponse] is either a [FileInfo] object for fully downloaded files
  /// or a [DownloadProgress] object for when a file is being downloaded.
  /// The [DownloadProgress] objects are only dispatched when [withProgress] is
  /// set on true and the file is not available in the cache. When the file is
  /// returned from the cache there will be no progress given, although the file
  /// might be outdated and a new file is being downloaded in the background.
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress});

  ///Download the file and add to cache
  Future<FileInfo> downloadFile(String url,
      {String? key, Map<String, String>? authHeaders, bool force = false});

  /// Get the file from the cache.
  /// Specify [ignoreMemCache] to force a re-read from the database
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false});

  ///Returns the file from memory if it has already been fetched
  Future<FileInfo?> getFileFromMemory(String key);

  /// Put a file in the cache. It is recommended to specify the [eTag] and the
  /// [maxAge]. When [maxAge] is passed and the eTag is not set the file will
  /// always be downloaded again. The [fileExtension] should be without a dot,
  /// for example "jpg". When cache info is available for the url that path
  /// is re-used.
  /// The returned [File] is saved on disk.
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  });

  /// Put a byte stream in the cache. When using an existing file you can use
  /// file.openRead(). It is recommended to specify  the [eTag] and the
  /// [maxAge]. When [maxAge] is passed and the eTag is not set the file will
  /// always be downloaded again. The [fileExtension] should be without a dot,
  /// for example "jpg". When cache info is available for the url that path
  /// is re-used.
  /// The returned [File] is saved on disk.
  Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  });

  /// Remove a file from the cache
  Future<void> removeFile(String key);

  /// Removes all files from the cache
  Future<void> emptyCache();

  /// Closes the cache database
  Future<void> dispose();
}
