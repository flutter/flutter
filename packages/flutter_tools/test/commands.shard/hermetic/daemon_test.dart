// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=1000"
@Tags(<String>['no-shuffle'])

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:file/src/interface/file.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/commands/daemon.dart';
import 'package:flutter_tools/src/daemon.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_workflow.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/fakes.dart';

/// Runs a callback using FakeAsync.run while continually pumping the
/// microtask queue. This avoids a deadlock when tests `await` a Future
/// which queues a microtask that will not be processed unless the queue
/// is flushed.
Future<T> _runFakeAsync<T>(Future<T> Function(FakeAsync time) f) async {
  return FakeAsync().run((FakeAsync time) async {
    bool pump = true;
    final Future<T> future = f(time).whenComplete(() => pump = false);
    while (pump) {
      time.flushMicrotasks();
    }
    return future;
  });
}

class FakeDaemonStreams implements DaemonStreams {
  final StreamController<DaemonMessage> inputs = StreamController<DaemonMessage>();
  final StreamController<DaemonMessage> outputs = StreamController<DaemonMessage>();

  @override
  Stream<DaemonMessage> get inputStream {
    return inputs.stream;
  }

  @override
  void send(Map<String, dynamic> message, [ List<int> binary ]) {
    outputs.add(DaemonMessage(message, binary != null ? Stream<List<int>>.value(binary) : null));
  }

  @override
  Future<void> dispose() async {
    await inputs.close();
    // In some tests, outputs have no listeners. We don't wait for outputs to close.
    unawaited(outputs.close());
  }
}

void main() {
  Daemon daemon;
  NotifyingLogger notifyingLogger;
  BufferLogger bufferLogger;

  group('daemon', () {
    FakeDaemonStreams daemonStreams;
    DaemonConnection daemonConnection;
    setUp(() {
      bufferLogger = BufferLogger.test();
      notifyingLogger = NotifyingLogger(verbose: false, parent: bufferLogger);
      daemonStreams = FakeDaemonStreams();
      daemonConnection = DaemonConnection(
        daemonStreams: daemonStreams,
        logger: bufferLogger,
      );
    });

    tearDown(() async {
      if (daemon != null) {
        return daemon.shutdown();
      }
      notifyingLogger.dispose();
      await daemonConnection.dispose();
    });

    testUsingContext('daemon.version command should succeed', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'daemon.version'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['result'], isNotEmpty);
      expect(response.data['result'], isA<String>());
    });

    testUsingContext('daemon.getSupportedPlatforms command should succeed', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      // Use the flutter_gallery project which has a known set of supported platforms.
      final String projectPath = globals.fs.path.join(getFlutterRoot(), 'dev', 'integration_tests', 'flutter_gallery');

      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{
        'id': 0,
        'method': 'daemon.getSupportedPlatforms',
        'params': <String, Object>{'projectRoot': projectPath},
      }));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);

      expect(response.data['id'], 0);
      expect(response.data['result'], isNotEmpty);
      expect((response.data['result'] as Map<String, dynamic>)['platforms'], <String>{'macos'});
    }, overrides: <Type, Generator>{
      // Disable Android/iOS and enable macOS to make sure result is consistent and defaults are tested off.
      FeatureFlags: () => TestFeatureFlags(isAndroidEnabled: false, isIOSEnabled: false, isMacOSEnabled: true),
    });

    testUsingContext('printError should send daemon.logMessage event', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      globals.printError('daemon.logMessage test');
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere((DaemonMessage message) {
        return message.data['event'] == 'daemon.logMessage' && (message.data['params'] as Map<String, dynamic>)['level'] == 'error';
      });
      expect(response.data['id'], isNull);
      expect(response.data['event'], 'daemon.logMessage');
      final Map<String, String> logMessage = castStringKeyedMap(response.data['params']).cast<String, String>();
      expect(logMessage['level'], 'error');
      expect(logMessage['message'], 'daemon.logMessage test');
    }, overrides: <Type, Generator>{
      Logger: () => notifyingLogger,
    });

    testUsingContext('printWarning should send daemon.logMessage event', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      globals.printWarning('daemon.logMessage test');
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere((DaemonMessage message) {
        return message.data['event'] == 'daemon.logMessage' && (message.data['params'] as Map<String, dynamic>)['level'] == 'warning';
      });
      expect(response.data['id'], isNull);
      expect(response.data['event'], 'daemon.logMessage');
      final Map<String, String> logMessage = castStringKeyedMap(response.data['params']).cast<String, String>();
      expect(logMessage['level'], 'warning');
      expect(logMessage['message'], 'daemon.logMessage test');
    }, overrides: <Type, Generator>{
      Logger: () => notifyingLogger,
    });

    testUsingContext('printStatus should log to stdout when logToStdout is enabled', () async {
      final StringBuffer buffer = await capturedConsolePrint(() {
        daemon = Daemon(
          daemonConnection,
          notifyingLogger: notifyingLogger,
          logToStdout: true,
        );
        globals.printStatus('daemon.logMessage test');
        return Future<void>.value();
      });

      expect(buffer.toString().trim(), 'daemon.logMessage test');
    }, overrides: <Type, Generator>{
      Logger: () => notifyingLogger,
    });

    testUsingContext('printBox should log to stdout when logToStdout is enabled', () async {
      final StringBuffer buffer = await capturedConsolePrint(() {
        daemon = Daemon(
          daemonConnection,
          notifyingLogger: notifyingLogger,
          logToStdout: true,
        );
        globals.printBox('This is the box message', title: 'Sample title');
        return Future<void>.value();
      });

      expect(buffer.toString().trim(), contains('Sample title: This is the box message'));
    }, overrides: <Type, Generator>{
      Logger: () => notifyingLogger,
    });

    testUsingContext('daemon.shutdown command should stop daemon', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'daemon.shutdown'}));
      return daemon.onExit.then<void>((int code) async {
        await daemonStreams.inputs.close();
        expect(code, 0);
      });
    });

    testUsingContext('app.restart without an appId should report an error', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );

      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'app.restart'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['error'], contains('appId is required'));
    });

    testUsingContext('ext.flutter.debugPaint via service extension without an appId should report an error', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );

      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{
        'id': 0,
        'method': 'app.callServiceExtension',
        'params': <String, String>{
          'methodName': 'ext.flutter.debugPaint',
        },
      }));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['error'], contains('appId is required'));
    });

    testUsingContext('app.stop without appId should report an error', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );

      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'app.stop'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['error'], contains('appId is required'));
    });

    testUsingContext('device.getDevices should respond with list', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'device.getDevices'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['result'], isList);
    });

    testUsingContext('device.getDevices reports available devices', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      final FakePollingDeviceDiscovery discoverer = FakePollingDeviceDiscovery();
      daemon.deviceDomain.addDeviceDiscoverer(discoverer);
      discoverer.addDevice(FakeAndroidDevice());
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'device.getDevices'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      final dynamic result = response.data['result'];
      expect(result, isList);
      expect(result, isNotEmpty);
    });

    testUsingContext('should send device.added event when device is discovered', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );

      final FakePollingDeviceDiscovery discoverer = FakePollingDeviceDiscovery();
      daemon.deviceDomain.addDeviceDiscoverer(discoverer);
      discoverer.addDevice(FakeAndroidDevice());

      return daemonStreams.outputs.stream.skipWhile(_isConnectedEvent).first.then<void>((DaemonMessage response) async {
        expect(response.data['event'], 'device.added');
        expect(response.data['params'], isMap);

        final Map<String, dynamic> params = castStringKeyedMap(response.data['params']);
        expect(params['platform'], isNotEmpty); // the fake device has a platform of 'android-arm'
      });
    }, overrides: <Type, Generator>{
      AndroidWorkflow: () => FakeAndroidWorkflow(),
      IOSWorkflow: () => FakeIOSWorkflow(),
      FuchsiaWorkflow: () => FakeFuchsiaWorkflow(),
    });

    testUsingContext('device.discoverDevices should respond with list', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'device.discoverDevices'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['result'], isList);
    });

    testUsingContext('device.discoverDevices reports available devices', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      final FakePollingDeviceDiscovery discoverer = FakePollingDeviceDiscovery();
      daemon.deviceDomain.addDeviceDiscoverer(discoverer);
      discoverer.addDevice(FakeAndroidDevice());
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'device.discoverDevices'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      final dynamic result = response.data['result'];
      expect(result, isList);
      expect(result, isNotEmpty);
      expect(discoverer.discoverDevicesCalled, true);
    });

    testUsingContext('device.supportsRuntimeMode returns correct value', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      final FakePollingDeviceDiscovery discoverer = FakePollingDeviceDiscovery();
      daemon.deviceDomain.addDeviceDiscoverer(discoverer);
      final FakeAndroidDevice device = FakeAndroidDevice();
      discoverer.addDevice(device);
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{
        'id': 0,
        'method': 'device.supportsRuntimeMode',
        'params': <String, dynamic>{
          'deviceId': 'device',
          'buildMode': 'profile',
        },
      }));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      final dynamic result = response.data['result'];
      expect(result, true);
      expect(device.supportsRuntimeModeCalledBuildMode, BuildMode.profile);
    });

    testUsingContext('device.logReader.start and .stop starts and stops log reader', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      final FakePollingDeviceDiscovery discoverer = FakePollingDeviceDiscovery();
      daemon.deviceDomain.addDeviceDiscoverer(discoverer);
      final FakeAndroidDevice device = FakeAndroidDevice();
      discoverer.addDevice(device);
      final FakeDeviceLogReader logReader = FakeDeviceLogReader();
      device.logReader = logReader;
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{
        'id': 0,
        'method': 'device.logReader.start',
        'params': <String, dynamic>{
          'deviceId': 'device',
        },
      }));
      final Stream<DaemonMessage> broadcastOutput = daemonStreams.outputs.stream.asBroadcastStream();
      final DaemonMessage firstResponse = await broadcastOutput.firstWhere(_notEvent);
      expect(firstResponse.data['id'], 0);
      final String logReaderId = firstResponse.data['result'] as String;
      expect(logReaderId, isNotNull);

      // Try sending logs.
      logReader.logLinesController.add('Sample log line');
      final DaemonMessage logEvent = await broadcastOutput.firstWhere(
        (DaemonMessage message) => message.data['event'] != null && message.data['event'] != 'device.added',
      );
      expect(logEvent.data['params'], 'Sample log line');

      // Now try to stop the log reader.
      expect(logReader.disposeCalled, false);
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{
        'id': 1,
        'method': 'device.logReader.stop',
        'params': <String, dynamic>{
          'id': logReaderId,
        },
      }));
      final DaemonMessage stopResponse = await broadcastOutput.firstWhere(_notEvent);
      expect(stopResponse.data['id'], 1);
      expect(logReader.disposeCalled, true);
    });

    group('device.startApp and .stopApp', () {
      FakeApplicationPackageFactory applicationPackageFactory;
      setUp(() {
        applicationPackageFactory = FakeApplicationPackageFactory();
      });

      testUsingContext('device.startApp and .stopApp starts and stops an app', () async {
        daemon = Daemon(
          daemonConnection,
          notifyingLogger: notifyingLogger,
        );
        final FakePollingDeviceDiscovery discoverer = FakePollingDeviceDiscovery();
        daemon.deviceDomain.addDeviceDiscoverer(discoverer);
        final FakeAndroidDevice device = FakeAndroidDevice();
        discoverer.addDevice(device);
        final Stream<DaemonMessage> broadcastOutput = daemonStreams.outputs.stream.asBroadcastStream();

        // First upload the application package.
        final FakeApplicationPackage applicationPackage = FakeApplicationPackage();
        applicationPackageFactory.applicationPackage = applicationPackage;
        daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{
          'id': 0,
          'method': 'device.uploadApplicationPackage',
          'params': <String, dynamic>{
            'targetPlatform': 'android',
            'applicationBinary': 'test_file',
          },
        }));
        final DaemonMessage applicationPackageIdResponse = await broadcastOutput.firstWhere(_notEvent);
        expect(applicationPackageIdResponse.data['id'], 0);
        expect(applicationPackageFactory.applicationBinaryRequested.basename, 'test_file');
        expect(applicationPackageFactory.platformRequested, TargetPlatform.android);
        final String applicationPackageId = applicationPackageIdResponse.data['result'] as String;

        // Try starting the app.
        final Uri observatoryUri = Uri.parse('http://127.0.0.1:12345/observatory');
        device.launchResult = LaunchResult.succeeded(observatoryUri: observatoryUri);
        daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{
          'id': 1,
          'method': 'device.startApp',
          'params': <String, dynamic>{
            'deviceId': 'device',
            'applicationPackageId': applicationPackageId,
            'debuggingOptions': DebuggingOptions.enabled(BuildInfo.debug).toJson(),
          },
        }));
        final DaemonMessage startAppResponse = await broadcastOutput.firstWhere(_notEvent);
        expect(startAppResponse.data['id'], 1);
        expect(device.startAppPackage, applicationPackage);
        final Map<String, dynamic> startAppResult = startAppResponse.data['result'] as Map<String, dynamic>;
        expect(startAppResult['started'], true);
        expect(startAppResult['observatoryUri'], observatoryUri.toString());

        // Try stopping the app.
        daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{
          'id': 2,
          'method': 'device.stopApp',
          'params': <String, dynamic>{
            'deviceId': 'device',
            'applicationPackageId': applicationPackageId,
          },
        }));
        final DaemonMessage stopAppResponse = await broadcastOutput.firstWhere(_notEvent);
        expect(stopAppResponse.data['id'], 2);
        expect(device.stopAppPackage, applicationPackage);
        final bool stopAppResult = stopAppResponse.data['result'] as bool;
        expect(stopAppResult, true);
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => applicationPackageFactory,
      });
    });

    testUsingContext('emulator.launch without an emulatorId should report an error', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );

      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'emulator.launch'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['error'], contains('emulatorId is required'));
    });

    testUsingContext('emulator.launch coldboot parameter must be boolean', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      final Map<String, dynamic> params = <String, dynamic>{'emulatorId': 'device', 'coldBoot': 1};
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'emulator.launch', 'params': params}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['error'], contains('coldBoot is not a bool'));
    });

    testUsingContext('emulator.getEmulators should respond with list', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );
      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'emulator.getEmulators'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere(_notEvent);
      expect(response.data['id'], 0);
      expect(response.data['result'], isList);
    });

    testUsingContext('daemon can send exposeUrl requests to the client', () async {
      const String originalUrl = 'http://localhost:1234/';
      const String mappedUrl = 'https://publichost:4321/';

      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );

      // Respond to any requests from the daemon to expose a URL.
      unawaited(daemonStreams.outputs.stream
        .firstWhere((DaemonMessage request) => request.data['method'] == 'app.exposeUrl')
        .then((DaemonMessage request) {
          expect((request.data['params'] as Map<String, dynamic>)['url'], equals(originalUrl));
          daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': request.data['id'], 'result': <String, dynamic>{'url': mappedUrl}}));
        })
      );

      final String exposedUrl = await daemon.daemonDomain.exposeUrl(originalUrl);
      expect(exposedUrl, equals(mappedUrl));
    });

    testUsingContext('devtools.serve command should return host and port on success', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );

      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'devtools.serve'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere((DaemonMessage response) => response.data['id'] == 0);
      final Map<String, dynamic> result = response.data['result'] as Map<String, dynamic>;
      expect(result, isNotEmpty);
      expect(result['host'], '127.0.0.1');
      expect(result['port'], 1234);
    }, overrides: <Type, Generator>{
      DevtoolsLauncher: () => FakeDevtoolsLauncher(DevToolsServerAddress('127.0.0.1', 1234)),
    });

    testUsingContext('devtools.serve command should return null fields if null returned', () async {
      daemon = Daemon(
        daemonConnection,
        notifyingLogger: notifyingLogger,
      );

      daemonStreams.inputs.add(DaemonMessage(<String, dynamic>{'id': 0, 'method': 'devtools.serve'}));
      final DaemonMessage response = await daemonStreams.outputs.stream.firstWhere((DaemonMessage response) => response.data['id'] == 0);
      final Map<String, dynamic> result = response.data['result'] as Map<String, dynamic>;
      expect(result, isNotEmpty);
      expect(result['host'], null);
      expect(result['port'], null);
    }, overrides: <Type, Generator>{
      DevtoolsLauncher: () => FakeDevtoolsLauncher(null),
    });
  });

  testUsingContext('notifyingLogger outputs trace messages in verbose mode', () async {
    final NotifyingLogger logger = NotifyingLogger(verbose: true, parent: bufferLogger);

    logger.printTrace('test');

    expect(bufferLogger.errorText, contains('test'));
  });

  testUsingContext('notifyingLogger ignores trace messages in non-verbose mode', () async {
    final NotifyingLogger logger = NotifyingLogger(verbose: false, parent: bufferLogger);

    final Future<LogMessage> messageResult = logger.onMessage.first;
    logger.printTrace('test');
    logger.printStatus('hello');

    final LogMessage message = await messageResult;

    expect(message.level, 'status');
    expect(message.message, 'hello');
    expect(bufferLogger.errorText, contains('test'));
  });

  testUsingContext('notifyingLogger buffers messages sent before a subscription', () async {
    final NotifyingLogger logger = NotifyingLogger(verbose: false, parent: bufferLogger);

    logger.printStatus('hello');

    final LogMessage message = await logger.onMessage.first;

    expect(message.level, 'status');
    expect(message.message, 'hello');
  });

  group('daemon queue', () {
    DebounceOperationQueue<int, String> queue;
    const Duration debounceDuration = Duration(seconds: 1);

    setUp(() {
      queue = DebounceOperationQueue<int, String>();
    });

    testWithoutContext(
        'debounces/merges same operation type and returns same result',
        () async {
      await _runFakeAsync((FakeAsync time) async {
        final List<Future<int>> operations = <Future<int>>[
          queue.queueAndDebounce('OP1', debounceDuration, () async => 1),
          queue.queueAndDebounce('OP1', debounceDuration, () async => 2),
        ];

        time.elapse(debounceDuration * 5);
        final List<int> results = await Future.wait(operations);

        expect(results, orderedEquals(<int>[1, 1]));
      });
    });

    testWithoutContext('does not merge results outside of the debounce duration',
        () async {
      await _runFakeAsync((FakeAsync time) async {
        final List<Future<int>> operations = <Future<int>>[
          queue.queueAndDebounce('OP1', debounceDuration, () async => 1),
          Future<int>.delayed(debounceDuration * 2).then((_) =>
              queue.queueAndDebounce('OP1', debounceDuration, () async => 2)),
        ];

        time.elapse(debounceDuration * 5);
        final List<int> results = await Future.wait(operations);

        expect(results, orderedEquals(<int>[1, 2]));
      });
    });

    testWithoutContext('does not merge results of different operations',
        () async {
      await _runFakeAsync((FakeAsync time) async {
        final List<Future<int>> operations = <Future<int>>[
          queue.queueAndDebounce('OP1', debounceDuration, () async => 1),
          queue.queueAndDebounce('OP2', debounceDuration, () async => 2),
        ];

        time.elapse(debounceDuration * 5);
        final List<int> results = await Future.wait(operations);

        expect(results, orderedEquals(<int>[1, 2]));
      });
    });

    testWithoutContext('does not run any operations concurrently', () async {
      // Crete a function that's slow, but throws if another instance of the
      // function is running.
      bool isRunning = false;
      Future<int> f(int ret) async {
        if (isRunning) {
          throw Exception('Functions ran concurrently!');
        }
        isRunning = true;
        await Future<void>.delayed(debounceDuration * 2);
        isRunning = false;
        return ret;
      }

      await _runFakeAsync((FakeAsync time) async {
        final List<Future<int>> operations = <Future<int>>[
          queue.queueAndDebounce('OP1', debounceDuration, () => f(1)),
          queue.queueAndDebounce('OP2', debounceDuration, () => f(2)),
        ];

        time.elapse(debounceDuration * 5);
        final List<int> results = await Future.wait(operations);

        expect(results, orderedEquals(<int>[1, 2]));
      });
    });
  });
}

bool _notEvent(DaemonMessage message) => message.data['event'] == null;

bool _isConnectedEvent(DaemonMessage message) => message.data['event'] == 'daemon.connected';

class FakeFuchsiaWorkflow extends Fake implements FuchsiaWorkflow {
  FakeFuchsiaWorkflow({ this.canListDevices = true });

  @override
  final bool canListDevices;
}

class FakeAndroidWorkflow extends Fake implements AndroidWorkflow {
  FakeAndroidWorkflow({ this.canListDevices = true });

  @override
  final bool canListDevices;
}

class FakeIOSWorkflow extends Fake implements IOSWorkflow {
  FakeIOSWorkflow({ this.canListDevices = true });

  @override
  final bool canListDevices;
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeAndroidDevice extends Fake implements AndroidDevice {
  @override
  final String id = 'device';

  @override
  final String name = 'device';

  @override
  Future<String> get emulatorId async => 'device';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android_arm;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  final Category category = Category.mobile;

  @override
  final PlatformType platformType = PlatformType.android;

  @override
  final bool ephemeral = false;

  @override
  Future<String> get sdkNameAndVersion async => 'Android 12';

  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => true;

  @override
  bool get supportsScreenshot => true;

  @override
  bool get supportsFastStart => true;

  @override
  bool get supportsFlutterExit => true;

  @override
  Future<bool> get supportsHardwareRendering async => true;

  @override
  bool get supportsStartPaused => true;

  BuildMode supportsRuntimeModeCalledBuildMode;
  @override
  Future<bool> supportsRuntimeMode(BuildMode buildMode) async {
    supportsRuntimeModeCalledBuildMode = buildMode;
    return true;
  }

  DeviceLogReader logReader;
  @override
  FutureOr<DeviceLogReader> getLogReader({
    covariant ApplicationPackage app,
    bool includePastLogs = false,
  }) => logReader;

  ApplicationPackage startAppPackage;
  LaunchResult launchResult;
  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, Object> platformArgs = const <String, Object>{},
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String userIdentifier,
  }) async {
    startAppPackage = package;
    return launchResult;
  }

  ApplicationPackage stopAppPackage;
  @override
  Future<bool> stopApp(
    ApplicationPackage app, {
    String userIdentifier,
  }) async {
    stopAppPackage = app;
    return true;
  }
}

class FakeDeviceLogReader implements DeviceLogReader {
  final StreamController<String> logLinesController = StreamController<String>();
  bool disposeCalled = false;

  @override
  int appPid;

  @override
  FlutterVmService connectedVMService;

  @override
  void dispose() {
    disposeCalled = true;
  }

  @override
  Stream<String> get logLines => logLinesController.stream;

  @override
  String get name => 'device';

}

class FakeDevtoolsLauncher extends Fake implements DevtoolsLauncher {
  FakeDevtoolsLauncher(this._serverAddress);

  final DevToolsServerAddress _serverAddress;

  @override
  Future<DevToolsServerAddress> serve() async => _serverAddress;

  @override
  Future<void> close() async {}
}

class FakeApplicationPackageFactory implements ApplicationPackageFactory {
  TargetPlatform platformRequested;
  File applicationBinaryRequested;
  ApplicationPackage applicationPackage;

  @override
  Future<ApplicationPackage> getPackageForPlatform(TargetPlatform platform, {BuildInfo buildInfo, File applicationBinary}) async {
    platformRequested = platform;
    applicationBinaryRequested = applicationBinary;
    return applicationPackage;
  }
}

class FakeApplicationPackage extends Fake implements ApplicationPackage {}
