import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:mockito/mockito.dart';
import '../mock.mocks.dart';

class MockCacheInfoRepository extends MockCacheInfoRepositoryBase {
  MockCacheInfoRepository._();

  factory MockCacheInfoRepository() {
    var provider = MockCacheInfoRepository._();
    when(provider.delete(any)).thenAnswer((_) => Future.value(0));
    when(provider.deleteAll(any)).thenAnswer((_) => Future.value(0));
    when(provider.get(any)).thenAnswer((_) => Future.value(null));
    when(provider.insert(any, setTouchedToNow: anyNamed('setTouchedToNow')))
        .thenAnswer((realInvocation) {
      return Future.value(
          realInvocation.positionalArguments.first as CacheObject);
    });
    when(provider.open()).thenAnswer((_) => Future.value(true));
    when(provider.update(any, setTouchedToNow: anyNamed('setTouchedToNow')))
        .thenAnswer((realInvocation) => Future.value(0));
    when(provider.updateOrInsert(any)).thenAnswer((realInvocation) async =>
        Future.value(realInvocation.positionalArguments.first));
    when(provider.getObjectsOverCapacity(any))
        .thenAnswer((realInvocation) async => Future.value([]));
    when(provider.getOldObjects(any))
        .thenAnswer((realInvocation) async => Future.value([]));
    return provider;
  }
}
