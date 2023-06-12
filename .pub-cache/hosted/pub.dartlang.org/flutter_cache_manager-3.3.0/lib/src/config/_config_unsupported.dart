import 'package:flutter_cache_manager/src/storage/cache_info_repositories/cache_info_repository.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';
import 'package:flutter_cache_manager/src/web/file_service.dart';

import 'config.dart' as def;

class Config implements def.Config {
  //ignore: avoid_unused_constructor_parameters
  Config(
    //ignore: avoid_unused_constructor_parameters
    String cacheKey, {
    //ignore: avoid_unused_constructor_parameters
    Duration? stalePeriod,
    //ignore: avoid_unused_constructor_parameters
    int? maxNrOfCacheObjects,
    //ignore: avoid_unused_constructor_parameters
    CacheInfoRepository? repo,
    //ignore: avoid_unused_constructor_parameters
    FileSystem? fileSystem,
    //ignore: avoid_unused_constructor_parameters
    FileService? fileService,
  }) {
    throw UnsupportedError('Platform is not supported');
  }

  @override
  CacheInfoRepository get repo => throw UnimplementedError();

  @override
  FileSystem get fileSystem => throw UnimplementedError();

  @override
  String get cacheKey => throw UnimplementedError();

  @override
  Duration get stalePeriod => throw UnimplementedError();

  @override
  int get maxNrOfCacheObjects => throw UnimplementedError();

  @override
  FileService get fileService => throw UnimplementedError();
}
