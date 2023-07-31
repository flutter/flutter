@TestOn('vm')
library process_run.dartfmt_test;

import 'package:process_run/cmd_run.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() => defineTests();

void defineTests() {
  group('dartfmt', () {
    test('help', () async {
      var result = await runCmd(
          DartFmtCmd(// ignore: deprecated_member_use_from_same_package
              ['--help']));
      expect(result.exitCode, 0);
      expect(result.stdout, contains('Usage:'));
      expect(result.stdout, contains('dartfmt'));

      // The raw version is displayed
      result = await runCmd(
          DartFmtCmd(// ignore: deprecated_member_use_from_same_package
              ['--version']));
      var version = Version.parse((result.stdout as String).trim());
      expect(version, greaterThan(Version(1, 0, 0)));
      expect(result.exitCode, 0);
    });
  }, skip: 'Deprecated');
}
