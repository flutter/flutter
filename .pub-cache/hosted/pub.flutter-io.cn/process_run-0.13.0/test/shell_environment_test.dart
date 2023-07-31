@TestOn('vm')
library process_run.test.shell_environment_test;

import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:test/test.dart';

import 'echo_test.dart';

void main() {
  var emptyEnv = ShellEnvironment.empty();
  var basicEnv = ShellEnvironment.empty();
  basicEnv.vars['VAR1'] = 'var1';
  basicEnv.paths.add('path1');
  basicEnv.aliases['alias1'] = 'command1';

  group('ShellEnvironment', () {
    test('empty', () {
      var prevEnv = shellEnvironment;
      expect(shellEnvironment, isNotEmpty);
      var env = ShellEnvironment.empty();
      try {
        shellEnvironment = env;
        expect(shellEnvironment, isEmpty);
        shellEnvironment = null;
        expect(shellEnvironment, prevEnv);
      } finally {
        shellEnvironment = prevEnv;
        expect(shellEnvironment, isNotEmpty);
      }
    });
    test('vars and paths name', () {
      var env = ShellEnvironment.empty();
      env.paths.addAll(['path1', 'path2']);
      env.vars['VAR1'] = 'var1';
      env.vars['PATH'] = 'dummy';

      expect(env, {
        'VAR1': 'var1',
        'PATH': (Platform.isWindows ? 'path1;path2' : 'path1:path2')
      });
    });

    test('vars', () {
      var env = ShellEnvironment.empty();
      env.vars['VAR1'] = 'var1';
      env.paths.add('path1');

      expect(env, {'VAR1': 'var1', 'PATH': 'path1'});
      env.vars.clear();
      env.vars.remove('PATH');
      expect(env, {'PATH': 'path1'});

      env.vars.addAll({'VAR2': 'var2', 'PATH': 'path2', 'VAR3': 'var3'});
      expect(env, {'PATH': 'path1', 'VAR2': 'var2', 'VAR3': 'var3'});
      env.vars.remove('VAR2');
      env.vars.remove('VAR4');
      expect(env, {
        'PATH': 'path1',
        'VAR3': 'var3',
      });
      env.paths.remove('path1');
      env.paths.remove('path2');
      expect(env, {
        'VAR3': 'var3',
      });
    });
    test('prepend', () {
      var env = ShellEnvironment.empty();
      env.paths.addAll(['path2', 'path3']);
      env.paths.prepend('path1');
      env.paths.remove('path3');

      expect(env, {
        envPathKey: ['path1', 'path2'].join(envPathSeparator)
      });
    });

    test('non empty paths', () {
      var env = ShellEnvironment(environment: {'PATH': 'test'});
      env.paths.addAll(['path2']);

      env.paths.prepend('path1');
      env.paths.addAll(['path3']);
      env.paths.remove('path3');

      expect(env, {
        envPathKey: ['path1', 'test', 'path2'].join(envPathSeparator)
      });
    });

    test('global vars ', () async {
      var prevEnv = shellEnvironment;
      expect(shellEnvironment, isNotEmpty);
      var shell = Shell(verbose: false);
      var env = ShellEnvironment()
        ..vars['TEST_PROCESS_RUN_VAR1'] = 'test_process_run_value1';

      var result = await getEchoEnv(shell);

      // expect(result, {});
      expect(result.vars['TEST_PROCESS_RUN_VAR1'], isNull);

      try {
        // Set globally
        shellEnvironment = env;

        // print(shellEnvironment);

        // Create the shell after
        var shell = Shell(verbose: false);
        var result = await getEchoEnv(shell);

        // expect(result, {});
        expect(result.vars['TEST_PROCESS_RUN_VAR1'], 'test_process_run_value1');
      } finally {
        shellEnvironment = prevEnv;
      }
    }); // not working

    test('local vars', () async {
      var env = ShellEnvironment()
        ..vars['TEST_PROCESS_RUN_VAR1'] = 'test_process_run_value1';
      var localShell = Shell(environment: env, verbose: false);
      var shell = Shell(verbose: false);

      var result = await getEchoEnv(shell);
      expect(result.vars['TEST_PROCESS_RUN_VAR1'], isNull);

      var resultWithParent = await getEchoEnv(localShell);
      expect(resultWithParent.vars['TEST_PROCESS_RUN_VAR1'],
          'test_process_run_value1');

      localShell = Shell(environment: env, includeParentEnvironment: false);
      var resultWithoutParent = await getEchoEnv(localShell);
      expect(resultWithoutParent.vars['TEST_PROCESS_RUN_VAR1'],
          'test_process_run_value1');
    });

    test('local one var', () async {
      try {
        var env = ShellEnvironment.empty()
          ..vars['TEST_PROCESS_RUN_VAR1'] = 'test_process_run_value1';
        var shell = Shell(environment: env, verbose: false);

        print(await getEchoEnv(shell));

        shell = Shell(
            environment: env,
            includeParentEnvironment: false,
            verbose: true); // This should be small
        var resultWithoutParent = await getEchoEnv(shell);
        print(resultWithoutParent);

        var result = await getEchoEnv(shell);

        // expect(result, {});
        expect(result.vars['TEST_PROCESS_RUN_VAR1'], 'test_process_run_value1');

        await shell.run('dart --version');
      } catch (e) {
        stderr.writeln('empty environment test error $e');
        stderr.writeln('could fail on CI');
      }
    });

    // ignore: non_constant_identifier_names
    var current_dir = 'current_dir';
    test('which', () async {
      var dart = 'dart';
      var env = ShellEnvironment.empty();
      expect(await env.which(dart), isNull);
      expect(await env.which(current_dir), isNull);
      env.paths.add('test/src');
      expect(await env.which(current_dir), isNotNull);

      env = ShellEnvironment();
      expect(await env.which(dart), isNotNull);
    });

    test('global path', () async {
      // Don't test if there is a global current_id
      if (whichSync(current_dir) != null) {
        stderr.writeln('Global current_dir found, skipping');
      }
      var prevEnv = shellEnvironment;
      expect(shellEnvironment, isNotEmpty);

      var shell = Shell();
      try {
        await shell.run(current_dir);
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }

      var newEnvironment = ShellEnvironment.empty()..paths.add('test/src');

      try {
        // Set globally
        shellEnvironment = newEnvironment;

        var shell = Shell();
        await shell.run(current_dir);
      } finally {
        shellEnvironment = prevEnv;
      }
    });
    test('local empty include parent', () async {
      var git = 'git';
      if (await which(git) != null) {
        var env = ShellEnvironment.empty();
        expect(await env.which(git), isNull);
        var shell = Shell(
            environment: env,
            includeParentEnvironment:
                false); // Shell(environment: env, includeParentEnvironment: false);

        try {
          await shell.run('git --version');
          fail('Should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }

        shell = Shell(environment: env, includeParentEnvironment: true);

        await shell.run('git --version');
      }
    },
        skip:
            true); // It does not seem to prevent calling git although not in the path
    test('equals', () async {
      expect(ShellEnvironment.empty(), ShellEnvironment.empty());
    });
    test('toJson', () async {
      expect(ShellEnvironment.empty().toJson(), {
        'paths': <String>[],
        'vars': <Object?, Object?>{},
        'aliases': <Object?, Object?>{}
      });
      expect(basicEnv.toJson(), {
        'paths': ['path1'],
        'vars': {'VAR1': 'var1'},
        'aliases': {'alias1': 'command1'}
      });
    });
    test('fromJson', () async {
      expect(
          ShellEnvironment.fromJson({
            'paths': ['path1'],
            'vars': {'VAR1': 'var1'},
            'aliases': {'alias1': 'command1'}
          }),
          basicEnv);
      expect(ShellEnvironment.fromJson({}), emptyEnv);
    });
    test('merge', () {
      var env = ShellEnvironment.empty();

      env.vars.addAll({'VAR1': 'var1', 'VAR2': 'value2'});
      env.paths.addAll(['path_fourth', 'path_second']);

      var envOther = ShellEnvironment.empty();

      envOther.vars.addAll({'VAR2': 'new_value2', 'VAR3': 'var3'});
      envOther.paths.addAll([
        'path_first',
        'path_second',
        'path_third',
      ]);
      env.merge(envOther);
      expect(env, {
        'VAR1': 'var1',
        'VAR2': 'new_value2',
        'PATH': ['path_first', 'path_second', 'path_third', 'path_fourth']
            .join(envPathSeparator),
        'VAR3': 'var3'
      });
    });
    test('path merge', () {
      var paths = ShellEnvironment().paths;
      paths.merge(paths);
      var env = ShellEnvironment.full(
          environment: shellEnvironment, includeParentEnvironment: true);
      paths = env.paths;
      paths.merge(paths);

      env = ShellEnvironment();
      paths = env.paths;
      paths.merge(paths);

      paths = ShellEnvironment.empty().paths;
      paths.add('1');
      paths.prepend('0');
      paths.add('2');
      paths.addAll(['3', '4']);
      expect(paths, ['0', '1', '2', '3', '4']);
      paths.insertAll(0, ['1', '4']);
      paths.addAll(paths);
      // Shoud be ignored
      paths.addAll(['3', '4']);
      expect(paths, ['1', '4', '0', '2', '3']);
      paths.merge(paths);
      expect(paths, ['1', '4', '0', '2', '3']);
    });
  });

  test('overriding', () async {
    var prevEnv = shellEnvironment;
    try {
      var env = ShellEnvironment()..paths.prepend('T1');
      shellEnvironment = env;
      expect(ShellEnvironment().paths.first, 'T1');
    } finally {
      shellEnvironment = prevEnv;
    }
  });
}

/// Better with non verbose shell.
Future<ShellEnvironment> getEchoEnv(Shell shell) async {
  return ShellEnvironment.fromJson(
      jsonDecode((await shell.run('$echo --all-env')).outLines.join()) as Map?);
}
