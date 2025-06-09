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
    packagePlatform: SwiftPackagePlatform.ios,
    artifactName: 'ios',
    artifactZip: 'artifacts.zip',
    xcframeworkArtifact: Artifact.flutterXcframework,
    sdks: <XcodeSdk>[XcodeSdk.IPhoneOS, XcodeSdk.IPhoneSimulator],
  ),
  macos(
    name: 'macos',
    frameworkName: 'FlutterMacOS',
    targetPlatform: TargetPlatform.darwin,
    packagePlatform: SwiftPackagePlatform.macos,
    artifactName: 'darwin-x64',
    artifactZip: 'framework.zip',
    xcframeworkArtifact: Artifact.flutterMacOSXcframework,
    sdks: <XcodeSdk>[XcodeSdk.MacOSX],
  );

  const FlutterDarwinPlatform({
    required this.name,
    required this.frameworkName,
    required this.targetPlatform,
    required this.packagePlatform,
    required String artifactName,
    required this.artifactZip,
    required this.xcframeworkArtifact,
    required this.sdks,
  }) : _artifactName = artifactName;

  final String name;
  final String frameworkName;
  final TargetPlatform targetPlatform;
  final SwiftPackagePlatform packagePlatform;
  final String _artifactName;
  final String artifactZip;
  final Artifact xcframeworkArtifact;
  final List<XcodeSdk> sdks;

  Version deploymentTarget() {
    switch (this) {
      case FlutterDarwinPlatform.ios:
        return Version(13, 0, null);
      case FlutterDarwinPlatform.macos:
        return Version(10, 15, null);
    }
  }

  String artifactName(BuildMode mode) {
    return mode == BuildMode.debug ? _artifactName : '$_artifactName-${mode.cliName}';
  }

  SwiftPackageSupportedPlatform get supportedPackagePlatform {
    return SwiftPackageSupportedPlatform(platform: packagePlatform, version: deploymentTarget());
  }

  static FlutterDarwinPlatform? fromTargetPlatform(TargetPlatform targetPlatform) {
    if (targetPlatform == TargetPlatform.ios) {
      return ios;
    }
    if (targetPlatform == TargetPlatform.darwin) {
      return macos;
    }
    return null;
  }

  XcodeBasedProject xcodeProject(FlutterProject project) {
    switch (this) {
      case FlutterDarwinPlatform.ios:
        return project.ios;
      case FlutterDarwinPlatform.macos:
        return project.macos;
    }
  }
}
