import 'package:mockito/mockito.dart';

import '../mock.mocks.dart';

class MockCacheStore extends MockCacheStoreBase {
  MockCacheStore._();
  factory MockCacheStore() {
    final store = MockCacheStore._();
    when(store.retrieveCacheData(any,
            ignoreMemCache: anyNamed('ignoreMemCache')))
        .thenAnswer((_) => Future.value(null));
    return store;
  }
}
