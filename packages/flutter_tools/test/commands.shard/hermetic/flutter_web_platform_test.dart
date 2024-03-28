// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/bundle_builder.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/test/flutter_web_platform.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/memory_fs.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../../src/context.dart';
import '../../src/fakes.dart';

class MockServer implements shelf.Server {
  shelf.Handler? mountedHandler;

  @override
  Future<void> close() async {}

  @override
  void mount(shelf.Handler handler) {
    mountedHandler = handler;
  }

  @override
  Uri get url => Uri.parse('');
}

void main() {
  const String shaderLibDir = '/./shader_lib';

  late FileSystem fileSystem;
  late BufferLogger logger;
  late Platform platform;
  late Artifacts artifacts;
  late ProcessManager processManager;
  late FakeOperatingSystemUtils operatingSystemUtils;
  late String impellerc;
  late Directory output;
  late String shadersPath;
  late String shaderPath;
  late String outputPath;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    platform = FakePlatform();
    artifacts = Artifacts.test(fileSystem: fileSystem);
    processManager = FakeProcessManager.empty();
    operatingSystemUtils = FakeOperatingSystemUtils();

    for (final HostArtifact artifact in <HostArtifact>[
      HostArtifact.webPrecompiledAmdCanvaskitAndHtmlSoundSdk,
      HostArtifact.webPrecompiledAmdCanvaskitAndHtmlSdk,
      HostArtifact.webPrecompiledAmdCanvaskitSoundSdk,
      HostArtifact.webPrecompiledAmdCanvaskitSdk,
      HostArtifact.webPrecompiledAmdSoundSdk,
      HostArtifact.webPrecompiledAmdSdk,
      HostArtifact.webPrecompiledDdcCanvaskitAndHtmlSoundSdk,
      HostArtifact.webPrecompiledDdcCanvaskitAndHtmlSdk,
      HostArtifact.webPrecompiledDdcCanvaskitSoundSdk,
      HostArtifact.webPrecompiledDdcCanvaskitSdk,
      HostArtifact.webPrecompiledDdcSoundSdk,
      HostArtifact.webPrecompiledDdcSdk,
    ]) {
      final File artifactFile = artifacts.getHostArtifact(artifact) as File;
      artifactFile.createSync();
      artifactFile.writeAsStringSync(artifact.name);
    }
  });

  testUsingContext(
      'FlutterWebPlatform serves the correct dart_sdk.js (amd module system) for the passed web renderer',
      () async {
    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
      logger: logger,
    );
    final MockServer server = MockServer();
    fileSystem.directory('/test').createSync();
    final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
      'ProjectRoot',
      buildInfo: const BuildInfo(BuildMode.debug, '', treeShakeIcons: false),
      webMemoryFS: WebMemoryFS(),
      fileSystem: fileSystem,
      buildDirectory: fileSystem.directory('build'),
      logger: logger,
      chromiumLauncher: chromiumLauncher,
      artifacts: artifacts,
      processManager: processManager,
      webRenderer: WebRendererMode.canvaskit,
      useWasm: false,
      serverFactory: () async => server,
      testPackageUri: Uri.parse('test'),
    );
    final shelf.Handler? handler = server.mountedHandler;
    expect(handler, isNotNull);
    handler!;
    final shelf.Response response = await handler(shelf.Request(
      'GET',
      Uri.parse('http://localhost/dart_sdk.js'),
    ));
    final String contents = await response.readAsString();
    expect(contents, HostArtifact.webPrecompiledAmdCanvaskitSoundSdk.name);
    await webPlatform.close();
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Logger: () => logger,
  });

  testUsingContext(
      'FlutterWebPlatform serves the correct dart_sdk.js (ddc module system) for the passed web renderer',
      () async {
    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
      logger: logger,
    );
    final MockServer server = MockServer();
    fileSystem.directory('/test').createSync();
    final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
      'ProjectRoot',
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>['--dartdevc-module-format=ddc'],
      ),
      webMemoryFS: WebMemoryFS(),
      fileSystem: fileSystem,
      buildDirectory: fileSystem.directory('build'),
      logger: logger,
      chromiumLauncher: chromiumLauncher,
      artifacts: artifacts,
      processManager: processManager,
      webRenderer: WebRendererMode.canvaskit,
      useWasm: false,
      serverFactory: () async => server,
      testPackageUri: Uri.parse('test'),
    );
    final shelf.Handler? handler = server.mountedHandler;
    expect(handler, isNotNull);
    handler!;
    final shelf.Response response = await handler(shelf.Request(
      'GET',
      Uri.parse('http://localhost/dart_sdk.js'),
    ));
    final String contents = await response.readAsString();
    expect(contents, HostArtifact.webPrecompiledDdcCanvaskitSoundSdk.name);
    await webPlatform.close();
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Logger: () => logger,
  });

  testUsingContext('FlutterWebPlatform serves the files in test asset directory', () async {
    impellerc = artifacts.getHostArtifact(HostArtifact.impellerc).path;
    fileSystem.file(impellerc).createSync(recursive: true);
    output = fileSystem.directory('asset_output')..createSync(recursive: true);
    shadersPath = 'shaders';
    shaderPath = fileSystem.path.join(shadersPath, 'shader.frag');
    outputPath = fileSystem.path.join(output.path, shadersPath, 'shader.frag');
    fileSystem.file(shaderPath).createSync(recursive: true);

    fileSystem.file('.packages').createSync();
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
  name: example
  flutter:
    shaders:
      - shaders/shader.frag
  ''');
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();

    expect(await assetBundle.build(packagesPath: '.packages', targetPlatform: TargetPlatform.web_javascript), 0);

    await writeBundle(
      output,
      assetBundle.entries,
      targetPlatform: TargetPlatform.web_javascript,
      impellerStatus: ImpellerStatus.disabled,
      processManager: globals.processManager,
      fileSystem: globals.fs,
      artifacts: globals.artifacts!,
      logger: testLogger,
      projectDir: globals.fs.currentDirectory,
    );

    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: (Platform platform, FileSystem filesystem) => 'chrome',
      logger: logger,
    );
    final MockServer server = MockServer();
    fileSystem.directory('/test').createSync();
    final FlutterWebPlatform webPlatform = await FlutterWebPlatform.start(
      'ProjectRoot',
      buildInfo: const BuildInfo(
        BuildMode.debug,
        '',
        treeShakeIcons: false,
        extraFrontEndOptions: <String>['--dartdevc-module-format=ddc'],
      ),
      webMemoryFS: WebMemoryFS(),
      fileSystem: fileSystem,
      buildDirectory: fileSystem.directory('build'),
      logger: logger,
      chromiumLauncher: chromiumLauncher,
      artifacts: artifacts,
      processManager: processManager,
      webRenderer: WebRendererMode.canvaskit,
      useWasm: false,
      serverFactory: () async => server,
      testPackageUri: Uri.parse('test'),
      assetPath: fileSystem.path.join(output.path),
    );
    final shelf.Handler? handler = server.mountedHandler;
    expect(handler, isNotNull);
    handler!;
    final shelf.Response response = await handler(shelf.Request(
      'GET',
      Uri.parse('http://localhost/assets/shaders/shader.frag'),
    ));
    // Check that we get a correct answer (the fragment file is empty because it
    // is a fake file created by this test).
    final String contents = await response.readAsString();
    expect(contents, isEmpty);

    await webPlatform.close();

    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            impellerc,
            '--sksl',
            '--iplr',
            '--json',
            '--sl=$outputPath',
            '--spirv=$outputPath.spirv',
            '--input=/$shaderPath',
            '--input-type=frag',
            '--include=/$shadersPath',
            '--include=$shaderLibDir',
          ],
          onRun: (_) {
            fileSystem.file(outputPath).createSync(recursive: true);
            fileSystem.file('$outputPath.spirv').createSync(recursive: true);
          },
        ),
      ]),
    });
}
