// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../../android/deferred_components_setup_validator.dart';
import '../../base/deferred_component.dart';
import '../../build_info.dart';
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';
import 'android.dart';

/// An enumeration of the checks and tasks available in [DeferredComponentsSetupValidator].
///
/// Each of these enumerations corresponds to a method in [DeferredComponentsSetupValidator]
/// of the same name. This is used to configure which checks and tasks to run in a
/// [DeferredComponentsSetupValidatorTarget].
enum DeferredComponentsSetupValidatorTask {
  /// Runs [DeferredComponentsSetupValidator.checkAndroidDynamicFeature].
  checkAndroidDynamicFeature,
  /// Runs [DeferredComponentsSetupValidator.checkAppAndroidManifestComponentLoadingUnitMapping].
  checkAppAndroidManifestComponentLoadingUnitMapping,
  /// Runs [DeferredComponentsSetupValidator.checkAndroidResourcesStrings].
  checkAndroidResourcesStrings,
  /// Runs [DeferredComponentsSetupValidator.checkAgainstLoadingUnitGolden].
  checkAgainstLoadingUnitGolden,
  /// Runs [DeferredComponentsSetupValidator.writeGolden].
  writeGolden,
  /// Runs [DeferredComponentsSetupValidator.clearOutputDir].
  clearOutputDir,
}

// Rule that copies split aot library files to the intermediate dirs of each deferred component.
class DeferredComponentsSetupValidatorTarget extends Target {
  /// Create an [AndroidAotDeferredComponentsBundle] implementation for a given [targetPlatform] and [buildMode].
  DeferredComponentsSetupValidatorTarget({
    this.tasks,
    this.dependency,
    this.title,
    this.exitOnFail = true,
    String name = 'deferred_components_setup_validator',
  }) : _name = name;
  final List<DeferredComponentsSetupValidatorTask> tasks;

  /// The [AndroidAotDeferredComponentsBundle] derived target instances this rule depends on.
  final CompositeTarget dependency;

  final String title;

  final bool exitOnFail;

  /// The name of the produced Android ABI.
  List<String> get _androidAbiNames {
    final List<String> abis = <String>[];
    if (dependency == null) {
      return abis;
    }
    for (final Target target in dependency.dependencies) {
      if (target.dependencies.isNotEmpty) {
        abis.add(getNameForAndroidArch(
          getAndroidArchForName(getNameForTargetPlatform((target.dependencies[0] as AndroidAotBundle).targetPlatform))));
      }
    }
    return abis;
  }

  @override
  String get name => _name;
  final String _name;

  @override
  List<Source> get inputs {
    return const <Source>[];
  }

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => <String>[
    'flutter_$name.d',
  ];

  @override
  List<Target> get dependencies => dependency == null ? <Target>[] : <Target>[dependency];

  DeferredComponentsSetupValidator validator;

  @override
  Future<void> build(Environment environment) async {
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    validator = DeferredComponentsSetupValidator(
      environment,
      title: title,
      exitOnFail: exitOnFail,
    );

    List<LoadingUnit> generatedLoadingUnits;
    if (tasks.contains(DeferredComponentsSetupValidatorTask.checkAppAndroidManifestComponentLoadingUnitMapping)
        || tasks.contains(DeferredComponentsSetupValidatorTask.checkAgainstLoadingUnitGolden)
        || tasks.contains(DeferredComponentsSetupValidatorTask.writeGolden)) {
      generatedLoadingUnits = LoadingUnit.parseGeneratedLoadingUnits(environment.outputDir, environment.logger, abis: _androidAbiNames);
    }

    for (final DeferredComponentsSetupValidatorTask task in tasks) {
      switch(task) {
        case DeferredComponentsSetupValidatorTask.checkAndroidDynamicFeature:
          await validator.checkAndroidDynamicFeature(FlutterProject.current().manifest.deferredComponents);
          break;
        case DeferredComponentsSetupValidatorTask.checkAppAndroidManifestComponentLoadingUnitMapping:
          validator.checkAppAndroidManifestComponentLoadingUnitMapping(FlutterProject.current().manifest.deferredComponents, generatedLoadingUnits);
          break;
        case DeferredComponentsSetupValidatorTask.checkAndroidResourcesStrings:
          validator.checkAndroidResourcesStrings(FlutterProject.current().manifest.deferredComponents);
          break;
        case DeferredComponentsSetupValidatorTask.checkAgainstLoadingUnitGolden:
          validator.checkAgainstLoadingUnitGolden(generatedLoadingUnits);
          break;
        case DeferredComponentsSetupValidatorTask.writeGolden:
          validator.writeGolden(generatedLoadingUnits);
          break;
        case DeferredComponentsSetupValidatorTask.clearOutputDir:
          validator.clearOutputDir();
          break;
        // TODO(garyq): Add diff task here once it is implemented.
      }
    }

    validator.handleResults();

    depfileService.writeToFile(
      Depfile(validator.inputs, validator.outputs),
      environment.buildDir.childFile('flutter_$name.d'),
    );
  }
}
