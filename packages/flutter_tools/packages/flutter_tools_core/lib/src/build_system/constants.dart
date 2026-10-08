// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'enums.dart';
import 'source.dart';
import 'target.dart';

const String kProjectDirPlaceholder = '{PROJECT_DIR}';
const String kWorkspaceDirPlaceholder = '{WORKSPACE_DIR}';
const String kBuildDirPlaceholder = '{BUILD_DIR}';
const String kCacheDirPlaceholder = '{CACHE_DIR}';
const String kFlutterRootDirPlaceholder = '{FLUTTER_ROOT}';
const String kOutputDirPlaceholder = '{OUTPUT_DIR}';
const String kBuildModePlaceholder = '{BUILD_MODE}';
const String kTargetPlatformPlaceholder = '{TARGET_PLATFORM}';

/// Commonly used [Artifact] constants.
abstract final class BuiltInArtifacts {
  /// The International Components for Unicode (ICU) data file (`icudtl.dat`),
  /// containing localization, collation, and formatting rules used by the engine.
  static const Artifact icuData = Artifact('icuData');

  /// The precompiled Dart compiler binary `gen_snapshot` used to compile
  /// Dart code to AOT (Ahead-of-Time) machine code.
  static const Artifact genSnapshot = Artifact('genSnapshot');

  /// The directory path to the Flutter patched SDK, which contains the Dart SDK
  /// libraries with Flutter-specific modifications/patches (like `dart:ui` hooks) applied.
  static const Artifact flutterPatchedSdkPath = Artifact('flutterPatchedSdkPath');
}

/// Commonly used [HostArtifact] constants.
abstract final class BuiltInHostArtifacts {
  /// The Impeller shader compiler executable (`impellerc`), used to compile GLSL
  /// shaders into platform-specific GPU formats (like MSL or SPIR-V) for the Impeller engine.
  static const HostArtifact impellerc = HostArtifact('impellerc');

  /// The dynamic library containing the libtessellator implementation, used by
  /// the Impeller shader compiler (`impellerc`) to tessellate complex vector shapes.
  static const HostArtifact libtessellator = HostArtifact('libtessellator');
}

/// Metadata for built-in targets that extensions can reference.
abstract final class BuiltInTargets {
  static const SimpleTarget kernelSnapshot = SimpleTarget(
    name: 'kernel_snapshot_program',
    inputs: <Source>[Source.pattern('$kProjectDirPlaceholder/pubspec.yaml')],
    outputs: <Source>[Source.pattern('$kBuildDirPlaceholder/app.dill')],
  );

  static const SimpleTarget copyAssets = SimpleTarget(
    name: 'copy_assets',
    inputs: <Source>[Source.pattern('$kProjectDirPlaceholder/pubspec.yaml')],
  );
}
