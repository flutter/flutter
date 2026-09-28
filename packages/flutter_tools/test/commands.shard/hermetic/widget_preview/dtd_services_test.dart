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

class FakeDtdLauncher extends Fake implements DtdLauncher {
  @override
  Future<void> dispose() async {}
}

class FakeDartToolingDaemon extends Fake implements DartToolingDaemon {
  final postedEvents = <({String streamId, String eventKind, Map<String, Object?> eventData})>[];

  @override
  Future<void> postEvent(String streamId, String eventKind, Map<String, Object?> eventData) async {
    postedEvents.add((streamId: streamId, eventKind: eventKind, eventData: eventData));
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('DTD Types', () {
    test('SyntheticPreviewDetails serialization and equality', () {
      const details = SyntheticPreviewDetails(
        constructorExpression: "PrimaryButton(label: 'Submit')",
        filePath: '/project/lib/button.dart',
        previewId: 'btn_preview',
        widgetName: 'PrimaryButton',
        wrappers: <String>['Material', 'Directionality'],
      );

      final Map<String, Object?> json = details.toJson();
      final SyntheticPreviewDetails deserialized = SyntheticPreviewDetails.fromJson(json);

      expect(deserialized, equals(details));
      expect(deserialized.hashCode, equals(details.hashCode));
      expect(deserialized.constructorExpression, "PrimaryButton(label: 'Submit')");
      expect(deserialized.filePath, '/project/lib/button.dart');
      expect(deserialized.previewId, 'btn_preview');
      expect(deserialized.widgetName, 'PrimaryButton');
      expect(deserialized.wrappers, <String>['Material', 'Directionality']);
      expect(deserialized.toString(), contains('PrimaryButton'));
    });

    test('WebPreviewUrlResult serialization and equality', () {
      const result = WebPreviewUrlResult(
        host: '127.0.0.1',
        port: 8080,
        url: 'http://127.0.0.1:8080',
      );

      final Map<String, Object?> json = result.toJson();
      final WebPreviewUrlResult deserialized = WebPreviewUrlResult.fromJson(json);

      expect(deserialized, equals(result));
      expect(deserialized.hashCode, equals(result.hashCode));
      expect(deserialized.host, '127.0.0.1');
      expect(deserialized.port, 8080);
      expect(deserialized.url, 'http://127.0.0.1:8080');
      expect(deserialized.toString(), contains('8080'));
    });

    test('PreviewServiceInfo serialization and equality', () {
      const info = PreviewServiceInfo(
        dtdUri: 'ws://127.0.0.1:42135/xyz',
        serviceName: 'widget-preview',
        version: '1.0.0',
        webPreviewUrl: 'http://127.0.0.1:8080',
      );

      final Map<String, Object?> json = info.toJson();
      final PreviewServiceInfo deserialized = PreviewServiceInfo.fromJson(json);

      expect(deserialized, equals(info));
      expect(deserialized.hashCode, equals(info.hashCode));
      expect(deserialized.dtdUri, 'ws://127.0.0.1:42135/xyz');
      expect(deserialized.serviceName, 'widget-preview');
      expect(deserialized.version, '1.0.0');
      expect(deserialized.webPreviewUrl, 'http://127.0.0.1:8080');
      expect(deserialized.toString(), contains('1.0.0'));
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
      final projectFactory = FlutterProjectFactory(fileSystem: fs, logger: logger);
      project = projectFactory.fromDirectory(projectDir);
      analytics = WidgetPreviewAnalytics(analytics: const NoOpAnalytics());
    });

    test('Registers all expected agent DTD service methods', () {
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

      final Set<String> registeredNames = services.services.map((DtdService s) => s.$1).toSet();
      expect(
        registeredNames,
        containsAll(<String>[
          WidgetPreviewDtdServices.kHotRestartPreviewer,
          WidgetPreviewDtdServices.kHotReloadPreviewer,
          WidgetPreviewDtdServices.kIsWindows,
          WidgetPreviewDtdServices.kResolveUri,
          WidgetPreviewDtdServices.kSetPreference,
          WidgetPreviewDtdServices.kGetPreference,
          WidgetPreviewDtdServices.kGetDevToolsUri,
          WidgetPreviewDtdServices.kGetWebPreviewUrl,
          WidgetPreviewDtdServices.kGetServiceInfo,
          WidgetPreviewDtdServices.kRegisterSyntheticPreview,
          WidgetPreviewDtdServices.kUnregisterSyntheticPreview,
          WidgetPreviewDtdServices.kClearSyntheticPreviews,
        ]),
      );
    });

    test('Invokes onHotReloadPreviewerRequest when hotReloadPreviewer is called', () async {
      var hotReloadCalled = false;
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        onHotReloadPreviewerRequest: () async {
          hotReloadCalled = true;
        },
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      final DTDServiceCallback callback = services.services
          .firstWhere((DtdService s) => s.$1 == WidgetPreviewDtdServices.kHotReloadPreviewer)
          .$2;
      final Map<String, Object?> response = await callback(
        Parameters('hotReloadPreviewer', <String, Object?>{}),
      );

      expect(hotReloadCalled, isTrue);
      expect(response, equals(const Success().toJson()));
    });

    test('Returns web preview URL when webPreviewUri callback is provided', () async {
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        webPreviewUri: () => Uri.parse('http://127.0.0.1:9090'),
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      final DTDServiceCallback callback = services.services
          .firstWhere((DtdService s) => s.$1 == WidgetPreviewDtdServices.kGetWebPreviewUrl)
          .$2;
      final Map<String, Object?> response = await callback(
        Parameters('getWebPreviewUrl', <String, Object?>{}),
      );

      expect(response['host'], '127.0.0.1');
      expect(response['port'], 9090);
      expect(response['url'], 'http://127.0.0.1:9090');
    });

    test('Throws RpcException from getWebPreviewUrl when webPreviewUri is null', () async {
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

      final DTDServiceCallback callback = services.services
          .firstWhere((DtdService s) => s.$1 == WidgetPreviewDtdServices.kGetWebPreviewUrl)
          .$2;

      expect(
        () => callback(Parameters('getWebPreviewUrl', <String, Object?>{})),
        throwsA(
          isA<RpcException>().having(
            (RpcException e) => e.code,
            'code',
            WidgetPreviewDtdServices.kNoValueForKey,
          ),
        ),
      );
    });

    test('Returns service info from getServiceInfo', () async {
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        webPreviewUri: () => Uri.parse('http://127.0.0.1:8080'),
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      final DTDServiceCallback callback = services.services
          .firstWhere((DtdService s) => s.$1 == WidgetPreviewDtdServices.kGetServiceInfo)
          .$2;
      final Map<String, Object?> response = await callback(
        Parameters('getServiceInfo', <String, Object?>{}),
      );

      expect(response['serviceName'], WidgetPreviewDtdServices.kWidgetPreviewServiceRoot);
      expect(response['version'], WidgetPreviewDtdServices.kProtocolVersion);
      expect(response['webPreviewUrl'], 'http://127.0.0.1:8080');
    });

    test('Handles register, unregister, and clear synthetic previews', () async {
      SyntheticPreviewDetails? registeredDetails;
      String? unregisteredId;
      var clearCount = 0;
      final fakeDtd = FakeDartToolingDaemon();

      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtd: fakeDtd,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        onRegisterSyntheticPreview: (SyntheticPreviewDetails details) async {
          registeredDetails = details;
          return true;
        },
        onUnregisterSyntheticPreview: (String id) async {
          unregisteredId = id;
          return true;
        },
        onClearSyntheticPreviews: () async {
          clearCount = 3;
          return clearCount;
        },
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      // Register synthetic preview.
      final DTDServiceCallback registerCallback = services.services
          .firstWhere((DtdService s) => s.$1 == WidgetPreviewDtdServices.kRegisterSyntheticPreview)
          .$2;
      final Map<String, Object?> registerResponse = await registerCallback(
        Parameters('registerSyntheticPreview', <String, Object?>{
          'constructorExpression': 'MyCard()',
          'filePath': '/project/lib/card.dart',
          'previewId': 'my_card_id',
          'widgetName': 'MyCard',
          'wrappers': <String>['Material'],
        }),
      );
      expect(registerResponse['value'], isTrue);
      expect(
        registeredDetails,
        equals(
          const SyntheticPreviewDetails(
            constructorExpression: 'MyCard()',
            filePath: '/project/lib/card.dart',
            previewId: 'my_card_id',
            widgetName: 'MyCard',
            wrappers: <String>['Material'],
          ),
        ),
      );
      expect(fakeDtd.postedEvents, hasLength(1));
      expect(
        fakeDtd.postedEvents[0].eventKind,
        WidgetPreviewDtdServices.kSyntheticPreviewStateChangedEvent,
      );
      expect(
        fakeDtd.postedEvents[0].eventData,
        equals(<String, Object?>{
          WidgetPreviewDtdServices.kPreviewId: 'my_card_id',
          WidgetPreviewDtdServices.kRegistered: true,
        }),
      );

      // Unregister synthetic preview.
      final DTDServiceCallback unregisterCallback = services.services
          .firstWhere(
            (DtdService s) => s.$1 == WidgetPreviewDtdServices.kUnregisterSyntheticPreview,
          )
          .$2;
      final Map<String, Object?> unregisterResponse = await unregisterCallback(
        Parameters('unregisterSyntheticPreview', <String, Object?>{'previewId': 'my_card_id'}),
      );
      expect(unregisterResponse['value'], isTrue);
      expect(unregisteredId, 'my_card_id');
      expect(fakeDtd.postedEvents, hasLength(2));
      expect(
        fakeDtd.postedEvents[1].eventKind,
        WidgetPreviewDtdServices.kSyntheticPreviewStateChangedEvent,
      );
      expect(
        fakeDtd.postedEvents[1].eventData,
        equals(<String, Object?>{
          WidgetPreviewDtdServices.kPreviewId: 'my_card_id',
          WidgetPreviewDtdServices.kRegistered: false,
        }),
      );

      // Clear synthetic previews.
      final DTDServiceCallback clearCallback = services.services
          .firstWhere((DtdService s) => s.$1 == WidgetPreviewDtdServices.kClearSyntheticPreviews)
          .$2;
      final Map<String, Object?> clearResponse = await clearCallback(
        Parameters('clearSyntheticPreviews', <String, Object?>{}),
      );
      expect(clearResponse['clearedCount'], 3);
    });

    test('Returns false for registerSyntheticPreview and unregisterSyntheticPreview when callbacks are null', () async {
      final fakeDtd = FakeDartToolingDaemon();
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtd: fakeDtd,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      final DTDServiceCallback registerCallback = services.services
          .firstWhere((DtdService s) => s.$1 == WidgetPreviewDtdServices.kRegisterSyntheticPreview)
          .$2;
      final Map<String, Object?> registerResponse = await registerCallback(
        Parameters('registerSyntheticPreview', <String, Object?>{
          'constructorExpression': 'MyCard()',
          'filePath': '/project/lib/card.dart',
          'previewId': 'my_card_id',
          'widgetName': 'MyCard',
        }),
      );
      expect(registerResponse['value'], isFalse);
      expect(fakeDtd.postedEvents, isEmpty);

      final DTDServiceCallback unregisterCallback = services.services
          .firstWhere(
            (DtdService s) => s.$1 == WidgetPreviewDtdServices.kUnregisterSyntheticPreview,
          )
          .$2;
      final Map<String, Object?> unregisterResponse = await unregisterCallback(
        Parameters('unregisterSyntheticPreview', <String, Object?>{'previewId': 'my_card_id'}),
      );
      expect(unregisterResponse['value'], isFalse);
      expect(fakeDtd.postedEvents, isEmpty);
    });

    test('Throws RpcException.invalidParams when registerSyntheticPreview has missing or malformed params', () async {
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

      final DTDServiceCallback registerCallback = services.services
          .firstWhere((DtdService s) => s.$1 == WidgetPreviewDtdServices.kRegisterSyntheticPreview)
          .$2;

      await expectLater(
        registerCallback(
          Parameters('registerSyntheticPreview', <String, Object?>{'previewId': 'my_card_id'}),
        ),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', error_code.INVALID_PARAMS),
        ),
      );

      await expectLater(
        registerCallback(
          Parameters('registerSyntheticPreview', <String, Object?>{
            'constructorExpression': 'MyCard()',
            'filePath': '/project/lib/card.dart',
            'previewId': 'my_card_id',
            'widgetName': 'MyCard',
            'wrappers': <Object?>[42],
          }),
        ),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', error_code.INVALID_PARAMS),
        ),
      );
    });

    test('Event-posting helpers emit expected events on widgetPreviewScaffoldStream', () async {
      final fakeDtd = FakeDartToolingDaemon();
      final services = WidgetPreviewDtdServices(
        addUuidToServiceName: false,
        dtd: fakeDtd,
        dtdLauncher: FakeDtdLauncher(),
        fs: fs,
        logger: logger,
        onHotRestartPreviewerRequest: () {},
        previewAnalytics: analytics,
        project: project,
        shutdownHooks: shutdownHooks,
      );

      await services.postLayoutExceptionEvent(
        diagnostic: <String, Object?>{'message': 'RenderFlex overflowed by 42 pixels'},
        previewId: 'preview_1',
      );
      await services.postPreviewsUpdatedEvent(
        previews: <Map<String, Object?>>[
          <String, Object?>{'functionName': 'myPreview'},
        ],
      );
      await services.postCompilationEvent(success: true, durationMs: 125);
      await services.postCompilationEvent(success: false, error: 'Compilation failed');
      await services.postSyntheticPreviewStateChangedEvent(
        previewId: 'synthetic_1',
        registered: true,
      );

      expect(fakeDtd.postedEvents, hasLength(5));

      expect(
        fakeDtd.postedEvents[0].streamId,
        WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot,
      );
      expect(fakeDtd.postedEvents[0].eventKind, WidgetPreviewDtdServices.kLayoutExceptionEvent);
      expect(
        fakeDtd.postedEvents[0].eventData,
        equals(<String, Object?>{
          WidgetPreviewDtdServices.kPreviewId: 'preview_1',
          WidgetPreviewDtdServices.kDiagnostic: <String, Object?>{
            'message': 'RenderFlex overflowed by 42 pixels',
          },
        }),
      );

      expect(
        fakeDtd.postedEvents[1].streamId,
        WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot,
      );
      expect(fakeDtd.postedEvents[1].eventKind, WidgetPreviewDtdServices.kPreviewsUpdatedEvent);
      expect(
        fakeDtd.postedEvents[1].eventData,
        equals(<String, Object?>{
          WidgetPreviewDtdServices.kCount: 1,
          WidgetPreviewDtdServices.kPreviews: <Map<String, Object?>>[
            <String, Object?>{'functionName': 'myPreview'},
          ],
        }),
      );

      expect(
        fakeDtd.postedEvents[2].streamId,
        WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot,
      );
      expect(
        fakeDtd.postedEvents[2].eventKind,
        WidgetPreviewDtdServices.kCompilationSucceededEvent,
      );
      expect(
        fakeDtd.postedEvents[2].eventData,
        equals(<String, Object?>{
          WidgetPreviewDtdServices.kSuccess: true,
          WidgetPreviewDtdServices.kDurationMs: 125,
        }),
      );

      expect(
        fakeDtd.postedEvents[3].streamId,
        WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot,
      );
      expect(fakeDtd.postedEvents[3].eventKind, WidgetPreviewDtdServices.kCompilationFailedEvent);
      expect(
        fakeDtd.postedEvents[3].eventData,
        equals(<String, Object?>{
          WidgetPreviewDtdServices.kSuccess: false,
          WidgetPreviewDtdServices.kError: 'Compilation failed',
        }),
      );

      expect(
        fakeDtd.postedEvents[4].streamId,
        WidgetPreviewDtdServices.kWidgetPreviewScaffoldStreamRoot,
      );
      expect(
        fakeDtd.postedEvents[4].eventKind,
        WidgetPreviewDtdServices.kSyntheticPreviewStateChangedEvent,
      );
      expect(
        fakeDtd.postedEvents[4].eventData,
        equals(<String, Object?>{
          WidgetPreviewDtdServices.kPreviewId: 'synthetic_1',
          WidgetPreviewDtdServices.kRegistered: true,
        }),
      );
    });
  });
}
