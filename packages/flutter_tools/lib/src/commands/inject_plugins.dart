// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../globals.dart' as globals;
import '../plugins.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class InjectPluginsCommand extends FlutterCommand {
  InjectPluginsCommand() {
    requiresPubspecYaml();
  }

  @override
  final String name = 'inject-plugins';

  @override
  final String description = 'Re-generates the GeneratedPluginRegistrants.';

  @override
  final bool hidden = true;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject project = FlutterProject.current();
    await refreshPluginsList(project, checkProjects: true);
    await injectPlugins(project, checkProjects: true);
    final bool result = hasPlugins(project);
    if (result) {
      globals.printStatus('GeneratedPluginRegistrants successfully written.');
    } else {
      globals.printStatus('This project does not use plugins, no GeneratedPluginRegistrants have been created.');
    }

    return FlutterCommandResult.success();
  }
}
