@TestOn('vm')
library process_run.test.src_shell_utils_test;

import 'dart:convert';

import 'package:process_run/shell.dart';
import 'package:process_run/src/bin/shell/import.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('shell_utils', () {
    test('scriptToCommands', () {
      expect(scriptToCommands(''), isEmpty);
      // expect(scriptToCommands('\\'), ['\\']);
      expect(scriptToCommands(' e\n#\n # comment\nf \n '),
          ['e', '#', '# comment', 'f']);
    });

    test('isLineToBeContinued', () {
      expect(isLineToBeContinued(''), isFalse);
      expect(isLineToBeContinued('\\'), isTrue);
      expect(isLineToBeContinued('^'), isTrue);
      expect(isLineToBeContinued('\\'), isTrue);
      expect(isLineToBeContinued('a^'), isFalse);
      expect(isLineToBeContinued(' ^'), isTrue);
      expect(isLineToBeContinued('a ^'), isTrue);
      expect(isLineToBeContinued(' \\'), isTrue);
      expect(isLineToBeContinued('a\\'), isFalse);
      expect(isLineToBeContinued('a \\'), isTrue);
    });

    test('isLineComment', () {
      expect(isLineComment(''), isFalse);
      expect(isLineComment('a'), isFalse);
      expect(isLineComment('\\'), isFalse);
      expect(isLineComment('//'), isTrue);
      expect(isLineComment('//a'), isFalse);
      expect(isLineComment('// '), isTrue);
      expect(isLineComment('///'), isTrue);
      expect(isLineComment('///a'), isFalse);
      expect(isLineComment('/// '), isTrue);
      expect(isLineComment('#a'), isTrue);
    });

    test('environmentFilterOutVmOptions', () {
      var env = {
        'DART_VM_OPTIONS': '--pause-isolates-on-start --enable-vm-service:51156'
      };
      env = environmentFilterOutVmOptions(env);
      expect(env, isEmpty);
      env = {
        'DART_VM_OPTIONS': '--enable-vm-service:51156',
        'TEKARTIK_DART_VM_OPTIONS': '--profile'
      };
      env = environmentFilterOutVmOptions(env);
      expect(env, {
        'TEKARTIK_DART_VM_OPTIONS': '--profile',
        'DART_VM_OPTIONS': '--profile'
      });
    });

    test('shellSplit', () {
      // We differ from io implementation
      expect(shellSplit(r'\'), [r'\']);
      expect(shellSplit('Hello  world'), ['Hello', 'world']);
      expect(shellSplit('"Hello  world"'), ['Hello  world']);
      expect(shellSplit("'Hello  world'"), ['Hello  world']);
      expect(
          shellSplit(
              'curl --location --request POST "https://postman-echo.com/post" --data "This is expected to be sent back as part of response body."'),
          [
            'curl',
            '--location',
            '--request',
            'POST',
            'https://postman-echo.com/post',
            '--data',
            'This is expected to be sent back as part of response body.'
          ]);
    });

    test('shellJoin', () {
      void testSplitJoin(String command, {String? expected}) {
        var parts = shellSplit(command);
        var joined = shellJoin(parts);
        expect(joined, expected ?? command, reason: parts.toString());
      }

      testSplitJoin('foo');
      testSplitJoin('foo bar');
      testSplitJoin(r'\');
      testSplitJoin('"foo bar"');
      testSplitJoin("'foo bar'", expected: '"foo bar"');
    });

    test('no_env', () {
      expect(findExecutableSync('dart', []), isNull);
      expect(findExecutableSync('pub', []), isNull);

      expect(findExecutableSync('dart', [dartSdkBinDirPath]), dartExecutable);
      if (dartVersion < Version(2, 17, 0, pre: '0')) {
        // no longer supported
        expect(findExecutableSync('pub', [dartSdkBinDirPath]), isNotNull);
      }
    });
    test('folder not executable', () {
      expect(findExecutableSync('test', ['.']), isNull);
    });

    test('various', () {
      expect(scriptToCommands('''
     a ^
     
     b
    '''), ['a', 'b']);
      expect(scriptToCommands('''
     a ^
     b
     
     c
    '''), ['a b', 'c']);
      expect(scriptToCommands('''
a ^
 "b" ^
 "c" d
e
    '''), ['a "b" "c" d', 'e']);
    });

    test('streamSinkWrite', () async {
      var controller = ShellLinesController(encoding: systemEncoding);
      controller.writeln('t');
      controller.writeln('éà');
      controller.writeln('你好');
      controller.close();
      var list = await controller.stream.toList();
      if (!Platform.isWindows) {
        expect(list, ['t', 'éà', '你好']);
      } else {
        // Don't test other non supported characters
        expect(list.first, 't');
        expect(list[1], 'éà');
      }

      controller = ShellLinesController(encoding: utf8);
      controller.writeln('t');
      controller.writeln('éà');
      controller.writeln('你好');
      controller.close();
      expect(await controller.stream.toList(), ['t', 'éà', '你好']);
    });
  });
}
