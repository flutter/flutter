// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../src/macos/xcode.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/xcodeproj.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class XcodeOptionCommand extends FlutterCommand {
  XcodeOptionCommand({
    bool verbose = false,
  }) : _verbose = verbose {
    requiresPubspecYaml();
  }

  final bool _verbose;

  @override
  final String name = 'xcode-options';

  @override
  final String description = 'list options';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    // Clean Xcode to remove intermediate DerivedData artifacts.
    // Do this before removing ephemeral directory, which would delete the xcworkspace.
    final FlutterProject flutterProject = FlutterProject.current();
    final XcodeProjectInfo? projectInfo = await flutterProject.ios.projectInfo();
    if (projectInfo == null) {
      globals.printStatus('projectInfo null');
      return const FlutterCommandResult(ExitStatus.fail);
    }
    globals.printStatus('projectInfo ${projectInfo.buildConfigurations}, ${projectInfo.targets}, ${projectInfo.schemes}');

    return const FlutterCommandResult(ExitStatus.success);
  }
}
