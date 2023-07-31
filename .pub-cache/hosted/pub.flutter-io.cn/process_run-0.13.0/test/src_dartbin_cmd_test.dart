// TODO non vm
//@TestOn('vm')
library process_run.test.src_dart_bin_cmd_test;

import 'package:process_run/dartbin.dart';
import 'package:process_run/src/dartbin_cmd.dart'
    show parsePlatformVersion, parsePlatformChannel;
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('src_dartbin_cmd', () {
    test('parse', () {
      expect(parsePlatformVersion('1.0.0'), Version(1, 0, 0));
      expect(
          parsePlatformVersion('2.7.0 (Unknown timestamp)'), Version(2, 7, 0));

      // 2.8.0-dev.18.0.flutter-eea9717938 (be) (Wed Apr 1 08:55:31 2020 +0000) on "linux_x64"
      expect(parsePlatformVersion('2.8.0-dev.18.0.flutter-eea9717938 (be)'),
          Version(2, 8, 0, pre: 'dev.18.0.flutter-eea9717938'));
      // expect(parsePlatformChannel('2.8.0-dev.18.0.flutter-eea9717938 (be)'), dartChannelBeta);

      expect(
          parsePlatformChannel(
              '2.9.0-5.0.dev (dev) (Thu Apr 30 13:02:02 2020 +0200) on "linux_x64"'),
          dartChannelDev);
      expect(
          parsePlatformChannel(
              '2.8.0-20.11.beta (beta) (Mon Apr 20 14:33:01 2020 +0200) on "linux_x64"'),
          dartChannelBeta);
    });
  });
}
