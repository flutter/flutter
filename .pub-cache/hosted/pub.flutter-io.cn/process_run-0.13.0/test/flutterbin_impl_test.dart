@TestOn('vm')
library process_run.flutterbin_cmd_test;

import 'package:process_run/src/flutterbin_cmd.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('flutterbin_impl', () {
    test('FlutterBinInfo', () {
      var info = FlutterBinInfo.parseVersionOutput(
          'Flutter 1.7.8+hotfix.4 • channel stable • https://github.com/flutter/flutter.git')!;
      expect(info.version, Version(1, 7, 8, build: 'hotfix.4'));
      expect(info.channel, 'stable');

      info = FlutterBinInfo.parseVersionOutput(
          'Flutter 1.14.3 • channel dev • https://github.com/flutter/flutter.git')!;
      expect(info.version, Version(1, 14, 3));
      expect(info.channel, 'dev');
    });
  });
}
