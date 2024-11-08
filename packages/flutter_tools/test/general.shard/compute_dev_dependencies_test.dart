// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/compute_dev_dependencies.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';

// For all of these examples, imagine the following package structure:
//
// /
//   /my_app
//     pubspec.yaml
//   /package_a
//     pubspec.yaml
//   /pacakge_b
//     pubspec.yaml
//   /package_c
//     pubspec.yaml
void main() {
  late BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
  });


  testUsingContext('no dev dependencies at all', () async {
    // Simulates the following:
    //
    // # /my_app/pubspec.yaml
    // name: my_app
    // dependencies:
    //   package_a:
    //
    // # /package_a/pubspec.yaml
    // name: package_a
    // dependencies:
    //   package_b:
    final ProcessManager processes = _dartPubDepsReturns('''
    {
      "root": "my_app",
      "packages": [
        {
          "name": "my_app",
          "kind": "root",
          "dependencies": [
            "package_a",
            "package_b"
          ],
          "directDependencies": [
            "package_a"
          ],
          "devDependencies": []
        },
        {
          "name": "package_a",
          "kind": "direct",
          "dependencies": [
            "package_b"
          ],
          "directDependencies": [
            "package_b"
          ]
        },
        {
          "name": "package_b",
          "kind": "transitive",
          "dependencies": [],
          "directDependencies": []
        }
      ]
    }''');

    final Set<String> dependencies = await computeExclusiveDevDependencies(
      processes,
      projectPath: _fakeProjectPath,
      logger: logger,
    );

    expect(
      dependencies,
      isEmpty,
      reason: 'There are no dev_dependencies of "my_app".',
    );
  });

  testUsingContext('dev dependency', () async {
    // Simulates the following:
    //
    // # /my_app/pubspec.yaml
    // name: my_app
    // dependencies:
    //   package_a:
    //
    // dev_dependencies:
    //   package_b:
    //
    // # /package_a/pubspec.yaml
    // name: package_a
    final ProcessManager processes = _dartPubDepsReturns('''
    {
      "root": "my_app",
      "packages": [
        {
          "name": "my_app",
          "kind": "root",
          "dependencies": [
            "package_a",
            "package_b"
          ],
          "directDependencies": [
            "package_a"
          ],
          "devDependencies": [
            "package_b"
          ]
        },
        {
          "name": "package_a",
          "kind": "direct",
          "dependencies": [],
          "directDependencies": []
        },
        {
          "name": "package_b",
          "kind": "dev",
          "dependencies": [],
          "directDependencies": []
        }
      ]
    }''');

    final Set<String> dependencies = await computeExclusiveDevDependencies(
      processes,
      projectPath: _fakeProjectPath,
      logger: logger,
    );

    expect(
      dependencies,
      <String>{'package_b'},
      reason: 'There is a single dev_dependency of my_app: package_b.',
    );
  });

  testUsingContext('dev used as a non-dev dependency transitively', () async {
    // Simulates the following:
    //
    // # /my_app/pubspec.yaml
    // name: my_app
    // dependencies:
    //   package_a:
    //
    // dev_dependencies:
    //   package_b:
    //
    // # /package_a/pubspec.yaml
    // name: package_a
    // dependencies:
    //   package_b:
    final ProcessManager processes = _dartPubDepsReturns('''
    {
      "root": "my_app",
      "packages": [
        {
          "name": "my_app",
          "kind": "root",
          "dependencies": [
            "package_a",
            "package_b"
          ],
          "directDependencies": [
            "package_a"
          ],
          "devDependencies": [
            "package_b"
          ]
        },
        {
          "name": "package_a",
          "kind": "direct",
          "dependencies": [
            "package_b"
          ],
          "directDependencies": [
            "package_b"
          ]
        },
        {
          "name": "package_b",
          "kind": "dev",
          "dependencies": [],
          "directDependencies": []
        }
      ]
    }''');

    final Set<String> dependencies = await computeExclusiveDevDependencies(
      processes,
      projectPath: _fakeProjectPath,
      logger: logger,
    );

    expect(
      dependencies,
      isEmpty,
      reason: 'There is a dev_dependency also used as a standard dependency',
    );
  });

  testUsingContext('combination of an included and excluded dev_dependency', () async {
    // Simulates the following:
    //
    // # /my_app/pubspec.yaml
    // name: my_app
    // dependencies:
    //   package_a:
    //
    // dev_dependencies:
    //   package_b:
    //   package_c:
    //
    // # /package_a/pubspec.yaml
    // name: package_a
    // dependencies:
    //   package_b:
    //
    // # /package_b/pubspec.yaml
    // name: package_b
    //
    // # /package_c/pubspec.yaml
    // name: package_c
    final ProcessManager processes = _dartPubDepsReturns('''
    {
      "root": "my_app",
      "packages": [
        {
          "name": "my_app",
          "kind": "root",
          "dependencies": [
            "package_a",
            "package_b"
          ],
          "directDependencies": [
            "package_a"
          ],
          "devDependencies": [
            "package_b",
            "package_c"
          ]
        },
        {
          "name": "package_a",
          "kind": "direct",
          "dependencies": [
            "package_b"
          ],
          "directDependencies": [
            "package_b"
          ]
        },
        {
          "name": "package_b",
          "kind": "dev",
          "dependencies": [
            "package_c"
          ],
          "directDependencies": [
            "package_c"
          ]
        },
        {
          "name": "package_c",
          "kind": "dev",
          "dependencies": [],
          "directDependencies": []
        }
      ]
    }''');

    final Set<String> dependencies = await computeExclusiveDevDependencies(
      processes,
      projectPath: _fakeProjectPath,
      logger: logger,
    );

    expect(
      dependencies,
      <String>{'package_c'},
      reason: 'package_b is excluded but package_c should not',
    );
  });

  testUsingContext('throws and logs on non-zero exit code', () async {
    final ProcessManager processes = _dartPubDepsFails(
      'Bad thing',
      exitCode: 1,
    );

    await expectLater(
      computeExclusiveDevDependencies(
        processes,
        projectPath: _fakeProjectPath,
        logger: logger,
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('dart pub deps --json failed'),
        ),
      ),
    );

    expect(logger.traceText, isEmpty);
  });

  testUsingContext('throws and logs on unexpected output type', () async {
    final ProcessManager processes = _dartPubDepsReturns(
      'Not JSON haha!',
    );

    await expectLater(
      computeExclusiveDevDependencies(
        processes,
        projectPath: _fakeProjectPath,
        logger: logger,
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('dart pub deps --json had unexpected output'),
        ),
      ),
    );

    expect(logger.traceText, contains('Not JSON haha'));
  });

  testUsingContext('throws and logs on invalid JSON', () async {
    final ProcessManager processes = _dartPubDepsReturns('''
    {
      "root": "my_app",
      "packages": [
        {
          "name": "my_app",
          "kind": "root",
          "dependencies": [
            "package_a",
            "package_b"
          ],
          "directDependencies": [
            1
          ],
          "devDependencies": []
        },
        {
          "name": "package_a",
          "kind": "direct",
          "dependencies": [
            "package_b"
          ],
          "directDependencies": [
            "package_b"
          ]
        },
        {
          "name": "package_b",
          "kind": "transitive",
          "dependencies": [],
          "directDependencies": []
        }
      ]
    }''');

    await expectLater(
      computeExclusiveDevDependencies(
        processes,
        projectPath: _fakeProjectPath,
        logger: logger,
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('dart pub deps --json had unexpected output'),
        ),
      ),
    );

    expect(
      logger.traceText,
      contains('"root": "my_app"'),
      reason: 'Stdout should include the JSON blob',
    );
  });
}

const String _fakeProjectPath = '/path/to/project';

ProcessManager _dartPubDepsReturns(String dartPubDepsOutput) {
  final String dartBinaryPath = globals.artifacts!.getArtifactPath(Artifact.engineDartBinary);
  return FakeProcessManager.list(<FakeCommand>[
    FakeCommand(
      command: <String>[dartBinaryPath, 'pub', 'deps', '--json'],
      stdout: dartPubDepsOutput,
      workingDirectory: _fakeProjectPath,
    ),
  ]);
}

ProcessManager _dartPubDepsFails(
  String dartPubDepsError, {
  required int exitCode,
}) {
  final String dartBinaryPath = globals.artifacts!.getArtifactPath(Artifact.engineDartBinary);
  return FakeProcessManager.list(<FakeCommand>[
    FakeCommand(
      command: <String>[dartBinaryPath, 'pub', 'deps', '--json'],
      exitCode: exitCode,
      stderr: dartPubDepsError,
      workingDirectory: _fakeProjectPath,
    ),
  ]);
}
