@TestOn('vm')
library process_run.test.src_user_config_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/src/common/constant.dart';
import 'package:process_run/src/shell_utils.dart';
import 'package:process_run/src/user_config.dart';
import 'package:test/test.dart';

import 'shell_test.dart';
import 'src/shell_impl_test.dart';

void main() {
  group('src_user_config', () {
    var dummyEnvPath1 = join('test', 'data', 'test_env1.yaml_dummy');
    var dummyEnvPath2 = join('test', 'data', 'test_env2.yaml_dummy');
    test('dummy_file', () async {
      //print(a);
      var path1 = dummyEnvPath1;
      var path2 = dummyEnvPath2;
      var userConfig = getUserConfig(<String, String>{
        userEnvFilePathEnvKey: path1,
        localEnvFilePathEnvKey: path2
      });
      expect(userConfig.vars, {
        'TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH': path1,
        'TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH': path2,
      });
      expect(userConfig.paths, [
        if (getFlutterAncestorPath(dartSdkBinDirPath) != null)
          getFlutterAncestorPath(dartSdkBinDirPath),
        dartSdkBinDirPath
      ]);

      // user only
      userConfig = getUserConfig(<String, String>{
        userEnvFilePathEnvKey: path2,
        // localEnvFilePathEnvKey: path
      });
      expect(userConfig.vars['TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH'], path2);

      // user only
      userConfig = getUserConfig(<String, String>{
        localEnvFilePathEnvKey: path1,
        userEnvFilePathEnvKey: path1
      });
      expect(
          userConfig.vars['TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH'], path1);
    });
    test('overriding local env file name', () {
      //print(a);
      var path =
          join('test', 'data', 'test_user_env1_local_env_file_override.yaml');
      var userConfig =
          getUserConfig(<String, String>{userEnvFilePathEnvKey: path});
      expect(userConfig.aliases['test'], 'test alias');
    });

    test('simple', () async {
      //print(a);
      var path = join('test', 'data', 'test_env1.yaml');
      var userConfig = getUserConfig(<String, String>{
        userEnvFilePathEnvKey: path,
        localEnvFilePathEnvKey: dummyEnvPath1
      });
      expect(userConfig.vars, {
        'TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH': path,
        'TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH': dummyEnvPath1,
        'test': '1',
      });
      expect(userConfig.paths,
          [...getExpectedPartPaths(newEnvNoOverride()), 'my_path']);
      var shEnv = ShellEnvironment.empty()
        ..paths.addAll(userConfig.paths)
        ..vars.addAll(userConfig.vars);
      expect(shEnv['TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH'], path);
      expect(shEnv['test'], '1');
      expect(
          shEnv['PATH'],
          [...expectedDartPaths, 'my_path']
              .join(Platform.isWindows ? ';' : ':'));
    });

    test('config no overload', () async {
      var env = Map<String, String>.from(platformEnvironment)
        ..[userEnvFilePathEnvKey] = dummyEnvPath1
        ..[localEnvFilePathEnvKey] = dummyEnvPath1;
      var userConfig = getUserConfig(env);

      expect(userConfig.vars['TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH'],
          dummyEnvPath1);
      expect(userConfig.vars['TEKARTIK_PROCESS_RUN_LOCAL_ENV_FILE_PATH'],
          dummyEnvPath1);
    });

    test('config order', () async {
      // User then local env then overriden local
      //print(a);
      var path = join('test', 'data', 'test_env1.yaml');
      var userConfig = getUserConfig(<String, String>{
        userEnvFilePathEnvKey: path,
        localEnvFilePathEnvKey: dummyEnvPath1
      });
      expect(userConfig.paths, [...expectedDartPaths, 'my_path']);
      userConfig = getUserConfig(<String, String>{
        userEnvFilePathEnvKey: dummyEnvPath1,
        localEnvFilePathEnvKey: path
      });
      expect(userConfig.paths, [
        'my_path',
        ...expectedDartPaths,
      ]);
    });

    test('userLoadConfigFile', () async {
      userConfig = UserConfig();

      //print(a);
      var path = join('test', 'data', 'test_env1.yaml');
      userLoadEnvFile(path);
      expect(userConfig.vars, {'test': '1', 'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
      userLoadEnvFile(path);
      // pointing out current bad (or expected hehavior when loading multiple files
      // TODO fix by compating the first items
      expect(userConfig.vars, {'test': '1', 'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
    });

    test('userLoadConfigMap', () async {
      userConfig = UserConfig();

      //print(a);
      userLoadConfigMap({
        'vars': {'test': '1'}
      });
      expect(userConfig.vars, {'test': '1', 'PATH': ''});
      expect(userConfig.paths, isEmpty);
      userLoadConfigMap({
        'path': ['my_path']
      });
      expect(userConfig.vars, {'test': '1', 'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
    });

    test('userLoadConfigMap(path)', () async {
      userConfig = UserConfig();

      userLoadConfigMap({
        'path': ['my_path']
      });
      expect(userConfig.vars, {'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
      userLoadConfigMap({
        'path': ['my_path']
      });
      expect(userConfig.vars, {'PATH': 'my_path'});
      expect(userConfig.paths, ['my_path']);
      userLoadConfigMap({
        'path': ['other_path']
      });
      expect(userConfig.vars, {
        'PATH': ['other_path', 'my_path'].join(envPathSeparator)
      });
      expect(userConfig.paths, ['other_path', 'my_path']);
      userLoadConfigMap({
        'path': ['other_path']
      });
      expect(userConfig.vars, {
        'PATH': ['other_path', 'my_path'].join(envPathSeparator)
      });
      expect(userConfig.paths, ['other_path', 'my_path']);
      userLoadConfigMap({'path': <Object?>[]});
      expect(userConfig.vars, {
        'PATH': ['other_path', 'my_path'].join(envPathSeparator)
      });
      expect(userConfig.paths, ['other_path', 'my_path']);
      userLoadConfigMap({
        'path': ['my_path']
      });
      expect(userConfig.paths, ['my_path', 'other_path', 'my_path']);
    });

    test('loadFromMap', () async {
      var config = loadFromMap({
        'var': {'test': 1}
      });
      expect(config.paths, <Object?>[]);
      expect(config.vars, {'test': '1'});
    });

    test('flutter ancestor', () async {
      expect(getFlutterAncestorPath(join('bin', 'cache', 'dart-sdk', 'bin')),
          'bin');
      expect(
          getFlutterAncestorPath(
              join('flutter', 'bin', 'cache', 'dart-sdk', 'bin')),
          join('flutter', 'bin'));
    });

    test('loadFromMap missing file', () async {
      var config = loadFromPath('dummy_file');
      expect(config.isEmpty, isTrue);
    });
  });
}
