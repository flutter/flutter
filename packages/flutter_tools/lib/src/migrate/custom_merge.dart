// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../migrate/migrate_utils.dart';

/// 
abstract class CustomMerge {
  CustomMerge({
    required this.logger,
  });

  final String localPath = '';
  final Logger logger;

  MergeResult merge(File current, File base, File target);
}

class MetadataCustomMerge extends CustomMerge {
  MetadataCustomMerge({
    required Logger logger,
  }) : super(logger: logger);

  @override
  final String localPath = '.metadata';

  @override
  MergeResult merge(File current, File base, File target) {
    print('CUSTOM MERGE');
    final FlutterProjectMetadata result = FlutterProjectMetadata.merge(
      FlutterProjectMetadata(current, logger),
      FlutterProjectMetadata(base, logger),
      FlutterProjectMetadata(target, logger),
      logger,
    );
    print(result.toString());
    return MergeResult.explicit(
      mergedString: result.toString(),
      hasConflict: false,
      exitCode: 0,
      localPath: localPath,
    );
  }
}
