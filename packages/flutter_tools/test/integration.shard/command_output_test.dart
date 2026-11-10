// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/features.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_utils.dart';

// This test file does not use [getLocalEngineArguments] because it is testing
// command output and not using cached artifacts.

void main() {
  testWithoutContext(
    'All development tools and deprecated commands are hidden and help text is not verbose',
    () async {
      final ProcessResult result = await processManager.run(<String>[flutterBin, '-h', '-v']);

      // Development tools.
      expect(result.stdout, isNot(contains('update-packages')));

      // Only printed by verbose tool.
      expect(result.stdout, isNot(contains('exiting with code 0')));
    },
  );

  testWithoutContext('Flutter help is shown with -? command line argument', () async {
    final ProcessResult result = await processManager.run(<String>[flutterBin, '-?']);

    // Development tools.
    expect(
      result.stdout,
      contains(
        'Run "flutter help <command>" for more information about a command.\n'
        'Run "flutter help -v" for verbose help output, including less commonly used options.',
      ),
    );
  });

  testWithoutContext('Flutter help is shown with /? command line argument', () async {
    final ProcessResult result = await processManager.run(<String>[flutterBin, '/?']);

    // Development tools.
    expect(
      result.stdout,
      contains(
        'Run "flutter help <command>" for more information about a command.\n'
        'Run "flutter help -v" for verbose help output, including less commonly used options.',
      ),
    );
  });

  testWithoutContext('flutter doctor is not verbose', () async {
    final ProcessResult result = await processManager.run(<String>[flutterBin, 'doctor', '-v']);

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  // Regression test for https://github.com/flutter/flutter/issues/124793
  testWithoutContext('flutter doctor is not verbose when preceded by a global flag', () async {
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      '--no-version-check',
      'doctor',
      '-v',
    ]);

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  testWithoutContext(
    'flutter help -v shows hidden options when preceded by a global flag',
    () async {
      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        '--no-version-check',
        'help',
        '-v',
      ]);

      // Only shown in verbose help.
      expect(result.stdout, contains('--local-engine'));

      // Only printed by verbose tool.
      expect(result.stdout, isNot(contains('exiting with code 0')));
    },
  );

  testWithoutContext('flutter doctor -vv super verbose', () async {
    final ProcessResult result = await processManager.run(<String>[flutterBin, 'doctor', '-vv']);

    // Check for message only printed in verbose mode.
    expect(result.stdout, contains('Shutdown hooks complete'));
  });

  testUsingContext('flutter config --list contains all features', () async {
    final ProcessResult result = await processManager.run(<String>[flutterBin, 'config', '--list']);

    // contains all of the experiments in features.dart
    expect(
      (result.stdout as String).split('\n'),
      containsAll(<Matcher>[
        for (final Feature feature in allConfigurableFeatures) contains(feature.configSetting),
      ]),
    );
  });

  testWithoutContext('flutter run --machine uses AppRunLogger', () async {
    final Directory directory = createResolvedTempDirectorySync(
      'flutter_run_test.',
    ).createTempSync('_flutter_run_test.')..createSync(recursive: true);

    try {
      directory.childFile('pubspec.yaml').writeAsStringSync('name: foo');
      directory.childDirectory('lib').childFile('main.dart').createSync(recursive: true);
      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        'run',
        '--show-test-device', // ensure command can fail to run and hit injection of correct logger.
        '--machine',
        '-v',
        '--no-resident',
      ], workingDirectory: directory.path);
      expect(result.stderr, isNot(contains('Oops; flutter has exited unexpectedly:')));
    } finally {
      tryToDelete(directory);
    }
  });

  testWithoutContext('flutter attach --machine uses AppRunLogger', () async {
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'attach',
      '--machine',
      '-v',
    ]);

    expect(
      result.stderr,
      contains('Target file'),
    ); // Target file not found, but different paths on Windows and Linux/macOS.
  });

  testWithoutContext('flutter --version --machine outputs JSON with flutterRoot', () async {
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      '--version',
      '--machine',
    ]);

    final versionInfo = json.decode(
      result.stdout
          .toString()
          .replaceAll('Building flutter tool...', '')
          .replaceAll('Waiting for another flutter command to release the startup lock...', '')
          .trim(),
    ) as Map<String, Object?>;

    expect(versionInfo, containsPair('flutterRoot', isNotNull));
  });

  testWithoutContext('A tool exit is thrown for an invalid debug-url in flutter attach', () async {
    // This test is almost exactly like the next one; update them together please.
    final String helloWorld = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      '--show-test-device',
      'attach',
      '-d',
      'flutter-tester',
      '--debug-url=http://127.0.0.1:3333*/',
    ], workingDirectory: helloWorld);

    expect(
      result,
      const ProcessResultMatcher(
        exitCode: 1,
        stderrPattern: 'Invalid `--debug-url`: http://127.0.0.1:3333*/',
      ),
    );
  });

  testWithoutContext('--debug-uri is an alias for --debug-url', () async {
    // This text is exactly the same as the previous one but with a "l" turned to an "i".
    final String helloWorld = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      '--show-test-device',
      'attach',
      '-d',
      'flutter-tester',
      '--debug-uri=http://127.0.0.1:3333*/', // "uri" not "url"
    ], workingDirectory: helloWorld);

    expect(
      result,
      const ProcessResultMatcher(
        exitCode: 1,
        // _"url"_ not "uri"!
        stderrPattern: 'Invalid `--debug-url`: http://127.0.0.1:3333*/',
      ),
    );
  });

  testWithoutContext('will load bootstrap script before starting', () async {
    final File bootstrap = fileSystem.file(
      fileSystem.path.join(
        getFlutterRoot(),
        'bin',
        'internal',
        platform.isWindows ? 'bootstrap.bat' : 'bootstrap.sh',
      ),
    );

    try {
      bootstrap.writeAsStringSync('echo TESTING 1 2 3');
      final ProcessResult result = await processManager.run(<String>[flutterBin]);

      expect(result.stdout, contains('TESTING 1 2 3'));
    } finally {
      bootstrap.deleteSync();
    }
  });

  testWithoutContext('flutter attach does not support --release', () async {
    final String helloWorld = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      '--show-test-device',
      'attach',
      '--release',
    ], workingDirectory: helloWorld);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Could not find an option named "--release"'));
  });

  testWithoutContext('flutter can report crashes', () async {
    final ProcessResult result = await processManager.run(
      <String>[flutterBin, 'update-packages', '--crash'],
      environment: <String, String>{'BOT': 'false'},
    );

    expect(result.exitCode, isNot(0));
    expect(
      result.stderr,
      contains(
        'Oops; flutter has exited unexpectedly: "Bad state: test crash please ignore.".\n'
        'A crash report has been written to',
      ),
    );
  });

  testWithoutContext('flutter supports trailing args', () async {
    final String helloWorld = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'test',
      'test/hello_test.dart',
      '-r',
      'json',
    ], workingDirectory: helloWorld);

    expect(result, const ProcessResultMatcher());
    expect(result.stderr, isEmpty);
  });

  // Regression test for https://github.com/flutter/flutter/issues/195791.
  testWithoutContext('dart and flutter run from a git hook in a linked worktree preserve flutter.version.json and caller GIT_* environment', () async {
    final Directory flutterRoot = fileSystem.directory(getFlutterRoot());
    final String dartBin = fileSystem.path.join(
      flutterRoot.path,
      'bin',
      platform.isWindows ? 'dart.bat' : 'dart',
    );
    final Directory cacheDir = flutterRoot.childDirectory('bin').childDirectory('cache');
    final File flutterVersionJson = cacheDir.childFile('flutter.version.json');
    final File flutterToolsStamp = cacheDir.childFile('flutter_tools.stamp');

    if (!flutterVersionJson.existsSync() || !flutterToolsStamp.existsSync()) {
      final ProcessResult initResult = await processManager.run(<String>[flutterBin, '--version']);
      expect(initResult, const ProcessResultMatcher());
    }
    final String initialVersionJson = flutterVersionJson.readAsStringSync();
    final String initialToolsStamp = flutterToolsStamp.readAsStringSync();

    final Directory tempDir = createResolvedTempDirectorySync('git_hook_worktree_test.');
    try {
      final Directory demoDir = tempDir.childDirectory('demo')..createSync();
      for (final command in <List<String>>[
        <String>['git', 'init', '-q'],
        <String>['git', 'config', 'user.email', 'test@example.com'],
        <String>['git', 'config', 'user.name', 'Test User'],
      ]) {
        expect(
          await processManager.run(command, workingDirectory: demoDir.path),
          const ProcessResultMatcher(),
        );
      }

      demoDir.childFile('pubspec.yaml').writeAsStringSync('''
name: demo
environment:
  sdk: ^3.8.0
dependencies:
  sky_engine:
    sdk: flutter
''');
      expect(
        await processManager.run(<String>[
          'git',
          'add',
          'pubspec.yaml',
        ], workingDirectory: demoDir.path),
        const ProcessResultMatcher(),
      );
      expect(
        await processManager.run(<String>[
          'git',
          'commit',
          '-q',
          '-m',
          'init',
        ], workingDirectory: demoDir.path),
        const ProcessResultMatcher(),
      );

      final Directory worktreeDir = tempDir.childDirectory('demo-wt');
      expect(
        await processManager.run(<String>[
          'git',
          'worktree',
          'add',
          '-q',
          worktreeDir.path,
        ], workingDirectory: demoDir.path),
        const ProcessResultMatcher(),
      );

      final File hookEnvOutput = tempDir.childFile('hook_env.json');
      final File dumpEnvScript = tempDir.childFile('dump_git_env.dart')
        ..writeAsStringSync('''
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final gitVars = <String, String>{
    for (final MapEntry(:key, :value) in Platform.environment.entries)
      if (key.toUpperCase().startsWith('GIT_')) key.toUpperCase(): value,
  };
  File(args.single).writeAsStringSync(jsonEncode(gitVars));
}
''');

      final String posixDartBin = dartBin.replaceAll(r'\', '/');
      final String posixDumpScript = dumpEnvScript.path.replaceAll(r'\', '/');
      final String posixHookEnvOutput = hookEnvOutput.path.replaceAll(r'\', '/');
      final Directory hooksDir = worktreeDir.childDirectory('hooks')..createSync();
      final File preCommitHook = hooksDir.childFile('pre-commit')
        ..writeAsStringSync('''
#!/bin/sh
set -e
"$posixDartBin" --version
"$posixDartBin" "$posixDumpScript" "$posixHookEnvOutput"
''');
      if (!platform.isWindows) {
        expect(
          processManager.runSync(<String>['chmod', '+x', preCommitHook.path]),
          const ProcessResultMatcher(),
        );
      }

      expect(
        await processManager.run(<String>[
          'git',
          '-c',
          'core.hooksPath=hooks',
          'commit',
          '-q',
          '--allow-empty',
          '-m',
          'trigger',
        ], workingDirectory: worktreeDir.path),
        const ProcessResultMatcher(),
      );

      expect(
        flutterVersionJson.existsSync(),
        isTrue,
        reason: 'bin/cache/flutter.version.json must not be deleted by dart in a git hook',
      );
      expect(flutterVersionJson.readAsStringSync(), initialVersionJson);
      expect(flutterToolsStamp.readAsStringSync(), initialToolsStamp);

      // Verify the user's dart process inside the hook still received GIT_DIR.
      expect(hookEnvOutput.existsSync(), isTrue);
      final Object? decodedHookEnv = json.decode(hookEnvOutput.readAsStringSync());
      if (decodedHookEnv is! Map<String, Object?>) {
        fail('Expected JSON object from hook environment dump, got $decodedHookEnv');
      }
      expect(
        decodedHookEnv['GIT_DIR'],
        isA<String>().having((String value) => value, 'GIT_DIR', contains('demo-wt')),
      );

      // Verify `dart pub get --offline` still resolves the Flutter SDK dependency.
      expect(
        await processManager.run(<String>[
          dartBin,
          'pub',
          'get',
          '--offline',
        ], workingDirectory: worktreeDir.path),
        const ProcessResultMatcher(),
      );

      // Verify all 7 git repository environment variables are isolated from
      // the wrapper's own git calls while remaining visible to user commands.
      final File directEnvOutput = tempDir.childFile('direct_env.json');
      final String demoGitDir = demoDir.childDirectory('.git').path;
      final String demoObjectsDir = fileSystem.path.join(demoGitDir, 'objects');
      final injectedGitVars = <String, String>{
        'GIT_DIR': demoGitDir,
        'GIT_INDEX_FILE': fileSystem.path.join(demoGitDir, 'index'),
        'GIT_WORK_TREE': demoDir.path,
        'GIT_OBJECT_DIRECTORY': demoObjectsDir,
        'GIT_ALTERNATE_OBJECT_DIRECTORIES': demoObjectsDir,
        'GIT_QUARANTINE_PATH': demoObjectsDir,
        'GIT_COMMON_DIR': demoGitDir,
      };
      final combinedEnv = <String, String>{...platform.environment, ...injectedGitVars};
      expect(
        await processManager.run(
          <String>[dartBin, dumpEnvScript.path, directEnvOutput.path],
          workingDirectory: worktreeDir.path,
          environment: combinedEnv,
        ),
        const ProcessResultMatcher(),
      );
      expect(flutterVersionJson.existsSync(), isTrue);
      expect(flutterToolsStamp.readAsStringSync(), initialToolsStamp);

      final Object? decodedDirectEnv = json.decode(directEnvOutput.readAsStringSync());
      if (decodedDirectEnv is! Map<String, Object?>) {
        fail('Expected JSON object from direct environment dump, got $decodedDirectEnv');
      }
      for (final MapEntry(:key, :value) in injectedGitVars.entries) {
        expect(decodedDirectEnv[key], value, reason: '$key should be preserved for user command');
      }

      final ProcessResult flutterResult = await processManager.run(
        <String>[flutterBin, '--version', '--machine'],
        workingDirectory: worktreeDir.path,
        environment: combinedEnv,
      );
      expect(flutterResult, const ProcessResultMatcher());
      expect(flutterResult.stderr, isNot(contains('Building flutter tool')));
      expect(flutterToolsStamp.readAsStringSync(), initialToolsStamp);
    } finally {
      try {
        if (!flutterVersionJson.existsSync() ||
            !flutterToolsStamp.existsSync() ||
            flutterVersionJson.readAsStringSync() != initialVersionJson ||
            flutterToolsStamp.readAsStringSync() != initialToolsStamp) {
          await processManager.run(<String>[flutterBin, '--version']);
        }
      } finally {
        tryToDelete(tempDir);
      }
    }
  });

  // Regression test for https://github.com/flutter/flutter/issues/75876.
  testWithoutContext('flutter create daemon produces output', () async {
    final Directory directory = createResolvedTempDirectorySync('create_daemon_test.');

    try {
      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        'create',
        '--no-pub',
        'daemon',
      ], workingDirectory: directory.path);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('Creating project daemon...'));
    } finally {
      tryToDelete(directory);
    }
  });
}
