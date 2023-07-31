@TestOn('vm')
library process_run.pub_test;

import 'package:path/path.dart';
import 'package:process_run/package/package.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() => defineTests();

void defineTests() {
  group('package', () {
    test('getPackageVersion', () async {
      expect(await getPackageVersion(), greaterThan(Version(0, 10, 0)));
      expect(await getPackageVersion(dir: join('test', '..')),
          greaterThan(Version(0, 10, 0)));
      expect(await getPackageVersion(dir: 'test'), isNull);
    });
  });
}
