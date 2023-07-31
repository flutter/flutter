@TestOn('vm')
library process_run.test.shell_run_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

import 'process_run_test_common.dart';

/// Truncate at max element.
String stringTruncate(String text, int len) {
  if (text.length <= len) {
    return text;
  }
  return text.substring(0, len);
}

void main() {
  group('shell_run', () {
    test('public', () {
      // ignore: unnecessary_statements
      getFlutterBinVersion;
      // ignore: unnecessary_statements
      getFlutterBinChannel;
      isFlutterSupported;
      isFlutterSupportedSync;
      dartVersion;
      dartChannel;
    });
    test('userEnvironment', () async {
      await run(
          'dart example/echo.dart ${shellArgument(stringTruncate(userEnvironment.toString(), 1500))}',
          verbose: false);

      expect(userEnvironment.length,
          greaterThanOrEqualTo(shellEnvironment.length));
      expect(userEnvironment.length,
          greaterThanOrEqualTo(platformEnvironment.length));
    });
    test('shellEnvironment', () async {
      await run(
          'dart example/echo.dart ${shellArgument(stringTruncate(shellEnvironment.toString(), 1500))}',
          verbose: false);
    });

    test('--version', () async {
      for (var bin in [
        // 'dartdoc', deprecated
        'dart',
        // 'pub', deprecated
        // 'dartfmt', deprecated
        // 'dart2js', deprecated
        // 'dartanalyzer', deprecated
      ]) {
        stdout.writeln('');
        var result = (await run('$bin --version',
                throwOnError: false, verbose: false, commandVerbose: true))
            .first;
        stdout.writeln('stdout: ${result.stdout.toString().trim()}');
        stdout.writeln('stderr: ${result.stderr.toString().trim()}');
        stdout.writeln('exitCode: ${result.exitCode}');
      }
    });
    test('dart compile', () async {
      var bin = 'build/native/info.exe';
      await Directory(dirname(bin)).create(recursive: true);
      await run('''
  dart compile exe example/info.dart -o $bin
  $bin
  ''');
    });
    test('throwOnError', () async {
      var verbose = false; // devWarning(true);
      var env = ShellEnvironment()
        ..aliases['echo'] = 'dart run ${shellArgument(echoScriptPath)}';

      // Prevent error to be thrown if exitCode is not 0
      var shell =
          Shell(throwOnError: false, verbose: verbose, environment: env);
      // This won't throw
      var exitCode = (await shell.run('echo --exit-code 1')).first.exitCode;
      expect(exitCode, 1);

      if (!Platform.isWindows) {
        try {
          await shell.run('dummy_command_BfwXVcrONHT3QIiMzNoS');
          fail('should fail');
        } on ShellException catch (e) {
          // ShellException(dummy_command_BfwXVcrONHT3QIiMzNoS, error: ProcessException: No such file or directory)
          // ignore: dead_code
          if (verbose) {
            print(e);
          }
        }
      } else {
        //TODO test on Windows
      }
      try {
        shell = Shell(environment: env, verbose: verbose);
        await shell.run('echo --exit-code 1');
        fail('should fail');
      } on ShellException catch (e) {
        // ShellException(dart run ./example/echo.dart --exit-code 1, exitCode 1)
        // ignore: dead_code
        if (verbose) {
          print(e);
        }
      }
    });
  });
}
