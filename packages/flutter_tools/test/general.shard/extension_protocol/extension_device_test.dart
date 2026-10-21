// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

final class _TestDeviceService extends DeviceService {
  _TestDeviceService({
    this.onInstallApp,
    this.onIsAppInstalled,
    this.onStartScreenRecording,
    this.onStopScreenRecording,
    this.onTakeScreenshot,
    this.onUninstallApp,
  });

  final Future<bool> Function(String deviceId, Uri bundleUri)? onInstallApp;
  final Future<bool> Function(String deviceId, String appId)? onIsAppInstalled;
  final Future<void> Function(String deviceId, Uri outputFileUri, Duration? duration)?
  onStartScreenRecording;
  final Future<Uri> Function(String deviceId)? onStopScreenRecording;
  final Future<void> Function(String deviceId, Uri outputFileUri)? onTakeScreenshot;
  final Future<bool> Function(String deviceId, String appId)? onUninstallApp;

  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

  @override
  Future<bool> isSupportedForProject({required String deviceId, required Uri projectRoot}) async {
    return true;
  }

  @override
  Future<bool> installApp({required Uri bundleUri, required String deviceId}) async {
    if (onInstallApp case final callback?) {
      return callback(deviceId, bundleUri);
    }
    return super.installApp(bundleUri: bundleUri, deviceId: deviceId);
  }

  @override
  Future<bool> uninstallApp({required String appId, required String deviceId}) async {
    if (onUninstallApp case final callback?) {
      return callback(deviceId, appId);
    }
    return super.uninstallApp(appId: appId, deviceId: deviceId);
  }

  @override
  Future<bool> isAppInstalled({required String appId, required String deviceId}) async {
    if (onIsAppInstalled case final callback?) {
      return callback(deviceId, appId);
    }
    return super.isAppInstalled(appId: appId, deviceId: deviceId);
  }

  @override
  Future<void> takeScreenshot({required String deviceId, required Uri outputFileUri}) async {
    if (onTakeScreenshot case final callback?) {
      return callback(deviceId, outputFileUri);
    }
    return super.takeScreenshot(deviceId: deviceId, outputFileUri: outputFileUri);
  }

  @override
  Future<void> startScreenRecording({
    required String deviceId,
    required Uri outputFileUri,
    Duration? duration,
  }) async {
    if (onStartScreenRecording case final callback?) {
      return callback(deviceId, outputFileUri, duration);
    }
    return super.startScreenRecording(
      deviceId: deviceId,
      duration: duration,
      outputFileUri: outputFileUri,
    );
  }

  @override
  Future<Uri> stopScreenRecording({required String deviceId}) async {
    if (onStopScreenRecording case final callback?) {
      return callback(deviceId);
    }
    return super.stopScreenRecording(deviceId: deviceId);
  }
}

final class _FakePrebuiltApplicationPackage extends ApplicationPackage
    implements PrebuiltApplicationPackage {
  _FakePrebuiltApplicationPackage({required super.id, required this.applicationPackage});

  @override
  final FileSystemEntity applicationPackage;

  @override
  String? get name => id;
}

final class _FakeNonPrebuiltApplicationPackage extends ApplicationPackage {
  _FakeNonPrebuiltApplicationPackage({required super.id});

  @override
  String? get name => id;
}

Matcher _isInvalidParamsRpcException() => isA<json_rpc.RpcException>().having(
  (json_rpc.RpcException e) => e.code,
  'code',
  error_code.INVALID_PARAMS,
);

void main() {
  group('TargetDevice capture capabilities', () {
    test('serializes and deserializes supportsScreenshot and supportsScreenRecording', () {
      const device = TargetDevice(
        category: Category.mobile,
        id: 'capture_device',
        name: 'Capture Device',
        supportsScreenRecording: true,
        supportsScreenshot: true,
      );

      final Map<String, Object?> map = device.toMap();
      expect(map[TargetDevice.supportsScreenshotKey], isTrue);
      expect(map[TargetDevice.supportsScreenRecordingKey], isTrue);

      final parsed = TargetDevice.fromJson(map);
      expect(parsed, equals(device));
      expect(parsed.supportsScreenshot, isTrue);
      expect(parsed.supportsScreenRecording, isTrue);
      expect(parsed.hashCode, equals(device.hashCode));
      expect(
        parsed.toString(),
        allOf(contains('supportsScreenshot: true'), contains('supportsScreenRecording: true')),
      );
    });

    test('defaults supportsScreenshot and supportsScreenRecording to false when omitted', () {
      final parsed = TargetDevice.fromJson(const <String, Object?>{
        TargetDevice.categoryKey: 'desktop',
        TargetDevice.idKey: 'default_device',
        TargetDevice.nameKey: 'Default Device',
      });

      expect(parsed.supportsScreenshot, isFalse);
      expect(parsed.supportsScreenRecording, isFalse);
    });

    test(
      'throws FormatException when supportsScreenshot or supportsScreenRecording is not bool',
      () {
        expect(
          () => TargetDevice.fromJson(const <String, Object?>{
            TargetDevice.supportsScreenshotKey: 'yes',
          }),
          throwsFormatException,
        );
        expect(
          () => TargetDevice.fromJson(const <String, Object?>{
            TargetDevice.supportsScreenRecordingKey: 1,
          }),
          throwsFormatException,
        );
      },
    );
  });

  group('DeviceService RPC install and capture', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    test('handles installApp, uninstallApp, and isAppInstalled over RPC', () async {
      final eventsPort = ReceivePort();
      addTearDown(eventsPort.close);
      final SendPort eventsSendPort = eventsPort.sendPort;

      void entryPoint(SendPort sendPort) {
        final installedApps = <String>{};
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _TestDeviceService(
              onInstallApp: (String deviceId, Uri bundleUri) async {
                eventsSendPort.send(<String, Object?>{
                  'method': 'installApp',
                  'deviceId': deviceId,
                  'bundleUri': bundleUri.toString(),
                });
                installedApps.add('com.example.app');
                return true;
              },
              onIsAppInstalled: (String deviceId, String appId) async {
                return installedApps.contains(appId);
              },
              onUninstallApp: (String deviceId, String appId) async {
                return installedApps.remove(appId);
              },
            ),
          ],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      const deviceId = 'device-1';
      const appId = 'com.example.app';
      final bundleUri = Uri.file('/tmp/build/app.bundle');

      expect(await client.isAppInstalled(appId: appId, deviceId: deviceId), isFalse);
      expect(await client.installApp(bundleUri: bundleUri, deviceId: deviceId), isTrue);

      final event = await eventsPort.first as Map<String, Object?>;
      expect(event['method'], 'installApp');
      expect(event['deviceId'], deviceId);
      expect(event['bundleUri'], bundleUri.toString());

      expect(await client.isAppInstalled(appId: appId, deviceId: deviceId), isTrue);
      expect(await client.uninstallApp(appId: appId, deviceId: deviceId), isTrue);
      expect(await client.isAppInstalled(appId: appId, deviceId: deviceId), isFalse);
    });

    test(
      'handles takeScreenshot, startScreenRecording, and stopScreenRecording over RPC',
      () async {
        final events = <Map<String, Object?>>[];
        final eventsPort = ReceivePort();
        addTearDown(eventsPort.close);
        final StreamSubscription<Object?> sub = eventsPort.listen((Object? message) {
          if (message case final Map<String, Object?> map) {
            events.add(map);
          }
        });
        addTearDown(sub.cancel);
        final SendPort eventsSendPort = eventsPort.sendPort;

        void entryPoint(SendPort sendPort) {
          Uri? activeRecordingUri;
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _TestDeviceService(
                onTakeScreenshot: (String deviceId, Uri outputFileUri) async {
                  eventsSendPort.send(<String, Object?>{
                    'method': 'takeScreenshot',
                    'deviceId': deviceId,
                    'outputFileUri': outputFileUri.toString(),
                  });
                },
                onStartScreenRecording:
                    (String deviceId, Uri outputFileUri, Duration? duration) async {
                      activeRecordingUri = outputFileUri;
                      eventsSendPort.send(<String, Object?>{
                        'method': 'startScreenRecording',
                        'deviceId': deviceId,
                        'outputFileUri': outputFileUri.toString(),
                        'durationMs': duration?.inMilliseconds,
                      });
                    },
                onStopScreenRecording: (String deviceId) async {
                  eventsSendPort.send(<String, Object?>{
                    'method': 'stopScreenRecording',
                    'deviceId': deviceId,
                  });
                  return activeRecordingUri ?? Uri.file('/tmp/fallback.mp4');
                },
              ),
            ],
            supportedPlatforms: const <String>{'linux'},
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);
        final client = ExtensionDeviceClient(conn, logger: logger);

        const deviceId = 'device-capture';
        final screenshotUri = Uri.file('/tmp/screenshot.png');
        final recordingUri = Uri.file('/tmp/recording.mp4');

        await client.takeScreenshot(deviceId: deviceId, outputFileUri: screenshotUri);
        await client.startScreenRecording(
          deviceId: deviceId,
          duration: const Duration(seconds: 10),
          outputFileUri: recordingUri,
        );
        final Uri stoppedUri = await client.stopScreenRecording(deviceId: deviceId);
        expect(stoppedUri, equals(recordingUri));

        expect(events, hasLength(3));
        expect(events[0], <String, Object?>{
          'method': 'takeScreenshot',
          'deviceId': deviceId,
          'outputFileUri': screenshotUri.toString(),
        });
        expect(events[1], <String, Object?>{
          'method': 'startScreenRecording',
          'deviceId': deviceId,
          'outputFileUri': recordingUri.toString(),
          'durationMs': 10000,
        });
        expect(events[2], <String, Object?>{'method': 'stopScreenRecording', 'deviceId': deviceId});
      },
    );

    test('default DeviceService implementations return false for install methods and throw for capture', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_TestDeviceService()],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      const deviceId = 'default-device';
      expect(
        await client.installApp(bundleUri: Uri.file('/tmp/app.bundle'), deviceId: deviceId),
        isFalse,
      );
      expect(await client.uninstallApp(appId: 'com.example.app', deviceId: deviceId), isFalse);
      expect(await client.isAppInstalled(appId: 'com.example.app', deviceId: deviceId), isFalse);

      await expectLater(
        client.takeScreenshot(deviceId: deviceId, outputFileUri: Uri.file('/tmp/out.png')),
        throwsA(isA<json_rpc.RpcException>()),
      );
      await expectLater(
        client.startScreenRecording(deviceId: deviceId, outputFileUri: Uri.file('/tmp/out.mp4')),
        throwsA(isA<json_rpc.RpcException>()),
      );
      await expectLater(
        client.stopScreenRecording(deviceId: deviceId),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });

    test('returns INVALID_PARAMS (-32602) on missing or invalid RPC parameters', () async {
      void entryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_TestDeviceService()],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      // installApp: empty deviceId, relative bundleUri, non-file bundleUri.
      await expectLater(
        conn.sendRequest(
          DeviceService.installAppMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: '',
            DeviceService.bundleUriParam: 'file:///tmp/app.bundle',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.installAppMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.bundleUriParam: 'relative/path/app.bundle',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.installAppMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.bundleUriParam: 'https://example.com/app.bundle',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );

      // uninstallApp: empty deviceId, empty appId.
      await expectLater(
        conn.sendRequest(
          DeviceService.uninstallAppMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: '',
            DeviceService.appIdParam: 'com.example.app',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.uninstallAppMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.appIdParam: '',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );

      // isAppInstalled: empty deviceId, empty appId.
      await expectLater(
        conn.sendRequest(
          DeviceService.isAppInstalledMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: '',
            DeviceService.appIdParam: 'com.example.app',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.isAppInstalledMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.appIdParam: '',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );

      // takeScreenshot: empty deviceId, invalid outputFileUri.
      await expectLater(
        conn.sendRequest(
          DeviceService.takeScreenshotMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: '',
            DeviceService.outputFileUriParam: 'file:///tmp/screenshot.png',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.takeScreenshotMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.outputFileUriParam: 'relative/screenshot.png',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );

      // startScreenRecording: empty deviceId, invalid outputFileUri, negative durationMs, wrong type durationMs.
      await expectLater(
        conn.sendRequest(
          DeviceService.startScreenRecordingMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: '',
            DeviceService.outputFileUriParam: 'file:///tmp/recording.mp4',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.startScreenRecordingMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.outputFileUriParam: 'http://example.com/recording.mp4',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.startScreenRecordingMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.outputFileUriParam: 'file:///tmp/recording.mp4',
            DeviceService.durationMsParam: -100,
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.startScreenRecordingMethod,
          params: <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.outputFileUriParam: 'file:///tmp/recording.mp4',
            DeviceService.durationMsParam: '5000',
          },
        ),
        throwsA(_isInvalidParamsRpcException()),
      );

      // stopScreenRecording: empty deviceId, missing deviceId.
      await expectLater(
        conn.sendRequest(
          DeviceService.stopScreenRecordingMethod,
          params: <String, Object?>{DeviceService.deviceIdParam: ''},
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
      await expectLater(
        conn.sendRequest(
          DeviceService.stopScreenRecordingMethod,
          params: const <String, Object?>{},
        ),
        throwsA(_isInvalidParamsRpcException()),
      );
    });
  });

  group('ExtensionBackedDevice delegation', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
    });

    test('delegates installApp, uninstallApp, isAppInstalled, takeScreenshot, '
        'startScreenRecording, and stopScreenRecording', () async {
      void entryPoint(SendPort sendPort) {
        final installedApps = <String>{};
        Uri? recordedUri;
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _TestDeviceService(
              onInstallApp: (String deviceId, Uri bundleUri) async {
                if (bundleUri.isValidFileUri) {
                  installedApps.add('com.example.prebuilt');
                  return true;
                }
                return false;
              },
              onIsAppInstalled: (String deviceId, String appId) async {
                return installedApps.contains(appId);
              },
              onUninstallApp: (String deviceId, String appId) async {
                return installedApps.remove(appId);
              },
              onTakeScreenshot: (String deviceId, Uri outputFileUri) async {},
              onStartScreenRecording:
                  (String deviceId, Uri outputFileUri, Duration? duration) async {
                    recordedUri = outputFileUri;
                  },
              onStopScreenRecording: (String deviceId) async {
                return recordedUri ?? Uri.file('/tmp/default.mp4');
              },
            ),
          ],
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      const targetDevice = TargetDevice(
        category: Category.mobile,
        id: 'ext-device-1',
        name: 'Extension Device 1',
        supportsScreenRecording: true,
        supportsScreenshot: true,
      );
      final device = ExtensionBackedDevice(
        connection: conn,
        deviceService: client,
        logger: logger,
        targetDevice: targetDevice,
      );

      expect(device.supportsScreenshot, isTrue);
      expect(device.supportsScreenRecording, isTrue);

      final File bundleFile = fs.file('/build/app.apk')..createSync(recursive: true);
      final app = _FakePrebuiltApplicationPackage(
        id: 'com.example.prebuilt',
        applicationPackage: bundleFile,
      );

      expect(await device.isAppInstalled(app), isFalse);
      expect(await device.installApp(app), isTrue);
      expect(await device.isAppInstalled(app), isTrue);
      expect(await device.uninstallApp(app), isTrue);
      expect(await device.isAppInstalled(app), isFalse);

      final nonPrebuiltApp = _FakeNonPrebuiltApplicationPackage(id: 'com.example.nonprebuilt');
      expect(await device.installApp(nonPrebuiltApp), isFalse);
      expect(
        logger.warningText,
        contains('Cannot install application "com.example.nonprebuilt" on "ext-device-1"'),
      );

      final File screenshotFile = fs.file('/captures/screen.png');
      await device.takeScreenshot(screenshotFile);

      final File recordingFile = fs.file('/captures/video.mp4');
      await device.startScreenRecording(recordingFile, duration: const Duration(seconds: 5));
      final Uri savedRecordingUri = await device.stopScreenRecording();
      expect(savedRecordingUri, equals(recordingFile.absolute.uri));
    });

    test('isAppInstalled, installApp, and uninstallApp catch errors and log warning', () async {
      void failingEntryPoint(SendPort sendPort) {
        ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _TestDeviceService(
              onInstallApp: (String _, Uri _) async {
                throw StateError('Simulated install failure');
              },
              onIsAppInstalled: (String _, String _) async {
                throw StateError('Simulated isAppInstalled failure');
              },
              onUninstallApp: (String _, String _) async {
                throw StateError('Simulated uninstall failure');
              },
            ),
          ],
          extensionName: 'failing_device_extension',
          supportedPlatforms: const <String>{'linux'},
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(
        failingEntryPoint,
        logger: logger,
      );
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      const targetDevice = TargetDevice(
        category: Category.mobile,
        id: 'ext-device-fail',
        name: 'Failing Extension Device',
      );
      final device = ExtensionBackedDevice(
        connection: conn,
        deviceService: client,
        logger: logger,
        targetDevice: targetDevice,
      );

      expect(device.supportsScreenshot, isFalse);
      expect(device.supportsScreenRecording, isFalse);

      final File bundleFile = fs.file('/build/app.apk')..createSync(recursive: true);
      final app = _FakePrebuiltApplicationPackage(
        id: 'com.example.app',
        applicationPackage: bundleFile,
      );

      expect(await device.isAppInstalled(app), isFalse);
      expect(
        logger.warningText,
        contains(
          'Failed to check if application "com.example.app" is installed on '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );

      expect(await device.installApp(app), isFalse);
      expect(
        logger.warningText,
        contains(
          'Failed to install application "com.example.app" on '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );

      expect(await device.uninstallApp(app), isFalse);
      expect(
        logger.warningText,
        contains(
          'Failed to uninstall application "com.example.app" from '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );
    });
  });
}
