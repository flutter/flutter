// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import '../web/compile.dart';
import 'build.dart';

class BuildWebCommand extends BuildSubCommand {
  BuildWebCommand() {
    usesTargetOption();
    usesPubOption();
    defaultBuildMode = BuildMode.release;
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
    DevelopmentArtifact.web,
  };

  @override
  final String name = 'web';

  @override
  bool get hidden => true;

  @override
  bool get isExperimental => true;

  @override
  final String description = '(EXPERIMENTAL) build a web application bundle.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String target = argResults['target'];
    final Status status = logger.startProgress('Compiling $target to JavaScript...', timeout: null);
    final int result = await webCompiler.compile(target: target);
    status.stop();
    if (result == 1) {
      throwToolExit('Failed to compile $target to JavaScript.');
    }
    return null;
  }
}
