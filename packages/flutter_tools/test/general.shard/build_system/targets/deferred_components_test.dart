// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/deferred_components_setup_validator.dart';
import 'package:flutter_tools/src/base/deferred_component.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/deferred_components.dart';
import 'package:flutter_tools/src/build_system/targets/android.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
    fileSystem = MemoryFileSystem.test();
  });

  // Tests if the validator runs. Detailed per-check tests are in android/deferred_components_setup_validator_test.dart.
  testUsingContext('empty checks passes', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      buildDir: fileSystem.directory('build')..createSync(),
      defines: <String, String>{
        kSplitAot: 'true',
      },
      artifacts: null,
      processManager: null,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    final CompositeTarget androidDefBundle = CompositeTarget(<Target>[androidAotBundle]);
    final CompositeTarget compositeTarget = CompositeTarget(<Target>[androidDefBundle]);
    final DeferredComponentsSetupValidatorTarget validatorTarget = DeferredComponentsSetupValidatorTarget(
      tasks: <DeferredComponentsSetupValidatorTask>[],
      dependency: compositeTarget,
      title: 'test checks',
      exitOnFail: false,
    );

    await validatorTarget.build(environment);

    expect(logger.statusText.contains('test checks passed.'), true);
  });

  // Tests if the validator runs checkAndroidDynamicFeature. Detailed per-check tests are in android/deferred_components_setup_validator_test.dart.
  testUsingContext('checkAndroidDynamicFeature checks runs', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      buildDir: fileSystem.directory('build')..createSync(),
      projectDir: fileSystem.directory('project')..createSync(),
      defines: <String, String>{
        kSplitAot: 'true',
      },
      artifacts: null,
      processManager: null,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    final CompositeTarget androidDefBundle = CompositeTarget(<Target>[androidAotBundle]);
    final CompositeTarget compositeTarget = CompositeTarget(<Target>[androidDefBundle]);
    final DeferredComponentsSetupValidatorTarget validatorTarget = DeferredComponentsSetupValidatorTarget(
      tasks: <DeferredComponentsSetupValidatorTask>[
        DeferredComponentsSetupValidatorTask.checkAndroidDynamicFeature
      ],
      dependency: compositeTarget,
      title: 'test checks',
      exitOnFail: false,
    );

    await validatorTarget.build(environment);

    // We check the inputs to determine if the task was executed.
    expect(validatorTarget.validator.inputs.length, 1);
    expect(validatorTarget.validator.inputs[0].path, 'project/pubspec.yaml');
  });

  // Tests if the validator runs checkAppAndroidManifestComponentLoadingUnitMapping. Detailed per-check tests are in android/deferred_components_setup_validator_test.dart.
  testUsingContext('checkAppAndroidManifestComponentLoadingUnitMapping checks runs', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      buildDir: fileSystem.directory('build')..createSync(),
      projectDir: fileSystem.directory('project')..createSync(),
      defines: <String, String>{
        kSplitAot: 'true',
      },
      artifacts: null,
      processManager: null,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    final CompositeTarget androidDefBundle = CompositeTarget(<Target>[androidAotBundle]);
    final CompositeTarget compositeTarget = CompositeTarget(<Target>[androidDefBundle]);
    final DeferredComponentsSetupValidatorTarget validatorTarget = DeferredComponentsSetupValidatorTarget(
      tasks: <DeferredComponentsSetupValidatorTask>[
        DeferredComponentsSetupValidatorTask.checkAppAndroidManifestComponentLoadingUnitMapping
      ],
      dependency: compositeTarget,
      title: 'test checks',
      exitOnFail: false,
    );

    await validatorTarget.build(environment);

    // We check the inputs to determine if the task was executed.
    expect(validatorTarget.validator.inputs.length, 2);
    expect(validatorTarget.validator.inputs[0].path, 'project/pubspec.yaml');
    expect(validatorTarget.validator.inputs[1].path, 'project/android/app/src/main/AndroidManifest.xml');
  });

  // Tests if the validator runs checkAndroidResourcesStrings. Detailed per-check tests are in android/deferred_components_setup_validator_test.dart.
  testUsingContext('checkAndroidResourcesStrings checks runs', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      buildDir: fileSystem.directory('build')..createSync(),
      projectDir: fileSystem.directory('project')..createSync(),
      defines: <String, String>{
        kSplitAot: 'true',
      },
      artifacts: null,
      processManager: null,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    final CompositeTarget androidDefBundle = CompositeTarget(<Target>[androidAotBundle]);
    final CompositeTarget compositeTarget = CompositeTarget(<Target>[androidDefBundle]);
    final DeferredComponentsSetupValidatorTarget validatorTarget = DeferredComponentsSetupValidatorTarget(
      tasks: <DeferredComponentsSetupValidatorTask>[
        DeferredComponentsSetupValidatorTask.checkAndroidResourcesStrings
      ],
      dependency: compositeTarget,
      title: 'test checks',
      exitOnFail: false,
    );

    await validatorTarget.build(environment);

    // We check the inputs to determine if the task was executed.
    expect(validatorTarget.validator.inputs.length, 2);
    expect(validatorTarget.validator.inputs[0].path, 'project/pubspec.yaml');
    expect(validatorTarget.validator.inputs[1].path, 'project/android/app/src/main/res/values/strings.xml');
  });

  // Tests if the validator runs checkAgainstLoadingUnitGolden. Detailed per-check tests are in android/deferred_components_setup_validator_test.dart.
  testUsingContext('checkAgainstLoadingUnitGolden checks runs', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      buildDir: fileSystem.directory('build')..createSync(),
      projectDir: fileSystem.directory('project')..createSync(),
      defines: <String, String>{
        kSplitAot: 'true',
      },
      artifacts: null,
      processManager: null,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    final CompositeTarget androidDefBundle = CompositeTarget(<Target>[androidAotBundle]);
    final CompositeTarget compositeTarget = CompositeTarget(<Target>[androidDefBundle]);
    final DeferredComponentsSetupValidatorTarget validatorTarget = DeferredComponentsSetupValidatorTarget(
      tasks: <DeferredComponentsSetupValidatorTask>[
        DeferredComponentsSetupValidatorTask.checkAgainstLoadingUnitGolden
      ],
      dependency: compositeTarget,
      title: 'test checks',
      exitOnFail: false,
    );

    await validatorTarget.build(environment);

    // We check the inputs to determine if the task was executed.
    expect(validatorTarget.validator.inputs.length, 1);
    expect(validatorTarget.validator.inputs[0].path, 'project/deferred_components_golden.yaml');
  });

  // Tests if the validator runs writeGolden. Detailed per-task tests are in android/deferred_components_setup_validator_test.dart.
  testUsingContext('writeGolden task runs', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      buildDir: fileSystem.directory('build')..createSync(),
      projectDir: fileSystem.directory('project')..createSync(),
      defines: <String, String>{
        kSplitAot: 'true',
      },
      artifacts: null,
      processManager: null,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    final CompositeTarget androidDefBundle = CompositeTarget(<Target>[androidAotBundle]);
    final CompositeTarget compositeTarget = CompositeTarget(<Target>[androidDefBundle]);
    final DeferredComponentsSetupValidatorTarget validatorTarget = DeferredComponentsSetupValidatorTarget(
      tasks: <DeferredComponentsSetupValidatorTask>[
        DeferredComponentsSetupValidatorTask.writeGolden
      ],
      dependency: compositeTarget,
      title: 'test checks',
      exitOnFail: false,
    );

    await validatorTarget.build(environment);

    // We check the inputs to determine if the task was executed.
    expect(validatorTarget.validator.outputs.length, 1);
    expect(validatorTarget.validator.outputs[0].path, 'project/deferred_components_golden.yaml');
  });

  // Tests if the validator runs clearOutputDir. Detailed per-check tests are in android/deferred_components_setup_validator_test.dart.
  testUsingContext('clearOutputDir task runs', () async {
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      outputDir: fileSystem.directory('out')..createSync(),
      buildDir: fileSystem.directory('build')..createSync(),
      projectDir: fileSystem.directory('project')..createSync(),
      defines: <String, String>{
        kSplitAot: 'true',
      },
      artifacts: null,
      processManager: null,
      fileSystem: fileSystem,
      logger: logger,
    );
    environment.buildDir.createSync(recursive: true);
    const AndroidAot androidAot = AndroidAot(TargetPlatform.android_arm64, BuildMode.release);
    const AndroidAotBundle androidAotBundle = AndroidAotBundle(androidAot);
    final CompositeTarget androidDefBundle = CompositeTarget(<Target>[androidAotBundle]);
    final CompositeTarget compositeTarget = CompositeTarget(<Target>[androidDefBundle]);
    final DeferredComponentsSetupValidatorTarget validatorTarget = DeferredComponentsSetupValidatorTarget(
      tasks: <DeferredComponentsSetupValidatorTask>[
        DeferredComponentsSetupValidatorTask.clearOutputDir
      ],
      dependency: compositeTarget,
      title: 'test checks',
      exitOnFail: false,
    );
    final Directory outputDir = fileSystem.directory('project/build/android_deferred_components_setup_files')..createSync(recursive: true);
    expect(outputDir.existsSync(), true);

    await validatorTarget.build(environment);

    // We check the inputs to determine if the task was executed.
    expect(outputDir.existsSync(), false);
  });
}
