// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/build_step.dart';
import '../builder/build_step_impl.dart';
import '../builder/builder.dart';
import '../builder/logging.dart';
import '../resource/resource.dart';
import 'expected_outputs.dart';

/// Run [builder] with each asset in [inputs] as the primary input.
///
/// Builds for all inputs are run asynchronously and ordering is not guaranteed.
/// The [log] instance inside the builds will be scoped to [logger] which is
/// defaulted to a [Logger] name 'runBuilder'.
///
/// If a [resourceManager] is provided it will be used and it will not be
/// automatically disposed of (its up to the caller to dispose of it later). If
/// one is not provided then one will be created and disposed at the end of
/// this function call.
///
/// If [reportUnusedAssetsForInput] is provided then all calls to
/// `BuildStep.reportUnusedAssets` in [builder] will be forwarded to this
/// function with the associated primary input.
Future<void> runBuilder(Builder builder, Iterable<AssetId> inputs,
    AssetReader reader, AssetWriter writer, Resolvers? resolvers,
    {Logger? logger,
    ResourceManager? resourceManager,
    StageTracker stageTracker = NoOpStageTracker.instance,
    void Function(AssetId input, Iterable<AssetId> assets)?
        reportUnusedAssetsForInput}) async {
  var shouldDisposeResourceManager = resourceManager == null;
  final resources = resourceManager ?? ResourceManager();
  logger ??= Logger('runBuilder');
  //TODO(nbosch) check overlapping outputs?
  Future<void> buildForInput(AssetId input) async {
    var outputs = expectedOutputs(builder, input);
    if (outputs.isEmpty) return;
    var buildStep = BuildStepImpl(
        input, outputs, reader, writer, resolvers, resources,
        stageTracker: stageTracker,
        reportUnusedAssets: reportUnusedAssetsForInput == null
            ? null
            : (assets) => reportUnusedAssetsForInput(input, assets));
    try {
      await builder.build(buildStep);
    } finally {
      await buildStep.complete();
    }
  }

  await scopeLogAsync(() => Future.wait(inputs.map(buildForInput)), logger);

  if (shouldDisposeResourceManager) {
    await resources.disposeAll();
    await resources.beforeExit();
  }
}
