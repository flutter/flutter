// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/platform.dart';

import '../base/common.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a macos desktop target through a build shell script.
class BuildMacosCommand extends BuildSubCommand {
  @override
  final String name = 'macos';

  @override
  bool isExperimental = true;

  @override
  bool hidden = true;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.macOS,
    DevelopmentArtifact.universal,
  };

  @override
  String get description => 'build the MacOS desktop target (Experimental).';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final FlutterProject flutterProject = await FlutterProject.current();
    if (!platform.isMacOS) {
      throwToolExit('"build macos" only supported on macOS hosts.');
    }
    if (!flutterProject.macos.existsSync()) {
      throwToolExit('No macOS desktop project configured.');
    }
    final Process process = await processManager.start(<String>[
      flutterProject.macos.buildScript.path,
      Cache.flutterRoot,
    ], runInShell: true);
    process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(printError);
    process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(printStatus);
    final int result = await process.exitCode;
    if (result != 0) {
      throwToolExit('Build process failed');
    }
    return null;
  }
}
