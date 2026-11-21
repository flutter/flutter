// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/testing.dart';
import 'package:test/test.dart';

final class _FakeService extends ToolExtensionService {
  int shutdownCount = 0;

  @override
  String get namespace => DiagnosticsExtension.serviceNamespace;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async => <String, ExtensionRpcHandler>{};

  @override
  Future<void> shutdown() async {
    shutdownCount++;
  }
}

final class _FakeDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => false;

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async => false;

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async => null;

  @override
  Future<bool> stopApp({required String deviceId}) async => false;
}

Directory _createTempPackage(String prefix) {
  final Directory dir = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return dir;
}

Directory _writeTempExtension(String prefix, String body) {
  final Directory packageDir = _createTempPackage(prefix);
  final file = File.fromUri(packageDir.uri.resolve('extension/flutter_tools/extension.dart'))
    ..createSync(recursive: true);
  file.writeAsStringSync(body);
  return packageDir;
}

void main() {
  group('ServiceTestHarness', () {
    test('captures logs with and without explicit timestamp', () async {
      final service = _FakeService();
      final harness = ServiceTestHarness<_FakeService>(service);
      addTearDown(harness.dispose);

      final streamedLogs = <ExtensionLogMessage>[];
      final StreamSubscription<ExtensionLogMessage> sub = harness.onLog.listen(streamedLogs.add);
      addTearDown(sub.cancel);

      final explicitTime = DateTime.utc(2026, 1, 2, 3, 4, 5);
      service
        ..log('plain message')
        ..log('warning message', level: .warning, timestamp: explicitTime);

      await pumpEventQueue();

      expect(harness.logs, hasLength(2));
      expect(harness.logs[0].level, ExtensionLogLevel.info);
      expect(harness.logs[0].message, 'plain message');
      expect(harness.logs[0].timestamp, isNull);
      expect(harness.logs[1].level, ExtensionLogLevel.warning);
      expect(harness.logs[1].message, 'warning message');
      expect(harness.logs[1].timestamp, explicitTime);
      expect(streamedLogs, equals(harness.logs));
    });

    test('captures deviceLogLines and custom notifications', () async {
      final service = _FakeDeviceService();
      final harness = ServiceTestHarness<_FakeDeviceService>(service);
      addTearDown(harness.dispose);

      service
        ..emitLogLine(deviceId: 'dev-1', line: 'line 1')
        ..emitLogLine(deviceId: 'dev-2', line: 'other device')
        ..emitLogLine(deviceId: 'dev-1', line: 'line 2')
        ..sendNotification('custom.event', <String, Object?>{'count': 42});

      expect(harness.deviceLogLines('dev-1'), <String>['line 1', 'line 2']);
      expect(harness.deviceLogLines('dev-2'), <String>['other device']);
      expect(harness.notifications, hasLength(4));
      expect(harness.notifications.last.method, 'custom.event');
      expect(harness.notifications.last.params, <String, Object?>{'count': 42});
    });

    test('rejects malformed extension.log and device.logEntry payloads', () async {
      final harness = ServiceTestHarness<_FakeService>(_FakeService());
      addTearDown(harness.dispose);

      expect(
        () => harness.service.sendNotification(
          ToolExtensionEntryPoint.logNotificationMethod,
          <String, Object?>{'level': 'bogus', 'message': 'bad'},
        ),
        throwsFormatException,
      );

      harness.service.sendNotification(DeviceService.logEntryNotificationMethod, <String, Object?>{
        DeviceService.deviceIdParam: 123,
        DeviceService.lineKey: 'bad',
      });
      expect(() => harness.deviceLogLines('123'), throwsFormatException);
    });

    test('rejects attaching a second harness to the same service', () async {
      final service = _FakeService();
      final harness = ServiceTestHarness<_FakeService>(service);
      addTearDown(harness.dispose);

      expect(() => ServiceTestHarness<_FakeService>(service), throwsStateError);
    });

    test('dispose detaches notificationSender, invokes shutdown, and is idempotent', () async {
      final service = _FakeService();
      final harness = ServiceTestHarness<_FakeService>(service);

      await Future.wait<void>(<Future<void>>[harness.dispose(), harness.dispose()]);
      expect(service.shutdownCount, 1);
      expect(() => service.log('after dispose'), throwsStateError);

      final reattached = ServiceTestHarness<_FakeService>(service);
      addTearDown(reattached.dispose);
    });
  });

  group('verifyExtensionPackage', () {
    test('succeeds via Isolate.spawnUri and invokes service.shutdown()', () async {
      final Directory packageDir = _createTempPackage('verify_pkg_ok.');
      final templateDir = Directory.fromUri(packageDir.uri.resolve('templates/app/'))
        ..createSync(recursive: true);
      final shutdownMarker = File.fromUri(packageDir.uri.resolve('shutdown.marker'));

      File.fromUri(packageDir.uri.resolve('extension/flutter_tools/extension.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _TempService extends TemplateService {
  @override
  Set<String> get appPlatformTemplates => <String>{'${templateDir.uri}'};

  @override
  Set<String> get pluginPlatformTemplates => const <String>{};

  @override
  Set<ProjectTemplate> get projectTemplates => const <ProjectTemplate>{};

  @override
  Future<void> shutdown() async {
    File('${shutdownMarker.path}').writeAsStringSync('done');
  }
}

void main(List<String> args, SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_TempService()]));
}
''');

      await verifyExtensionPackage(packageRoot: packageDir.uri);
      expect(shutdownMarker.existsSync(), isTrue);
      expect(shutdownMarker.readAsStringSync(), 'done');
    });

    test('skips service RPCs when supportedPlatforms excludes host OS', () async {
      final otherPlatform = Platform.isLinux ? 'macos' : 'linux';
      final Directory packageDir = _writeTempExtension('verify_pkg_platform.', '''
import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _Target extends BuildTarget {
  const _Target()
    : super(description: 'Dup', outputDir: 'build/dup', targetPlatform: 'linux-x64');

  @override
  String get name => 'dup';

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async =>
      const ExtensionBuildResult(success: true);
}

final class _DupBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[_Target(), _Target()];
}

void main(List<String> args, SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[_DupBuildService()],
      supportedPlatforms: const <String>{'$otherPlatform'},
    ),
  );
}
''');

      await verifyExtensionPackage(packageRoot: packageDir.uri);
    });

    test('fails on missing entrypoint', () async {
      final Directory missingDir = _createTempPackage('verify_pkg_missing.');
      await expectLater(verifyExtensionPackage(packageRoot: missingDir.uri), throwsStateError);
    });

    test('fails cleanly on startup crash, post-handshake exit, and async error', () async {
      final Directory crashDir = _writeTempExtension('verify_pkg_crash.', '''
import 'dart:isolate';

void main(List<String> args, SendPort sendPort) {
  throw StateError('boom during startup');
}
''');
      await expectLater(verifyExtensionPackage(packageRoot: crashDir.uri), throwsStateError);

      final Directory exitDir = _writeTempExtension('verify_pkg_exit.', '''
import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _ExitingBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets {
    Isolate.current.kill(priority: Isolate.immediate);
    return const <BuildTarget>[];
  }
}

void main(List<String> args, SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_ExitingBuildService()]));
}
''');
      await expectLater(verifyExtensionPackage(packageRoot: exitDir.uri), throwsA(isA<Object>()));

      final Directory asyncErrorDir = _writeTempExtension('verify_pkg_async.', '''
import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _AsyncErrorBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets {
    unawaited(Future<void>.error(StateError('async isolate failure')));
    return const <BuildTarget>[];
  }
}

void main(List<String> args, SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_AsyncErrorBuildService()]),
  );
}
''');
      await expectLater(verifyExtensionPackage(packageRoot: asyncErrorDir.uri), throwsStateError);
    });

    test('validates capabilities, build targets, and package template URIs', () async {
      final Directory dupNamespaceDir = _writeTempExtension('verify_pkg_dup_ns.', '''
import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _Diag extends DiagnosticsExtension {
  @override
  String get title => 'Diag';

  @override
  Future<List<ValidationResult>> runDiagnostics() async => const <ValidationResult>[];
}

void main(List<String> args, SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_Diag(), _Diag()]));
}
''');
      await expectLater(verifyExtensionPackage(packageRoot: dupNamespaceDir.uri), throwsStateError);

      final Directory emptyPlatformsDir = _writeTempExtension('verify_pkg_empty_plat.', '''
import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _Diag extends DiagnosticsExtension {
  @override
  String get title => 'Diag';

  @override
  Future<List<ValidationResult>> runDiagnostics() async => const <ValidationResult>[];
}

void main(List<String> args, SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[_Diag()],
      supportedPlatforms: const <String>{},
    ),
  );
}
''');
      await expectLater(
        verifyExtensionPackage(packageRoot: emptyPlatformsDir.uri),
        throwsStateError,
      );

      final Directory dupBuildDir = _writeTempExtension('verify_pkg_dup_build.', '''
import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _Target extends BuildTarget {
  const _Target()
    : super(description: 'Dup', outputDir: 'build/dup', targetPlatform: 'linux-x64');

  @override
  String get name => 'dup-target';

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async =>
      const ExtensionBuildResult(success: true);
}

final class _DupBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[_Target(), _Target()];
}

void main(List<String> args, SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_DupBuildService()]));
}
''');
      await expectLater(verifyExtensionPackage(packageRoot: dupBuildDir.uri), throwsStateError);

      final Directory dupAssembleDir = _writeTempExtension('verify_pkg_dup_asm.', '''
import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _Asm extends AssembleTarget {
  const _Asm() : super(description: 'Dup', targetPlatform: 'linux-x64');

  @override
  String get name => 'dup-assemble';

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async =>
      const ExtensionBuildResult(success: true);
}

final class _DupBuildService extends BuildService {
  @override
  List<AssembleTarget> get assembleTargets => const <AssembleTarget>[_Asm(), _Asm()];
}

void main(List<String> args, SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_DupBuildService()]));
}
''');
      await expectLater(verifyExtensionPackage(packageRoot: dupAssembleDir.uri), throwsStateError);

      final Directory missingTemplateDir = _writeTempExtension('verify_pkg_missing_tpl.', '''
import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _TplService extends TemplateService {
  @override
  Set<String> get appPlatformTemplates => const <String>{
    'package:flutter_tools_extension_linux_prototype/does_not_exist',
  };

  @override
  Set<String> get pluginPlatformTemplates => const <String>{};

  @override
  Set<ProjectTemplate> get projectTemplates => const <ProjectTemplate>{};
}

void main(List<String> args, SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_TplService()]));
}
''');
      await expectLater(
        verifyExtensionPackage(packageRoot: missingTemplateDir.uri),
        throwsStateError,
      );
    });
  });
}
