// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:build_daemon/client.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:built_collection/built_collection.dart';
import 'package:dwds/asset_handler.dart';
import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/build_runner/web_fs.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:http_multi_server/http_multi_server.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  MockBuildDaemonCreator mockBuildDaemonCreator;
  MockDwds mockDwds;
  MockChromeLauncher mockChromeLauncher;
  MockHttpMultiServer mockHttpMultiServer;
  MockBuildDaemonClient mockBuildDaemonClient;
  MockOperatingSystemUtils mockOperatingSystemUtils;
  MockProcessUtils mockProcessUtils;
  bool lastInitializePlatform;
  dynamic lastAddress;
  int lastPort;

  setUp(() {
    lastAddress = null;
    lastPort = null;
    lastInitializePlatform = null;
    mockBuildDaemonCreator =  MockBuildDaemonCreator();
    mockChromeLauncher = MockChromeLauncher();
    mockHttpMultiServer = MockHttpMultiServer();
    mockBuildDaemonClient = MockBuildDaemonClient();
    mockOperatingSystemUtils = MockOperatingSystemUtils();
    mockDwds = MockDwds();
    mockProcessUtils = MockProcessUtils();
    when(mockBuildDaemonCreator.startBuildDaemon(any, release: anyNamed('release'), initializePlatform: anyNamed('initializePlatform')))
      .thenAnswer((Invocation invocation) async {
        lastInitializePlatform = invocation.namedArguments[#initializePlatform] as bool;
        return mockBuildDaemonClient;
      });
    when(mockOperatingSystemUtils.findFreePort()).thenAnswer((Invocation _) async {
      return 1234;
    });
    when(mockProcessUtils.stream(
      any,
      workingDirectory: anyNamed('workingDirectory'),
      mapFunction: anyNamed('mapFunction'),
      environment: anyNamed('environment'),
    )).thenAnswer((Invocation invocation) async {
      final String workingDirectory = invocation.namedArguments[#workingDirectory] as String;
      globals.fs.file(globals.fs.path.join(workingDirectory, '.packages')).createSync(recursive: true);
      return 0;
    });
    when(mockBuildDaemonClient.buildResults).thenAnswer((Invocation _) {
      return Stream<BuildResults>.fromFuture(Future<BuildResults>.value(
        BuildResults((BuildResultsBuilder builder) {
          builder.results = ListBuilder<BuildResult>(
            <BuildResult>[
              DefaultBuildResult((DefaultBuildResultBuilder builder) {
                builder.target = 'web';
                builder.status = BuildStatus.succeeded;
              }),
            ],
          );
        })
      ));
    });
    when(mockBuildDaemonCreator.assetServerPort(any)).thenReturn(4321);
    testbed = Testbed(
      setup: () {
        globals.fs.file(globals.fs.path.join('packages', 'flutter_tools', 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..setLastModifiedSync(DateTime(1991, 08, 23));
        // Create an empty .packages file so we can read it when we check for
        // plugins on Webglobals.fs.start()
        globals.fs.file('.packages').createSync();
      },
      overrides: <Type, Generator>{
        Pub: () => MockPub(),
        OperatingSystemUtils: () => mockOperatingSystemUtils,
        BuildDaemonCreator: () => mockBuildDaemonCreator,
        ChromeLauncher: () => mockChromeLauncher,
        ProcessUtils: () => mockProcessUtils,
        HttpMultiServerFactory: () => (dynamic address, int port) async {
          lastAddress = address;
          lastPort = port;
          return mockHttpMultiServer;
        },
        DwdsFactory: () => ({
          @required AssetHandler assetHandler,
          @required Stream<BuildResult> buildResults,
          @required ConnectionProvider chromeConnection,
          String hostname,
          ReloadConfiguration reloadConfiguration,
          bool serveDevTools,
          LogWriter logWriter,
          bool verbose,
          bool enableDebugExtension,
          UrlEncoder urlEncoder,
        }) async {
          return mockDwds;
        },
      },
    );
  });

  test('Can create webFs from mocked interfaces', () => testbed.run(() async {
    final FlutterProject flutterProject = FlutterProject.current();
    await WebFs.start(
      skipDwds: false,
      target: globals.fs.path.join('lib', 'main.dart'),
      buildInfo: BuildInfo.debug,
      flutterProject: flutterProject,
      initializePlatform: true,
      hostname: null,
      port: null,
      urlTunneller: null,
      dartDefines: const <String>[],
    );
    // Since the .packages file is missing in the memory filesystem, this should
    // be called.
    verify(pub.get(
      context: PubContext.pubGet,
      directory: anyNamed('directory'),
      offline: true,
      skipPubspecYamlCheck: true,
      checkLastModified: false,
    )).called(1);

    // The build daemon is told to build once.
    verify(mockBuildDaemonClient.startBuild()).called(1);

    // .dart_tool directory is created.
    expect(flutterProject.dartTool.existsSync(), true);
    expect(lastInitializePlatform, true);
  }));

  test('Can create webFs from mocked interfaces with initializePlatform', () => testbed.run(() async {
    final FlutterProject flutterProject = FlutterProject.current();
    await WebFs.start(
      skipDwds: false,
      target: globals.fs.path.join('lib', 'main.dart'),
      buildInfo: BuildInfo.debug,
      flutterProject: flutterProject,
      initializePlatform: false,
      hostname: null,
      port: null,
      urlTunneller: null,
      dartDefines: const <String>[],
    );

    // The build daemon is told to build once.
    verify(mockBuildDaemonClient.startBuild()).called(1);

    // .dart_tool directory is created.
    expect(flutterProject.dartTool.existsSync(), true);
    expect(lastInitializePlatform, false);
  }));

  test('Uses provided port number and hostname.', () => testbed.run(() async {
    final FlutterProject flutterProject = FlutterProject.current();
    final WebFs webFs = await WebFs.start(
      skipDwds: false,
      target: globals.fs.path.join('lib', 'main.dart'),
      buildInfo: BuildInfo.debug,
      flutterProject: flutterProject,
      initializePlatform: false,
      hostname: 'foo',
      port: '1234',
      urlTunneller: null,
      dartDefines: const <String>[],
    );

    expect(webFs.uri, contains('foo:1234'));
    expect(lastPort, 1234);
    expect(lastAddress, contains('foo'));
  }));

  test('Throws exception if build fails', () => testbed.run(() async {
    when(mockBuildDaemonClient.buildResults).thenAnswer((Invocation _) {
      return Stream<BuildResults>.fromFuture(Future<BuildResults>.value(
        BuildResults((BuildResultsBuilder builder) {
          builder.results = ListBuilder<BuildResult>(
            <BuildResult>[
              DefaultBuildResult((DefaultBuildResultBuilder builder) {
                builder.target = 'web';
                builder.status = BuildStatus.failed;
              }),
            ],
          );
        })
      ));
    });
    final FlutterProject flutterProject = FlutterProject.current();

    expect(WebFs.start(
      skipDwds: false,
      target: globals.fs.path.join('lib', 'main.dart'),
      buildInfo: BuildInfo.debug,
      flutterProject: flutterProject,
      initializePlatform: false,
      hostname: 'foo',
      port: '1234',
      urlTunneller: null,
      dartDefines: const <String>[],
    ), throwsA(isInstanceOf<Exception>()));
  }));
}

class MockBuildDaemonCreator extends Mock implements BuildDaemonCreator {}
class MockBuildDaemonClient extends Mock implements BuildDaemonClient {}
class MockDwds extends Mock implements Dwds {}
class MockHttpMultiServer extends Mock implements HttpMultiServer {}
class MockChromeLauncher extends Mock implements ChromeLauncher {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class MockProcessUtils extends Mock implements ProcessUtils {}
class MockPub extends Mock implements Pub {}
