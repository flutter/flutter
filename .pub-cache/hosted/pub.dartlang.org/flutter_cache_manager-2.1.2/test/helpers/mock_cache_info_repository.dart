import 'package:flutter_cache_manager/src/storage/cache_info_repositories/cache_info_repository.dart';
import 'package:mockito/mockito.dart';

class MockCacheInfoRepository extends Mock implements CacheInfoRepository {
  MockCacheInfoRepository._();
  factory MockCacheInfoRepository() {
    var provider = MockCacheInfoRepository._();
    when(provider.open()).thenAnswer((realInvocation) async => null);
    return provider;
  }
}
