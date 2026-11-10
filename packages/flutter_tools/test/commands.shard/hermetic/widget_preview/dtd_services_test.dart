// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dtd_services.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../src/common.dart';
import '../../../src/fakes.dart';

class FakeWidgetPreviewAnalytics extends Fake implements WidgetPreviewAnalytics {
  int reportPreviewerConnectedCount = 0;

  @override
  void reportPreviewerConnected() {
    reportPreviewerConnectedCount++;
  }
}

class FakeDtdLauncher extends Fake implements DtdLauncher {
  @override
  Future<void> dispose() async {}
}

class FakeDartToolingDaemon extends Fake implements DartToolingDaemon {
  final postedEvents = <({String streamId, String eventKind, Map<String, Object?> eventData})>[];
  final registeredMethods = <String, Map<String, DTDServiceCallback>>{};
  final _eventControllers = <String, StreamController<DTDEvent>>{};
  final subscribedStreams = <String>{};
  int getRegisteredServicesCallCount = 0;
  int streamListenCallCount = 0;
  int streamCancelCallCount = 0;
  int waitForAnalysisCallCount = 0;
  RegisteredServicesResponse registeredServicesResponse = const RegisteredServicesResponse(
    clientServices: [],
    dtdServices: <String>[],
  );
  RpcException? streamListenError;

  bool hasListener(String streamId) => _eventControllers[streamId]?.hasListener ?? false;

  @override
  Future<void> registerService(
    String service,
    String method,
    DTDServiceCallback callback, {
    Map<String, Object?>? capabilities,
  }) async {
    registeredMethods.putIfAbsent(service, () => <String, DTDServiceCallback>{})[method] = callback;
  }

  @override
  Future<void> postEvent(String streamId, String eventKind, Map<String, Object?> eventData) async {
    postedEvents.add((streamId: streamId, eventKind: eventKind, eventData: eventData));
  }

  @override
  Future<void> streamListen(String streamId) async {
    streamListenCallCount++;
    if (streamListenError case final RpcException error) {
      throw error;
    }
    if (subscribedStreams.contains(streamId)) {
      throw RpcException(RpcErrorCodes.kStreamAlreadySubscribed, 'Stream already subscribed');
    }
    subscribedStreams.add(streamId);
  }

  @override
  Future<void> streamCancel(String streamId) async {
    streamCancelCallCount++;
    if (!subscribedStreams.contains(streamId)) {
      throw RpcException(RpcErrorCodes.kStreamNotSubscribed, 'Stream not subscribed');
    }
    subscribedStreams.remove(streamId);
  }

  @override
  Stream<DTDEvent> onEvent(String streamId) {
    return _eventControllers.putIfAbsent(streamId, StreamController<DTDEvent>.broadcast).stream;
  }

  void postFakeEvent(String streamId, String eventKind, Map<String, Object?> eventData) {
    _eventControllers[streamId]?.add(DTDEvent(streamId, eventKind, eventData, 0));
  }

  @override
  Future<RegisteredServicesResponse> getRegisteredServices() async {
    getRegisteredServicesCallCount++;
    return registeredServicesResponse;
  }

  @override
  Future<DTDResponse> call(
    String? serviceName,
    String methodName, {
    Map<String, Object?>? params,
  }) async {
    if (serviceName == 'Lsp' &&
        (methodName == 'dart/workspace/getFlutterWidgetPreviews' ||
            methodName == 'dart/textDocument/getFlutterWidgetPreviews')) {
      return DTDResponse('1', 'result', <String, Object?>{
        'result': <String, Object?>{
          'namespaces': <String, String>{},
          'previews': <Map<String, Object?>>[],
          'scriptUris': <String>[],
        },
      });
    }
    if (serviceName == 'Lsp' && methodName == 'dart/workspace/analysis/complete') {
      waitForAnalysisCallCount++;
      return DTDResponse('1', 'Null', <String, Object?>{'type': 'Null', 'result': null});
    }
    throw UnimplementedError('Unexpected call: $serviceName.$methodName');
  }

  @override
  Future<void> close() async {
    for (final StreamController<DTDEvent> controller in _eventControllers.values) {
      await controller.close();
    }
  }
}

DTDServiceCallback _callbackFor(WidgetPreviewDtdServices services, String method) {
  for (final (String name, DTDServiceCallback callback) in services.services) {
    if (name == method) {
      return callback;
    }
  }
  fail('Expected service method "$method" to be registered.');
}

void main() {
  group('DTD Types', () {
    testWithoutContext('WebPreviewUrlResult serialization, fromDTDResponse, and equality', () {
      const result = WebPreviewUrlResult(
        host: '127.0.0.1',
        port: 8080,
        url: 'http://127.0.0.1:8080',
      );

      final Map<String, Object?> json = result.toJson();
      expect(json[WebPreviewUrlResult.kType], WebPreviewUrlResult.kTypeName);
      final deserialized = WebPreviewUrlResult.fromDTDResponse(
        DTDResponse('1', WebPreviewUrlResult.kTypeName, json),
      );

      expect(deserialized, equals(result));
      expect(deserialized.hashCode, equals(result.hashCode));
      expect(deserialized.host, '127.0.0.1');
      expect(deserialized.port, 8080);
      expect(deserialized.url, 'http://127.0.0.1:8080');
      expect(deserialized.toString(), contains('8080'));

      expect(
        () => WebPreviewUrlResult.fromDTDResponse(
          DTDResponse('1', 'WrongType', <String, Object?>{'type': 'WrongType'}),
        ),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', error_code.INVALID_PARAMS),
        ),
      );
    });

    testWithoutContext('PreviewServiceInfo serialization, fromDTDResponse, and equality', () {
      const info = PreviewServiceInfo(
        dtdUri: 'ws://127.0.0.1:42135/xyz',
        previewService: 'widget-preview-123',
        projectRoot: '/abs/path/to/project',
        scaffoldConnected: true,
        scaffoldService: 'PreviewScaffold-123',
        scaffoldStream: 'WidgetPreviewScaffold-123',
        webPreviewUri: 'http://127.0.0.1:8080',
      );

      final Map<String, Object?> json = info.toJson();
      expect(json[PreviewServiceInfo.kType], PreviewServiceInfo.kTypeName);
      final deserialized = PreviewServiceInfo.fromDTDResponse(
        DTDResponse('1', PreviewServiceInfo.kTypeName, json),
      );

      expect(deserialized, equals(info));
      expect(deserialized.hashCode, equals(info.hashCode));
      expect(deserialized.dtdUri, 'ws://127.0.0.1:42135/xyz');
      expect(deserialized.projectRoot, '/abs/path/to/project');
      expect(deserialized.previewService, 'widget-preview-123');
      expect(deserialized.scaffoldService, 'PreviewScaffold-123');
      expect(deserialized.scaffoldStream, 'WidgetPreviewScaffold-123');
      expect(deserialized.webPreviewUri, 'http://127.0.0.1:8080');
      expect(deserialized.scaffoldConnected, isTrue);
      expect(deserialized.toString(), contains('PreviewScaffold-123'));

      const disconnectedInfo = PreviewServiceInfo(
        dtdUri: 'ws://127.0.0.1:42135/xyz',
        previewService: 'widget-preview',
        projectRoot: '/abs/path/to/project',
        scaffoldConnected: false,
        scaffoldService: 'PreviewScaffold',
        scaffoldStream: 'WidgetPreviewScaffold',
      );
      final Map<String, Object?> disconnectedJson = disconnectedInfo.toJson();
      expect(disconnectedJson.containsKey(PreviewServiceInfo.kWebPreviewUri), isTrue);
      expect(disconnectedJson[PreviewServiceInfo.kWebPreviewUri], isNull);
      expect(
        PreviewServiceInfo.fromDTDResponse(
          DTDResponse('1', PreviewServiceInfo.kTypeName, disconnectedJson),
        ),
        equals(disconnectedInfo),
      );

      expect(
        () => PreviewServiceInfo.fromDTDResponse(
          DTDResponse('1', 'WrongType', <String, Object?>{'type': 'WrongType'}),
        ),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', error_code.INVALID_PARAMS),
        ),
      );
    });

    testWithoutContext('SyncPreviewsResponse serialization, fromDTDResponse, and equality', () {
      const okResponse = SyncPreviewsResponse(
        compileSuccess: true,
        errorPreviewCount: 0,
        fullRestart: false,
        reloaded: true,
      );
      final Map<String, Object?> okJson = okResponse.toJson();
      expect(okJson[SyncPreviewsResponse.kType], SyncPreviewsResponse.kTypeName);
      expect(okJson.containsKey(SyncPreviewsResponse.kCompileError), isTrue);
      expect(okJson[SyncPreviewsResponse.kCompileError], isNull);

      final deserializedOk = SyncPreviewsResponse.fromDTDResponse(
        DTDResponse('1', SyncPreviewsResponse.kTypeName, okJson),
      );
      expect(deserializedOk, equals(okResponse));
      expect(deserializedOk.hashCode, equals(okResponse.hashCode));

      const failedResponse = SyncPreviewsResponse(
        compileError: 'Failed to recompile application.',
        compileSuccess: false,
        errorPreviewCount: 2,
        fullRestart: true,
        reloaded: false,
      );
      final Map<String, Object?> failedJson = failedResponse.toJson();
      final deserializedFailed = SyncPreviewsResponse.fromDTDResponse(
        DTDResponse('1', SyncPreviewsResponse.kTypeName, failedJson),
      );
      expect(deserializedFailed, equals(failedResponse));
      expect(deserializedFailed.compileError, 'Failed to recompile application.');
      expect(deserializedFailed.errorPreviewCount, 2);
      expect(deserializedFailed.fullRestart, isTrue);
      expect(deserializedFailed.reloaded, isFalse);
      expect(deserializedFailed.toString(), contains('Failed to recompile application.'));

      expect(
        () => SyncPreviewsResponse.fromDTDResponse(
          DTDResponse('1', 'WrongType', <String, Object?>{'type': 'WrongType'}),
        ),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', error_code.INVALID_PARAMS),
        ),
      );
    });
  });

  group('WidgetPreviewDtdServices Method Registration & Handlers', () {
    late FileSystem fs;
    late Logger logger;
    late ShutdownHooks shutdownHooks;
    late FlutterProject project;
    late WidgetPreviewAnalytics analytics;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
      shutdownHooks = ShutdownHooks();
      final Directory projectDir = fs.directory('/project')..createSync(recursive: true);
      projectDir.childFile('pubspec.yaml').writeAsStringSync('name: test_project\n');
      final projectFactory = FlutterProjectFactory(
        config: FakeConfig(),
        fileSystem: fs,
        logger: logger,
      );
      project = projectFactory.fromDirectory(projectDir);
      analytics = WidgetPreviewAnalytics(analytics: const NoOpAnalytics());
    });

    testWithoutContext('builds matching service and stream names with and without UUID', () {
      final withoutUuid = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );
      expect(withoutUuid.widgetPreviewService, 'widget-preview');
      expect(withoutUuid.widgetPreviewScaffoldService, 'PreviewScaffold');
      expect(withoutUuid.widgetPreviewScaffoldStream, 'WidgetPreviewScaffold');

      final withUuid = WidgetPreviewDtdServices(
        addUuidToServiceName: true,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );
      final String uuid = withUuid.serviceUuid;
      expect(uuid, isNotEmpty);
      expect(withUuid.widgetPreviewService, 'widget-preview-$uuid');
      expect(withUuid.widgetPreviewScaffoldService, 'PreviewScaffold-$uuid');
      expect(withUuid.widgetPreviewScaffoldStream, 'WidgetPreviewScaffold-$uuid');
    });

    testWithoutContext('registers expected DTD service methods', () {
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      final registeredNames = <String>{for (final (String name, _) in services.services) name};
      expect(
        registeredNames,
        equals(<String>{
          WidgetPreviewDtdServices.kHotRestartPreviewer,
          WidgetPreviewDtdServices.kHotReloadPreviewer,
          WidgetPreviewDtdServices.kIsWindows,
          WidgetPreviewDtdServices.kResolveUri,
          WidgetPreviewDtdServices.kSetPreference,
          WidgetPreviewDtdServices.kGetPreference,
          WidgetPreviewDtdServices.kGetDevToolsUri,
          WidgetPreviewDtdServices.kGetWebPreviewUrl,
          WidgetPreviewDtdServices.kGetServiceInfo,
          WidgetPreviewDtdServices.kSyncPreviews,
        }),
      );
    });

    testWithoutContext('invokes onHotReloadPreviewer when hotReloadPreviewer is called', () async {
      var hotReloadCalled = false;
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotReloadPreviewer: () async {
          hotReloadCalled = true;
        },
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      final DTDServiceCallback callback = _callbackFor(
        services,
        WidgetPreviewDtdServices.kHotReloadPreviewer,
      );
      final Map<String, Object?> response = await callback(
        Parameters('hotReloadPreviewer', <String, Object?>{}),
      );

      expect(hotReloadCalled, isTrue);
      expect(response, equals(const Success().toJson()));
    });

    testWithoutContext('returns web preview URL when webPreviewUriProvider is provided', () async {
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
        webPreviewUriProvider: () => Uri.parse('http://127.0.0.1:9090'),
      );

      final DTDServiceCallback callback = _callbackFor(
        services,
        WidgetPreviewDtdServices.kGetWebPreviewUrl,
      );
      final Map<String, Object?> response = await callback(
        Parameters('getWebPreviewUrl', <String, Object?>{}),
      );

      expect(response[WebPreviewUrlResult.kType], WebPreviewUrlResult.kTypeName);
      expect(response['host'], '127.0.0.1');
      expect(response['port'], 9090);
      expect(response['url'], 'http://127.0.0.1:9090');
    });

    testWithoutContext('throws RpcException from getWebPreviewUrl when webPreviewUriProvider is null or returns null', () async {
      final servicesWithoutCallback = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      final DTDServiceCallback callbackWithout = _callbackFor(
        servicesWithoutCallback,
        WidgetPreviewDtdServices.kGetWebPreviewUrl,
      );

      await expectLater(
        callbackWithout(Parameters('getWebPreviewUrl', <String, Object?>{})),
        throwsA(
          isA<RpcException>().having(
            (RpcException e) => e.code,
            'code',
            WidgetPreviewDtdServices.kNoValueForKey,
          ),
        ),
      );

      final servicesReturningNull = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
        webPreviewUriProvider: () => null,
      );

      final DTDServiceCallback callbackReturningNull = _callbackFor(
        servicesReturningNull,
        WidgetPreviewDtdServices.kGetWebPreviewUrl,
      );

      await expectLater(
        callbackReturningNull(Parameters('getWebPreviewUrl', <String, Object?>{})),
        throwsA(
          isA<RpcException>().having(
            (RpcException e) => e.code,
            'code',
            WidgetPreviewDtdServices.kNoValueForKey,
          ),
        ),
      );
    });

    testWithoutContext('returns PreviewServiceInfo from getServiceInfo', () async {
      final fakeDtd = FakeDartToolingDaemon();
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: true,
        dtd: fakeDtd,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project.widgetPreviewScaffoldProject,
        projectRootPath: '/project',
        shutdownHooks: shutdownHooks,
        webPreviewUriProvider: () => Uri.parse('http://127.0.0.1:8080'),
      );
      await services.connect(dtdWsUri: Uri.parse('ws://127.0.0.1:54322/secret'));

      final DTDServiceCallback callback = _callbackFor(
        services,
        WidgetPreviewDtdServices.kGetServiceInfo,
      );
      final Map<String, Object?> initialResponse = await callback(
        Parameters('getServiceInfo', <String, Object?>{}),
      );

      final String uuid = services.serviceUuid;
      expect(initialResponse[PreviewServiceInfo.kType], PreviewServiceInfo.kTypeName);
      expect(initialResponse[PreviewServiceInfo.kDtdUri], 'ws://127.0.0.1:54322/secret');
      expect(initialResponse[PreviewServiceInfo.kProjectRoot], '/project');
      expect(initialResponse[PreviewServiceInfo.kPreviewService], 'widget-preview-$uuid');
      expect(initialResponse[PreviewServiceInfo.kScaffoldService], 'PreviewScaffold-$uuid');
      expect(initialResponse[PreviewServiceInfo.kScaffoldStream], 'WidgetPreviewScaffold-$uuid');
      expect(initialResponse[PreviewServiceInfo.kWebPreviewUri], 'http://127.0.0.1:8080');
      expect(initialResponse[PreviewServiceInfo.kScaffoldConnected], isFalse);

      fakeDtd.postFakeEvent(
        services.widgetPreviewScaffoldStream,
        WidgetPreviewDtdServices.kWidgetPreviewConnectedEvent,
        const <String, Object?>{},
      );
      await pumpEventQueue();

      final Map<String, Object?> connectedResponse = await callback(
        Parameters('getServiceInfo', <String, Object?>{}),
      );
      expect(connectedResponse[PreviewServiceInfo.kScaffoldConnected], isTrue);

      await fakeDtd.close();
    });

    testWithoutContext('syncPreviews forwards timeout and returns SyncPreviewsResponse', () async {
      Duration? receivedTimeout;
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        onSyncPreviews: ({required Duration timeout}) async {
          receivedTimeout = timeout;
          return const SyncPreviewsResponse(
            compileSuccess: true,
            errorPreviewCount: 1,
            fullRestart: false,
            reloaded: true,
          );
        },
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      final DTDServiceCallback callback = _callbackFor(
        services,
        WidgetPreviewDtdServices.kSyncPreviews,
      );

      // Default timeout when params map is null, empty, or timeoutMs is explicitly null.
      final Map<String, Object?> defaultResponse = await callback(Parameters('syncPreviews', null));
      expect(
        receivedTimeout,
        const Duration(milliseconds: WidgetPreviewDtdServices.kDefaultSyncTimeoutMs),
      );
      expect(defaultResponse[SyncPreviewsResponse.kType], SyncPreviewsResponse.kTypeName);
      expect(defaultResponse[SyncPreviewsResponse.kReloaded], isTrue);
      expect(defaultResponse[SyncPreviewsResponse.kErrorPreviewCount], 1);

      receivedTimeout = null;
      await callback(Parameters('syncPreviews', <String, Object?>{}));
      expect(
        receivedTimeout,
        const Duration(milliseconds: WidgetPreviewDtdServices.kDefaultSyncTimeoutMs),
      );

      receivedTimeout = null;
      await callback(Parameters('syncPreviews', <String, Object?>{'timeoutMs': null}));
      expect(
        receivedTimeout,
        const Duration(milliseconds: WidgetPreviewDtdServices.kDefaultSyncTimeoutMs),
      );

      // Custom timeoutMs.
      await callback(Parameters('syncPreviews', <String, Object?>{'timeoutMs': 12500}));
      expect(receivedTimeout, const Duration(milliseconds: 12500));

      // Invalid negative or non-int timeoutMs.
      await expectLater(
        callback(Parameters('syncPreviews', <String, Object?>{'timeoutMs': -1})),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', error_code.INVALID_PARAMS),
        ),
      );
      await expectLater(
        callback(Parameters('syncPreviews', <String, Object?>{'timeoutMs': 'invalid'})),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', error_code.INVALID_PARAMS),
        ),
      );

      // Missing onSyncPreviews callback.
      final unconfiguredServices = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );
      final DTDServiceCallback unconfiguredCallback = _callbackFor(
        unconfiguredServices,
        WidgetPreviewDtdServices.kSyncPreviews,
      );
      await expectLater(
        unconfiguredCallback(Parameters('syncPreviews', <String, Object?>{})),
        throwsA(
          isA<RpcException>().having(
            (RpcException e) => e.code,
            'code',
            WidgetPreviewDtdServices.kNoValueForKey,
          ),
        ),
      );
    });

    testWithoutContext(
      'tracks scaffoldConnected across Connected events, markScaffoldDisconnected, and timeouts',
      () async {
        final fakeDtd = FakeDartToolingDaemon();
        final fakeAnalytics = FakeWidgetPreviewAnalytics();
        final services = WidgetPreviewDtdServices(
          addUuidToServiceName: false,
          dtd: fakeDtd,
          dtdLauncher: FakeDtdLauncher(),
          fs: fs,
          logger: logger,
          onHotRestartPreviewerRequest: () {},
          previewAnalytics: fakeAnalytics,
          project: project,
          shutdownHooks: shutdownHooks,
        );
        await services.connect(dtdWsUri: Uri.parse('ws://127.0.0.1:54322/secret'));

        expect(services.scaffoldConnected, isFalse);

        var waiterCompleted = false;
        final Future<void> initialWait = services.waitForScaffoldConnected().then((_) {
          waiterCompleted = true;
        });
        await pumpEventQueue();
        expect(waiterCompleted, isFalse);

        fakeDtd.postFakeEvent(
          services.widgetPreviewScaffoldStream,
          WidgetPreviewDtdServices.kWidgetPreviewConnectedEvent,
          const <String, Object?>{},
        );
        await initialWait;

        expect(waiterCompleted, isTrue);
        expect(services.scaffoldConnected, isTrue);
        expect(fakeAnalytics.reportPreviewerConnectedCount, 1);

        // Already connected: returns immediately.
        await services.waitForScaffoldConnected(timeout: Duration.zero);

        // Reset before fullRestart: waits for fresh Connected event.
        services.markScaffoldDisconnected();
        expect(services.scaffoldConnected, isFalse);

        await expectLater(
          services.waitForScaffoldConnected(timeout: const Duration(milliseconds: 10)),
          throwsA(isA<TimeoutException>()),
        );
        expect(services.scaffoldConnected, isFalse);

        // Subsequent waiter after a timeout still completes once Connected arrives.
        final Future<void> secondWait = services.waitForScaffoldConnected();
        fakeDtd.postFakeEvent(
          services.widgetPreviewScaffoldStream,
          WidgetPreviewDtdServices.kWidgetPreviewConnectedEvent,
          const <String, Object?>{},
        );
        await secondWait;
        expect(services.scaffoldConnected, isTrue);
        expect(fakeAnalytics.reportPreviewerConnectedCount, 2);

        // Restoring connected state after an aborted fullRestart completes waiters
        // without incrementing analytics.
        services.markScaffoldDisconnected();
        expect(services.scaffoldConnected, isFalse);
        final Future<void> restoredWait = services.waitForScaffoldConnected();
        services.markScaffoldConnected();
        await restoredWait;
        expect(services.scaffoldConnected, isTrue);
        expect(fakeAnalytics.reportPreviewerConnectedCount, 2);

        await fakeDtd.close();
      },
    );
  });

  group('Lsp service and stream handling', () {
    late FileSystem fs;
    late Logger logger;
    late ShutdownHooks shutdownHooks;
    late FakeDartToolingDaemon fakeDtd;
    late FlutterProject project;
    late WidgetPreviewDtdServices dtdServices;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
      shutdownHooks = ShutdownHooks();
      fakeDtd = FakeDartToolingDaemon();
      final projectFactory = FlutterProjectFactory(
        config: FakeConfig(),
        fileSystem: fs,
        logger: logger,
      );
      project = projectFactory.fromDirectory(fs.directory('project'));

      dtdServices = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtd: fakeDtd,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: FakeWidgetPreviewAnalytics(),
        project: project,
        shutdownHooks: shutdownHooks,
      );
    });

    tearDown(() async {
      await fakeDtd.close();
    });

    testWithoutContext(
      'concurrent calls to getFlutterWidgetPreviews do not throw stream already subscribed',
      () async {
        final Future<FlutterWidgetPreviews> future1 = dtdServices.getFlutterWidgetPreviews();
        final Future<FlutterWidgetPreviews> future2 = dtdServices.getFlutterWidgetPreviews();

        // Allow both futures to initiate _waitForLspService and reach the waiting state.
        await pumpEventQueue();

        // Simulate LSP service finishing registration with DTD.
        fakeDtd.postFakeEvent(
          WidgetPreviewDtdServices.kLspStream,
          WidgetPreviewDtdServices.kLspInitializedEvent,
          <String, Object?>{},
        );

        final (FlutterWidgetPreviews result1, FlutterWidgetPreviews result2) = await (
          future1,
          future2,
        ).wait;
        expect(result1.previews, isEmpty);
        expect(result2.previews, isEmpty);
        expect(fakeDtd.streamListenCallCount, 1);
        expect(fakeDtd.getRegisteredServicesCallCount, 1);
      },
    );

    testWithoutContext('mixed concurrent calls to getFlutterWidgetPreviews and '
        'getFlutterWidgetPreviewsForFile do not throw', () async {
      final Future<FlutterWidgetPreviews> future1 = dtdServices.getFlutterWidgetPreviews();
      final Future<FlutterWidgetPreviews> future2 = dtdServices.getFlutterWidgetPreviewsForFile(
        filePath: fs.path.join('lib', 'main.dart'),
      );

      await pumpEventQueue();

      fakeDtd.postFakeEvent(
        WidgetPreviewDtdServices.kLspStream,
        WidgetPreviewDtdServices.kLspInitializedEvent,
        <String, Object?>{},
      );

      final (FlutterWidgetPreviews result1, FlutterWidgetPreviews result2) = await (
        future1,
        future2,
      ).wait;
      expect(result1.previews, isEmpty);
      expect(result2.previews, isEmpty);
      expect(fakeDtd.streamListenCallCount, 1);
      expect(fakeDtd.getRegisteredServicesCallCount, 1);
    });

    testWithoutContext(
      'getFlutterWidgetPreviews succeeds when stream is already subscribed',
      () async {
        // Simulate the stream already being subscribed on DTD prior to calling _waitForLspService.
        fakeDtd.subscribedStreams.add(WidgetPreviewDtdServices.kLspStream);

        final Future<FlutterWidgetPreviews> future = dtdServices.getFlutterWidgetPreviews();
        await pumpEventQueue();

        fakeDtd.postFakeEvent(
          WidgetPreviewDtdServices.kLspStream,
          WidgetPreviewDtdServices.kLspInitializedEvent,
          <String, Object?>{},
        );

        final FlutterWidgetPreviews result = await future;
        expect(result.previews, isEmpty);
      },
    );

    testWithoutContext(
      'waitForAnalysis calls Lsp.dart/workspace/analysis/complete over DTD',
      () async {
        final Future<void> future = dtdServices.waitForAnalysis(delay: Duration.zero);
        await pumpEventQueue();

        fakeDtd.postFakeEvent(
          WidgetPreviewDtdServices.kLspStream,
          WidgetPreviewDtdServices.kLspInitializedEvent,
          <String, Object?>{},
        );

        await future;
        expect(fakeDtd.waitForAnalysisCallCount, 1);
      },
    );

    testWithoutContext(
      'waits for Lsp initialized event when only a subset of required Lsp methods are registered',
      () async {
        fakeDtd.registeredServicesResponse = RegisteredServicesResponse.fromDTDResponse(
          DTDResponse('1', RegisteredServicesResponse.type, <String, Object?>{
            'type': RegisteredServicesResponse.type,
            'dtdServices': <String>[],
            'clientServices': <Map<String, Object?>>[
              <String, Object?>{
                'name': WidgetPreviewDtdServices.kLspStream,
                'methods': <Map<String, Object?>>[
                  <String, Object?>{
                    'name': WidgetPreviewDtdServices.kGetFlutterWidgetPreviewsMethod,
                  },
                ],
              },
            ],
          }),
        );

        var completed = false;
        final Future<FlutterWidgetPreviews> future = dtdServices.getFlutterWidgetPreviews().then((
          FlutterWidgetPreviews value,
        ) {
          completed = true;
          return value;
        });

        await pumpEventQueue();
        expect(completed, isFalse);

        fakeDtd.postFakeEvent(
          WidgetPreviewDtdServices.kLspStream,
          WidgetPreviewDtdServices.kLspInitializedEvent,
          <String, Object?>{},
        );

        final FlutterWidgetPreviews result = await future;
        expect(completed, isTrue);
        expect(result.previews, isEmpty);
      },
    );

    testWithoutContext(
      'proceeds without waiting for event when all required Lsp methods are already registered',
      () async {
        fakeDtd.registeredServicesResponse = RegisteredServicesResponse.fromDTDResponse(
          DTDResponse('1', RegisteredServicesResponse.type, <String, Object?>{
            'type': RegisteredServicesResponse.type,
            'dtdServices': <String>[],
            'clientServices': <Map<String, Object?>>[
              <String, Object?>{
                'name': WidgetPreviewDtdServices.kLspStream,
                'methods': <Map<String, Object?>>[
                  for (final String method in WidgetPreviewDtdServices.kRequiredLspServices)
                    <String, Object?>{'name': method},
                ],
              },
            ],
          }),
        );

        final FlutterWidgetPreviews result = await dtdServices.getFlutterWidgetPreviews();
        expect(result.previews, isEmpty);
        expect(fakeDtd.getRegisteredServicesCallCount, 1);
      },
    );

    testWithoutContext('cancels the Lsp event subscription when streamListen fails', () async {
      fakeDtd.streamListenError = RpcErrorCodes.buildRpcException(RpcErrorCodes.kConnectionFailed);

      await expectLater(
        dtdServices.getFlutterWidgetPreviews(),
        throwsA(
          isA<RpcException>().having(
            (RpcException e) => e.code,
            'code',
            RpcErrorCodes.kConnectionFailed,
          ),
        ),
      );
      expect(fakeDtd.hasListener(WidgetPreviewDtdServices.kLspStream), isFalse);
    });
  });
}
