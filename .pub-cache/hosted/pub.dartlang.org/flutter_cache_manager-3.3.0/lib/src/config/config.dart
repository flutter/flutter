import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repositories/cache_info_repository.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';

import '_config_unsupported.dart'
    if (dart.library.html) '_config_web.dart'
    if (dart.library.io) '_config_io.dart' as impl;

abstract class Config {
  /// Config file for the CacheManager.
  /// [cacheKey] is used for the folder to store files and for the database
  /// file name.
  /// [stalePeriod] is the time duration in which a cache object is
  /// considered 'stale'. When a file is cached but not being used for a
  /// certain time the file will be deleted.
  /// [maxNrOfCacheObjects] defines how large the cache is allowed to be. If
  /// there are more files the files that haven't been used for the longest
  /// time will be removed.
  /// [repo] is the [CacheInfoRepository] which stores the cache metadata. On
  /// Android, iOS and macOS this defaults to [CacheObjectProvider], a
  /// sqflite implementation due to legacy. On web this defaults to
  /// [NonStoringObjectProvider]. On the other platforms this defaults to
  /// [JsonCacheInfoRepository].
  /// The [fileSystem] defines where the cached files are stored and the
  /// [fileService] defines where files are fetched, for example online.
  factory Config(
    String cacheKey, {
    Duration stalePeriod,
    int maxNrOfCacheObjects,
    CacheInfoRepository repo,
    FileSystem fileSystem,
    FileService fileService,
  }) = impl.Config;

  String get cacheKey;
  Duration get stalePeriod;
  int get maxNrOfCacheObjects;
  CacheInfoRepository get repo;
  FileSystem get fileSystem;
  FileService get fileService;
}
