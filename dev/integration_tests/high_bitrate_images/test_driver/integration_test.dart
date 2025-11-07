// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:vm_service/vm_service.dart' as vm;

const String _kGoldenFileComparatorStream =
    'integration_test.VmServiceProxyGoldenFileComparator';

/// A simple VM service client that proxies golden file comparator requests
/// from the application to the host.
///
/// This is a simplified version of `flutter_test/lib/_goldens_io.dart`.
class _GoldenFileComparatorProxy {
  _GoldenFileComparatorProxy(this._vmService) {
    _subscription = _vmService.onEvent(_kGoldenFileComparatorStream).listen(_handleMessage);
  }

  final vm.VmService _vmService;
  late final StreamSubscription<vm.Event> _subscription;

  Future<void> dispose() async {
    await _subscription.cancel();
  }

  Future<void> _handleMessage(vm.Event event) async {
    final Map<String, dynamic> data = event.extensionData!.data;
    final String? method = event.extensionKind;

    switch (method) {
      case 'compare':
        print('got compare!');
        final int id = data['id'] as int;
        final String path = data['path'] as String;
        final String bytes = data['bytes'] as String;
        final File golden = File(path);
        bool passed = false;
        if (golden.existsSync()) {
          final List<int> actual = base64.decode(bytes);
          final List<int> expected = golden.readAsBytesSync();
          // Very basic comparison.
          if (actual.length == expected.length) {
            passed = true;
            for (int i = 0; i < actual.length; i++) {
              if (actual[i] != expected[i]) {
                passed = false;
                break;
              }
            }
          }
        }
        _respond(id, null);
        break;
      case 'update':
        final int id = data['id'] as int;
        final String path = data['path'] as String;
        final String bytes = data['bytes'] as String;
        final File golden = File(path);
        try {
          if (!golden.parent.existsSync()) {
            golden.parent.createSync(recursive: true);
          }
          golden.writeAsBytesSync(base64.decode(bytes));
          _respond(id, null);
        } catch (e) {
          _respond(id, 'Failed to update golden file: $e');
        }
        break;
      default:
        throw UnimplementedError('Unknown method: $method');
    }
  }

  void _respond(int id, String? error) {
    _vmService.callServiceExtension(
      'ext.integration_test.VmServiceProxyGoldenFileComparator',
      args: <String, Object?>{
        'id': id,
        'result': error != null,
        if (error != null) 'error': error,
      },
    );
  }
}

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  final _GoldenFileComparatorProxy proxy = _GoldenFileComparatorProxy(driver.serviceClient);
  await driver.serviceClient.streamListen(_kGoldenFileComparatorStream);

  try {
    final String jsonResult = await driver.requestData(null);
    final Response response = Response.fromJson(jsonResult);

    if (response.allTestsPassed) {
      print('All tests passed.');
      exit(0);
    } else {
      print('Failure Details:\n${response.formattedFailureDetails}');
      exit(1);
    }
  } finally {
    await proxy.dispose();
    await driver.close();
  }
}
