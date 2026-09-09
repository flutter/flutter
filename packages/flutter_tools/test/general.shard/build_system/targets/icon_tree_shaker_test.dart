// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/icon_tree_shaker.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:record_use/record_use.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/fakes.dart';

const _kTtfHeaderBytes = <int>[0, 1, 0, 0, 0, 15, 0, 128, 0, 3, 0, 112];

const inputPath = '/input/fonts/MaterialIcons-Regular.otf';
const outputPath = '/output/fonts/MaterialIcons-Regular.otf';
const relativePath = 'fonts/MaterialIcons-Regular.otf';

final whitespace = RegExp(r'\s+');

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;
  late Artifacts artifacts;
  late DevFSStringContent fontManifestContent;

  late String fontSubsetPath;
  late List<String> fontSubsetArgs;

  void writeRecordedUsesFile(
    String appDillPath, {
    required String content,
    String fileName = 'recorded_uses.json',
  }) {
    final File appDillFile = fileSystem.file(appDillPath);
    final Directory buildDir = appDillFile.parent;
    buildDir.childFile(fileName)
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  void resetFontSubsetInvocation({
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
    required CompleterIOSink stdinSink,
  }) {
    stdinSink.clear();
    processManager.addCommand(
      FakeCommand(
        command: fontSubsetArgs,
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
        stdin: stdinSink,
      ),
    );
  }

  setUp(() {
    processManager = FakeProcessManager.empty();
    fontManifestContent = DevFSStringContent(validFontManifestJson);
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    fontSubsetPath = artifacts.getArtifactPath(Artifact.fontSubset);

    fontSubsetArgs = <String>[fontSubsetPath, outputPath, inputPath];

    fileSystem.file(fontSubsetPath).createSync(recursive: true);
    fileSystem.file(inputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(_kTtfHeaderBytes);
  });

  Environment createEnvironment(Map<String, String> defines) {
    return Environment.test(
      fileSystem.directory('/icon_test')..createSync(recursive: true),
      defines: defines,
      artifacts: artifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
  }

  testWithoutContext('Prints error in debug mode environment', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'debug',
    });

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    expect(iconTreeShaker.enabled, false);
    expect(
      logger.errorText,
      contains(
        'Font subsetting is not supported in debug mode. The --tree-shake-icons flag will be ignored.',
      ),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Does not get enabled without font manifest', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final iconTreeShaker = IconTreeShaker(
      environment,
      null,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    expect(iconTreeShaker.enabled, false);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Gets enabled', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    expect(iconTreeShaker.enabled, true);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('No recorded uses file throws exception', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    final File input = fileSystem.file(inputPath)..createSync(recursive: true);
    input.writeAsBytesSync(_kTtfHeaderBytes);

    expect(
      iconTreeShaker.subsetFont(input: input, outputPath: outputPath, relativePath: relativePath),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Can subset a font', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );
    final stdinSink = CompleterIOSink();
    writeRecordedUsesFile(appDill.path, content: validRecordedUsesResult);
    resetFontSubsetInvocation(stdinSink: stdinSink);
    // Font starts out 2500 bytes long
    final File inputFont = fileSystem.file(inputPath)..writeAsBytesSync(List<int>.filled(2500, 0));
    // after subsetting, font is 1200 bytes long
    fileSystem.file(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1200, 0));
    bool subsetted = await iconTreeShaker.subsetFont(
      input: inputFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(stdinSink.getAndClear(), '59470\n');
    resetFontSubsetInvocation(stdinSink: stdinSink);

    expect(subsetted, true);
    subsetted = await iconTreeShaker.subsetFont(
      input: fileSystem.file(inputPath),
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsetted, true);
    expect(stdinSink.getAndClear(), '59470\n');
    expect(processManager, hasNoRemainingExpectations);
    expect(
      logger.statusText,
      contains(
        'Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 2500 to 1200 bytes (52.0% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.',
      ),
    );
  });

  testWithoutContext('Does not subset a non-supported font', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    final stdinSink = CompleterIOSink();
    writeRecordedUsesFile(appDill.path, content: validRecordedUsesResult);
    resetFontSubsetInvocation(stdinSink: stdinSink);

    final File notAFont = fileSystem.file('input/foo/bar.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('I could not think of a better string');
    final bool subsetted = await iconTreeShaker.subsetFont(
      input: notAFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsetted, false);
  });

  testWithoutContext('Does not subset an invalid ttf font', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    final stdinSink = CompleterIOSink();
    writeRecordedUsesFile(appDill.path, content: validRecordedUsesResult);
    resetFontSubsetInvocation(stdinSink: stdinSink);

    final File notAFont = fileSystem.file(inputPath)..writeAsBytesSync(<int>[0, 1, 2]);
    final bool subsetted = await iconTreeShaker.subsetFont(
      input: notAFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );

    expect(subsetted, false);
  });

  for (final platform in <TargetPlatform>[
    TargetPlatform.android_arm,
    TargetPlatform.web_javascript,
  ]) {
    testWithoutContext('Non-constant instances $platform', () async {
      final Environment environment = createEnvironment(<String, String>{
        kIconTreeShakerFlag: 'true',
        kBuildMode: 'release',
      });
      final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

      final iconTreeShaker = IconTreeShaker(
        environment,
        fontManifestContent,
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: artifacts,
        targetPlatform: platform,
      );

      writeRecordedUsesFile(appDill.path, content: recordedUsesWithInvalidResult);

      await expectLater(
        () => iconTreeShaker.subsetFont(
          input: fileSystem.file(inputPath),
          outputPath: outputPath,
          relativePath: relativePath,
        ),
        throwsToolExit(
          message:
              'Avoid non-constant invocations of IconData or try to build'
              ' again with --no-tree-shake-icons.',
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    });
  }

  testWithoutContext('Does not add 0x32 for non-web builds', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android_arm64,
    );

    writeRecordedUsesFile(appDill.path, content: validRecordedUsesResult);
    final stdinSink = CompleterIOSink();
    resetFontSubsetInvocation(stdinSink: stdinSink);
    expect(processManager.hasRemainingExpectations, isTrue);
    final File inputFont = fileSystem.file(inputPath)..writeAsBytesSync(List<int>.filled(2500, 0));
    fileSystem.file(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1200, 0));

    final bool result = await iconTreeShaker.subsetFont(
      input: inputFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );

    expect(result, isTrue);
    final List<String> codePoints = stdinSink.getAndClear().trim().split(whitespace);
    expect(codePoints, isNot(contains('optional:32')));

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Ensures 0x32 is included for web builds', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.web_javascript,
    );

    writeRecordedUsesFile(appDill.path, content: validRecordedUsesResult);
    final stdinSink = CompleterIOSink();
    resetFontSubsetInvocation(stdinSink: stdinSink);
    expect(processManager.hasRemainingExpectations, isTrue);
    final File inputFont = fileSystem.file(inputPath)..writeAsBytesSync(List<int>.filled(2500, 0));
    fileSystem.file(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1200, 0));

    final bool result = await iconTreeShaker.subsetFont(
      input: inputFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );

    expect(result, isTrue);
    final List<String> codePoints = stdinSink.getAndClear().trim().split(whitespace);
    expect(codePoints, containsAllInOrder(const <String>['59470', 'optional:32']));

    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Non-zero font-subset exit code', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);
    fileSystem.file(inputPath).createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    final stdinSink = CompleterIOSink();
    writeRecordedUsesFile(appDill.path, content: validRecordedUsesResult);
    resetFontSubsetInvocation(exitCode: -1, stdinSink: stdinSink);

    await expectLater(
      () => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('font-subset throws on write to sdtin', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    final stdinSink = CompleterIOSink(throwOnAdd: true);
    writeRecordedUsesFile(appDill.path, content: validRecordedUsesResult);
    resetFontSubsetInvocation(exitCode: -1, stdinSink: stdinSink);

    await expectLater(
      () => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Invalid font manifest', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    fontManifestContent = DevFSStringContent(invalidFontManifestJson);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    writeRecordedUsesFile(appDill.path, content: validRecordedUsesResult);

    await expectLater(
      () => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Allow system font fallback when fontFamily is null', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    // Valid manifest, just not using it.
    fontManifestContent = DevFSStringContent(validFontManifestJson);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    final stdinSink = CompleterIOSink();
    writeRecordedUsesFile(appDill.path, content: emptyRecordedUsesResult);
    resetFontSubsetInvocation(stdinSink: stdinSink);
    fileSystem.file(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1200, 0));
    // Does not throw
    await iconTreeShaker.subsetFont(
      input: fileSystem.file(inputPath),
      outputPath: outputPath,
      relativePath: relativePath,
    );

    expect(stdinSink.getAndClear(), '57415\n');
    expect(
      logger.traceText,
      contains(
        'Expected to find fontFamily for constant IconData with codepoint: '
        '59470, but found fontFamily: null. This usually means '
        'you are relying on the system font. Alternatively, font families in '
        'an IconData class can be provided in the assets section of your '
        'pubspec.yaml, or you are missing "uses-material-design: true".\n',
      ),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext(
    'Allow system font fallback when fontFamily is null and manifest is empty',
    () async {
      final Environment environment = createEnvironment(<String, String>{
        kIconTreeShakerFlag: 'true',
        kBuildMode: 'release',
      });
      final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

      // Nothing in font manifest
      fontManifestContent = DevFSStringContent(emptyFontManifestJson);

      final iconTreeShaker = IconTreeShaker(
        environment,
        fontManifestContent,
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: artifacts,
        targetPlatform: TargetPlatform.android,
      );

      writeRecordedUsesFile(appDill.path, content: emptyRecordedUsesResult);
      // Does not throw
      await iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      );

      expect(
        logger.traceText,
        contains(
          'Expected to find fontFamily for constant IconData with codepoint: '
          '59470, but found fontFamily: null. This usually means '
          'you are relying on the system font. Alternatively, font families in '
          'an IconData class can be provided in the assets section of your '
          'pubspec.yaml, or you are missing "uses-material-design: true".\n',
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext('Invalid recorded uses JSON', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    fontManifestContent = DevFSStringContent(validFontManifestJson);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    writeRecordedUsesFile(appDill.path, content: 'invalid json content');

    await expectLater(
      () async => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext(
    'Can subset a font using InstanceCreationReference with constant arguments',
    () async {
      final Environment environment = createEnvironment(<String, String>{
        kIconTreeShakerFlag: 'true',
        kBuildMode: 'release',
      });
      final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

      final iconTreeShaker = IconTreeShaker(
        environment,
        fontManifestContent,
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: artifacts,
        targetPlatform: TargetPlatform.android,
      );

      writeRecordedUsesFile(appDill.path, content: validRecordedUsesCreationResult);

      final stdinSink = CompleterIOSink();
      resetFontSubsetInvocation(stdinSink: stdinSink);

      final File inputFont = fileSystem.file(inputPath)
        ..writeAsBytesSync(List<int>.filled(2500, 0));
      fileSystem.file(outputPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(List<int>.filled(1200, 0));

      final bool subsetted = await iconTreeShaker.subsetFont(
        input: inputFont,
        outputPath: outputPath,
        relativePath: relativePath,
      );

      expect(subsetted, true);
      expect(stdinSink.getAndClear(), '59470\n');
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'InstanceCreationReference with non-constant arguments fails icon tree shaking',
    () async {
      final Environment environment = createEnvironment(<String, String>{
        kIconTreeShakerFlag: 'true',
        kBuildMode: 'release',
      });
      final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

      final iconTreeShaker = IconTreeShaker(
        environment,
        fontManifestContent,
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: artifacts,
        targetPlatform: TargetPlatform.android,
      );

      writeRecordedUsesFile(appDill.path, content: recordedUsesNonConstantCreationResult);

      await expectLater(
        () async => iconTreeShaker.subsetFont(
          input: fileSystem.file(inputPath),
          outputPath: outputPath,
          relativePath: relativePath,
        ),
        throwsToolExit(),
      );
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext('ConstructorTearoffReference fails icon tree shaking', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    writeRecordedUsesFile(appDill.path, content: recordedUsesTearoffResult);

    await expectLater(
      () async => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsToolExit(),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Combines recorded uses from both js and wasm files', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.web_javascript,
    );

    writeRecordedUsesFile(
      appDill.path,
      content: validRecordedUsesResult,
      fileName: 'recorded_uses_js.json',
    );
    writeRecordedUsesFile(
      appDill.path,
      content: validRecordedUsesSecondResult,
      fileName: 'recorded_uses_wasm.json',
    );

    final stdinSink = CompleterIOSink();
    resetFontSubsetInvocation(stdinSink: stdinSink);

    final File inputFont = fileSystem.file(inputPath)..writeAsBytesSync(List<int>.filled(2500, 0));
    fileSystem.file(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1200, 0));

    expect(
      await iconTreeShaker.subsetFont(
        input: inputFont,
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      true,
    );

    final String stdin = stdinSink.getAndClear();
    expect(stdin, contains('59470'));
    expect(stdin, contains('59471'));
    expect(stdin, contains('optional:32'));
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext(
    'Non-constant instance of non-Flutter IconData does not fail icon tree shaking',
    () async {
      final Environment environment = createEnvironment(<String, String>{
        kIconTreeShakerFlag: 'true',
        kBuildMode: 'release',
      });
      final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

      final iconTreeShaker = IconTreeShaker(
        environment,
        fontManifestContent,
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: artifacts,
        targetPlatform: TargetPlatform.android,
      );

      const customLibrary = Library('package:my_package/custom_icon_data.dart');
      const customIconDataClass = Class('IconData', customLibrary);
      const customOtherClass = Class('MyIconData', customLibrary);

      final String mixedRecordings = json.encode(
        Recordings(
          calls: <DefinitionWithStaticCalls, List<CallReference>>{},
          instances: <DefinitionWithInstances, List<InstanceReference>>{
            iconDataClass: <InstanceReference>[
              const InstanceConstantReference(
                instanceConstant: InstanceConstant(
                  definition: iconDataClass,
                  fields: <String, Constant>{
                    'codePoint': IntConstant(59470),
                    'fontFamily': StringConstant('MaterialIcons'),
                  },
                ),
                loadingUnit: rootLoadingUnit,
              ),
            ],
            customIconDataClass: <InstanceReference>[
              const InstanceCreationReference(
                definition: customIconDataClass,
                loadingUnit: rootLoadingUnit,
                positionalArguments: <MaybeConstant>[NonConstant()],
                namedArguments: <String, MaybeConstant>{},
              ),
            ],
            customOtherClass: <InstanceReference>[
              const InstanceCreationReference(
                definition: customOtherClass,
                loadingUnit: rootLoadingUnit,
                positionalArguments: <MaybeConstant>[NonConstant()],
                namedArguments: <String, MaybeConstant>{},
              ),
            ],
          },
        ).toJson(),
      );

      writeRecordedUsesFile(appDill.path, content: mixedRecordings);

      final stdinSink = CompleterIOSink();
      resetFontSubsetInvocation(stdinSink: stdinSink);

      final File inputFont = fileSystem.file(inputPath)
        ..writeAsBytesSync(List<int>.filled(2500, 0));
      fileSystem.file(outputPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(List<int>.filled(1200, 0));

      final bool subsetted = await iconTreeShaker.subsetFont(
        input: inputFont,
        outputPath: outputPath,
        relativePath: relativePath,
      );

      expect(subsetted, true);
      expect(stdinSink.getAndClear(), '59470\n');
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext('Skips empty recorded uses files', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.web_javascript,
    );

    writeRecordedUsesFile(appDill.path, content: '', fileName: 'recorded_uses_js.json');
    writeRecordedUsesFile(
      appDill.path,
      content: validRecordedUsesResult,
      fileName: 'recorded_uses_wasm.json',
    );

    final stdinSink = CompleterIOSink();
    resetFontSubsetInvocation(stdinSink: stdinSink);

    final File inputFont = fileSystem.file(inputPath)..writeAsBytesSync(List<int>.filled(2500, 0));
    fileSystem.file(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1200, 0));

    expect(
      await iconTreeShaker.subsetFont(
        input: inputFont,
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      true,
    );

    final String stdin = stdinSink.getAndClear();
    expect(stdin, contains('59470'));
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Subsets unused CupertinoIcons font to fallback code point', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    const cupertinoFontPath = 'packages/cupertino_icons/assets/CupertinoIcons.ttf';
    const cupertinoManifestJson =
        '''
[
  {
    "family": "packages/cupertino_icons/CupertinoIcons",
    "fonts": [
      {
        "asset": "$cupertinoFontPath"
      }
    ]
  }
]
''';
    fontManifestContent = DevFSStringContent(cupertinoManifestJson);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    // Empty recordings (0 icons used)
    writeRecordedUsesFile(appDill.path, content: emptyRecordedUsesResult);

    final stdinSink = CompleterIOSink();
    fontSubsetArgs = <String>[fontSubsetPath, outputPath, inputPath];
    resetFontSubsetInvocation(stdinSink: stdinSink);

    final File inputFont = fileSystem.file(inputPath)..writeAsBytesSync(List<int>.filled(2500, 0));
    fileSystem.file(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(1200, 0));

    expect(
      await iconTreeShaker.subsetFont(
        input: inputFont,
        outputPath: outputPath,
        relativePath: cupertinoFontPath,
      ),
      true,
    );

    expect(stdinSink.getAndClear(), '62418\n');
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Does not subset unused non-icon font', () async {
    final Environment environment = createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')..createSync(recursive: true);

    const customFontPath = 'fonts/Roboto-Regular.ttf';
    const customManifestJson =
        '''
[
  {
    "family": "Roboto",
    "fonts": [
      {
        "asset": "$customFontPath"
      }
    ]
  }
]
''';
    fontManifestContent = DevFSStringContent(customManifestJson);

    final iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
      targetPlatform: TargetPlatform.android,
    );

    // Empty recordings (0 icons used)
    writeRecordedUsesFile(appDill.path, content: emptyRecordedUsesResult);

    final File inputFont = fileSystem.file(inputPath)..writeAsBytesSync(List<int>.filled(2500, 0));

    expect(
      await iconTreeShaker.subsetFont(
        input: inputFont,
        outputPath: outputPath,
        relativePath: customFontPath,
      ),
      false,
    );

    expect(processManager, hasNoRemainingExpectations);
  });
}

const Library iconDataLibrary = Library('package:flutter/src/widgets/icon_data.dart');
const Class iconDataClass = Class('IconData', iconDataLibrary);
const LoadingUnit rootLoadingUnit = LoadingUnit('root');

// Generated from: const IconData(0xe84e, fontFamily: 'MaterialIcons')
final String validRecordedUsesResult = json.encode(
  Recordings(
    calls: <DefinitionWithStaticCalls, List<CallReference>>{},
    instances: <DefinitionWithInstances, List<InstanceReference>>{
      iconDataClass: <InstanceReference>[
        const InstanceConstantReference(
          instanceConstant: InstanceConstant(
            definition: iconDataClass,
            fields: <String, Constant>{
              'codePoint': IntConstant(59470),
              'fontFamily': StringConstant('MaterialIcons'),
            },
          ),
          loadingUnit: rootLoadingUnit,
        ),
      ],
    },
  ).toJson(),
);

// Generated from: const IconData(0xe84f, fontFamily: 'MaterialIcons')
final String validRecordedUsesSecondResult = json.encode(
  Recordings(
    calls: <DefinitionWithStaticCalls, List<CallReference>>{},
    instances: <DefinitionWithInstances, List<InstanceReference>>{
      iconDataClass: <InstanceReference>[
        const InstanceConstantReference(
          instanceConstant: InstanceConstant(
            definition: iconDataClass,
            fields: <String, Constant>{
              'codePoint': IntConstant(59471),
              'fontFamily': StringConstant('MaterialIcons'),
            },
          ),
          loadingUnit: rootLoadingUnit,
        ),
      ],
    },
  ).toJson(),
);

// Generated from: IconData(0xe84e, fontFamily: 'MaterialIcons')
final String validRecordedUsesCreationResult = json.encode(
  Recordings(
    calls: <DefinitionWithStaticCalls, List<CallReference>>{},
    instances: <DefinitionWithInstances, List<InstanceReference>>{
      iconDataClass: <InstanceReference>[
        const InstanceCreationReference(
          definition: iconDataClass,
          loadingUnit: rootLoadingUnit,
          positionalArguments: <MaybeConstant>[IntConstant(59470)],
          namedArguments: <String, MaybeConstant>{'fontFamily': StringConstant('MaterialIcons')},
        ),
      ],
    },
  ).toJson(),
);

// Generated from: const IconData(0xe84e)
final String emptyRecordedUsesResult = json.encode(
  Recordings(
    calls: <DefinitionWithStaticCalls, List<CallReference>>{},
    instances: <DefinitionWithInstances, List<InstanceReference>>{
      iconDataClass: <InstanceReference>[
        const InstanceConstantReference(
          instanceConstant: InstanceConstant(
            definition: iconDataClass,
            fields: <String, Constant>{
              'codePoint': IntConstant(59470),
              'fontFamily': NullConstant(),
            },
          ),
          loadingUnit: rootLoadingUnit,
        ),
      ],
    },
  ).toJson(),
);

// Generated from: IconData(codePoint) (where codePoint is a non-const variable)
final String recordedUsesWithInvalidResult = json.encode(
  Recordings(
    calls: <DefinitionWithStaticCalls, List<CallReference>>{},
    instances: <DefinitionWithInstances, List<InstanceReference>>{
      iconDataClass: <InstanceReference>[
        const InstanceCreationReference(
          definition: iconDataClass,
          loadingUnit: rootLoadingUnit,
          positionalArguments: <MaybeConstant>[NonConstant()],
          namedArguments: <String, MaybeConstant>{},
        ),
      ],
    },
  ).toJson(),
);

// Generated from: IconData(codePoint, fontFamily: 'MaterialIcons') (where codePoint is a non-const variable)
final String recordedUsesNonConstantCreationResult = json.encode(
  Recordings(
    calls: <DefinitionWithStaticCalls, List<CallReference>>{},
    instances: <DefinitionWithInstances, List<InstanceReference>>{
      iconDataClass: <InstanceReference>[
        const InstanceCreationReference(
          definition: iconDataClass,
          loadingUnit: rootLoadingUnit,
          positionalArguments: <MaybeConstant>[NonConstant()],
          namedArguments: <String, MaybeConstant>{'fontFamily': StringConstant('MaterialIcons')},
        ),
      ],
    },
  ).toJson(),
);

// Generated from: const fn = IconData.new;
final String recordedUsesTearoffResult = json.encode(
  Recordings(
    calls: <DefinitionWithStaticCalls, List<CallReference>>{},
    instances: <DefinitionWithInstances, List<InstanceReference>>{
      iconDataClass: <InstanceReference>[
        const ConstructorTearoffReference(definition: iconDataClass, loadingUnit: rootLoadingUnit),
      ],
    },
  ).toJson(),
);

const validFontManifestJson = '''
[
  {
    "family": "MaterialIcons",
    "fonts": [
      {
        "asset": "fonts/MaterialIcons-Regular.otf"
      }
    ]
  },
  {
    "family": "GalleryIcons",
    "fonts": [
      {
        "asset": "packages/flutter_gallery_assets/fonts/private/gallery_icons/GalleryIcons.ttf"
      }
    ]
  },
  {
    "family": "packages/cupertino_icons/CupertinoIcons",
    "fonts": [
      {
        "asset": "packages/cupertino_icons/assets/CupertinoIcons.ttf"
      }
    ]
  }
]
''';

const invalidFontManifestJson = '''
{
  "famly": "MaterialIcons",
  "fonts": [
    {
      "asset": "fonts/MaterialIcons-Regular.otf"
    }
  ]
}
''';

const emptyFontManifestJson = '[]';
