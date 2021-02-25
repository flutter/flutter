// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../../android/deferred_components_gen_snapshot_validator.dart';
import '../../base/deferred_component.dart';
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';

/// Creates a [DeferredComponentsGenSnapshotValidator], runs the checks, and displays the validator
/// output to the developer if changes are recommended.
class DeferredComponentsGenSnapshotValidatorTarget extends Target {
  /// Create an [AndroidAotDeferredComponentsBundle] implementation for a given [targetPlatform] and [buildMode].
  DeferredComponentsGenSnapshotValidatorTarget({
    @required this.dependency,
    @required this.abis,
    this.title,
    this.exitOnFail = true,
    String name = 'deferred_components_setup_validator',
  }) : _name = name;

  /// The [AndroidAotDeferredComponentsBundle] derived target instances this rule depends on packed
  /// as a [CompositeTarget].
  final CompositeTarget dependency;

  /// The title of the [DeferredComponentsGenSnapshotValidator] that is
  /// displayed to the developer when logging results.
  final String title;

  /// Whether to exit the tool if a recommended change is found by the
  /// [DeferredComponentsGenSnapshotValidator].
  final bool exitOnFail;

  /// The abis to validate.
  final List<String> abis;

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
  DeferredComponentsGenSnapshotValidator validator;

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
        abis: abis
    );

    validator
      ..checkAppAndroidManifestComponentLoadingUnitMapping(
          FlutterProject.current().manifest.deferredComponents,
          generatedLoadingUnits,
      )
      ..checkAgainstLoadingUnitsCache(generatedLoadingUnits)
      ..writeLoadingUnitsCache(generatedLoadingUnits);

    validator.handleResults();

    depfileService.writeToFile(
      Depfile(validator.inputs, validator.outputs),
      environment.buildDir.childFile('flutter_$name.d'),
    );
  }
}
