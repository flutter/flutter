// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io'; // ignore: dart_io_import

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:matcher/matcher.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  group('Flutter Tool VMService method', () {
    Directory tempDir;
    FlutterRunTestDriver flutter;
    VmService vmService;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('vmservice_integration_test.');

      final BasicProject _project = BasicProject();
      await _project.setUpIn(tempDir);

      flutter = FlutterRunTestDriver(tempDir);
      await flutter.run(withDebugger: true);
      final int port = flutter.vmServicePort;
      vmService = await vmServiceConnectUri('ws://localhost:$port/ws');
    });

    tearDown(() async {
      await flutter?.stop();
      tryToDelete(tempDir);
    });

    test('flutterVersion can be called', () async {
      final Response response =
          await vmService.callServiceExtension('s0.flutterVersion');
      expect(response.type, 'Success');
      expect(response.json, containsPair('frameworkRevisionShort', isNotNull));
      expect(response.json, containsPair('engineRevisionShort', isNotNull));
    });

    test('flutterMemoryInfo can be called', () async {
      final Response response =
          await vmService.callServiceExtension('s0.flutterMemoryInfo');
      expect(response.type, 'Success');
    });

    test('reloadSources can be called', () async {
      final VM vm = await vmService.getVM();
      final IsolateRef isolateRef = vm.isolates.first;

      final Response response = await vmService.callMethod('s0.reloadSources',
          isolateId: isolateRef.id);
      expect(response.type, 'Success');
    });

    test('reloadSources fails on bad params', () async {
      final Future<Response> response =
          vmService.callMethod('s0.reloadSources', isolateId: '');
      expect(response, throwsA(const TypeMatcher<RPCError>()));
    });

    test('hotRestart can be called', () async {
      final VM vm = await vmService.getVM();
      final IsolateRef isolateRef = vm.isolates.first;

      final Response response =
          await vmService.callMethod('s0.hotRestart', isolateId: isolateRef.id);
      expect(response.type, 'Success');
    });

    test('hotRestart fails on bad params', () async {
      final Future<Response> response = vmService.callMethod('s0.hotRestart',
          args: <String, dynamic>{'pause': 'not_a_bool'});
      expect(response, throwsA(const TypeMatcher<RPCError>()));
    });

    test('flutterGetSkSL can be called', () async {
      final Response response = await vmService.callMethod('s0.flutterGetSkSL');

      expect(response.type, 'Success');
    });

    test('ext.flutter.brightnessOverride can toggle window brightness', () async {
      final Isolate isolate = await waitForExtension(vmService);
      final Response response = await vmService.callServiceExtension(
        'ext.flutter.brightnessOverride',
        isolateId: isolate.id,
      );
      expect(response.json['value'], 'Brightness.light');

      final Response updateResponse = await vmService.callServiceExtension(
        'ext.flutter.brightnessOverride',
        isolateId: isolate.id,
        args: <String, String>{
          'value': 'Brightness.dark',
        }
      );
      expect(updateResponse.json['value'], 'Brightness.dark');

      // Change the brightness back to light
      final Response verifyResponse = await vmService.callServiceExtension(
        'ext.flutter.brightnessOverride',
        isolateId: isolate.id,
        args: <String, String>{
          'value': 'Brightness.light',
        }
      );
      expect(verifyResponse.json['value'], 'Brightness.light');

      // Change with a bogus value
      final Response bogusResponse = await vmService.callServiceExtension(
        'ext.flutter.brightnessOverride',
        isolateId: isolate.id,
        args: <String, String>{
          'value': 'dark', // Intentionally invalid value.
        }
      );
      expect(bogusResponse.json['value'], 'Brightness.light');
    });

    // TODO(devoncarew): These tests fail on cirrus-ci windows.
  }, skip: Platform.isWindows);
}

Future<Isolate> waitForExtension(VmService vmService) async {
  final Completer<void> completer = Completer<void>();
  await vmService.streamListen(EventStreams.kExtension);
  vmService.onExtensionEvent.listen((Event event) {
    if (event.json['extensionKind'] == 'Flutter.FrameworkInitialization') {
      completer.complete();
    }
  });
  final IsolateRef isolateRef = (await vmService.getVM()).isolates.first;
  final Isolate isolate = await vmService.getIsolate(isolateRef.id);
  if (isolate.extensionRPCs.contains('ext.flutter.brightnessOverride')) {
    return isolate;
  }
  await completer.future;
  return isolate;
}
