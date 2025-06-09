// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../ios/xcodeproj.dart';
import '../macos/swift_packages.dart';
import '../project.dart';

enum FlutterDarwinPlatform {
  ios(
    name: 'ios',
    frameworkName: 'Flutter',
    targetPlatform: TargetPlatform.ios,
    swiftPackagePlatform: SwiftPackagePlatform.ios,
    artifactName: 'ios',
    artifactZip: 'artifacts.zip',
    xcframeworkArtifact: Artifact.flutterXcframework,
    sdks: <XcodeSdk>[XcodeSdk.IPhoneOS, XcodeSdk.IPhoneSimulator],
  ),
  macos(
    name: 'macos',
    frameworkName: 'FlutterMacOS',
    targetPlatform: TargetPlatform.darwin,
    swiftPackagePlatform: SwiftPackagePlatform.macos,
    artifactName: 'darwin-x64',
    artifactZip: 'framework.zip',
    xcframeworkArtifact: Artifact.flutterMacOSXcframework,
    sdks: <XcodeSdk>[XcodeSdk.MacOSX],
  );

  const FlutterDarwinPlatform({
    required this.name,
    required this.frameworkName,
    required this.targetPlatform,
    required this.swiftPackagePlatform,
    required String artifactName,
    required this.artifactZip,
    required this.xcframeworkArtifact,
    required this.sdks,
  }) : _artifactName = artifactName;

  final String name;
  final String frameworkName;
  final TargetPlatform targetPlatform;
  final SwiftPackagePlatform swiftPackagePlatform;
  final String _artifactName;
  final String artifactZip;
  final Artifact xcframeworkArtifact;
  final List<XcodeSdk> sdks;

  /// Minimum supported version for the platform.
  Version deploymentTarget() {
    switch (this) {
      case FlutterDarwinPlatform.ios:
        return Version(13, 0, null);
      case FlutterDarwinPlatform.macos:
        return Version(10, 15, null);
    }
  }

  /// Artifact name for the platform and [mode].
  ///
  /// e.g. (`ios`, `ios-profile`, `ios-release`, `darwin-x64`, `darwin-x64-profile`,
  /// `darwin-x64-release`).
  String artifactName(BuildMode mode) {
    return mode == BuildMode.debug ? _artifactName : '$_artifactName-${mode.cliName}';
  }

  /// Minimum supported Swift package version for the platform.
  SwiftPackageSupportedPlatform get supportedPackagePlatform {
    return SwiftPackageSupportedPlatform(
      platform: swiftPackagePlatform,
      version: deploymentTarget(),
    );
  }

  /// Framework name with the `.framework` extension.
  ///
  /// e.g. (`Flutter.framework`, `FlutterMacOS.framework`).
  String get frameworkPath => '$frameworkName.framework';

  /// Framework name with the `.xcframework` extension.
  ///
  /// e.g. (`Flutter.xcframework`, `FlutterMacOS.xcframework`).
  String get xcframeworkPath => '$frameworkName.xcframework';

  /// Returns corresponding [FlutterDarwinPlatform] for the [targetPlatform].
  static FlutterDarwinPlatform? fromTargetPlatform(TargetPlatform targetPlatform) {
    for (final FlutterDarwinPlatform darwinPlatform in FlutterDarwinPlatform.values) {
      if (targetPlatform == darwinPlatform.targetPlatform) {
        return darwinPlatform;
      }
    }
    return null;
  }

  /// Returns corresponding [XcodeBasedProject] for the platform.
  XcodeBasedProject xcodeProject(FlutterProject project) {
    switch (this) {
      case FlutterDarwinPlatform.ios:
        return project.ios;
      case FlutterDarwinPlatform.macos:
        return project.macos;
    }
  }
}
