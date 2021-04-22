// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/features.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  testWithoutContext('All development tools and deprecated commands are hidden and help text is not verbose', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      '-h',
      '-v',
    ]);

    // Development tools.
    expect(result.stdout, isNot(contains('update-packages')));

    // Deprecated.
    expect(result.stdout, isNot(contains('make-host-app-editable')));

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  testWithoutContext('Flutter help is shown with -? command line argument', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      '-?',
    ]);

    // Development tools.
    expect(result.stdout, contains(
      'Run "flutter help <command>" for more information about a command.\n'
      'Run "flutter help -v" for verbose help output, including less commonly used options.'
    ));
  });

  testWithoutContext('flutter doctor is not verbose', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'doctor',
      '-v',
    ]);

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  testWithoutContext('flutter doctor -vv super verbose', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'doctor',
      '-vv',
    ]);

    // Check for message only printed in verbose mode.
    expect(result.stdout, contains('Running shutdown hooks'));
  });

  testWithoutContext('flutter config contains all features', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'config',
    ]);

    // contains all of the experiments in features.dart
    expect(result.stdout.split('\n'), containsAll(<Matcher>[
      for (final Feature feature in allFeatures)
        contains(feature.configSetting),
    ]));
  });

  testWithoutContext('flutter run --machine uses AppRunLogger', () async {
    final Directory directory = createResolvedTempDirectorySync('flutter_run_test.')
      .createTempSync('_flutter_run_test.')
      ..createSync(recursive: true);

    try {
      directory
        .childFile('pubspec.yaml')
        .writeAsStringSync('name: foo');
      directory
        .childFile('.packages')
        .writeAsStringSync('\n');
      directory
        .childDirectory('lib')
        .childFile('main.dart')
        .createSync(recursive: true);
      final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
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
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'attach',
      '--machine',
      '-v',
    ]);

    expect(result.stderr, contains('Target file')); // Target file not found, but different paths on Windows and Linux/macOS.
  });

  testWithoutContext('flutter --version --machine outputs JSON with flutterRoot', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      '--version',
      '--machine',
    ]);

    final Map<String, Object> versionInfo = json.decode(result.stdout
      .toString()
      .replaceAll('Building flutter tool...', '')
      .replaceAll('Waiting for another flutter command to release the startup lock...', '')
      .trim()) as Map<String, Object>;

    expect(versionInfo, containsPair('flutterRoot', isNotNull));
  });

  testWithoutContext('A tool exit is thrown for an invalid debug-uri in flutter attach', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final String helloWorld = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      '--show-test-device',
      'attach',
      '-d',
      'flutter-tester',
      '--debug-uri=http://127.0.0.1:3333*/',
    ], workingDirectory: helloWorld);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('Invalid `--debug-uri`: http://127.0.0.1:3333*/'));
  });

  testWithoutContext('will load bootstrap script before starting', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    final File bootstrap = fileSystem.file(fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'internal',
      platform.isWindows ? 'bootstrap.bat' : 'bootstrap.sh'),
    );

    try {
      bootstrap.writeAsStringSync('echo TESTING 1 2 3');
      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
      ]);

      expect(result.stdout, contains('TESTING 1 2 3'));
    } finally {
      bootstrap.deleteSync();
    }
  });

  testWithoutContext('Providing sksl bundle with missing file with tool exit', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final String helloWorld = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--bundle-sksl-path=foo/bar/baz.json', // This file does not exist.
    ], workingDirectory: helloWorld);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('No SkSL shader bundle found at foo/bar/baz.json'));
  });

  testWithoutContext('flutter attach does not support --release', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final String helloWorld = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      '--show-test-device',
      'attach',
      '--release',
    ], workingDirectory: helloWorld);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('Could not find an option named "release"'));
  });

  testWithoutContext('flutter can report crashes', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'update-packages',
      '--crash',
    ], environment: <String, String>{
      'BOT': 'false',
    });

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains(
      'Oops; flutter has exited unexpectedly: "Bad state: test crash please ignore.".\n'
      'A crash report has been written to',
    ));
  });
}
