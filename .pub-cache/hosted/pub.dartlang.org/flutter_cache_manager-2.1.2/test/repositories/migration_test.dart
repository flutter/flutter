import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/json_repo_helpers.dart' show JsonRepoHelpers;
import '../helpers/mock_cache_info_repository.dart';

void main() {
  group('Migration tests', () {
    test('Files are added in new repo', () async {
      var mockRepo = setupMockRepo(false);
      var source = await JsonRepoHelpers.createRepository(open: false);
      await mockRepo.migrateFrom(source);
      for (var object in JsonRepoHelpers.startCacheObjects) {
        verify(
          mockRepo.insert(
            argThat(CacheObjectMatcher(object)),
            setTouchedToNow: anyNamed('setTouchedToNow'),
          ),
        );
      }
    });

    test('Old repo is deleted', () async {
      var mockRepo = setupMockRepo(false);
      var source = await JsonRepoHelpers.createRepository(open: false);
      await mockRepo.migrateFrom(source);
      var exists = await source.exists();
      expect(exists, false);
    });

    test('Files are updated in an existing repo', () async {
      var mockRepo = setupMockRepo(true);
      var source = await JsonRepoHelpers.createRepository(open: false);
      await mockRepo.migrateFrom(source);
      for (var object in JsonRepoHelpers.startCacheObjects) {
        verify(
          mockRepo.update(
            argThat(CacheObjectMatcher(object)),
            setTouchedToNow: anyNamed('setTouchedToNow'),
          ),
        );
      }
    });
  });
}

MockCacheInfoRepository setupMockRepo(bool returnObjects) {
  var mockRepo = MockCacheInfoRepository();
  when(mockRepo.get(any)).thenAnswer((realInvocation) {
    if (!returnObjects) return null;
    var key = realInvocation.positionalArguments.first as String;
    var cacheObject = JsonRepoHelpers.startCacheObjects.firstWhere(
      (element) => element.key == key,
      orElse: () => null,
    );
    return Future.value(cacheObject);
  });
  when(mockRepo.insert(any)).thenAnswer((realInvocation) =>
      Future.value(realInvocation.positionalArguments.first as CacheObject));
  return mockRepo;
}

class CacheObjectMatcher extends Matcher {
  final CacheObject value;
  static final Object _mismatchedValueKey = Object();

  CacheObjectMatcher(this.value);

  @override
  Description describe(Description description) {
    description.add('Matches cacheObject $value');
    return description;
  }

  @override
  bool matches(item, Map matchState) {
    var isMatch = false;
    if (item is CacheObject) {
      isMatch = item.key == value.key &&
          item.url == value.url &&
          item.relativePath == value.relativePath &&
          item.length == value.length &&
          item.touched.millisecondsSinceEpoch ==
              value.touched.millisecondsSinceEpoch &&
          item.eTag == value.eTag;
    }
    if (!isMatch) matchState[_mismatchedValueKey] = item;
    return isMatch;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (matchState.containsKey(_mismatchedValueKey)) {
      final actualValue = matchState[_mismatchedValueKey] as CacheObject;
      // Leading whitespace is added so that lines in the multiline
      // description returned by addDescriptionOf are all indented equally
      // which makes the output easier to read for this case.
      return mismatchDescription
          .add('expected normalized value\n  ')
          .addDescriptionOf('${value.key}: ${value.url}')
          .add('\nbut got\n  ')
          .addDescriptionOf('${actualValue.key}: ${actualValue.url}');
    }
    return mismatchDescription;
  }
}
