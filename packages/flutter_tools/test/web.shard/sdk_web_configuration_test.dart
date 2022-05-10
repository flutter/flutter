// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:dwds/dwds.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/sdk_web_configuration.dart';

import '../src/common.dart';

void main() {
  FileSystem fileSystem;

  group('Flutter SDK configuration for web', () {
    final SdkConfigurationProvider provider = SdkWebConfigurationProvider();
    SdkConfiguration configuration;

    setUp(() async {
      fileSystem = MemoryFileSystem.test();
      fileSystem.directory('HostArtifact.flutterWebSdk').createSync();
      fileSystem.file('HostArtifact.webPlatformKernelDill').createSync();
      fileSystem.file('HostArtifact.webPlatformSoundKernelDill').createSync();
      fileSystem.file('HostArtifact.flutterWebLibrariesJson').createSync();

      await context.run<void>(
        overrides: <Type, Generator>{
          Logger: () => globals.logger,
          Artifacts: () =>  Artifacts.test(fileSystem: fileSystem),
          FileSystem: () => fileSystem,
        },
        body: () async {
          configuration = await provider.configuration;
        }
      );
    });

    testWithoutContext('can be validated', () {
      SdkWebConfigurationProvider.validate(configuration, fileSystem: fileSystem);
    });

    testWithoutContext('is correct', () {
      expect(configuration.sdkDirectory, 'HostArtifact.flutterWebSdk');
      expect(configuration.unsoundSdkSummaryPath, 'HostArtifact.webPlatformKernelDill');
      expect(configuration.soundSdkSummaryPath, 'HostArtifact.webPlatformSoundKernelDill');
      expect(configuration.librariesPath, 'HostArtifact.flutterWebLibrariesJson');
      expect(configuration.compilerWorkerPath, isNull);
    });
  });
}
