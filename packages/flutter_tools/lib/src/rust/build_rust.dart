// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/common.dart';
import '../bundle_builder.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'native_libraries.dart';

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

  // The Dart SDK embedded in the Rust-shell engine (libflutter_rust_engine.so)
  // only loads kernels compiled by a frontend_server built from the exact
  // same source tree; anything else, even a very recent upstream SDK, fails
  // at startup with "Invalid SDK hash". `sdk/lib/<profile>/` (populated by
  // `_ensureRustShellSdk`, either from a local engine checkout or the BETA
  // download) ships a `flutter_patched_sdk`/`dart-sdk` pair built alongside
  // that exact engine, so kernel compilation must use those instead of the
  // ambient `bin/cache` SDK that a plain `bundleBuilder.build` would pick up.
  final Directory sdkLibDir = project.directory
      .childDirectory('.dart_tool')
      .childDirectory('flutter_rs')
      .childDirectory('sdk')
      .childDirectory('lib')
      .childDirectory(releaseMode ? 'release' : 'debug');
  // Explicit --local-engine flags already select a complete engine build.
  final bool userLocalEngine = globals.artifacts?.usesLocalArtifacts ?? false;
  final bool hasMatchingCompiler =
      !userLocalEngine &&
      sdkLibDir.childDirectory('flutter_patched_sdk').existsSync() &&
      sdkLibDir.childDirectory('dart-sdk').existsSync();
  if (!hasMatchingCompiler && !userLocalEngine) {
    logger.printWarning(
      'No matching kernel compiler was found alongside the Rust-shell '
      'engine at ${sdkLibDir.path}. Falling back to the default Flutter SDK '
      'to compile the kernel, which may not match the engine and can fail '
      'with "Invalid SDK hash" at launch.',
    );
  }

  Future<void> buildBundle() => bundleBuilder.build(
    platform: TargetPlatform.linux_x64,
    buildInfo: buildInfo,
    project: project,
    mainPath: mainPath,
    target: releaseMode ? const RustAotBundle(TargetPlatform.linux_x64) : null,
  );

  if (hasMatchingCompiler) {
    final Artifacts localArtifacts = Artifacts.getLocalEngine(
      EngineBuildPaths(targetEngine: sdkLibDir.path, hostEngine: sdkLibDir.path, webSdk: null),
    );
    await context.run<void>(
      overrides: <Type, Generator>{Artifacts: () => localArtifacts},
      body: buildBundle,
    );
  } else {
    await buildBundle();
  }
  logger.printStatus('Building Rust shell runner...');
  final arguments = <String>['cargo', 'build', if (releaseMode) '--release'];
  if (runner.childFile('Cargo.lock').existsSync()) {
    arguments.add('--locked');
  }
  final int result = await processUtils.stream(arguments, workingDirectory: runner.path);
  if (result != 0) {
    throwToolExit('Unable to build the Rust shell runner.');
  }

  await buildNativeLibraries(
    project,
    releaseMode: releaseMode,
    processUtils: processUtils,
    logger: logger,
    fileSystem: fileSystem,
  );

  final File runnerBinary = fileSystem.file(
    fileSystem.path.join(
      runner.path,
      'target',
      releaseMode ? 'release' : 'debug',
      project.manifest.appName,
    ),
  );
  _bundleDataNextToRunner(
    runnerBinary,
    sdkLibDir,
    nativeLibraryDirectory(project, releaseMode: releaseMode),
    fileSystem,
  );
  return runnerBinary;
}

/// Copies `flutter_assets` and `icudtl.dat` into `<runner dir>/data/`, and the
/// engine and native plugin libraries into `<runner dir>/libs/`, so the runner
/// finds them relative to its own executable (build.rs adds `$ORIGIN/libs` to
/// its rpath) without being passed an assets path.
void _bundleDataNextToRunner(
  File runnerBinary,
  Directory sdkLibDir,
  Directory nativeLibs,
  FileSystem fileSystem,
) {
  final Directory dataDir = runnerBinary.parent.childDirectory('data');
  final Directory assetsDest = dataDir.childDirectory('flutter_assets');
  if (assetsDest.existsSync()) {
    assetsDest.deleteSync(recursive: true);
  }
  copyDirectory(fileSystem.directory(getAssetBuildDirectory()), assetsDest);
  final File icu = sdkLibDir.childFile('icudtl.dat');
  if (icu.existsSync()) {
    icu.copySync(dataDir.childFile('icudtl.dat').path);
  }
  // Earlier tool versions used `lib/`, which some plugins treat as a bundled
  // third-party library directory; remove what we put there.
  final Directory legacyLibDir = runnerBinary.parent.childDirectory('lib');
  if (legacyLibDir.existsSync()) {
    legacyLibDir.deleteSync(recursive: true);
  }
  final Directory libDir = runnerBinary.parent.childDirectory('libs')..createSync(recursive: true);
  final File engine = sdkLibDir.childFile('libflutter_rust_engine.so');
  if (engine.existsSync()) {
    engine.copySync(libDir.childFile(engine.basename).path);
  }
  if (nativeLibs.existsSync()) {
    for (final File lib in nativeLibs.listSync().whereType<File>()) {
      lib.copySync(libDir.childFile(lib.basename).path);
    }
  }
}
