@TestOn('vm')
library process_run.test.bin.shell_bin_test;

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/env_file_content.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:process_run/src/common/constant.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

var shell = Shell(
    environment: ShellEnvironment()..aliases['ds'] = 'dart run bin/shell.dart',
    verbose: false);

var safeLocalEnvFile = '.dart_tool/process_run/test/test_local_env3_safe.yaml';

var safeShellEnvironment = ShellEnvironment()
  ..aliases['ds'] = 'dart run bin/shell.dart'
  ..vars[userEnvFilePathEnvKey] = 'test/data/test_user_env3_safe.yaml';

Shell get safeShell => Shell(environment: safeShellEnvironment, verbose: false);

void main() {
  group('bin_shell', () {
    test('version', () async {
      var output = (await shell.run('ds --version')).outText.trim();
      await shell.run('ds env edit -h');
      expect(Version.parse(output), shellBinVersion);
    });

    test('help', () async {
      var outLines = (await shell.run('ds --help')).outLines;
      expect(outLines.length, greaterThan(17), reason: '$outLines');
    });
    group('run', () {
      test('run', () async {
        await shell.run('ds run --help');
        await shell.run('ds run echo Hello World');
      });
    });

    group('env', () {
      test('info', () async {
        await shell.run('ds env -u -i');
        await shell.run('ds env -l -i');
      });
      test('delete', () async {
        shellEnvironment = safeShellEnvironment;
        try {
          // user file defines the local one!
          var file = File(safeLocalEnvFile);
          if (file.existsSync()) {
            await file.delete(recursive: true);
          }
          expect(file.existsSync(), isFalse);
          // Create it by adding an alias (safest modif)
          await safeShell.run('ds env alias set TEST_ALIAS test command');
          expect(file.existsSync(), isTrue);
          await safeShell.run('ds env delete --force');
          expect(file.existsSync(), isFalse);
        } finally {
          shellEnvironment = null;
        }
      });
      group('path', () {
        test('prepend', () async {
          await shell.run('ds env path prepend dummy1');
          await shell.run('ds env path dump');
        });

        test('set/get/delete', () async {
          var uniqueName = 'e1ccfaef-d320-4af6-a157-6f006dd7b6e0';
          await shell.run('ds env path prepend $uniqueName');
          var text = (await shell.run('ds env path get $uniqueName')).outText;
          expect(text, contains(uniqueName));
          await shell.run('ds env path delete $uniqueName');
          text = (await shell.run('ds env path get $uniqueName')).outText;
          expect(text, isNot(contains('dummy1')));
        });
      });

      group('var', () {
        test('var set/get/delete', () async {
          await safeShell.run('ds env var set TEST_VALUE dummy1');
          var text = (await safeShell.run('ds env var get TEST_VALUE')).outText;
          expect(text, contains('dummy1'));
          await safeShell.run('ds env var delete TEST_VALUE');
          text = (await safeShell.run('ds env var get TEST_VALUE')).outText;
          expect(text, isNot(contains('dummy1')));
        });
        test('dump', () async {
          await shell.run('ds env var dump');
        });
      });
      group('alias', () {
        test('alias', () async {
          await shell.run('ds env alias set TEST_ALIAS test command');
          await shell.run('ds env alias dump');
        });

        test('set/get/delete', () async {
          await shell.run('ds env alias set TEST_ALIAS dummy1');
          var text = (await shell.run('ds env alias get TEST_ALIAS')).outText;
          expect(text, contains('dummy1'));
          await shell.run('ds env alias delete TEST_ALIAS');
          text = (await shell.run('ds env alias get TEST_ALIAS')).outText;
          expect(text, isNot(contains('dummy1')));
        });
      });
    });
    group('file_content', () {
      test('addAlias', () async {
        var fileContent = EnvFileContent('dummy')..lines = [];
        expect(fileContent.addAlias('a1', 'v1'), true);
        expect(fileContent.lines, ['alias:', '  a1: v1']);
        expect(
            true,
            fileContent.addAlias(
                'a1', 'v1')); // yes even if not changed, we don't know
        expect(fileContent.lines, ['alias:', '  a1: v1']);
        fileContent.deleteAlias('a1');
        expect(fileContent.lines, ['alias:']);
        fileContent.addAlias('a1', 'v1');
        fileContent.addAlias('a2', 'v2');
        expect(fileContent.lines, ['alias:', '  a2: v2', '  a1: v1']);
        expect(fileContent.deleteAlias('a1'), true);
        expect(fileContent.lines, ['alias:', '  a2: v2']);
        expect(fileContent.deleteAlias('a1'), false);
        expect(fileContent.lines, ['alias:', '  a2: v2']);
      });
      test('addPath', () {
        var fileContent = EnvFileContent('dummy')..lines = [];
        fileContent.prependPaths(['a1', 'b1']);
        expect(fileContent.lines, ['path:', '  - a1', '  - b1']);
        fileContent.prependPaths(['a1', 'b1']);
        expect(fileContent.lines, ['path:', '  - a1', '  - b1']);
        fileContent.prependPaths(['c1']);
        expect(fileContent.lines, ['path:', '  - c1', '  - a1', '  - b1']);
        expect(fileContent.deletePaths(['b1', 'c1']), true);
        expect(fileContent.lines, ['path:', '  - a1']);
        expect(fileContent.deletePaths(['b1', 'c1']), false);
      });
    });
  });
}
