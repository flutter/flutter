// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import 'create_base.dart';

class WidgetPreviewCommand extends FlutterCommand {
  WidgetPreviewCommand() {
    addSubcommand(WidgetPreviewStartCommand());
    addSubcommand(WidgetPreviewCleanCommand());
  }

  @override
  String get description => 'Manage the widget preview environment.';

  @override
  String get name => 'widget-preview';

  @override
  String get category => FlutterCommandCategory.tools;

  // TODO(bkonyi): show when --verbose is not provided when this feature is
  // ready to ship.
  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async =>
      FlutterCommandResult.fail();
}

/// Common utilities for the 'start' and 'clean' commands.
mixin WidgetPreviewSubCommandMixin on FlutterCommand {
  FlutterProject getRootProject() {
    final ArgResults results = argResults!;
    final Directory projectDir;
    if (results.rest case <String>[final String directory]) {
      projectDir = globals.fs.directory(directory);
      if (!projectDir.existsSync()) {
        throwToolExit('Could not find ${projectDir.path}.');
      }
    } else if (results.rest.length > 1) {
      throwToolExit('Only one directory should be provided.');
    } else {
      projectDir = globals.fs.currentDirectory;
    }
    return validateFlutterProjectForPreview(projectDir);
  }

  FlutterProject validateFlutterProjectForPreview(Directory directory) {
    globals.logger
        .printTrace('Verifying that ${directory.path} is a Flutter project.');
    final FlutterProject flutterProject =
        globals.projectFactory.fromDirectory(directory);
    if (!flutterProject.dartTool.existsSync()) {
      throwToolExit(
        '${flutterProject.directory.path} is not a valid Flutter project.',
      );
    }
    return flutterProject;
  }
}

class WidgetPreviewStartCommand extends FlutterCommand
    with CreateBase, WidgetPreviewSubCommandMixin {
  WidgetPreviewStartCommand() {
    addPubOptions();
  }

  @override
  String get description => 'Starts the widget preview environment.';

  @override
  String get name => 'start';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject rootProject = getRootProject();

    // Check to see if a preview scaffold has already been generated. If not,
    // generate one.
    if (!rootProject.widgetPreviewScaffold.existsSync()) {
      globals.logger.printStatus(
        'Creating widget preview scaffolding at: ${rootProject.widgetPreviewScaffold.path}',
      );
      await generateApp(
        <String>['widget_preview_scaffold'],
        rootProject.widgetPreviewScaffold,
        createTemplateContext(
          organization: 'flutter',
          projectName: 'widget_preview_scaffold',
          titleCaseProjectName: 'Widget Preview Scaffold',
          flutterRoot: Cache.flutterRoot!,
          dartSdkVersionBounds: '^${globals.cache.dartSdkBuild}',
          linux: const LocalPlatform().isLinux,
          macos: const LocalPlatform().isMacOS,
          windows: const LocalPlatform().isWindows,
        ),
        overwrite: true,
        generateMetadata: false,
      );

      if (shouldCallPubGet) {
        await pub.get(
          context: PubContext.create,
          project: rootProject.widgetPreviewScaffoldProject,
          offline: offline,
          outputMode: PubOutputMode.summaryOnly,
        );
      }
    }
    return FlutterCommandResult.success();
  }
}

class WidgetPreviewCleanCommand extends FlutterCommand
    with WidgetPreviewSubCommandMixin {
  @override
  String get description => 'Cleans up widget preview state.';

  @override
  String get name => 'clean';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Directory widgetPreviewScaffold =
        getRootProject().widgetPreviewScaffold;
    if (widgetPreviewScaffold.existsSync()) {
      final String scaffoldPath = widgetPreviewScaffold.path;
      globals.logger.printStatus(
        'Deleting widget preview scaffold at $scaffoldPath.',
      );
      widgetPreviewScaffold.deleteSync(recursive: true);
    } else {
      globals.logger.printStatus('Nothing to clean up.');
    }
    return FlutterCommandResult.success();
  }
}
