// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/convert.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  late FileSystem fileSystem;
  late Environment environment;
  late TestTarget fooTarget;
  late TestTarget barTarget;
  late TestTarget fizzTarget;
  late TestTarget sharedTarget;
  late int fooInvocations;
  late int barInvocations;
  late int shared;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fooInvocations = 0;
    barInvocations = 0;
    shared = 0;

    /// Create various test targets.
    fooTarget =
        TestTarget((Environment environment) async {
            environment.buildDir.childFile('out')
              ..createSync(recursive: true)
              ..writeAsStringSync('hey');
            fooInvocations++;
          })
          ..name = 'foo'
          ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
          ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/out')]
          ..dependencies = <Target>[];
    barTarget =
        TestTarget((Environment environment) async {
            environment.buildDir.childFile('bar')
              ..createSync(recursive: true)
              ..writeAsStringSync('there');
            barInvocations++;
          })
          ..name = 'bar'
          ..inputs = const <Source>[Source.pattern('{BUILD_DIR}/out')]
          ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/bar')]
          ..dependencies = <Target>[];
    fizzTarget =
        TestTarget((Environment environment) async {
            throw Exception('something bad happens');
          })
          ..name = 'fizz'
          ..inputs = const <Source>[Source.pattern('{BUILD_DIR}/out')]
          ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/fizz')]
          ..dependencies = <Target>[fooTarget];
    sharedTarget =
        TestTarget((Environment environment) async {
            shared += 1;
          })
          ..name = 'shared'
          ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')];
    final artifacts = Artifacts.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: artifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
    fileSystem.file('foo.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    fileSystem.file('pubspec.yaml').createSync();
  });

  testWithoutContext('build invalidates when outputs are added or removed', () async {
    final fileSystem = MemoryFileSystem.test();
    final Directory buildDir = fileSystem.systemTempDirectory.childDirectory('BuildDirectory');
    final environment = Environment.test(
      fileSystem.currentDirectory,
      buildDir: buildDir,
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );

    // A unique hash of this build's particular environment. See class [Environment].
    const buildPrefix = '6666cd76f96956469e7be39d750cc7d9';

    final File txt1 = buildDir.childDirectory(buildPrefix).childFile('1.txt')
      ..createSync(recursive: true);
    final File txt2 = buildDir.childDirectory(buildPrefix).childFile('2.txt')
      ..createSync(recursive: true);

    // Outputs added
    var allFilesTarget = TestTarget((Environment environment) async {})
      ..name = 'allTextFiles'
      ..outputs = const <Source>[
        Source.pattern('{BUILD_DIR}/1.txt'),
        Source.pattern('{BUILD_DIR}/2.txt'),
      ]
      ..dependencies = <Target>[];

    final testLogger = BufferLogger.test();
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem, logger: testLogger);
    BuildResult result = await buildSystem.build(allFilesTarget, environment);
    expect(result.success, true);
    expect(
      testLogger.traceText,
      contains(
        'InvalidatedReasonKind.outputSetAddition: The following outputs were added to the output set: '
        '${txt1.path},'
        '${txt2.path}',
      ),
    );

    testLogger.clear();
    expect(testLogger.traceText, isEmpty);

    // No change
    allFilesTarget = TestTarget((Environment environment) async {})
      ..name = 'allTextFiles'
      ..outputs = const <Source>[
        Source.pattern('{BUILD_DIR}/1.txt'),
        Source.pattern('{BUILD_DIR}/2.txt'),
      ]
      ..dependencies = <Target>[];
    result = await buildSystem.build(allFilesTarget, environment);
    expect(result.success, true);
    expect(testLogger.traceText, contains('Skipping target: allTextFiles'));
    expect(testLogger.traceText, isNot(contains('InvalidatedReasonKind')));

    testLogger.clear();
    expect(testLogger.traceText, isEmpty);

    // Output removed
    allFilesTarget = TestTarget((Environment environment) async {})
      ..name = 'allTextFiles'
      ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/1.txt')]
      ..dependencies = <Target>[];
    result = await buildSystem.build(allFilesTarget, environment);
    expect(result.success, true);
    expect(
      testLogger.traceText,
      contains(
        'allTextFiles: Starting due to {InvalidatedReasonKind.outputSetRemoval: The following outputs were removed from the output set: '
        '${txt2.path}',
      ),
    );
  });

  testWithoutContext('Does not throw exception if asked to build with missing inputs', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);

    // Delete required input file.
    fileSystem.file('foo.dart').deleteSync();
    final BuildResult buildResult = await buildSystem.build(fooTarget, environment);

    expect(buildResult.hasException, false);
  });

  testWithoutContext(
    'Does not throw exception if it does not produce a specified output',
    () async {
      final BuildSystem buildSystem = setUpBuildSystem(fileSystem);

      // This target is document as producing foo.dart but does not actually
      // output this value.
      final Target badTarget = TestTarget((Environment environment) async {})
        ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
        ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/out')];
      final BuildResult result = await buildSystem.build(badTarget, environment);

      expect(result.hasException, false);
    },
  );

  testWithoutContext('Saves a stamp file with inputs and outputs', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    await buildSystem.build(fooTarget, environment);
    final File stampFile = fileSystem.file('${environment.buildDir.path}/foo.stamp');

    expect(stampFile, exists);

    final Map<String, Object?>? stampContents = castStringKeyedMap(
      json.decode(stampFile.readAsStringSync()),
    );

    expect(stampContents, containsPair('inputs', <Object>['/foo.dart']));
    expect(stampContents!.containsKey('buildKey'), false);
  });

  testWithoutContext('Saves a stamp file with inputs, outputs and build key', () async {
    fooTarget.buildKey = 'fooBuildKey';
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    await buildSystem.build(fooTarget, environment);
    final File stampFile = fileSystem.file('${environment.buildDir.path}/foo.stamp');

    expect(stampFile, exists);

    final Map<String, Object?>? stampContents = castStringKeyedMap(
      json.decode(stampFile.readAsStringSync()),
    );

    expect(stampContents, containsPair('inputs', <Object>['/foo.dart']));
    expect(stampContents, containsPair('buildKey', 'fooBuildKey'));
  });

  testWithoutContext('Creates a BuildResult with inputs and outputs', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    final BuildResult result = await buildSystem.build(fooTarget, environment);

    expect(result.inputFiles.single.path, '/foo.dart');
    expect(result.outputFiles.single.path, '${environment.buildDir.path}/out');
  });

  group('BuildResult.outputs filtering', () {
    final allFilesTarget = TestTarget((Environment environment) async {})
      ..name = 'allTextFiles'
      ..inputs = const <Source>[
        Source.pattern('{PROJECT_DIR}/*'),
        Source.pattern('{PROJECT_DIR}/*/*'),
      ]
      ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/out')]
      ..dependencies = <Target>[];
    late BuildSystem buildSystem;

    setUp(() {
      buildSystem = setUpBuildSystem(fileSystem);
    });

    testWithoutContext('normally would update when something has changed', () async {
      environment.projectDir.childFile('foo.dart').createSync();
      final BuildResult result = await buildSystem.build(allFilesTarget, environment);
      expect(
        result.inputFiles,
        contains(isA<File>().having((File f) => f.path, 'path', endsWith('foo.dart'))),
      );
    });

    testWithoutContext('ignores the .dart_tool directory', () async {
      environment.projectDir.childDirectory('.dart_tool').createSync();
      environment.projectDir.childDirectory('.dart_tool').childFile('IGNORE_ME.txt').createSync();
      final BuildResult result = await buildSystem.build(allFilesTarget, environment);
      expect(
        result.inputFiles,
        isNot(contains(isA<File>().having((File f) => f.path, 'path', endsWith('IGNORE_ME.txt')))),
      );
    });

    testWithoutContext('ignores files named .flutter-plugins', () async {
      environment.projectDir.childFile('.flutter-plugins').createSync();
      final BuildResult result = await buildSystem.build(allFilesTarget, environment);
      expect(
        result.inputFiles,
        isNot(
          contains(isA<File>().having((File f) => f.path, 'path', endsWith('.flutter-plugins'))),
        ),
      );
    });

    testWithoutContext('ignores files named .flutter-plugins-dependencies', () async {
      environment.projectDir.childFile('.flutter-plugins-dependencies').createSync();
      final BuildResult result = await buildSystem.build(allFilesTarget, environment);
      expect(
        result.inputFiles,
        isNot(
          contains(
            isA<File>().having(
              (File f) => f.path,
              'path',
              endsWith('.flutter-plugins-dependencies'),
            ),
          ),
        ),
      );
    });

    testWithoutContext('ignores files ending with .xcconfig', () async {
      environment.projectDir.childFile('foo.xcconfig').createSync();
      final BuildResult result = await buildSystem.build(allFilesTarget, environment);
      expect(
        result.inputFiles,
        isNot(contains(isA<File>().having((File f) => f.path, 'path', endsWith('.xcconfig')))),
      );
    });
  });

  testWithoutContext('Does not re-invoke build if stamp is valid', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);

    await buildSystem.build(fooTarget, environment);
    await buildSystem.build(fooTarget, environment);

    expect(fooInvocations, 1);
  });

  testWithoutContext('Re-invoke build if input is modified', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    await buildSystem.build(fooTarget, environment);

    fileSystem.file('foo.dart').writeAsStringSync('new contents');

    await buildSystem.build(fooTarget, environment);

    expect(fooInvocations, 2);
  });

  testWithoutContext('Re-invoke build if build key is modified', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    fooTarget.buildKey = 'old';

    await buildSystem.build(fooTarget, environment);

    fooTarget.buildKey = 'new';

    await buildSystem.build(fooTarget, environment);

    expect(fooInvocations, 2);
  });

  testWithoutContext('does not re-invoke build if input timestamp changes', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    await buildSystem.build(fooTarget, environment);

    // The file was previously empty so this does not modify it.
    fileSystem.file('foo.dart').writeAsStringSync('');
    await buildSystem.build(fooTarget, environment);

    expect(fooInvocations, 1);
  });

  testWithoutContext('does not re-invoke build if output timestamp changes', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    await buildSystem.build(fooTarget, environment);

    // This is the same content that the output file previously
    // contained.
    environment.buildDir.childFile('out').writeAsStringSync('hey');
    await buildSystem.build(fooTarget, environment);

    expect(fooInvocations, 1);
  });

  testWithoutContext('Re-invoke build if output is modified', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    await buildSystem.build(fooTarget, environment);

    environment.buildDir.childFile('out').writeAsStringSync('Something different');

    await buildSystem.build(fooTarget, environment);

    expect(fooInvocations, 2);
  });

  testWithoutContext('Runs dependencies of targets', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    barTarget.dependencies.add(fooTarget);

    await buildSystem.build(barTarget, environment);

    expect(fileSystem.file('${environment.buildDir.path}/bar'), exists);
    expect(fooInvocations, 1);
    expect(barInvocations, 1);
  });

  testWithoutContext('Only invokes shared dependencies once', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    fooTarget.dependencies.add(sharedTarget);
    barTarget.dependencies.add(sharedTarget);
    barTarget.dependencies.add(fooTarget);

    await buildSystem.build(barTarget, environment);

    expect(shared, 1);
  });

  testWithoutContext('Automatically cleans old outputs when build graph changes', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    final File preservedMacOSFile = environment.outputDir.childFile(
      'FlutterMacOS.framework/Versions/A/FlutterMacOS',
    );
    final File preservedIOSFile = environment.outputDir.childFile('Flutter.framework/Flutter');
    final testTarget =
        TestTarget((Environment environment) async {
            environment.buildDir.childFile('foo.out').createSync();
            preservedMacOSFile.createSync(recursive: true);
            preservedIOSFile.createSync(recursive: true);
          })
          ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
          ..outputs = const <Source>[
            Source.pattern('{BUILD_DIR}/foo.out'),
            kFlutterMacOSFrameworkBinarySource,
            kFlutterIOSFrameworkBinarySource,
          ];
    fileSystem.file('foo.dart').createSync();

    await buildSystem.build(testTarget, environment);

    expect(environment.buildDir.childFile('foo.out'), exists);
    expect(preservedMacOSFile, exists);
    expect(preservedIOSFile, exists);

    final testTarget2 =
        TestTarget((Environment environment) async {
            environment.buildDir.childFile('bar.out').createSync();
          })
          ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
          ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/bar.out')];

    await buildSystem.build(testTarget2, environment);

    expect(environment.buildDir.childFile('bar.out'), exists);
    expect(environment.buildDir.childFile('foo.out'), isNot(exists));
    expect(preservedMacOSFile, exists);
    expect(preservedIOSFile, exists);
  });

  testWithoutContext('Does not crash when filesystem and cache are out of sync', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    final testWithoutContextTarget =
        TestTarget((Environment environment) async {
            environment.buildDir.childFile('foo.out').createSync();
          })
          ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
          ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/foo.out')];
    fileSystem.file('foo.dart').createSync();

    await buildSystem.build(testWithoutContextTarget, environment);

    expect(environment.buildDir.childFile('foo.out'), exists);
    environment.buildDir.childFile('foo.out').deleteSync();

    final testWithoutContextTarget2 =
        TestTarget((Environment environment) async {
            environment.buildDir.childFile('bar.out').createSync();
          })
          ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
          ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/bar.out')];

    await buildSystem.build(testWithoutContextTarget2, environment);

    expect(environment.buildDir.childFile('bar.out'), exists);
    expect(environment.buildDir.childFile('foo.out'), isNot(exists));
  });

  testWithoutContext('Reruns build if stamp is corrupted', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    final testWithoutContextTarget =
        TestTarget((Environment environment) async {
            environment.buildDir.childFile('foo.out').createSync();
          })
          ..inputs = const <Source>[Source.pattern('{PROJECT_DIR}/foo.dart')]
          ..outputs = const <Source>[Source.pattern('{BUILD_DIR}/foo.out')];
    fileSystem.file('foo.dart').createSync();
    await buildSystem.build(testWithoutContextTarget, environment);

    // invalid JSON
    environment.buildDir.childFile('testWithoutContext.stamp').writeAsStringSync('{X');
    await buildSystem.build(testWithoutContextTarget, environment);

    // empty file
    environment.buildDir.childFile('testWithoutContext.stamp').writeAsStringSync('');
    await buildSystem.build(testWithoutContextTarget, environment);

    // invalid format
    environment.buildDir
        .childFile('testWithoutContext.stamp')
        .writeAsStringSync('{"inputs": 2, "outputs": 3}');
    await buildSystem.build(testWithoutContextTarget, environment);
  });

  testWithoutContext('handles a throwing build action without crashing', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    final BuildResult result = await buildSystem.build(fizzTarget, environment);

    expect(result.hasException, true);
  });

  testWithoutContext('Can describe itself with JSON output', () {
    environment.buildDir.createSync(recursive: true);

    expect(fooTarget.toJson(environment), <String, Object?>{
      'inputs': <Object>['/foo.dart'],
      'outputs': <Object>[fileSystem.path.join(environment.buildDir.path, 'out')],
      'dependencies': <Object>[],
      'name': 'foo',
      'stamp': fileSystem.path.join(environment.buildDir.path, 'foo.stamp'),
    });
  });

  testWithoutContext('Can find dependency cycles', () {
    final Target barTarget = TestTarget()..name = 'bar';
    final Target fooTarget = TestTarget()..name = 'foo';
    barTarget.dependencies.add(fooTarget);
    fooTarget.dependencies.add(barTarget);

    expect(() => checkCycles(barTarget), throwsA(isA<CycleException>()));
  });

  testWithoutContext(
    'Target with depfile dependency will not run twice without invalidation',
    () async {
      final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
      var called = 0;
      final target = TestTarget((Environment environment) async {
        environment.buildDir.childFile('example.d').writeAsStringSync('a.txt: b.txt');
        fileSystem.file('a.txt').writeAsStringSync('a');
        called += 1;
      })..depfiles = <String>['example.d'];
      fileSystem.file('b.txt').writeAsStringSync('b');

      await buildSystem.build(target, environment);

      expect(fileSystem.file('a.txt'), exists);
      expect(called, 1);

      // Second build is up to date due to depfile parse.
      await buildSystem.build(target, environment);

      expect(called, 1);
    },
  );

  testWithoutContext('Target with depfile dependency will not run twice without '
      'invalidation in incremental builds', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    var called = 0;
    final target = TestTarget((Environment environment) async {
      environment.buildDir.childFile('example.d').writeAsStringSync('a.txt: b.txt');
      fileSystem.file('a.txt').writeAsStringSync('a');
      called += 1;
    })..depfiles = <String>['example.d'];
    fileSystem.file('b.txt').writeAsStringSync('b');

    final BuildResult result = await buildSystem.buildIncremental(target, environment, null);

    expect(fileSystem.file('a.txt'), exists);
    expect(called, 1);

    // Second build is up to date due to depfile parse.
    await buildSystem.buildIncremental(target, environment, result);

    expect(called, 1);
  });

  testWithoutContext('output directory is an input to the build', () async {
    final environmentA = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('a'),
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
    final environmentB = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('b'),
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );

    expect(environmentA.buildDir.path, isNot(environmentB.buildDir.path));
  });

  testWithoutContext('Additional inputs do not change the build configuration', () async {
    final environmentA = Environment.test(
      fileSystem.currentDirectory,
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      inputs: <String, String>{'C': 'D'},
    );
    final environmentB = Environment.test(
      fileSystem.currentDirectory,
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      inputs: <String, String>{'A': 'B'},
    );

    expect(environmentA.buildDir.path, equals(environmentB.buildDir.path));
  });

  testWithoutContext(
    'A target with depfile dependencies can delete stale outputs on the first run',
    () async {
      final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
      var called = 0;
      final target = TestTarget((Environment environment) async {
        if (called == 0) {
          environment.buildDir.childFile('example.d').writeAsStringSync('a.txt c.txt: b.txt');
          fileSystem.file('a.txt').writeAsStringSync('a');
          fileSystem.file('c.txt').writeAsStringSync('a');
        } else {
          // On second run, we no longer claim c.txt as an output.
          environment.buildDir.childFile('example.d').writeAsStringSync('a.txt: b.txt');
          fileSystem.file('a.txt').writeAsStringSync('a');
        }
        called += 1;
      })..depfiles = const <String>['example.d'];
      fileSystem.file('b.txt').writeAsStringSync('b');

      await buildSystem.build(target, environment);

      expect(fileSystem.file('a.txt'), exists);
      expect(fileSystem.file('c.txt'), exists);
      expect(called, 1);

      // rewrite an input to force a rerun, expect that the old c.txt is deleted.
      fileSystem.file('b.txt').writeAsStringSync('ba');
      await buildSystem.build(target, environment);

      expect(fileSystem.file('a.txt'), exists);
      expect(fileSystem.file('c.txt'), isNot(exists));
      expect(called, 2);
    },
  );

  testWithoutContext('trackSharedBuildDirectory handles a missing .last_build_id', () {
    FlutterBuildSystem(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
    ).trackSharedBuildDirectory(environment, fileSystem, <String, File>{}, {});

    expect(environment.outputDir.childFile('.last_build_id'), exists);
    expect(
      environment.outputDir.childFile('.last_build_id').readAsStringSync(),
      '6666cd76f96956469e7be39d750cc7d9',
    );
  });

  testWithoutContext('trackSharedBuildDirectory handles a missing output dir', () {
    final environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('a/b/c/d'),
      artifacts: Artifacts.test(),
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
    FlutterBuildSystem(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
    ).trackSharedBuildDirectory(environment, fileSystem, <String, File>{}, {});

    expect(environment.outputDir.childFile('.last_build_id'), exists);
    expect(
      environment.outputDir.childFile('.last_build_id').readAsStringSync(),
      '5954e2278dd01e1c4e747578776eeb94',
    );
  });

  testWithoutContext(
    'trackSharedBuildDirectory does not modify .last_build_id when config is identical',
    () {
      environment.outputDir.childFile('.last_build_id')
        ..writeAsStringSync('6666cd76f96956469e7be39d750cc7d9')
        ..setLastModifiedSync(DateTime(1991, 8, 23));
      FlutterBuildSystem(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
      ).trackSharedBuildDirectory(environment, fileSystem, <String, File>{}, {});

      expect(
        environment.outputDir.childFile('.last_build_id').lastModifiedSync(),
        DateTime(1991, 8, 23),
      );
    },
  );

  testWithoutContext(
    'trackSharedBuildDirectory does not delete files when outputs.json is missing',
    () {
      environment.outputDir.childFile('.last_build_id').writeAsStringSync('foo');
      environment.buildDir.parent.childDirectory('foo').createSync(recursive: true);
      environment.outputDir.childFile('stale').createSync();
      FlutterBuildSystem(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
      ).trackSharedBuildDirectory(environment, fileSystem, <String, File>{}, {});

      expect(
        environment.outputDir.childFile('.last_build_id').readAsStringSync(),
        '6666cd76f96956469e7be39d750cc7d9',
      );
      expect(environment.outputDir.childFile('stale'), exists);
    },
  );

  testWithoutContext(
    'trackSharedBuildDirectory deletes files in outputs.json but not in current outputs',
    () {
      environment.outputDir.childFile('.last_build_id').writeAsStringSync('foo');
      final Directory otherBuildDir = environment.buildDir.parent.childDirectory('foo')
        ..createSync(recursive: true);
      final File staleFile = environment.outputDir.childFile('stale')..createSync();
      otherBuildDir
          .childFile('outputs.json')
          .writeAsStringSync(json.encode(<String>[staleFile.absolute.path]));
      FlutterBuildSystem(
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
      ).trackSharedBuildDirectory(environment, fileSystem, <String, File>{}, {});

      expect(
        environment.outputDir.childFile('.last_build_id').readAsStringSync(),
        '6666cd76f96956469e7be39d750cc7d9',
      );
      expect(environment.outputDir.childFile('stale'), isNot(exists));
    },
  );

  testWithoutContext('trackSharedBuildDirectory does not delete preserved outputs', () {
    environment.outputDir.childFile('.last_build_id').writeAsStringSync('foo');
    final Directory otherBuildDir = environment.buildDir.parent.childDirectory('foo')
      ..createSync(recursive: true);
    final File preservedFile = environment.outputDir.childFile('preserved')..createSync();
    otherBuildDir
        .childFile('outputs.json')
        .writeAsStringSync(json.encode(<String>[preservedFile.absolute.path]));
    FlutterBuildSystem(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      platform: FakePlatform(),
    ).trackSharedBuildDirectory(environment, fileSystem, <String, File>{}, {
      preservedFile.absolute.path,
    });

    expect(
      environment.outputDir.childFile('.last_build_id').readAsStringSync(),
      '6666cd76f96956469e7be39d750cc7d9',
    );
    expect(environment.outputDir.childFile('preserved'), exists);
  });

  testWithoutContext(
    'multiple builds to the same output directory do no leave stale artifacts',
    () async {
      final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
      final testEnvironmentDebug = Environment.test(
        fileSystem.currentDirectory,
        outputDir: fileSystem.directory('output'),
        defines: <String, String>{'config': 'debug'},
        artifacts: Artifacts.test(),
        processManager: FakeProcessManager.any(),
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
      );
      final testEnvironmentProfile = Environment.test(
        fileSystem.currentDirectory,
        outputDir: fileSystem.directory('output'),
        defines: <String, String>{'config': 'profile'},
        artifacts: Artifacts.test(),
        processManager: FakeProcessManager.any(),
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
      );

      final debugTarget = TestTarget((Environment environment) async {
        environment.outputDir.childFile('debug').createSync();
      })..outputs = const <Source>[Source.pattern('{OUTPUT_DIR}/debug')];
      final releaseTarget = TestTarget((Environment environment) async {
        environment.outputDir.childFile('release').createSync();
      })..outputs = const <Source>[Source.pattern('{OUTPUT_DIR}/release')];

      await buildSystem.build(debugTarget, testEnvironmentDebug);

      // Verify debug output was created
      expect(fileSystem.file('output/debug'), exists);

      await buildSystem.build(releaseTarget, testEnvironmentProfile);

      // Last build config is updated properly
      expect(testEnvironmentProfile.outputDir.childFile('.last_build_id'), exists);
      expect(
        testEnvironmentProfile.outputDir.childFile('.last_build_id').readAsStringSync(),
        'c20b3747fb2aa148cc4fd39bfbbd894f',
      );

      // Verify debug output removed
      expect(fileSystem.file('output/debug'), isNot(exists));
      expect(fileSystem.file('output/release'), exists);
    },
  );

  testWithoutContext('A target using canSkip can create a conditional output', () async {
    final BuildSystem buildSystem = setUpBuildSystem(fileSystem);
    final File bar = environment.buildDir.childFile('bar');
    final File foo = environment.buildDir.childFile('foo');

    // The target will write a file `foo`, but only if `bar` already exists.
    final target = TestTarget(
      (Environment environment) async {
        foo.writeAsStringSync(bar.readAsStringSync());
        environment.buildDir.childFile('example.d').writeAsStringSync('${foo.path}: ${bar.path}');
      },
      (Environment environment) {
        return !environment.buildDir.childFile('bar').existsSync();
      },
    )..depfiles = const <String>['example.d'];

    // bar does not exist, there should be no inputs/outputs.
    final BuildResult firstResult = await buildSystem.build(target, environment);

    expect(foo, isNot(exists));
    expect(firstResult.inputFiles, isEmpty);
    expect(firstResult.outputFiles, isEmpty);

    // bar is created, the target should be able to run.
    bar.writeAsStringSync('content-1');
    final BuildResult secondResult = await buildSystem.build(target, environment);

    expect(foo, exists);
    expect(secondResult.inputFiles.map((File file) => file.path), <String>[bar.path]);
    expect(secondResult.outputFiles.map((File file) => file.path), <String>[foo.path]);

    // bar is destroyed, foo is also deleted.
    bar.deleteSync();
    final BuildResult thirdResult = await buildSystem.build(target, environment);

    expect(foo, isNot(exists));
    expect(thirdResult.inputFiles, isEmpty);
    expect(thirdResult.outputFiles, isEmpty);
  });

  testWithoutContext('Build completes all dependencies before failing', () async {
    final fileSystem = MemoryFileSystem.test();
    final BuildSystem buildSystem = setUpBuildSystem(
      fileSystem,
      platform: FakePlatform(
        numberOfProcessors: 10, // Ensure the tool will process tasks concurrently.
      ),
    );
    final startB = Completer<void>();
    final startC = Completer<void>();
    final finishB = Completer<void>();

    final a = TestTarget((Environment environment) {
      throw StateError('Should not run');
    })..name = 'A';
    final b = TestTarget((Environment environment) async {
      startB.complete();
      await finishB.future;
      throw Exception('1');
    })..name = 'B';
    final c = TestTarget((Environment environment) {
      startC.complete();
      throw Exception('2');
    })..name = 'C';
    a.dependencies.addAll(<Target>[b, c]);

    final Future<BuildResult> pendingResult = buildSystem.build(a, environment);
    await startB.future;
    await startC.future;

    finishB.complete();

    final BuildResult result = await pendingResult;

    expect(result.success, false);
    expect(result.exceptions.keys, containsAll(<String>['B', 'C']));
  });
}

BuildSystem setUpBuildSystem(FileSystem fileSystem, {FakePlatform? platform, Logger? logger}) {
  return FlutterBuildSystem(
    fileSystem: fileSystem,
    logger: logger ?? BufferLogger.test(),
    platform: platform ?? FakePlatform(),
  );
}

class TestTarget extends Target {
  TestTarget([Future<void> Function(Environment environment)? build, this._canSkip])
    : _build = build ?? ((Environment environment) async {});

  final Future<void> Function(Environment environment) _build;

  final bool Function(Environment environment)? _canSkip;

  @override
  Future<bool> canSkip(Environment environment) async {
    if (_canSkip != null) {
      return _canSkip(environment);
    }
    return super.canSkip(environment);
  }

  @override
  Future<void> build(Environment environment) => _build(environment);

  @override
  var dependencies = <Target>[];

  @override
  var inputs = <Source>[];

  @override
  var depfiles = <String>[];

  @override
  var name = 'test';

  @override
  var outputs = <Source>[];

  @override
  String? buildKey;
}
