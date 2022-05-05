// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../flutter_project_metadata.dart';
import '../migrate/migrate_utils.dart';

/// Handles the custom/manual merging of one file at `localPath`.
///
/// The `merge` method should be overridden to implement custom merging.
abstract class CustomMerge {
  CustomMerge({
    required this.logger,
    required this.localPath,
  });

  /// The local path (with the project root as the root directory) of the file to merge.
  final String localPath;
  final Logger logger;

  /// Called to perform a custom three way merge between the current,
  /// base, and target files.
  MergeResult merge(File current, File base, File target);
}

/// Manually merges a flutter .metadata file.
///
/// See `FlutterProjectMetadata`.
class MetadataCustomMerge extends CustomMerge {
  MetadataCustomMerge({
    required Logger logger,
  }) : super(logger: logger, localPath: '.metadata');

  @override
  MergeResult merge(File current, File base, File target) {
    final FlutterProjectMetadata result = FlutterProjectMetadata.merge(
      FlutterProjectMetadata(current, logger),
      FlutterProjectMetadata(base, logger),
      FlutterProjectMetadata(target, logger),
      logger,
    );
    return StringMergeResult.explicit(
      mergedString: result.toString(),
      hasConflict: false,
      exitCode: 0,
      localPath: localPath,
    );
  }
}
