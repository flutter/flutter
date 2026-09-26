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
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/fake.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

class FakeWidgetPreviewAnalytics extends Fake implements WidgetPreviewAnalytics {
  @override
  void reportPreviewerConnected() {}
}

class FakeDtdLauncher extends Fake implements DtdLauncher {
  @override
  Future<void> dispose() async {}
}

class FakeDartToolingDaemon extends Fake implements DartToolingDaemon {
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

  @override
  Future<void> streamListen(String streamId) async {
    streamListenCallCount++;
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

void main() {
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
    project = FlutterProject.fromDirectoryTest(fs.directory('project'));

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

  testUsingContext(
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

  testUsingContext('mixed concurrent calls to getFlutterWidgetPreviews and getFlutterWidgetPreviewsForFile do not throw', () async {
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

  testUsingContext('getFlutterWidgetPreviews succeeds when stream is already subscribed', () async {
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
  });

  testUsingContext('waitForAnalysis calls Lsp.dart/workspace/analysis/complete over DTD', () async {
    final Future<void> future = dtdServices.waitForAnalysis(delay: Duration.zero);
    await pumpEventQueue();

    fakeDtd.postFakeEvent(
      WidgetPreviewDtdServices.kLspStream,
      WidgetPreviewDtdServices.kLspInitializedEvent,
      <String, Object?>{},
    );

    await future;
    expect(fakeDtd.waitForAnalysisCallCount, 1);
  });

  testUsingContext(
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
                <String, Object?>{'name': WidgetPreviewDtdServices.kGetFlutterWidgetPreviewsMethod},
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

  testUsingContext(
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
}
