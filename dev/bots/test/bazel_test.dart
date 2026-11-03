// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:path/path.dart' as path;

import '../bazel.dart';
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
}
