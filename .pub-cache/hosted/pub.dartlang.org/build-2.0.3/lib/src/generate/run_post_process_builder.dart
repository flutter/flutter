// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';

import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/logging.dart';
import '../builder/post_process_build_step.dart';
import '../builder/post_process_builder.dart';

/// Run [builder] with [inputId] as the primary input.
///
/// [addAsset] should update the build systems knowledge of what assets exist.
/// If an asset should not be written this function should throw.
/// [deleteAsset] should remove the asset from the build system, it will not be
/// deleted on disk since the `writer` has no mechanism for delete.
Future<void> runPostProcessBuilder(PostProcessBuilder builder, AssetId inputId,
    AssetReader reader, AssetWriter writer, Logger logger,
    {required void Function(AssetId) addAsset,
    required void Function(AssetId) deleteAsset}) async {
  await scopeLogAsync(() async {
    var buildStep =
        postProcessBuildStep(inputId, reader, writer, addAsset, deleteAsset);
    try {
      await builder.build(buildStep);
    } finally {
      await buildStep.complete();
    }
  }, logger);
}
