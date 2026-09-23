// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/common.dart';
import '../bundle_builder.dart';
import '../project.dart';

/// Copies the AOT-compiled application library into the asset build
/// directory as `app.so`, matching what the Rust runner is told to load in
/// release mode. Also depends on the normal release asset-copy target so
/// fonts, the asset manifest, and icon tree-shaking stay in sync with the
/// kernel that `app.so` was compiled from; without it the assets directory
/// would keep whatever a previous (e.g. debug) build left behind.
class RustAotBundle extends CopyFlutterAotBundle {
  const RustAotBundle(this.targetPlatform);

  final TargetPlatform targetPlatform;

  @override
  String get name => 'rust_shell_aot_bundle';

  @override
  List<Target> get dependencies => <Target>[
    const ReleaseCopyFlutterBundle(),
    AotElfRelease(targetPlatform),
  ];
}

/// Builds the generated `runner-rs/` Cargo project for a `flutter.shell:
/// rust` application: compiles the Flutter asset bundle (AOT-compiling the
/// Dart app to `app.so` in release mode), then builds the Rust runner with
/// Cargo.
///
/// Returns the built runner executable.
Future<File> buildRust(
  FlutterProject project,
  BuildInfo buildInfo, {
  String? mainPath,
  required BundleBuilder bundleBuilder,
  required ProcessUtils processUtils,
  required Logger logger,
  required FileSystem fileSystem,
}) async {
  if (buildInfo.mode != BuildMode.debug && buildInfo.mode != BuildMode.release) {
    throwToolExit('The Flutter Rust shell currently supports debug and release modes only.');
  }
  final Directory runner = project.directory.childDirectory('runner-rs');
  final File manifest = runner.childFile('Cargo.toml');
  if (!manifest.existsSync()) {
    throwToolExit(
      'Rust-shell project is missing ${manifest.path}. '
      'Run `flutter create --shell=rust --platforms=linux .` first.',
    );
  }

  final releaseMode = buildInfo.mode == BuildMode.release;
  await bundleBuilder.build(
    platform: TargetPlatform.linux_x64,
    buildInfo: buildInfo,
    project: project,
    mainPath: mainPath,
    target: releaseMode ? const RustAotBundle(TargetPlatform.linux_x64) : null,
  );
  logger.printStatus('Building Rust shell runner...');
  final arguments = <String>['cargo', 'build', if (releaseMode) '--release'];
  if (runner.childFile('Cargo.lock').existsSync()) {
    arguments.add('--locked');
  }
  final int result = await processUtils.stream(arguments, workingDirectory: runner.path);
  if (result != 0) {
    throwToolExit('Unable to build the Rust shell runner.');
  }

  return fileSystem.file(
    fileSystem.path.join(
      runner.path,
      'target',
      releaseMode ? 'release' : 'debug',
      project.manifest.appName,
    ),
  );
}
