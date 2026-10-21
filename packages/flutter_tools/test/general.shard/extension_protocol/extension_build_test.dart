// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/test.dart';

import '../../src/fakes.dart';

final class _ProgressAndStallBuildService extends BuildService {
  _ProgressAndStallBuildService({this.cancelEventsSendPort});

  final SendPort? cancelEventsSendPort;
  final _stallCompleters = <Object, Completer<ExtensionBuildResult>>{};

  @override
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    return const <ExtensionBuildTarget>[
      ExtensionBuildTarget(description: 'Heartbeat build target.', name: 'heartbeat-target'),
      ExtensionBuildTarget(description: 'Stalling build target.', name: 'stalling-target'),
    ];
  }

  @override
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
  }) async {
    if (targetName == 'heartbeat-target') {
      final completer = Completer<ExtensionBuildResult>();
      var ticks = 0;
      Timer.periodic(const Duration(milliseconds: 25), (Timer timer) {
        ticks++;
        if (ticks <= 3) {
          reportProgress(
            requestId: BuildService.buildMethod,
            message: 'Building step $ticks',
            progress: ticks / 3,
          );
        } else {
          timer.cancel();
          completer.complete(const ExtensionBuildResult(success: true));
        }
      });
      return completer.future;
    }

    final completer = Completer<ExtensionBuildResult>();
    _stallCompleters[BuildService.buildMethod] = completer;
    return completer.future;
  }

  @override
  Future<void> onCancelRequest(Object requestId) async {
    cancelEventsSendPort?.send(requestId);
    final Completer<ExtensionBuildResult>? completer = _stallCompleters.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        const ExtensionBuildResult(success: false, errorMessage: 'Cancelled by host.'),
      );
    }
  }
}

void main() {
  group('ExtensionBuildManager long-running build heartbeat and cancellation', () {
    test(
      'build succeeds when extension sends periodic progress heartbeats beyond single window',
      () async {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);

        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(
              sendPort,
              <ToolExtensionService>[_ProgressAndStallBuildService()],
              supportedPlatforms: const <String>{'linux'},
            ),
          );
        }

        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: featureFlags,
          entryPoints: <ExtensionEntryPoint>[entryPoint],
        );
        addTearDown(manager.dispose);

        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: logger,
        );

        final ExtensionBuildResult result = await buildManager.build(
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          projectRoot: Uri.parse('file:///project/'),
          targetName: 'heartbeat-target',
          inactivityTimeout: const Duration(milliseconds: 60),
        );

        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
      },
    );

    test(
      'build times out and sends extension.cancelRequest when no progress or heartbeat arrives',
      () async {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final cancelPort = ReceivePort();
        addTearDown(cancelPort.close);
        final SendPort cancelSendPort = cancelPort.sendPort;

        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(
              sendPort,
              <ToolExtensionService>[
                _ProgressAndStallBuildService(cancelEventsSendPort: cancelSendPort),
              ],
              supportedPlatforms: const <String>{'linux'},
            ),
          );
        }

        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: featureFlags,
          entryPoints: <ExtensionEntryPoint>[entryPoint],
        );
        addTearDown(manager.dispose);

        final buildManager = ExtensionBuildManager(
          extensionManager: manager,
          featureFlags: featureFlags,
          logger: logger,
        );

        final ExtensionBuildResult result = await buildManager.build(
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          projectRoot: Uri.parse('file:///project/'),
          targetName: 'stalling-target',
          inactivityTimeout: const Duration(milliseconds: 40),
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Request "build.build" timed out'));

        final Object? cancelledRequestId = await cancelPort.first;
        expect(cancelledRequestId, BuildService.buildMethod);
      },
    );
  });
}
