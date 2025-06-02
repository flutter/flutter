// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../macos/swift_packages.dart';
import '../project.dart';

enum DarwinPlatform {
  ios(
    name: 'ios',
    frameworkName: 'Flutter',
    targetPlatform: TargetPlatform.ios,
    packagePlatform: SwiftPackagePlatform.ios,
    artifactName: 'ios',
    artifactZip: 'artifacts.zip',
    xcframeworkArtifact: Artifact.flutterXcframework,
    sdks: <DarwinSDK>[DarwinSDK.iphoneos, DarwinSDK.iphonesimulator],
  ),
  macos(
    name: 'macos',
    frameworkName: 'FlutterMacOS',
    targetPlatform: TargetPlatform.darwin,
    packagePlatform: SwiftPackagePlatform.macos,
    artifactName: 'darwin-x64',
    artifactZip: 'framework.zip',
    xcframeworkArtifact: Artifact.flutterMacOSXcframework,
    sdks: <DarwinSDK>[DarwinSDK.macos],
  );

  const DarwinPlatform({
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
  final List<DarwinSDK> sdks;

  /// IPHONEOS_DEPLOYMENT_TARGET
  Version deploymentTarget() {
    switch (this) {
      case DarwinPlatform.ios:
        return Version(13, 0, null);
      case DarwinPlatform.macos:
        return Version(10, 15, null);
    }
  }

  String artifactName(BuildMode mode) {
    return mode == BuildMode.debug ? _artifactName : '$_artifactName-${mode.cliName}';
  }

  SwiftPackageSupportedPlatform get supportedPackagePlatform {
    return SwiftPackageSupportedPlatform(platform: packagePlatform, version: deploymentTarget());
  }

  XcodeBasedProject xcodeProject(FlutterProject project) {
    switch (this) {
      case DarwinPlatform.ios:
        return project.ios;
      case DarwinPlatform.macos:
        return project.macos;
    }
  }
}

// REplace with XcodeSdk?
enum DarwinSDK {
  iphoneos(name: 'iphoneos', sdkType: EnvironmentType.physical),
  iphonesimulator(name: 'iphonesimulator', sdkType: EnvironmentType.simulator),
  macos(name: 'macosx');

  const DarwinSDK({required this.name, this.sdkType});

  final String name;
  final EnvironmentType? sdkType;
}
