// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../convert.dart';
import '../project.dart';

enum AndroidAnalyzeOption {
  listBuildVariant,
  outputAppLinkSettings,
}

class AndroidAnalyze {
  AndroidAnalyze({
    required this.fileSystem,
    required this.option,
    required this.userPath,
    this.buildVariant,
    required this.logger,
  });

  final FileSystem fileSystem;
  final AndroidAnalyzeOption option;
  final String? buildVariant;
  final String userPath;
  final Logger logger;

  Future<void> analyze() async {
    final FlutterProject project = FlutterProject.fromDirectory(fileSystem.directory(userPath));
    await _analyze(project);
  }

  Future<void> _analyze(FlutterProject project) async {
    final String result;
    switch (option) {
      case AndroidAnalyzeOption.listBuildVariant:
        result = jsonEncode(await project.android.getBuildVariants());
        logger.printStatus('output = $result');
      case AndroidAnalyzeOption.outputAppLinkSettings:
        if (buildVariant == null) {
          throwToolExit('"--build-variant" must be provided');
        }
        await project.android.outputsAppLinkSettings(variant: buildVariant!);
        final String filePath = path.join(project.directory.path, 'build', 'app', 'app-link-settings-$buildVariant.json`');
        logger.printStatus('result saved in $filePath');
    }
  }
}
