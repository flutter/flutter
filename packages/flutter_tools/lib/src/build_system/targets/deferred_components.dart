// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../../android/deferred_components_setup_validator.dart';
import '../../base/deferred_component.dart';
import '../../build_info.dart';
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';
import 'android.dart';

/// Creates a [DeferredComponentsSetupValidator and displays the validator
/// output to the developer if changes are recommended.
class DeferredComponentsGenSnapshotValidatorTarget extends Target {
  /// Create an [AndroidAotDeferredComponentsBundle] implementation for a given [targetPlatform] and [buildMode].
  DeferredComponentsGenSnapshotValidatorTarget({
    this.dependency,
    this.title,
    this.exitOnFail = true,
    String name = 'deferred_components_setup_validator',
  }) : _name = name;

  /// The [AndroidAotDeferredComponentsBundle] derived target instances this rule depends on.
  final CompositeTarget dependency;

  /// The title of the [DeferredComponentsSetupValidator] that is
  /// displayed to the developer when logging results.
  final String title;

  /// Whether to exit the tool if a recommended change is found by the
  /// [DeferredComponentsSetupValidator].
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
          getAndroidArchForName(getNameForTargetPlatform((target.dependencies.first as AndroidAotBundle).dependency.targetPlatform))));
      }
    }
    return abis;
  }

  @override
  String get name => _name;
  final String _name;

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => <String>[
    'flutter_$name.d',
  ];

  @override
  List<Target> get dependencies => dependency == null ? <Target>[] : <Target>[dependency];

  @visibleForTesting
  DeferredComponentsSetupValidator validator;

  @override
  Future<void> build(Environment environment) async {
    final DepfileService depfileService = DepfileService(
      fileSystem: environment.fileSystem,
      logger: environment.logger,
    );
    validator = DeferredComponentsGenSnapshotValidator(
      environment,
      title: title,
      exitOnFail: exitOnFail,
    );

    final List<LoadingUnit> generatedLoadingUnits = LoadingUnit.parseGeneratedLoadingUnits(
        environment.outputDir,
        environment.logger,
        abis: _androidAbiNames
    );

    validator.checkAppAndroidManifestComponentLoadingUnitMapping(
        FlutterProject.current().manifest.deferredComponents,
        generatedLoadingUnits,
    );
    validator.checkAgainstLoadingUnitGolden(generatedLoadingUnits);
    validator.writeGolden(generatedLoadingUnits);

    validator.handleResults();

    depfileService.writeToFile(
      Depfile(validator.inputs, validator.outputs),
      environment.buildDir.childFile('flutter_$name.d'),
    );
  }
}
