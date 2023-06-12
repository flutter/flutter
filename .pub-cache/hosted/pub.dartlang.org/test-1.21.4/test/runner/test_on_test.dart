// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:package_config/package_config.dart';
import 'package:test/test.dart';
import 'package:test_core/src/util/io.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../io.dart';

void main() {
  late PackageConfig currentPackageConfig;

  setUpAll(() async {
    await precompileTestExecutable();
    currentPackageConfig =
        await loadPackageConfigUri((await Isolate.packageConfig)!);
  });

  setUp(() async {
    await d
        .file('package_config.json',
            jsonEncode(PackageConfig.toJson(currentPackageConfig)))
        .create();
  });

  group('for suite', () {
    test('runs a test suite on a matching platform', () async {
      await _writeTestFile('vm_test.dart', suiteTestOn: 'vm');

      var test = await runTest(['vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    });

    test("doesn't run a test suite on a non-matching platform", () async {
      await _writeTestFile('vm_test.dart', suiteTestOn: 'vm');

      var test = await runTest(['--platform', 'chrome', 'vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    }, tags: 'chrome');

    test('runs a test suite on a matching operating system', () async {
      await _writeTestFile('os_test.dart', suiteTestOn: currentOS.identifier);

      var test = await runTest(['os_test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    });

    test("doesn't run a test suite on a non-matching operating system",
        () async {
      await _writeTestFile('os_test.dart',
          suiteTestOn: otherOS, loadable: false);

      var test = await runTest(['os_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });

    test('only loads matching files when loading as a group', () async {
      await _writeTestFile('vm_test.dart', suiteTestOn: 'vm');
      await _writeTestFile('browser_test.dart',
          suiteTestOn: 'browser', loadable: false);
      await _writeTestFile('this_os_test.dart',
          suiteTestOn: currentOS.identifier);
      await _writeTestFile('other_os_test.dart',
          suiteTestOn: otherOS, loadable: false);

      var test = await runTest(['.']);
      expect(test.stdout, emitsThrough(contains('+2: All tests passed!')));
      await test.shouldExit(0);
    });
  });

  group('for group', () {
    test('runs a VM group on the VM', () async {
      await _writeTestFile('vm_test.dart', groupTestOn: 'vm');

      var test = await runTest(['vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    });

    test("doesn't run a Browser group on the VM", () async {
      await _writeTestFile('browser_test.dart', groupTestOn: 'browser');

      var test = await runTest(['browser_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });

    test('runs a browser group on a browser', () async {
      await _writeTestFile('browser_test.dart', groupTestOn: 'browser');

      var test = await runTest(['--platform', 'chrome', 'browser_test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test("doesn't run a VM group on a browser", () async {
      await _writeTestFile('vm_test.dart', groupTestOn: 'vm');

      var test = await runTest(['--platform', 'chrome', 'vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    }, tags: 'chrome');
  });

  group('for test', () {
    test('runs a VM test on the VM', () async {
      await _writeTestFile('vm_test.dart', testTestOn: 'vm');

      var test = await runTest(['vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    });

    test("doesn't run a browser test on the VM", () async {
      await _writeTestFile('browser_test.dart', testTestOn: 'browser');

      var test = await runTest(['browser_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });

    test('runs a browser test on a browser', () async {
      await _writeTestFile('browser_test.dart', testTestOn: 'browser');

      var test = await runTest(['--platform', 'chrome', 'browser_test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    }, tags: 'chrome');

    test("doesn't run a VM test on a browser", () async {
      await _writeTestFile('vm_test.dart', testTestOn: 'vm');

      var test = await runTest(['--platform', 'chrome', 'vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    }, tags: 'chrome');
  });

  group('with suite, group, and test selectors', () {
    test('runs the test if all selectors match', () async {
      await _writeTestFile('vm_test.dart',
          suiteTestOn: '!browser', groupTestOn: '!js', testTestOn: 'vm');

      var test = await runTest(['vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    });

    test("doesn't runs the test if the suite doesn't match", () async {
      await _writeTestFile('vm_test.dart',
          suiteTestOn: 'browser', groupTestOn: '!js', testTestOn: 'vm');

      var test = await runTest(['vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });

    test("doesn't runs the test if the group doesn't match", () async {
      await _writeTestFile('vm_test.dart',
          suiteTestOn: '!browser', groupTestOn: 'browser', testTestOn: 'vm');

      var test = await runTest(['vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });

    test("doesn't runs the test if the test doesn't match", () async {
      await _writeTestFile('vm_test.dart',
          suiteTestOn: '!browser', groupTestOn: '!js', testTestOn: 'browser');

      var test = await runTest(['vm_test.dart']);
      expect(test.stdout, emitsThrough(contains('No tests ran.')));
      await test.shouldExit(79);
    });
  });
}

/// Writes a test file with some platform selectors to [filename].
///
/// Each of [suiteTestOn], [groupTestOn], and [testTestOn] is a platform
/// selector that's suite-, group-, and test-level respectively. If [loadable]
/// is `false`, the test file will be made unloadable on the Dart VM.
Future<void> _writeTestFile(String filename,
    {String? suiteTestOn,
    String? groupTestOn,
    String? testTestOn,
    bool loadable = true}) {
  var buffer = StringBuffer();
  if (suiteTestOn != null) buffer.writeln("@TestOn('$suiteTestOn')");
  if (!loadable) buffer.writeln("import 'dart:html';");

  buffer
    ..writeln("import 'package:test/test.dart';")
    ..writeln('void main() {')
    ..writeln("  group('group', () {");

  if (testTestOn != null) {
    buffer.writeln("    test('test', () {}, testOn: '$testTestOn');");
  } else {
    buffer.writeln("    test('test', () {});");
  }

  if (groupTestOn != null) {
    buffer.writeln("  }, testOn: '$groupTestOn');");
  } else {
    buffer.writeln('  });');
  }

  buffer.writeln('}');

  return d.file(filename, buffer.toString()).create();
}
