// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Process, ProcessStartMode;

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/dart/analysis.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
import 'package:flutter_tools/src/widget_preview/persistent_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:test/fake.dart';
import 'package:widget_preview_scaffold/src/dtd/dtd_services.dart';

import '../../../../packages/flutter_tools/test/src/common.dart';
import '../../../../packages/flutter_tools/test/src/fake_process_manager.dart'
    show ProcessManager;
import '../../../../packages/flutter_tools/test/src/fakes.dart';

const _kProjectRootPath = '/project';

class _LocalProcessManager extends Fake implements ProcessManager {
  @override
  Future<Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    return Process.start(
      command.first.toString(),
      <String>[for (final Object arg in command.skip(1)) arg.toString()],
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
  }
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject();
}

class FakeAnalysisServer extends Fake implements AnalysisServer {
  @override
  Future<void> connectToDtd({required Uri dtdUri}) async {}
}

class _FakeDtdArtifacts extends Fake implements Artifacts {
  _FakeDtdArtifacts({required this.dartBinaryPath});

  final String dartBinaryPath;

  @override
  String getArtifactPath(
    Artifact artifact, {
    TargetPlatform? platform,
    BuildMode? mode,
    EnvironmentType? environmentType,
  }) {
    if (artifact == Artifact.engineDartBinary) {
      return dartBinaryPath;
    }
    throw UnimplementedError('Unexpected artifact: $artifact');
  }
}

String _resolveDartBinaryPath() {
  const Platform platform = LocalPlatform();
  final String flutterRoot = switch (platform.environment['FLUTTER_ROOT']) {
    final String root when root.isNotEmpty => root,
    _ => path.normalize(path.absolute('..', '..', '..')),
  };
  final String dartBinaryName = platform.isWindows ? 'dart.exe' : 'dart';
  return path.join(
    flutterRoot,
    'bin',
    'cache',
    'dart-sdk',
    'bin',
    dartBinaryName,
  );
}

void main() {
  late WidgetPreviewDtdServices dtdServer;
  late Logger logger;
  WidgetPreviewScaffoldDtdServices? scaffoldDtd;

  setUp(() {
    logger = BufferLogger.test();
  });

  tearDown(() async {
    await scaffoldDtd?.dtd.close();
    scaffoldDtd = null;
    await dtdServer.shutdownHooks.runShutdownHooks(logger);
  });

  Future<WidgetPreviewDtdServices> launchDtdServer({
    Future<void> Function()? onHotReloadPreviewer,
    void Function()? onHotRestartPreviewerRequest,
    Uri? Function()? webPreviewUriProvider,
  }) async {
    final server = WidgetPreviewDtdServices(
      addUuidToServiceName: false,
      dtdLauncher: DtdLauncher(
        artifacts: _FakeDtdArtifacts(dartBinaryPath: _resolveDartBinaryPath()),
        logger: logger,
        processManager: _LocalProcessManager(),
      ),
      fs: MemoryFileSystem.test(),
      logger: logger,
      onHotReloadPreviewer: onHotReloadPreviewer,
      onHotRestartPreviewerRequest: onHotRestartPreviewerRequest ?? () {},
      previewAnalytics: WidgetPreviewAnalytics(
        analytics: getInitializedFakeAnalyticsInstance(
          // We don't care about anything written to the file system by analytics, so we're safe
          // to use a different file system here.
          fs: MemoryFileSystem.test(),
          fakeFlutterVersion: FakeFlutterVersion(),
        ),
      ),
      project: FakeFlutterProject(),
      projectRootPath: _kProjectRootPath,
      shutdownHooks: ShutdownHooks(),
      webPreviewUriProvider: webPreviewUriProvider,
    );
    await server.launchAndConnect(analysisServer: FakeAnalysisServer());
    return server;
  }

  group('$WidgetPreviewDtdServices', () {
    testWithoutContext(
      'handles ${WidgetPreviewDtdServices.kHotRestartPreviewer} and '
      '${WidgetPreviewDtdServices.kHotReloadPreviewer} invocations',
      () async {
        final hotRestartRequestCompleter = Completer<void>();
        final hotReloadRequestCompleter = Completer<void>();
        dtdServer = await launchDtdServer(
          onHotReloadPreviewer: () async {
            hotReloadRequestCompleter.complete();
          },
          onHotRestartPreviewerRequest: hotRestartRequestCompleter.complete,
        );

        final dtd = WidgetPreviewScaffoldDtdServices();
        scaffoldDtd = dtd;
        expect(
          dtd.scaffoldServiceName,
          WidgetPreviewDtdServices.kWidgetPreviewScaffoldServiceRoot,
        );
        await dtd.connect(dtdUri: dtdServer.dtdUri);

        await dtd.hotRestartPreviewer();
        await hotRestartRequestCompleter.future;

        await dtd.hotReloadPreviewer();
        await hotReloadRequestCompleter.future;
      },
    );

    testWithoutContext(
      'handles ${WidgetPreviewDtdServices.kGetWebPreviewUrl} and '
      '${WidgetPreviewDtdServices.kGetServiceInfo} invocations',
      () async {
        Uri? currentWebUri;
        dtdServer = await launchDtdServer(
          webPreviewUriProvider: () => currentWebUri,
        );

        final dtd = WidgetPreviewScaffoldDtdServices();
        scaffoldDtd = dtd;
        await dtd.connect(dtdUri: dtdServer.dtdUri);
        await dtdServer.waitForScaffoldConnected();

        // Returns null when web preview URL is unavailable (kNoValueForKey).
        expect(await dtd.getWebPreviewUrl(), isNull);

        // Returns active web preview Uri once available.
        final expectedWebUri = Uri.parse('http://127.0.0.1:8080');
        currentWebUri = expectedWebUri;
        expect(await dtd.getWebPreviewUrl(), expectedWebUri);

        final Map<String, Object?>? info = await dtd.getServiceInfo();
        expect(info, isNotNull);
        expect(info![PreviewServiceInfo.kType], PreviewServiceInfo.kTypeName);
        expect(info[PreviewServiceInfo.kDtdUri], dtdServer.dtdUri.toString());
        expect(info[PreviewServiceInfo.kProjectRoot], _kProjectRootPath);
        expect(
          info[PreviewServiceInfo.kPreviewService],
          WidgetPreviewDtdServices.kWidgetPreviewServiceRoot,
        );
        expect(
          info[PreviewServiceInfo.kScaffoldService],
          WidgetPreviewDtdServices.kWidgetPreviewScaffoldServiceRoot,
        );
        expect(
          info[PreviewServiceInfo.kScaffoldStream],
          WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot,
        );
        expect(
          info[PreviewServiceInfo.kWebPreviewUri],
          expectedWebUri.toString(),
        );
        expect(info[PreviewServiceInfo.kScaffoldConnected], isTrue);
      },
    );

    testWithoutContext(
      'handles ${WidgetPreviewDtdServices.kGetDevToolsUri} invocation',
      () async {
        // Start DTD and register the widget preview DTD services.
        dtdServer = await launchDtdServer();

        // Connect to the DTD instance and invoke the getDevToolsUri endpoint.
        final dtd = WidgetPreviewScaffoldDtdServices();
        scaffoldDtd = dtd;
        await dtd.connect(dtdUri: dtdServer.dtdUri);

        final Future<Uri> devToolsUriResponseFuture = dtd.getDevToolsUri();

        dtdServer.setDevToolsServerAddress(
          devToolsServerAddress: Uri.http('localhost:8282', 'devtools'),
          applicationUri: Uri(scheme: 'ws', host: 'localhost', port: 1234),
        );
        final Uri actualDevToolsUri = await dtdServer.devToolsServerAddress;
        expect(await devToolsUriResponseFuture, actualDevToolsUri);
      },
    );

    testWithoutContext(
      'can set and retrieve values from $PersistentPreferences',
      () async {
        dtdServer = await launchDtdServer();

        // The properties file should be created by the PersistentProperties constructor.
        final File preferencesFile = dtdServer.preferences.file;
        expect(preferencesFile.existsSync(), true);

        // Connect to the DTD instance.
        final dtd = WidgetPreviewScaffoldDtdServices();
        scaffoldDtd = dtd;
        await dtd.connect(dtdUri: dtdServer.dtdUri);

        const kTestKey = 'myKey';

        // The preferences file should be empty.
        expect(await dtd.getPreference(kTestKey), null);
        expect(preferencesFile.readAsStringSync(), isEmpty);

        // Set a preference and ensure it's read back.
        const kFirstValue = 'foo';
        await dtd.setPreference(kTestKey, kFirstValue);
        expect(await dtd.getPreference(kTestKey), kFirstValue);
        expect(
          json.decode(preferencesFile.readAsStringSync()),
          <String, Object?>{kTestKey: kFirstValue},
        );

        // Overwrite kTestKey and ensure it's read back.
        const kSecondValue = 'bar';
        await dtd.setPreference(kTestKey, kSecondValue);
        expect(await dtd.getPreference(kTestKey), kSecondValue);
        expect(
          json.decode(preferencesFile.readAsStringSync()),
          <String, Object?>{kTestKey: kSecondValue},
        );

        // Write a flag.
        const kFlagKey = 'flag';
        await dtd.setPreference(kFlagKey, true);
        expect(await dtd.getFlag(kFlagKey), true);
        expect(
          json.decode(preferencesFile.readAsStringSync()),
          <String, Object?>{kFlagKey: true, kTestKey: kSecondValue},
        );

        // Remove an entry.
        await dtd.setPreference(kTestKey, null);
        expect(await dtd.getPreference(kTestKey), null);
        expect(
          json.decode(preferencesFile.readAsStringSync()),
          <String, Object?>{kFlagKey: true},
        );
      },
    );
  });
}
