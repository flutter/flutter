// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';


import '../base/file_system.dart';
import '../cache.dart';
import '../project.dart';
import '../version.dart';
import 'analyze_base.dart';
// import '../base/terminal.dart';

class AnalyzeInfo extends AnalyzeBase {
  AnalyzeInfo(
    super.argResults,
    this.projectDirectory,
    List<String> repoRoots,
    List<Directory> repoPackages, {
    required super.fileSystem,
    required super.logger,
    required super.platform,
    required super.processManager,
    required super.terminal,
    required super.artifacts,
  }) : super(
        repoRoots: repoRoots,
        repoPackages: repoPackages,
      );

  /// The working directory for testing analysis using dartanalyzer.
  final String? projectDirectory;

  @override
  Future<void> analyze() async {
    final Map<String, Object?> output = <String, Object?>{};
    // FlutterProject
    final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(logger: logger, fileSystem: fileSystem);
    final FlutterProject project = projectDirectory == null
      ? FlutterProject.current()
      : flutterProjectFactory.fromDirectory(fileSystem.directory(projectDirectory));
    output['FlutterProject.directory'] = project.directory.absolute.path;
    output['FlutterProject.metadataFile'] = project.metadataFile.absolute.path;
    output['FlutterProject.android.exists'] = project.android.existsSync();
    output['FlutterProject.ios.exists'] = project.ios.exists;
    output['FlutterProject.web.exists'] = project.web.existsSync();
    output['FlutterProject.macos.exists'] = project.macos.existsSync();
    output['FlutterProject.linux.exists'] = project.linux.existsSync();
    output['FlutterProject.windows.exists'] = project.windows.existsSync();
    output['FlutterProject.fuchsia.exists'] = project.fuchsia.existsSync();

    output['FlutterProject.android.isKotlin'] = project.android.isKotlin;
    output['FlutterProject.ios.isSwift'] = project.ios.isSwift;

    output['FlutterProject.isModule'] = project.isModule;
    output['FlutterProject.isPlugin'] = project.isPlugin;

    output['FlutterProject.manifest.appname'] = project.manifest.appName;

    // FlutterVersion
    final FlutterVersion version = FlutterVersion(workingDirectory: project.directory.absolute.path);
    output['FlutterVersion.frameworkRevision'] = version.frameworkRevision;

    // Platform
    output['Platform.operatingSystem'] = platform.operatingSystem;
    output['Platform.isAndroid'] = platform.isAndroid;
    output['Platform.isIOS'] = platform.isIOS;
    output['Platform.isWindows'] = platform.isWindows;
    output['Platform.isMacOS'] = platform.isMacOS;
    output['Platform.isFuchsia'] = platform.isFuchsia;
    output['Platform.pathSeparator'] = platform.pathSeparator;

    // Cache
    output['Cache.flutterRoot'] = Cache.flutterRoot;

    // Print properties
    logger.printStatus('{');
    int count = 0;
    for (final MapEntry<String, Object?> entry in output.entries) {
      String value = entry.value.toString();
      if (entry.value is String) {
        value = '"${entry.value}"';
      }
      count++;
      logger.printStatus('  "${entry.key}": $value${count < output.length ? ',' : ''}');
    }
    logger.printStatus('}');
  }
}
