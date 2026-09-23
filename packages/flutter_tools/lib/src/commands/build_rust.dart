// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../bundle_builder.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import '../rust/build_rust.dart';
import 'build.dart';

/// A command to build a `flutter.shell: rust` application's generated
/// `runner-rs/` Cargo project.
class BuildRustCommand extends BuildSubCommand {
  BuildRustCommand({
    required ToolContext super.toolContext,
    required bool verboseHelp,
    BundleBuilder? bundleBuilder,
  }) : _bundleBuilder = bundleBuilder ?? BundleBuilder(),
       super(
         logger: toolContext.logger,
         outputPreferences: toolContext.outputPreferences,
         verboseHelp: verboseHelp,
       ) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
  }

  final BundleBuilder _bundleBuilder;

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  final name = 'rust';

  @override
  bool get hidden => !toolContext.platform.isLinux;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
  };

  @override
  String get description => 'Build the Flutter Rust shell runner for an application.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!toolContext.platform.isLinux) {
      throwToolExit('"build rust" only supported on Linux hosts.');
    }

    final BuildInfo buildInfo = await getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!flutterProject.manifest.usesRustShell) {
      throwToolExit(
        'No Rust-shell project configured. Run `flutter create --shell=rust '
        '--platforms=linux .` first.',
      );
    }

    final File builtRunner = await buildRust(
      flutterProject,
      buildInfo,
      mainPath: targetFile,
      bundleBuilder: _bundleBuilder,
      processUtils: toolContext.processUtils,
      logger: toolContext.logger,
      fileSystem: toolContext.fs,
    );

    toolContext.logger.printStatus(
      '${toolContext.terminal.successMark} '
      'Built ${toolContext.fs.path.relative(builtRunner.path)}',
      color: TerminalColor.green,
    );
    return FlutterCommandResult.success();
  }
}
