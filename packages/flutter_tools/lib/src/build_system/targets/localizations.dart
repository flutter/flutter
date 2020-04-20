// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../../base/file_system.dart';
import '../build_system.dart';

Future<void> generateLocalizations({
  @required String flutterRoot,
  @required FileSystem fileSystem,
  @required ProcessManager processManager,
  @required Artifacts artifacts,
  @required Logger logger,
}) async {
  final String genL10nPath = fileSystem.path.join(
    flutterRoot,
    'dev',
    'tools',
    'localization',
    'bin',
    'gen_l10n.dart',
  );
  final ProcessResult result = await processManager.run(<String>[
    artifacts.getArtifactPath(Artifact.engineDartBinary),
    genL10nPath,
  ]);
  if (result.exitCode != 0) {
    logger.printError(result.stdout + result.stderr as String);
  }
}

class GenerateLocalizationsTarget extends Target {
  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[];

  @override
  String get name => 'gen_localizations';

  @override
  List<Source> get outputs => <Source>[];

  @override
  Future<void> build(Environment environment) async {
    await generateLocalizations(
      artifacts: environment.artifacts,
      fileSystem: environment.fileSystem,
      flutterRoot: environment.flutterRootDir.path,
      logger: environment.logger,
      processManager: environment.processManager
    );
  }
}
