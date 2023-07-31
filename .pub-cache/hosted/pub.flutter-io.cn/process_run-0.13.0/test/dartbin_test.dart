@TestOn('vm')
library process_run.dartbin_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart' show flutterExecutablePath;
import 'package:process_run/dartbin.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/dartbin_impl.dart'
    show
        debugDartExecutableForceWhich,
        findFlutterDartExecutableSync,
        resolveDartExecutable,
        resolvedDartExecutable;
import 'package:process_run/src/script_filename.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() => defineTests();

void testDartVersionOutput(ProcessResult result) {
  var errText = result.errText;
  if (dartVersion >= Version(2, 15, 0, pre: '0')) {
    var outText = result.outText;
    // New output is on stdout
    expect(outText.toLowerCase(), contains('dart'));
    expect(outText.toString().toLowerCase(), contains('version'));
    expect(outText, contains(Platform.version));
  } else {
    // Before it was on stderr
    expect(errText.toLowerCase(), contains('dart'));
    expect(errText.toLowerCase(), contains('version'));
    expect(errText, contains(Platform.version));
  }
}

void defineTests() {
  group('dartbin', () {
    group('dart', () {
      test('run_dart', () async {
        final result = await Process.run('dart', ['--version']);
        try {
          // New output is on stdout
          expect(result.outText.toLowerCase(), contains('dart'));
          expect(result.outText.toLowerCase(), contains('version'));
        } catch (_) {
          // before 2.15 is stdout
          // dart used might not match the current dart used here
          expect(result.errText.toLowerCase(), contains('dart'));
          expect(result.errText.toLowerCase(), contains('version'));
        }
        // Before 2.9.0
        // 'Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on 'linux_x64'\n'
        // After 2.9.0
        // Dart SDK version: 2.9.0-21.2.beta (beta) (Fri Jul 10 17:39:56 2020 +0200) on "linux_x64"
        // After 2.15.0
        // Dart SDK version: 2.15.0-82.0.dev (dev) (Sat Sep 4 03:33:09 2021 -0700) on "linux_x64"
      });

      test('run', () async {
        final result = await Process.run(dartExecutable!, ['--version']);
        testDartVersionOutput(result);
        // 'Dart VM version: 1.7.0-dev.4.5 (Thu Oct  9 01:44:31 2014) on 'linux_x64'\n'
      });

      test('dartExecutable_path', () {
        expect(isAbsolute(dartExecutable!), isTrue);
        expect(
            Directory(join(dirname(dartExecutable!), 'snapshots')).existsSync(),
            isTrue);
      });

      test('flutterDart', () async {
        if (isFlutterSupportedSync) {
          try {
            expect(
                dirname(findFlutterDartExecutableSync(
                    dirname(flutterExecutablePath!))!),
                endsWith(join('cache', 'dart-sdk', 'bin')));
          } finally {
            resolvedDartExecutable = null;
            debugDartExecutableForceWhich = false;
          }
        }
      });

      test('dart_empty_param', () async {
        final result = await Process.run(dartExecutable!, []);
        if (dartVersion > Version(2, 10, 0, pre: '1')) {
          // Not yet in 2.9.0-21
          // Ok in 2.10.0-1.0.dev
          expect(result.exitCode, 0,
              reason:
                  'dartVersion empty param not exitcode 0 yet in $dartVersion, exit code 255 in <=2.9.0 to check');
        } else {
          // pre 2.9 behavior
          expect(result.exitCode, 255);
        }
      }, skip: 'dart without params hangs on dev now 2020/10/31');
    });

    test('which', () {
      var whichDart = whichSync('dart');
      // might not be in path during the test
      if (whichDart != null) {
        if (Platform.isWindows) {
          expect(['dart.exe', 'dart.bat'],
              contains(basename(whichDart).toLowerCase()));
        } else {
          expect(basename(whichDart), getBashOrExeExecutableFilename('dart'));
        }
      }
    });

    test('resolveDartExecutable', () async {
      try {
        debugDartExecutableForceWhich = true;

        try {
          resolvedDartExecutable = null;
          expect(
              resolveDartExecutable(environment: <String, String>{}), isNull);
        } catch (e) {
          print(e);
        }
        expect(resolveDartExecutable(), isNotNull);
        expect(await which('dart'), isNotNull);
        // expect(resolveDartExecutable(), await which('dart'));
      } finally {
        resolvedDartExecutable = null;
        debugDartExecutableForceWhich = false;
        expect(resolveDartExecutable(), isNotNull);
        expect(await which('dart'), isNotNull);
        // expect(resolveDartExecutable(), await which('dart'));
      }
    });

    test('flutter resolveDartExecutable', () async {
      if (isFlutterSupportedSync) {
        try {
          debugDartExecutableForceWhich = true;

          resolvedDartExecutable = null;
          expect(
              dirname(resolveDartExecutable(environment: <String, String>{
                'PATH': dirname(flutterExecutablePath!)
              })!),
              endsWith(join('cache', 'dart-sdk', 'bin')));

          expect(resolveDartExecutable(), isNotNull);

          // Dart from flutter
          if (dirname(dartExecutable!)
              .contains(dirname(flutterExecutablePath!))) {
            expect(
                dartSdkBinDirPath, endsWith(join('cache', 'dart-sdk', 'bin')));
          }
        } finally {
          resolvedDartExecutable = null;
          expect(resolveDartExecutable(), isNotNull);
        }
      }
    });

    group('help', () {
      test('dart', () async {
        var result = await Process.run(dartExecutable!, ['--help']);
        expect(result.exitCode, 0);
        var minVersion = Version(2, 10, 0, pre: '1');
        var reason = 'Version output now on stdout since $minVersion';
        if (dartVersion >= minVersion) {
          // help is on stdout
          expect(result.stdout, contains('Usage: dart '), reason: reason);
          expect(result.stderr, '', reason: reason);
        } else {
          // Pre 2.9
          // help is on stderr
          expect(result.stdout, '', reason: reason);
          expect(result.stderr, contains('Usage: dart '), reason: reason);
        }

        // Version is on stdout after 2.15
        result = await Process.run(dartExecutable!, ['--version']);
        try {
          expect(result.stderr, '');
          minVersion = Version(2, 9, 0, pre: '1');
          reason =
              'Output stdout from VM to SDK since $minVersion err: ${result.stderr}';
          if (dartVersion >= minVersion) {
            // Dart SDK version: 2.9.0-21.2.beta (beta) (Fri Jul 10 17:39:56 2020 +0200) on "linux_x64"\n'
            expect(result.stdout, contains('Dart SDK'), reason: reason);
          } else {
            expect(result.stdout, contains('Dart VM'), reason: reason);
          }
        } catch (_) {
          // Pre 2.15
          expect(result.stdout, '');
          minVersion = Version(2, 9, 0, pre: '1');
          reason =
              'Output changed from VM to SDK since $minVersion err: ${result.stderr}';
          if (dartVersion >= minVersion) {
            // Dart SDK version: 2.9.0-21.2.beta (beta) (Fri Jul 10 17:39:56 2020 +0200) on "linux_x64"\n'
            expect(result.stderr, contains('Dart SDK'), reason: reason);
          } else {
            expect(result.stderr, contains('Dart VM'), reason: reason);
          }
        }
      });
    });

    test('dartVersion', () {
      expect(dartVersion, greaterThan(Version(2, 5, 0)));
    });

    test('dartChannel', () {
      // "TRAVIS_DART_VERSION": "stable"
      // print(Platform.version);
      expect(dartChannel, isNotNull);
      if (Platform.environment['TRAVIS_DART_VERSION'] == 'stable') {
        expect(dartChannel, dartChannelStable);
      }
      if (Platform.environment['TRAVIS_DART_VERSION'] == 'beta') {
        expect(dartChannel, dartChannelBeta);
      }
      if (Platform.environment['TRAVIS_DART_VERSION'] == 'dev') {
        expect(dartChannel, dartChannelDev);
      }
    });
  });
}
