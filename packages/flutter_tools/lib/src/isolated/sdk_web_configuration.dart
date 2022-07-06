// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

// ignore: import_of_legacy_library_into_null_safe
import 'package:dwds/dwds.dart';

import '../artifacts.dart';
import '../base/file_system.dart';

/// Provides paths to SDK files for dart SDK used in flutter.
class SdkWebConfigurationProvider extends SdkConfigurationProvider {

  SdkWebConfigurationProvider(this._artifacts);

  final Artifacts _artifacts;
  SdkConfiguration? _configuration;

  /// Create and validate configuration matching the default SDK layout.
  /// Create configuration matching the default SDK layout.
  @override
  Future<SdkConfiguration> get configuration async {
    if (_configuration == null) {
      final String sdkDir = _artifacts.getHostArtifact(HostArtifact.flutterWebSdk).path;
      final String unsoundSdkSummaryPath = _artifacts.getHostArtifact(HostArtifact.webPlatformKernelDill).path;
      final String soundSdkSummaryPath = _artifacts.getHostArtifact(HostArtifact.webPlatformSoundKernelDill).path;
      final String librariesPath = _artifacts.getHostArtifact(HostArtifact.flutterWebLibrariesJson).path;

      _configuration = SdkConfiguration(
        sdkDirectory: sdkDir,
        unsoundSdkSummaryPath: unsoundSdkSummaryPath,
        soundSdkSummaryPath: soundSdkSummaryPath,
        librariesPath: librariesPath,
      );
    }
    return _configuration!;
  }

  /// Validate that SDK configuration exists on disk.
  static void validate(SdkConfiguration configuration, { required FileSystem fileSystem }) {
    configuration.validateSdkDir(fileSystem: fileSystem);
    configuration.validateSummaries(fileSystem: fileSystem);
    configuration.validateLibrariesSpec(fileSystem: fileSystem);
  }
}
