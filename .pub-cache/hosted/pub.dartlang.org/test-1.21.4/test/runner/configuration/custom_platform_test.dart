// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:io';

import 'package:test/src/runner/browser/default_settings.dart';
import 'package:test/test.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_core/src/util/exit_codes.dart' as exit_codes;
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

import '../../io.dart';

void main() {
  setUpAll(precompileTestExecutable);

  setUp(() async {
    await d.file('test.dart', '''
        import 'package:test/test.dart';

        void main() {
          test("success", () {});
        }
      ''').create();
  });

  group('override_platforms', () {
    group('can override a browser', () {
      test('without any changes', () async {
        await d.file('dart_test.yaml', '''
          override_platforms:
            chrome:
              settings: {}
        ''').create();

        var test = await runTest(['-p', 'chrome', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'chrome');

      test("that's user-defined", () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: Chromium
              extends: chrome
              settings: {}

          override_platforms:
            chromium:
              settings: {}
        ''').create();

        var test = await runTest(['-p', 'chromium', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'chrome');

      test('with a basename-only executable', () async {
        await d.file('dart_test.yaml', '''
          override_platforms:
            firefox:
              settings:
                executable:
                  linux: firefox
                  mac_os: firefox
                  windows: firefox.exe
        ''').create();

        var test = await runTest(['-p', 'firefox', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'firefox');

      test('with an absolute-path executable', () async {
        String path;
        if (Platform.isLinux) {
          var process = await TestProcess.start('which', ['google-chrome']);
          path = await process.stdout.next;
          await process.shouldExit(0);
        } else {
          path = defaultSettings[Runtime.chrome]!.executable;
        }

        await d.file('dart_test.yaml', '''
          override_platforms:
            chrome:
              settings:
                executable: $path
        ''').create();

        var test = await runTest(['-p', 'chrome', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'chrome');

      test('with non-headless mode', () async {
        await d.file('dart_test.yaml', '''
          override_platforms:
            chrome:
              settings:
                headless: false
        ''').create();

        await d.file('test.dart', '''
          import 'dart:html';

          import 'package:test/test.dart';

          void main() {
            test("is not headless", () {
              expect(window.navigator.userAgent,
                  isNot(contains('HeadlessChrome')));
            });
          }
        ''').create();

        var test = await runTest(['-p', 'chrome', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'chrome');
    });

    test('can override Node.js without any changes', () async {
      await d.file('dart_test.yaml', '''
        override_platforms:
          node:
            settings: {}
      ''').create();

      var test = await runTest(['-p', 'node', 'test.dart']);
      expect(test.stdout, emitsThrough(contains('All tests passed!')));
      await test.shouldExit(0);
    }, tags: 'node');

    group('errors', () {
      test('rejects a non-map value', () async {
        await d.file('dart_test.yaml', 'override_platforms: 12').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['override_platforms must be a map.', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects a non-string key', () async {
        await d
            .file('dart_test.yaml', 'override_platforms: {12: null}')
            .create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Platform identifier must be a string.', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects a non-identifier-like key', () async {
        await d
            .file('dart_test.yaml', 'override_platforms: {foo bar: null}')
            .create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder([
              'Platform identifier must be an (optionally hyphenated) Dart '
                  'identifier.',
              '^^^^^^^'
            ]));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects a non-map definition', () async {
        await d.file('dart_test.yaml', '''
          override_platforms:
            chrome: 12
        ''').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Platform definition must be a map.', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('requires a settings key', () async {
        await d.file('dart_test.yaml', '''
          override_platforms:
            chrome: {}
        ''').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Missing required field "settings".', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('settings must be a map', () async {
        await d.file('dart_test.yaml', '''
          override_platforms:
            chrome:
              settings: null
        ''').create();

        var test = await runTest([]);
        expect(test.stderr, containsInOrder(['Must be a map.', '^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('the overridden platform must exist', () async {
        await d.file('dart_test.yaml', '''
          override_platforms:
            chromium:
              settings: {}
        ''').create();

        var test = await runTest(['test.dart']);
        expect(test.stderr,
            containsInOrder(['Unknown platform "chromium".', '^^^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test("uncustomizable platforms can't be overridden", () async {
        await d.file('dart_test.yaml', '''
          override_platforms:
            vm:
              settings: {}
        ''').create();

        var test = await runTest(['-p', 'vm', 'test.dart']);
        expect(test.stdout,
            containsInOrder(['The "vm" platform can\'t be customized.', '^^']));
        await test.shouldExit(1);
      });

      group('when overriding browsers', () {
        test('executable must be a string or map', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  executable: 12
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(test.stdout,
              containsInOrder(['Must be a map or a string.', '^^']));
          await test.shouldExit(1);
        });

        test('executable string may not be relative on POSIX', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  executable: foo/bar
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(
              test.stdout,
              containsInOrder([
                'Linux and Mac OS executables may not be relative paths.',
                '^^^^^^^'
              ]));
          await test.shouldExit(1);
        },
            // We allow relative executables for Windows so that Windows users
            // can set a global executable without having to explicitly write
            // `windows:`.
            testOn: '!windows');

        test('Linux executable must be a string', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  executable:
                    linux: 12
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(test.stdout, containsInOrder(['Must be a string.', '^^']));
          await test.shouldExit(1);
        });

        test('Linux executable may not be relative', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  executable:
                    linux: foo/bar
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(
              test.stdout,
              containsInOrder([
                'Linux and Mac OS executables may not be relative paths.',
                '^^^^^^^'
              ]));
          await test.shouldExit(1);
        });

        test('Mac OS executable must be a string', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  executable:
                    mac_os: 12
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(test.stdout, containsInOrder(['Must be a string.', '^^']));
          await test.shouldExit(1);
        });

        test('Mac OS executable may not be relative', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  executable:
                    mac_os: foo/bar
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(
              test.stdout,
              containsInOrder([
                'Linux and Mac OS executables may not be relative paths.',
                '^^^^^^^'
              ]));
          await test.shouldExit(1);
        });

        test('Windows executable must be a string', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  executable:
                    windows: 12
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(test.stdout, containsInOrder(['Must be a string.', '^^']));
          await test.shouldExit(1);
        });

        test('executable must exist', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  executable: _does_not_exist
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(
              test.stdout,
              emitsThrough(
                  contains('Failed to run Chrome: $noSuchFileMessage')));
          await test.shouldExit(1);
        });

        test('executable must exist for Node.js', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              node:
                settings:
                  executable: _does_not_exist
          ''').create();

          var test = await runTest(['-p', 'node', 'test.dart']);
          expect(
              test.stdout,
              emitsThrough(
                  contains('Failed to run Node.js: $noSuchFileMessage')));
          await test.shouldExit(1);
        }, tags: 'node');

        test('headless must be a boolean', () async {
          await d.file('dart_test.yaml', '''
            override_platforms:
              chrome:
                settings:
                  headless: definitely
          ''').create();

          var test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(
              test.stdout,
              emitsThrough(
                  containsInOrder(['Must be a boolean.', '^^^^^^^^^^'])));
          await test.shouldExit(1);
        });
      });
    });
  });

  group('define_platforms', () {
    group('can define a new browser', () {
      group('without any changes', () {
        setUp(() async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings: {}
          ''').create();
        });

        test('that can be used to run tests', () async {
          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout, emitsThrough(contains('All tests passed!')));
          await test.shouldExit(0);
        }, tags: 'chrome');

        test('that can be used in platform selectors', () async {
          await d.file('test.dart', '''
            import 'package:test/test.dart';

            void main() {
              test("success", () {}, testOn: "chromium");
            }
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout, emitsThrough(contains('All tests passed!')));
          await test.shouldExit(0);

          test = await runTest(['-p', 'chrome', 'test.dart']);
          expect(test.stdout, emitsThrough(contains('No tests ran.')));
          await test.shouldExit(79);
        }, tags: 'chrome');

        test('that counts as its parent', () async {
          await d.file('test.dart', '''
            import 'package:test/test.dart';

            void main() {
              test("success", () {}, testOn: "chrome");
            }
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout, emitsThrough(contains('All tests passed!')));
          await test.shouldExit(0);
        }, tags: 'chrome');
      });

      test('with a basename-only executable', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            my-firefox:
              name: My Firefox
              extends: firefox
              settings:
                executable:
                  linux: firefox
                  mac_os: firefox
                  windows: firefox.exe
        ''').create();

        var test = await runTest(['-p', 'my-firefox', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'firefox');

      test('with an absolute-path executable', () async {
        String path;
        if (Platform.isLinux) {
          var process = await TestProcess.start('which', ['google-chrome']);
          path = await process.stdout.next;
          await process.shouldExit(0);
        } else {
          path = defaultSettings[Runtime.chrome]!.executable;
        }

        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: Chromium
              extends: chrome
              settings:
                executable: $path
        ''').create();

        var test = await runTest(['-p', 'chromium', 'test.dart']);
        expect(test.stdout, emitsThrough(contains('All tests passed!')));
        await test.shouldExit(0);
      }, tags: 'chrome');
    });

    group('errors', () {
      test('rejects a non-map value', () async {
        await d.file('dart_test.yaml', 'define_platforms: 12').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['define_platforms must be a map.', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects a non-string key', () async {
        await d.file('dart_test.yaml', 'define_platforms: {12: null}').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Platform identifier must be a string.', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects a non-identifier-like key', () async {
        await d
            .file('dart_test.yaml', 'define_platforms: {foo bar: null}')
            .create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder([
              'Platform identifier must be an (optionally hyphenated) Dart '
                  'identifier.',
              '^^^^^^^'
            ]));
        await test.shouldExit(exit_codes.data);
      });

      test('rejects a non-map definition', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium: 12
        ''').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Platform definition must be a map.', '^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('requires a name key', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              extends: chrome
              settings: {}
        ''').create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder(
                ['Missing required field "name".', 'extends: chrome']));
        await test.shouldExit(exit_codes.data);
      });

      test('name must be a string', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: null
              extends: chrome
              settings: {}
        ''').create();

        var test = await runTest([]);
        expect(test.stderr, containsInOrder(['Must be a string.', '^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('requires an extends key', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: Chromium
              settings: {}
        ''').create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder(
                ['Missing required field "extends".', 'name: Chromium']));
        await test.shouldExit(exit_codes.data);
      });

      test('extends must be a string', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: Chromium
              extends: null
              settings: {}
        ''').create();

        var test = await runTest([]);
        expect(test.stderr,
            containsInOrder(['Platform parent must be a string.', '^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('extends must be identifier-like', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: Chromium
              extends: foo bar
              settings: {}
        ''').create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder([
              'Platform parent must be an (optionally hyphenated) Dart '
                  'identifier.',
              '^^^^^^^'
            ]));
        await test.shouldExit(exit_codes.data);
      });

      test('requires a settings key', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: Chromium
              extends: chrome
        ''').create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder(
                ['Missing required field "settings".', 'name: Chromium']));
        await test.shouldExit(exit_codes.data);
      });

      test('settings must be a map', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: Chromium
              extends: chrome
              settings: null
        ''').create();

        var test = await runTest([]);
        expect(test.stderr, containsInOrder(['Must be a map.', '^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test('the new platform may not override an existing platform', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chrome:
              name: Chromium
              extends: firefox
              settings: {}
        ''').create();

        await d.dir('test').create();

        var test = await runTest([]);
        expect(
            test.stderr,
            containsInOrder([
              'The platform "chrome" already exists. Use override_platforms to '
                  'override it.',
              '^^^^^^'
            ]));
        await test.shouldExit(exit_codes.data);
      });

      test('the new platform must extend an existing platform', () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            chromium:
              name: Chromium
              extends: foobar
              settings: {}
        ''').create();

        await d.dir('test').create();

        var test = await runTest([]);
        expect(test.stderr, containsInOrder(['Unknown platform.', '^^^^^^']));
        await test.shouldExit(exit_codes.data);
      });

      test("the new platform can't extend an uncustomizable platform",
          () async {
        await d.file('dart_test.yaml', '''
          define_platforms:
            myvm:
              name: My VM
              extends: vm
              settings: {}
        ''').create();

        var test = await runTest(['-p', 'myvm', 'test.dart']);
        expect(test.stdout,
            containsInOrder(['The "vm" platform can\'t be customized.', '^^']));
        await test.shouldExit(1);
      });

      group('when overriding browsers', () {
        test('executable must be a string or map', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  executable: 12
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout,
              containsInOrder(['Must be a map or a string.', '^^']));
          await test.shouldExit(1);
        });

        test('executable string may not be relative on POSIX', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  executable: foo/bar
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(
              test.stdout,
              containsInOrder([
                'Linux and Mac OS executables may not be relative paths.',
                '^^^^^^^'
              ]));
          await test.shouldExit(1);
        },
            // We allow relative executables for Windows so that Windows users
            // can set a global executable without having to explicitly write
            // `windows:`.
            testOn: '!windows');

        test('Linux executable must be a string', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  executable:
                    linux: 12
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout, containsInOrder(['Must be a string.', '^^']));
          await test.shouldExit(1);
        });

        test('Linux executable may not be relative', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  executable:
                    linux: foo/bar
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(
              test.stdout,
              containsInOrder([
                'Linux and Mac OS executables may not be relative paths.',
                '^^^^^^^'
              ]));
          await test.shouldExit(1);
        });

        test('Mac OS executable must be a string', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  executable:
                    mac_os: 12
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout, containsInOrder(['Must be a string.', '^^']));
          await test.shouldExit(1);
        });

        test('Mac OS executable may not be relative', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  executable:
                    mac_os: foo/bar
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(
              test.stdout,
              containsInOrder([
                'Linux and Mac OS executables may not be relative paths.',
                '^^^^^^^'
              ]));
          await test.shouldExit(1);
        });

        test('Windows executable must be a string', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  executable:
                    windows: 12
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout, containsInOrder(['Must be a string.', '^^']));
          await test.shouldExit(1);
        });

        test('executable must exist', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  executable: _does_not_exist
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(
              test.stdout,
              emitsThrough(
                  contains('Failed to run Chrome: $noSuchFileMessage')));
          await test.shouldExit(1);
        });

        test('arguments must be a string', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  arguments: 12
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout, containsInOrder(['Must be a string.', '^^']));
          await test.shouldExit(1);
        });

        test('arguments must be shell parseable', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  arguments: --foo 'bar
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(test.stdout,
              containsInOrder(['Unmatched single quote.', '^^^^^^^^^^']));
          await test.shouldExit(1);
        });

        test('headless must be a boolean', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              chromium:
                name: Chromium
                extends: chrome
                settings:
                  headless: definitely
          ''').create();

          var test = await runTest(['-p', 'chromium', 'test.dart']);
          expect(
              test.stdout,
              emitsThrough(
                  containsInOrder(['Must be a boolean.', '^^^^^^^^^^'])));
          await test.shouldExit(1);
        });

        test('with an argument that causes the browser to quit', () async {
          await d.file('dart_test.yaml', '''
            define_platforms:
              myfox:
                name: My Firefox
                extends: firefox
                settings:
                  arguments: --version
          ''').create();

          var test = await runTest(['-p', 'myfox', 'test.dart']);
          expect(test.stdout,
              emitsThrough(contains('My Firefox exited before connecting.')));
          await test.shouldExit(1);
        }, tags: 'firefox');
      });
    });
  });
}
