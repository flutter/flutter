// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/bundle_builder.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/preview_device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  testWithoutContext('PreviewDevice defaults', () async {
    final PreviewDevice device = PreviewDevice(
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      platform: FakePlatform(),
    );

    expect(await device.isLocalEmulator, false);
    expect(device.name, 'preview');
    expect(await device.sdkNameAndVersion, 'preview');
    expect(await device.targetPlatform, TargetPlatform.tester);
    expect(device.category, Category.desktop);
    expect(device.ephemeral, false);
    expect(device.id, 'preview');

    expect(device.isSupported(), true);
    expect(device.isSupportedForProject(FakeFlutterProject()), true);
    expect(await device.isLatestBuildInstalled(FakeApplicationPackage()), false);
    expect(await device.isAppInstalled(FakeApplicationPackage()), false);
    expect(await device.uninstallApp(FakeApplicationPackage()), true);
  });

  testUsingContext('Can build a simulator app', () async {
    Cache.flutterRoot = '';
    final Completer<void> completer = Completer<void>();
    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final PreviewDevice device = PreviewDevice(
      fileSystem: fileSystem,
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            '/.tmp_rand0/flutter_preview.rand0/splash',
          ],
          stdout: 'The Dart VM service is listening on http://127.0.0.1:64494/fZ_B2N6JRwY=/\n',
          completer: completer,
        ),
      ]),
      logger: logger,
      platform: FakePlatform(),
      builderFactory: () => FakeBundleBuilder(fileSystem),
    );
    fileSystem
      .directory('artifacts_temp')
      .childDirectory('Debug')
      .createSync(recursive: true);

    final LaunchResult result = await device.startApp(
      FakeApplicationPackage(),
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
    );

    expect(result.started, true);
    expect(result.vmServiceUri, Uri.parse('http://127.0.0.1:64494/fZ_B2N6JRwY=/'));
  });
}

class FakeFlutterProject extends Fake implements FlutterProject { }
class FakeApplicationPackage extends Fake implements ApplicationPackage { }
class FakeBundleBuilder extends Fake implements BundleBuilder {
  FakeBundleBuilder(this.fileSystem);

  final FileSystem fileSystem;

  @override
  Future<void> build({
    required TargetPlatform platform,
    required BuildInfo buildInfo,
    FlutterProject? project,
    String? mainPath,
    String manifestPath = defaultManifestPath,
    String? applicationKernelFilePath,
    String? depfilePath,
    String? assetDirPath,
    @visibleForTesting BuildSystem? buildSystem
  }) async {
    final Directory assetDirectory = fileSystem
      .directory(assetDirPath)
      .childDirectory('flutter_assets')
      ..createSync(recursive: true);
    assetDirectory.childFile('kernel_blob.bin').createSync();
  }
}
