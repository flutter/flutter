import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repositories/cache_info_repository.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repositories/cache_object_provider.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repositories/json_cache_info_repository.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system_io.dart';

import 'config.dart' as def;

class Config implements def.Config {
  Config(
    this.cacheKey, {
    Duration stalePeriod,
    int maxNrOfCacheObjects,
    CacheInfoRepository repo,
    FileSystem fileSystem,
    FileService fileService,
  })  : stalePeriod = stalePeriod ?? const Duration(days: 30),
        maxNrOfCacheObjects = maxNrOfCacheObjects ?? 200,
        repo = repo ?? _createRepo(cacheKey),
        fileSystem = fileSystem ?? IOFileSystem(cacheKey),
        fileService = fileService ?? HttpFileService();

  @override
  final CacheInfoRepository repo;

  @override
  final FileSystem fileSystem;

  @override
  final String cacheKey;

  @override
  final Duration stalePeriod;

  @override
  final int maxNrOfCacheObjects;

  @override
  final FileService fileService;

  static CacheInfoRepository _createRepo(String key) {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return CacheObjectProvider(databaseName: key);
    }
    return JsonCacheInfoRepository(databaseName: key);
  }
}
