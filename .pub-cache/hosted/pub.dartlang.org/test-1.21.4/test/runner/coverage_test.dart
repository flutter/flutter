// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

import '../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  group('with the --coverage flag,', () {
    late Directory coverageDirectory;

    Future<void> validateCoverage(TestProcess test, String coveragePath) async {
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);

      final coverageFile = File(p.join(coverageDirectory.path, coveragePath));
      final coverage = await coverageFile.readAsString();
      final jsonCoverage = json.decode(coverage);
      expect(jsonCoverage['coverage'], isNotEmpty);
    }

    setUp(() async {
      await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("test 1", () {
            expect(true, isTrue);
          });
        }
      ''').create();

      coverageDirectory =
          await Directory.systemTemp.createTemp('test_coverage');
    });

    tearDown(() async {
      await coverageDirectory.delete(recursive: true);
    });

    test('gathers coverage for VM tests', () async {
      var test =
          await runTest(['--coverage', coverageDirectory.path, 'test.dart']);
      await validateCoverage(test, 'test.dart.vm.json');
    });

    test('gathers coverage for Chrome tests', () async {
      var test = await runTest(
          ['--coverage', coverageDirectory.path, 'test.dart', '-p', 'chrome']);
      await validateCoverage(test, 'test.dart.chrome.json');
    });

    test(
        'gathers coverage for Chrome tests when JS files contain unicode characters',
        () async {
      final sourceMapFileContent =
          '{"version":3,"file":"","sources":[],"names":[],"mappings":""}';
      final jsContent = '''
        (function() {
          '© '
          window.foo = function foo() {
            return 'foo';
          };
        })({
        
          '© ': ''
          });
      ''';
      await d.file('file_with_unicode.js', jsContent).create();
      await d.file('file_with_unicode.js.map', sourceMapFileContent).create();

      await d.file('js_with_unicode_test.dart', '''
        import 'dart:html';
        import 'dart:js';
        
        import 'package:test/test.dart';
        
        Future<void> loadScript(String src) async {
          final script = ScriptElement()..src = src;
          final scriptLoaded = script.onLoad.first;
          document.body!.append(script);
          await scriptLoaded.timeout(Duration(seconds: 1));
        }

        void main() {
          test("test 1", () async {
            await loadScript('file_with_unicode.js');
            expect(context['foo'], isNotNull);
            context.callMethod('foo', []);
            expect(true, isTrue);
          });
        }
      ''').create();

      final jsBytes = utf8.encode(jsContent);
      final jsLatin1 = latin1.decode(jsBytes);
      final jsUtf8 = utf8.decode(jsBytes);
      expect(jsLatin1, isNot(jsUtf8),
          reason: 'test setup: should have decoded differently');

      const functionPattern = 'function foo';
      expect([jsLatin1, jsUtf8], everyElement(contains(functionPattern)));
      expect(jsLatin1.indexOf(functionPattern),
          isNot(jsUtf8.indexOf(functionPattern)),
          reason:
              'test setup: decoding should have shifted the position of the function');

      var test = await runTest([
        '--coverage',
        coverageDirectory.path,
        'js_with_unicode_test.dart',
        '-p',
        'chrome'
      ]);
      await validateCoverage(test, 'js_with_unicode_test.dart.chrome.json');
    });
  });
}
