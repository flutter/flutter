import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/web/web_helper.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([], customMocks: [
  MockSpec<CacheInfoRepository>(as: #MockCacheInfoRepositoryBase),
  MockSpec<CacheStore>(as: #MockCacheStoreBase),
  MockSpec<FileService>(as: #MockFileServiceBase),
  MockSpec<WebHelper>(),
])
// ignore: unused_element
void _f() {}
