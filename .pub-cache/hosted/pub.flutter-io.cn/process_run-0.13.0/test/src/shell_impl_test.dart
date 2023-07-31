@TestOn('vm')
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/common/import.dart';
import 'package:process_run/src/flutterbin_cmd.dart';
import 'package:process_run/src/user_config.dart';
import 'package:test/test.dart';

import '../echo_test.dart';
import '../shell_test.dart';

var expectedDartPaths = [
  if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
    getFlutterAncestorPath(dartSdkBinDirPath),
  dartSdkBinDirPath
];

List<String?> getExpectedPartPaths(ShellEnvironment environment) {
  return [
    if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
      getFlutterAncestorPath(dartSdkBinDirPath),
    dartSdkBinDirPath
  ];
}

void main() {
  group('Shell', () {
    test('user', () {
      if (Platform.isWindows) {
        expect(userHomePath, Platform.environment['USERPROFILE']);
        expect(userAppDataPath, Platform.environment['APPDATA']);
      } else {
        expect(userHomePath, Platform.environment['HOME']);
        expect(userAppDataPath, join(Platform.environment['HOME']!, '.config'));
      }
    });

    test('userHomePath', () {
      try {
        platformEnvironment = <String, String>{userHomePathEnvKey: 'test'};
        expect(userHomePath, 'test');
      } finally {
        platformEnvironment = null;
      }
    });

    test('userAppDataPath', () {
      try {
        platformEnvironment = <String, String>{userAppDataPathEnvKey: 'test'}
          ..addAll(Platform.environment);
        expect(userAppDataPath, 'test');

        platformEnvironment = <String, String>{userHomePathEnvKey: 'test'};
        expect(userAppDataPath, join('test', '.config'));
      } finally {
        platformEnvironment = null;
      }
    });

    test('null HOME', () async {
      try {
        var env = Map<String, String>.from(platformEnvironment)
          ..remove('HOME')
          ..remove('USERPROFILE')
          ..remove('APPDATA');
        platformEnvironment = env;
        expect(userHomePath, '~');
        expect(userAppDataPath, join('~', '.config'));
        // echo differs on windows
        var firstLine =
            (await run("echo 'Hello world'")).first.stdout.toString().trim();
        if (Platform.isWindows) {
          // We have both on windows depending on the shell used
          expect(['"Hello world"', 'Hello world'], contains(firstLine));
        } else {
          expect(firstLine, 'Hello world');
        }
      } finally {
        platformEnvironment = null;
      }
    });

    String getTestAbsPath() => Platform.isWindows ? r'C:\temp' : '/temp';
    String getTestHomeRelPath() => Platform.isWindows ? r'~\temp' : '~/temp';

    var configFileEmptyPath = 'test/data/test_env3_empty.yaml';

    test('userEnvironment in dart context', () async {
      try {
        platformEnvironment = newEnvNoOverride();
        expect(userPaths,
            getExpectedPartPaths(shellEnvironment as ShellEnvironment));
      } finally {
        platformEnvironment = null;
      }
    });

    var localFlutterExecutablePath = flutterExecutablePath;
    test('userEnvironment in flutter context', () async {
      try {
        var flutterBinDirPath = dirname(localFlutterExecutablePath!);
        platformEnvironment = newEnvNoOverride()
          ..paths.prepend(flutterBinDirPath);

        // '/opt/app/flutter/dev/flutter/bin',
        // '/opt/app/flutter/dev/flutter/bin/cache/dart-sdk/bin'
        if (dartSdkBinDirPath.contains(flutterBinDirPath)) {
          expect(userPaths,
              [dirname(localFlutterExecutablePath), dartSdkBinDirPath]);
        } else {
          expect(userPaths,
              [dartSdkBinDirPath, dirname(localFlutterExecutablePath)]);
        }
      } finally {
        platformEnvironment = null;
      }
    }, skip: localFlutterExecutablePath == null);

    test('userEnvironment', () async {
      try {
        var filePath =
            join('.dart_tool', 'process_run', 'test', 'user_env', 'env.yaml');
        resetUserConfig();
        await Directory(dirname(filePath)).create(recursive: true);
        await File(filePath).writeAsString('''
        path: test
        var:
          _TEKARTIK_PROCESS_RUN_TEST: 1
          $localEnvFilePathEnvKey: $configFileEmptyPath
        ''');
        platformEnvironment = <String, String>{userEnvFilePathEnvKey: filePath};
        // expect(getUserEnvFilePath(shellEnvironment), filePath);
        expect(userPaths, [
          if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
            getFlutterAncestorPath(dartSdkBinDirPath),
          dartSdkBinDirPath,
          'test',
        ]);
        expect(userEnvironment['_TEKARTIK_PROCESS_RUN_TEST'], '1');

        resetUserConfig();
        await Directory(dirname(filePath)).create(recursive: true);
        await File(filePath).writeAsString('''
        
        path:
          - test
          - '${getTestHomeRelPath()}'
        var:
          - _TEKARTIK_PROCESS_RUN_TEST: '~'
        ''');
        platformEnvironment = <String, String>{
          userEnvFilePathEnvKey: filePath,
          localEnvFilePathEnvKey: configFileEmptyPath,
          userHomePathEnvKey: getTestAbsPath()
        };
        // expect(getUserEnvFilePath(shellEnvironment), filePath);
        expect(userPaths, [
          if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
            getFlutterAncestorPath(dartSdkBinDirPath),
          dartSdkBinDirPath,
          'test',
          join(userHomePath, 'temp'),
        ]);
        expect(userEnvironment['_TEKARTIK_PROCESS_RUN_TEST'], '~');

        resetUserConfig();
        platformEnvironment = <String, String>{userEnvFilePathEnvKey: filePath}
          ..addAll(Platform.environment);
        expect(userPaths, containsAll(['test', join(userHomePath, 'temp')]));
        expect(userEnvironment['_TEKARTIK_PROCESS_RUN_TEST'], '~');
      } finally {
        platformEnvironment = null;
      }
    });

    test('missing user override for dart and dart binaries', () async {
      try {
        resetUserConfig();

        // empty environment
        platformEnvironment = <String, String>{
          userEnvFilePathEnvKey: configFileEmptyPath,
          localEnvFilePathEnvKey: configFileEmptyPath
        };

        var dartBinDir = dirname(dartExecutable!);
        var flutterDir = getFlutterAncestorPath(dartSdkBinDirPath);
        expect(userPaths, [
          if (flutterDir != null) flutterDir,
          dartBinDir,
        ]);
        expect(dirname((await which('dart'))!), flutterDir ?? dartBinDir);
      } finally {
        platformEnvironment = null;
      }
    });

    test('user env in shell', () async {
      try {
        var filePath = join('.dart_tool', 'process_run', 'test',
            'user_env_in_shell', 'env.yaml');
        resetUserConfig();
        await Directory(dirname(filePath)).create(recursive: true);
        await File(filePath).writeAsString('''
        path: test
        var:
          _TEKARTIK_PROCESS_RUN_TEST: 1
        ''', flush: true);
        platformEnvironment = <String, String>{userEnvFilePathEnvKey: filePath}
          ..addAll(Platform.environment);
        expect(userEnvironment['_TEKARTIK_PROCESS_RUN_TEST'], '1');

        var shell = Shell(verbose: false);
        var result = (await shell.run('$echo --stdout-env PATH'))
            .first
            .stdout
            .toString()
            .trim();
        expect(result, isNotEmpty);

        result =
            (await shell.run('$echo --stdout-env _dummy_that_will_never_exist'))
                .first
                .stdout
                .toString()
                .trim();
        expect(result, isEmpty);

        result =
            (await shell.run('$echo --stdout-env _TEKARTIK_PROCESS_RUN_TEST'))
                .first
                .stdout
                .toString()
                .trim();
        // Default environment is user environment
        expect(result, '1');

        shell = Shell(
            verbose: false,
            environment: platformEnvironment,
            includeParentEnvironment: false);
        result =
            (await shell.run('$echo --stdout-env _TEKARTIK_PROCESS_RUN_TEST'))
                .first
                .stdout
                .toString()
                .trim();
        expect(result, isEmpty);
        shell = Shell(
            verbose: false,
            environment: userEnvironment,
            includeParentEnvironment: false);
        result =
            (await shell.run('$echo --stdout-env _TEKARTIK_PROCESS_RUN_TEST'))
                .first
                .stdout
                .toString()
                .trim();
        expect(result, '1');
        shell = Shell(
            verbose: false,
            environment: shellEnvironment,
            includeParentEnvironment: false);
        result =
            (await shell.run('$echo --stdout-env _TEKARTIK_PROCESS_RUN_TEST'))
                .first
                .stdout
                .toString()
                .trim();
        expect(result, '1');
        shell = Shell(verbose: true, environment: <String, String>{
          '_TEKARTIK_PROCESS_RUN_TEST': '78910'
        });

        try {
          var lines = (await shell.run(
            '$echo --stdout-env _TEKARTIK_PROCESS_RUN_TEST',
          ))
              .outLines;
          result = lines.last;
          expect(result, '78910', reason: lines.join('\n'));
        } catch (e) {
          // This could fail on windows in some shell
          if (!Platform.isWindows) {
            rethrow;
          } else {
            stderr.writeln('minimal env experiment failing on widows $e');
          }
        }
      } finally {
        platformEnvironment = null;
      }
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('environment_vars', () async {
      String? linuxEnvCommand;

      if (Platform.isLinux) {
        linuxEnvCommand = shellArgument(whichSync('env')!);
      }
      expect(shellEnvironment, userEnvironment);
      userConfig = UserConfig(vars: <String, String>{'test': '1'});
      expect(userEnvironment['test'], '1');
      expect(shellEnvironment['test'], '1');

      // expect(platformEnvironment, isNot({'test': '1'}));
      //TODO test on other platform
      if (Platform.isLinux) {
        var out = (await Shell(verbose: false).run('$linuxEnvCommand'))
            .map((result) => result.stdout.toString())
            .join('\n');
        expect(out, contains('test=1'));
      } else if (Platform.isWindows) {
        try {
          //TODO test on other platform
          var out = (await Shell(verbose: false).run('echo test=%test%'))
              .map((result) => result.stdout.toString())
              .join('\n');
          expect(out, contains('test=1'));
        } on TestFailure catch (e) {
          stderr.writeln('%var% seems to start failing $e\n'
              '...to investigate or simple drop as it is a windows inconsistency');
        }
      }
      userConfig = UserConfig(vars: <String, String>{'test': '2'});
      expect(userEnvironment['test'], '2');
      expect(shellEnvironment['test'], '2');
    });

    test('getUserPaths', () async {
      expect(getUserPaths(userEnvironment), contains(dartSdkBinDirPath));
    });
  });
}
