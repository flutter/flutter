@TestOn('vm')
library process_run.flutterbin_cmd_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/script_filename.dart';
import 'package:process_run/src/user_config.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('flutterbin_cmd', () {
    test('api', () {
      // ignore: unnecessary_statements
      getFlutterBinVersion;
    });
    test('run_version', () async {
      //print(flutterExecutablePath);
      ProcessCmd cmd = FlutterCmd(['--version']);
      // expect(cmd.executable, flutterExecutablePath);
      expect(cmd.arguments, ['--version']);
      final result = await runCmd(cmd);
      expect(result.outText.toLowerCase(), contains('dart'));
      expect(result.outText.toLowerCase(), contains('revision'));
      expect(result.outText.toLowerCase(), contains('flutter'));

      // Whatever ship stable
      expect(await getFlutterBinVersion(), greaterThan(Version(1, 10, 0)));
      expect(await getFlutterBinChannel(), isNotNull);
    }, skip: !isFlutterSupportedSync);

    test('version & channel', () async {
      // Whatever ship stable
      expect(await getFlutterBinVersion(), greaterThan(Version(1, 10, 0)));
      expect(await getFlutterBinChannel(), isNotNull);
    }, skip: !isFlutterSupportedSync);

    test('get version', () async {
      var version = await getFlutterBinVersion();
      if (version != null) {
        expect(version, greaterThan(Version(1, 5, 0)));
      }
    });

    test('missing flutter', () async {
      // ignore: deprecated_member_use_from_same_package
      flutterExecutablePath = null;
      shellEnvironment = <String, String>{};
      try {
        var version = await getFlutterBinVersion();
        expect(version, isNull);
      } finally {
        // ignore: deprecated_member_use_from_same_package
        flutterExecutablePath = null;
        shellEnvironment = null;
      }
    });

    test('dart', () async {
      var flutterDir = dirname((await which('flutter'))!);
      // New in 2.9
      expect(File(join(flutterDir, 'dart')).existsSync(), isTrue);
      getFlutterAncestorPath(flutterDir);
      expect(getFlutterAncestorPath(flutterDir), flutterDir);
    }, skip: !isFlutterSupportedSync);

    test('which', () {
      expect(basename(whichSync('flutter')!),
          getBashOrBatExecutableFilename('flutter'));
    }, skip: !isFlutterSupportedSync);
  });
}
