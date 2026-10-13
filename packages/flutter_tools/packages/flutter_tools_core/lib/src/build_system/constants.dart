// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../build.dart';

/// Placeholder substituted with the Flutter project root directory.
///
/// Valid as the leading segment of an [ExtensionSource.pattern] or within
/// [ExtensionBuildTarget.outputDir].
const String kProjectDirPlaceholder = '{PROJECT_DIR}';

/// Placeholder substituted with the workspace root directory containing
/// `.dart_tool/package_config.json`.
///
/// Valid as the leading segment of an [ExtensionSource.pattern].
const String kWorkspaceDirPlaceholder = '{WORKSPACE_DIR}';

/// Placeholder substituted with the intermediate build directory.
///
/// Valid as the leading segment of an [ExtensionSource.pattern] or within
/// [ExtensionBuildTarget.outputDir].
const String kBuildDirPlaceholder = '{BUILD_DIR}';

/// Placeholder substituted with the Flutter artifact cache directory.
///
/// Valid as the leading segment of an [ExtensionSource.pattern].
const String kCacheDirPlaceholder = '{CACHE_DIR}';

/// Placeholder substituted with the Flutter SDK root directory.
///
/// Valid as the leading segment of an [ExtensionSource.pattern].
const String kFlutterRootDirPlaceholder = '{FLUTTER_ROOT}';

/// Placeholder substituted with the target's output directory.
///
/// Valid as the leading segment of an [ExtensionSource.pattern].
const String kOutputDirPlaceholder = '{OUTPUT_DIR}';

/// Placeholder substituted with the CLI name of the active [BuildMode]
/// (e.g. `'debug'`, `'profile'`, `'release'`).
///
/// Only substituted in [ExtensionBuildTarget.outputDir]; not supported in
/// [ExtensionSource.pattern].
const String kBuildModePlaceholder = '{BUILD_MODE}';

/// Placeholder substituted with the target platform name (e.g. `'linux-x64'`).
///
/// Only substituted in [ExtensionBuildTarget.outputDir]; not supported in
/// [ExtensionSource.pattern].
const String kTargetPlatformPlaceholder = '{TARGET_PLATFORM}';

/// Commonly used [ExtensionArtifact] constants.
abstract final class BuiltInArtifacts {
  /// The International Components for Unicode (ICU) data file (`icudtl.dat`),
  /// containing localization, collation, and formatting rules used by the engine.
  static const ExtensionArtifact icuData = ExtensionArtifact('icuData');

  /// The precompiled Dart compiler binary `gen_snapshot` used to compile
  /// Dart code to AOT (Ahead-of-Time) machine code.
  static const ExtensionArtifact genSnapshot = ExtensionArtifact('genSnapshot');

  /// The directory path to the Flutter patched SDK, which contains the Dart SDK
  /// libraries with Flutter-specific modifications/patches (like `dart:ui` hooks) applied.
  static const ExtensionArtifact flutterPatchedSdkPath = ExtensionArtifact('flutterPatchedSdkPath');
}

/// Commonly used [ExtensionHostArtifact] constants.
abstract final class BuiltInHostArtifacts {
  /// The Impeller shader compiler executable (`impellerc`), used to compile GLSL
  /// shaders into platform-specific GPU formats (like MSL or SPIR-V) for the Impeller engine.
  static const ExtensionHostArtifact impellerc = ExtensionHostArtifact('impellerc');

  /// The dynamic library containing the libtessellator implementation, used by
  /// the Impeller shader compiler (`impellerc`) to tessellate complex vector shapes.
  static const ExtensionHostArtifact libtessellator = ExtensionHostArtifact('libtessellator');
}

/// Names of built-in `flutter assemble` targets that extensions can depend on.
///
// TODO(bkonyi): Propagate extension targetPlatform to built-in dependency targets
// (copy_assets defaults to TargetPlatform.android when kTargetPlatform is unset, and
// kernel_snapshot_program requires -dTargetPlatform).
abstract final class BuiltInTargets {
  /// Compiles the application to `{BUILD_DIR}/app.dill`.
  static const String kernelSnapshot = 'kernel_snapshot_program';

  /// Copies the application's assets to `{BUILD_DIR}/flutter_assets`.
  static const String copyAssets = 'copy_assets';
}
