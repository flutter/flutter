// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide Directory, File;

import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/devfs_web.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/devfs_config.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

/// Helper function to create a [WebDevFS] with sensible testbed defaults.
WebDevFS createWebDevFS({
  String packagesFilePath = '.dart_tool/package_config.json',
  UrlTunneller? urlTunneller,
  bool useSseForDebugProxy = false,
  bool useSseForDebugBackend = false,
  bool useSseForInjectedClient = false,
  BuildInfo buildInfo = BuildInfo.debug,
  bool enableDwds = false,
  DartDevelopmentServiceConfiguration ddsConfig = const DartDevelopmentServiceConfiguration(),
  Uri? entrypoint,
  ExpressionCompiler? expressionCompiler,
  ChromiumLauncher? chromiumLauncher,
  bool nativeNullAssertions = true,
  bool ddcModuleSystem = false,
  bool canaryFeatures = false,
  WebDevServerConfig webDevServerConfig = const WebDevServerConfig(),
  WebRendererMode webRenderer = WebRendererMode.canvaskit,
  bool isWasm = false,
  bool useLocalCanvasKit = false,
  Directory? rootDirectory,
  bool useDwdsWebSocketConnection = false,
  bool webCrossOriginIsolation = false,
  FileSystem? fileSystem,
  Logger? logger,
  Platform? platform,
  bool testMode = true,
  Map<String, String> webDefines = const <String, String>{},
}) {
  return WebDevFS(
    packagesFilePath: packagesFilePath,
    urlTunneller: urlTunneller,
    useSseForDebugProxy: useSseForDebugProxy,
    useSseForDebugBackend: useSseForDebugBackend,
    useSseForInjectedClient: useSseForInjectedClient,
    buildInfo: buildInfo,
    enableDwds: enableDwds,
    ddsConfig: ddsConfig,
    entrypoint: entrypoint ?? globals.fs.file('lib/main.dart').uri,
    expressionCompiler: expressionCompiler,
    chromiumLauncher: chromiumLauncher,
    nativeNullAssertions: nativeNullAssertions,
    ddcModuleSystem: ddcModuleSystem,
    canaryFeatures: canaryFeatures,
    webDevServerConfig: webDevServerConfig,
    webRenderer: webRenderer,
    isWasm: isWasm,
    useLocalCanvasKit: useLocalCanvasKit,
    rootDirectory: rootDirectory ?? globals.fs.currentDirectory,
    useDwdsWebSocketConnection: useDwdsWebSocketConnection,
    webCrossOriginIsolation: webCrossOriginIsolation,
    fileSystem: fileSystem ?? globals.fs,
    logger: logger ?? globals.logger,
    platform: platform ?? globals.platform,
    testMode: testMode,
    webDefines: webDefines,
  );
}

/// A fake [HttpServer] for testing.
class FakeHttpServer extends Fake implements HttpServer {
  bool closed = false;

  @override
  Future<void> close({bool force = false}) async {
    closed = true;
  }
}

/// A fake [ResidentCompiler] for testing.
class FakeResidentCompiler extends Fake implements ResidentCompiler {
  CompilerOutput? output;

  @override
  void addFileSystemRoot(String root) {}

  @override
  Future<CompilerOutput?> recompile(
    Uri mainUri,
    List<Uri>? invalidatedFiles, {
    String? outputPath,
    PackageConfig? packageConfig,
    String? projectRootPath,
    FileSystem? fs,
    bool suppressErrors = false,
    bool checkDartPluginRegistry = false,
    File? dartPluginRegistrant,
    Uri? nativeAssetsYaml,
    bool recompileRestart = false,
  }) async {
    return output;
  }
}

/// A fake [DevelopmentShaderCompiler] for testing.
class FakeShaderCompiler implements DevelopmentShaderCompiler {
  const FakeShaderCompiler({this.returnNull = false});

  final bool returnNull;

  @override
  void configureCompiler(TargetPlatform? platform) {}

  @override
  Future<DevFSContent?> recompileShader(DevFSContent inputShader) async {
    if (returnNull) {
      return null;
    }
    final String source = utf8.decode(await inputShader.contentsAsBytes());
    return DevFSStringContent('compiled_shader: $source');
  }

  @override
  bool areDependenciesModified(DevFSContent shaderContent) => false;
}

/// A fake [AssetBundle] for testing.
class FakeAssetBundle extends Fake implements AssetBundle {
  @override
  final Map<String, AssetBundleEntry> entries = <String, AssetBundleEntry>{};
}

/// A fake [Dwds] service for testing.
class FakeDwds extends Fake implements Dwds {
  FakeDwds(Iterable<AppConnection> connectedAppsIterable)
    : connectedApps = Stream<AppConnection>.fromIterable(connectedAppsIterable);

  @override
  final Stream<AppConnection> connectedApps;

  @override
  Future<DebugConnection> debugConnection(AppConnection appConnection) =>
      Future<DebugConnection>.value(FakeDebugConnection());
}

/// A fake [AppConnection] for testing.
class FakeAppConnection extends Fake implements AppConnection {
  @override
  void runMain() {}
}

/// A fake [DebugConnection] for testing.
class FakeDebugConnection extends Fake implements DebugConnection {
  FakeDebugConnection({this.uri = 'http://foo'});

  @override
  final String uri;
}

/// A fake [vm_service.VmService] for testing.
class FakeVmService extends Fake implements vm_service.VmService {}
