// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:path/path.dart' as path;

import '../bazel.dart';
import '../luci_resultdb.dart';
import '../tool_subsharding.dart';
import '../utils.dart';
import 'common.dart';

void main() {
  group('bazelTestTarget', () {
    test('names a file for its path under the package', () {
      expect(
        bazelTestTarget(
          'packages/flutter_tools',
          'packages/flutter_tools/test/commands.shard/hermetic/build_apk_test.dart',
        ),
        '//packages/flutter_tools:test_commands.shard_hermetic_build_apk_test',
      );
      expect(
        bazelTestTarget(
          'packages/flutter/test/widgets',
          'packages/flutter/test/widgets/binding_test.dart',
        ),
        '//packages/flutter/test/widgets:binding_test',
      );
      expect(
        bazelTestTarget('dev/bots', 'dev/bots/test/bazel_test.dart'),
        '//dev/bots:test_bazel_test',
      );
    });

    test('takes an absolute path', () {
      expect(
        bazelTestTarget(
          'dev/bots',
          path.join(flutterRoot, 'dev', 'bots', 'test', 'bazel_test.dart'),
        ),
        '//dev/bots:test_bazel_test',
      );
    });

    test('refuses a file outside the package', () {
      expect(
        () => bazelTestTarget(
          'packages/flutter_tools',
          'packages/flutter/test/widgets/binding_test.dart',
        ),
        throwsArgumentError,
      );
      expect(() => bazelTestTarget('dev/bots', 'dev/bots/test/fixture.json'), throwsArgumentError);
    });
  });

  group('bazelPackageOf', () {
    test("is the label's package", () {
      expect(bazelPackageOf('//packages/flutter_tools:general_shard'), 'packages/flutter_tools');
      expect(bazelPackageOf('//:framework_tests_impeller'), '');
      expect(() => bazelPackageOf('packages/flutter_tools:general_shard'), throwsArgumentError);
      expect(() => bazelPackageOf('//packages/flutter_tools'), throwsArgumentError);
    });
  });

  group('testFilesUnder', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('bazel_test.');
      for (final file in <String>[
        'test/b_test.dart',
        'test/a_test.dart',
        'test/nested/deep/c_test.dart',
        'test/helper.dart',
        'test_release/d_test.dart',
        'lib/e_test.dart',
      ]) {
        File(path.join(root.path, file))
          ..createSync(recursive: true)
          ..writeAsStringSync('');
      }
    });

    tearDown(() {
      root.deleteSync(recursive: true);
    });

    test('lists the test files under test/, sorted, relative to the root', () {
      expect(testFilesUnder(root.path), <String>[
        path.join('test', 'a_test.dart'),
        path.join('test', 'b_test.dart'),
        path.join('test', 'nested', 'deep', 'c_test.dart'),
      ]);
    });

    test('lists another directory', () {
      expect(testFilesUnder(root.path, 'test_release'), <String>[
        path.join('test_release', 'd_test.dart'),
      ]);
      expect(testFilesUnder(root.path, path.join('test', 'nested')), <String>[
        path.join('test', 'nested', 'deep', 'c_test.dart'),
      ]);
    });

    test('is empty for a directory that is not there', () {
      expect(testFilesUnder(root.path, 'integration_test'), isEmpty);
    });
  });

  group('bazelisk', () {
    test('has a release asset for each supported host', () {
      expect(bazeliskAssetName(Abi.linuxX64), 'bazelisk-linux-amd64');
      expect(bazeliskAssetName(Abi.linuxArm64), 'bazelisk-linux-arm64');
      expect(bazeliskAssetName(Abi.macosX64), 'bazelisk-darwin-amd64');
      expect(bazeliskAssetName(Abi.macosArm64), 'bazelisk-darwin-arm64');
      expect(() => bazeliskAssetName(Abi.windowsX64), throwsUnsupportedError);
    });

    test("is DEPS' version", () {
      // dev/bots is the working directory: `dart test` here, and
      // //dev/bots:tests under Bazel, with the root's DEPS among its data.
      final deps = File(path.join('..', '..', 'DEPS'));
      expect(deps.readAsStringSync(), contains("'version': 'version:3@$kBazeliskVersion'"));
    });
  });

  group('bazelRbeOptions', () {
    const none = <String, String>{};

    test('is --config=rbe on a Linux bot and nowhere else by default', () {
      expect(bazelRbeOptions(onBot: true, onLinux: true, environment: none), <String>[
        '--config=rbe',
      ]);
      expect(bazelRbeOptions(onBot: true, onLinux: false, environment: none), isEmpty);
      expect(bazelRbeOptions(onBot: false, onLinux: true, environment: none), isEmpty);
      expect(kBazelRbeOnBots, isTrue);
    });

    test('is switched off for a run by $kBazelRbeEnvironmentVariable', () {
      for (final no in <String>['0', 'false', 'no']) {
        expect(
          bazelRbeOptions(
            onBot: true,
            onLinux: true,
            environment: <String, String>{kBazelRbeEnvironmentVariable: no},
          ),
          isEmpty,
        );
      }
      expect(
        bazelRbeOptions(
          onBot: true,
          onLinux: true,
          environment: <String, String>{kBazelRbeEnvironmentVariable: '1'},
        ),
        <String>['--config=rbe'],
      );
    });

    test('follows --bazel-rbe and --no-bazel-rbe on a Linux host, bot or not', () {
      expect(bazelRbeOptions(onBot: true, onLinux: true, environment: none, rbe: false), isEmpty);
      expect(bazelRbeOptions(onBot: false, onLinux: true, environment: none, rbe: true), <String>[
        '--config=rbe',
      ]);
      // The flag outranks the environment; the host outranks the flag.
      expect(
        bazelRbeOptions(
          onBot: true,
          onLinux: true,
          environment: <String, String>{kBazelRbeEnvironmentVariable: '0'},
          rbe: true,
        ),
        <String>['--config=rbe'],
      );
      expect(bazelRbeOptions(onBot: true, onLinux: false, environment: none, rbe: true), isEmpty);
    });

    test('is what bazelTestOptions gives a bot', () {
      final List<String> options = bazelTestOptions();
      expect(options.contains('--config=rbe'), bazelRbeOptions().isNotEmpty);
      expect(options, contains('--config=prebuilt_engine'));
    });
  });

  group('the results of a run', () {
    test("bazelTestResultsFile is the target's JSON reporter under bazel-testlogs", () {
      expect(
        bazelTestResultsFile('/logs', '//packages/flutter_tools:test_general.shard_foo_test').path,
        path.join(
          '/logs',
          'packages',
          'flutter_tools',
          'test_general.shard_foo_test',
          'test.outputs',
          'test_results.json',
        ),
      );
      expect(
        bazelTestResultsFile('/logs', '//:something_test').path,
        path.join('/logs', 'something_test', 'test.outputs', 'test_results.json'),
      );
    });

    // A JSON reporter file naming one suite at [suitePath].
    TestFileReporterResults resultsOf(Directory root, String suitePath) {
      final file = File(path.join(root.path, 'test_results.json'))
        ..writeAsStringSync(
          '{"protocolVersion":"0.1.1","runnerVersion":null,"pid":1,"type":"start","time":0}\n'
          '{"suite":{"id":0,"platform":"vm","path":"$suitePath"},"type":"suite","time":0}\n'
          '{"test":{"id":1,"name":"a test","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":null,"column":null,"url":null},"type":"testStart","time":1}\n'
          '{"testID":1,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":2}\n'
          '{"success":true,"type":"done","time":3}\n',
        );
      return TestFileReporterResults.fromFile(file);
    }

    test('bazelSuiteWorkingDirectory resolves a suite path against the package, then the root', () {
      final Directory root = Directory.systemTemp.createTempSync('bazel_test.');
      try {
        File(path.join(root.path, 'dev', 'bots', 'test', 'x_test.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('');
        // A dart_test names its suite relative to its package directory.
        expect(
          bazelSuiteWorkingDirectory(
            '//dev/bots:test_x_test',
            resultsOf(root, 'test/x_test.dart'),
            root: root.path,
          ),
          path.join(root.path, 'dev', 'bots'),
        );
        // A flutter_test names its suite by its repository path.
        expect(
          bazelSuiteWorkingDirectory(
            '//dev/bots:test_x_test',
            resultsOf(root, 'dev/bots/test/x_test.dart'),
            root: root.path,
          ),
          root.path,
        );
        expect(
          bazelSuiteWorkingDirectory(
            '//dev/bots:test_x_test',
            resultsOf(root, '/absolute/elsewhere_test.dart'),
            root: root.path,
          ),
          isNull,
        );
      } finally {
        root.deleteSync(recursive: true);
      }
    });

    test("bazelTestResults reads each target's file, names the module by the file", () {
      final Directory root = Directory.systemTemp.createTempSync('bazel_test.');
      try {
        final String testlogs = path.join(root.path, 'testlogs');
        File(path.join(root.path, 'dev', 'bots', 'test', 'x_test.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('');
        // A dart_test's file (the suite relative to dev/bots) and a
        // flutter_test's (the suite by its repository path); a third target
        // left none.
        resultsOf(
          bazelTestResultsFile(testlogs, '//dev/bots:test_x_test').parent
            ..createSync(recursive: true),
          'test/x_test.dart',
        );
        resultsOf(
          bazelTestResultsFile(testlogs, '//packages/flutter/test/widgets:y_test').parent
            ..createSync(recursive: true),
          'packages/flutter/test/widgets/y_test.dart',
        );
        final BazelTestResults results = bazelTestResults(testlogs, <String>{
          '//dev/bots:test_x_test',
          '//packages/flutter/test/widgets:y_test',
          '//packages/flutter/test/widgets:z_test',
        }, root: root.path);
        expect(results.files, 2);
        expect(results.missing, 1);
        expect(results.results.map((LuciTestResult result) => result.testId.moduleName), <String>[
          'dev/bots/test/x_test.dart',
          'packages/flutter/test/widgets/y_test.dart',
        ]);
        expect(results.results.map((LuciTestResult result) => result.status), everyElement('PASS'));
        expect(results.results.map((LuciTestResult result) => result.resultId), <String>[
          '0-0',
          '1-0',
        ]);
      } finally {
        root.deleteSync(recursive: true);
      }
    });
  });
}
