// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:build_daemon/client.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/build_runner/web_fs.dart';
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
  dynamic lastAddress;
  int lastPort;

  setUp(() {
    lastAddress = null;
    lastPort = null;
    mockBuildDaemonCreator =  MockBuildDaemonCreator();
    mockChromeLauncher = MockChromeLauncher();
    mockHttpMultiServer = MockHttpMultiServer();
    mockBuildDaemonClient = MockBuildDaemonClient();
    mockOperatingSystemUtils = MockOperatingSystemUtils();
    mockDwds = MockDwds();
    when(mockBuildDaemonCreator.startBuildDaemon(any, release: anyNamed('release')))
      .thenAnswer((Invocation _) async {
        return mockBuildDaemonClient;
      });
    when(mockOperatingSystemUtils.findFreePort()).thenAnswer((Invocation _) async {
      return 1234;
    });
    when(mockBuildDaemonClient.buildResults).thenAnswer((Invocation _) {
      return const Stream<BuildResults>.empty();
    });
    when(mockBuildDaemonCreator.assetServerPort(any)).thenReturn(4321);
    testbed = Testbed(
      setup: () {
        // Create an empty .packages file so we can read it when we check for
        // plugins on WebFs.start()
        fs.file('.packages').createSync();
      },
      overrides: <Type, Generator>{
        OperatingSystemUtils: () => mockOperatingSystemUtils,
        BuildDaemonCreator: () => mockBuildDaemonCreator,
        ChromeLauncher: () => mockChromeLauncher,
        HttpMultiServerFactory: () => (dynamic address, int port) async {
          lastAddress = address;
          lastPort = port;
          return mockHttpMultiServer;
        },
        DwdsFactory: () => ({
          @required int applicationPort,
          @required int assetServerPort,
          @required String applicationTarget,
          @required Stream<BuildResult> buildResults,
          @required ConnectionProvider chromeConnection,
          String hostname,
          ReloadConfiguration reloadConfiguration,
          bool serveDevTools,
          LogWriter logWriter,
          bool verbose,
          bool enableDebugExtension}) async {
            return mockDwds;
        },
      }
    );
  });

  test('Can create webFs from mocked interfaces', () => testbed.run(() async {
    final FlutterProject flutterProject = FlutterProject.current();
    await WebFs.start(
      skipDwds: false,
      target: fs.path.join('lib', 'main.dart'),
      buildInfo: BuildInfo.debug,
      flutterProject: flutterProject,
      hostname: null,
      port: null,
    );

    // The build daemon is told to build once.
    verify(mockBuildDaemonClient.startBuild()).called(1);

    // .dart_tool directory is created.
    expect(flutterProject.dartTool.existsSync(), true);
  }));

  test('Uses provided port number and hostname.', () => testbed.run(() async {
    final FlutterProject flutterProject = FlutterProject.current();
    await WebFs.start(
      skipDwds: false,
      target: fs.path.join('lib', 'main.dart'),
      buildInfo: BuildInfo.debug,
      flutterProject: flutterProject,
      hostname: 'foo',
      port: '1234',
    );

    expect(lastPort, 1234);
    expect(lastAddress, contains('foo'));
  }));
}

class MockBuildDaemonCreator extends Mock implements BuildDaemonCreator {}
class MockBuildDaemonClient extends Mock implements BuildDaemonClient {}
class MockDwds extends Mock implements Dwds {}
class MockHttpMultiServer extends Mock implements HttpMultiServer {}
class MockChromeLauncher extends Mock implements ChromeLauncher {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

