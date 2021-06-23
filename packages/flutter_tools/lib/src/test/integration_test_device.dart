// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../application_package.dart';
import '../base/common.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals_null_migrated.dart' as globals;
import '../sksl_writer.dart';
import '../vmservice.dart';
import 'test_device.dart';

const String kIntegrationTestExtension = 'Flutter.IntegrationTest';
const String kIntegrationTestData = 'data';
const String kIntegrationTestMethod = 'ext.flutter.integrationTest';

class IntegrationTestTestDevice implements TestDevice {
  IntegrationTestTestDevice({
    @required this.id,
    @required this.device,
    @required this.debuggingOptions,
    @required this.userIdentifier,
    @required this.writeSkslOnExit,
  });

  final int id;
  final Device device;
  final DebuggingOptions debuggingOptions;
  final String userIdentifier;

  /// File to write the SkSL shaders.
  ///
  /// The SkSL shaders will only be written to this file if it is not null.
  final File writeSkslOnExit;

  ApplicationPackage _applicationPackage;
  final Completer<void> _finished = Completer<void>();
  final Completer<FlutterVmService> _connectedToFlutterVmService = Completer<FlutterVmService>();

  /// Starts the device.
  ///
  /// [entrypointPath] must be a path to an un-compiled source file.
  @override
  Future<StreamChannel<String>> start(String entrypointPath) async {
    final TargetPlatform targetPlatform = await device.targetPlatform;
    _applicationPackage = await ApplicationPackageFactory.instance.getPackageForPlatform(
      targetPlatform,
      buildInfo: debuggingOptions.buildInfo,
    );

    final LaunchResult launchResult = await device.startApp(
      _applicationPackage,
      mainPath: entrypointPath,
      platformArgs: <String, dynamic>{},
      debuggingOptions: debuggingOptions,
      userIdentifier: userIdentifier,
    );
    if (!launchResult.started) {
      throw TestDeviceException('Unable to start the app on the device.', StackTrace.current);
    }
    if (launchResult.observatoryUri == null) {
      throw TestDeviceException('Observatory is not available on the test device.', StackTrace.current);
    }

    // No need to set up the log reader because the logs are captured and
    // streamed to the package:test_core runner.

    globals.printTrace('test $id: Connecting to vm service');
    final FlutterVmService vmService = await connectToVmService(launchResult.observatoryUri, logger: globals.logger).timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Connecting to the VM Service timed out.'),
    );

    globals.printTrace('test $id: Finding the correct isolate with the integration test service extension');
    final vm_service.IsolateRef isolateRef = await vmService.findExtensionIsolate(
      kIntegrationTestMethod,
    );

    await vmService.service.streamListen(vm_service.EventStreams.kExtension);
    final Stream<String> remoteMessages = vmService.service.onExtensionEvent
        .where((vm_service.Event e) => e.extensionKind == kIntegrationTestExtension)
        .map((vm_service.Event e) => e.extensionData.data[kIntegrationTestData] as String);

    final StreamChannelController<String> controller = StreamChannelController<String>();

    controller.local.stream.listen((String event) {
      vmService.service.callServiceExtension(
        kIntegrationTestMethod,
        isolateId: isolateRef.id,
        args: <String, String>{
          kIntegrationTestData: event,
        },
      );
    });

    unawaited(remoteMessages.pipe(controller.local.sink));
    _connectedToFlutterVmService.complete(vmService);

    return controller.foreign;
  }

  @override
  Future<Uri> get observatoryUri async => (await _connectedToFlutterVmService.future).httpAddress;

  @override
  Future<void> kill() async {
    if (writeSkslOnExit != null) {
      await _writeSksl();
    }

    if (!await device.stopApp(_applicationPackage, userIdentifier: userIdentifier)) {
      globals.printTrace('Could not stop the Integration Test app.');
    }
    if (!await device.uninstallApp(_applicationPackage, userIdentifier: userIdentifier)) {
      globals.printTrace('Could not uninstall the Integration Test app.');
    }

    await device.dispose();
    _finished.complete();
  }

  @override
  Future<void> get finished => _finished.future;

  Future<void> _writeSksl() async {
    if (!_connectedToFlutterVmService.isCompleted) {
      globals.printStatus('Skipped writing of SkSL data because the Flutter Tool could not connect to the device.');
      return;
    }
    final FlutterVmService vmService = await _connectedToFlutterVmService.future;

    final FlutterView flutterView = (await vmService.getFlutterViews()).first;
    final Map<String, Object> result = await vmService.getSkSLs(
      viewId: flutterView.id
    );
    await sharedSkSlWriter(device, result, outputFile: writeSkslOnExit, logger: globals.logger);
  }
}
