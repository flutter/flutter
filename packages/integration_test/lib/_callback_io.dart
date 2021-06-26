// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'common.dart';

const MethodChannel integrationTestChannel = MethodChannel('plugins.flutter.io/integration_test');

/// The dart:io implementation of [CallbackManager].
///
/// See also:
///
///  * `_callback_web.dart`, which has the dart:html implementation
CallbackManager get callbackManager => _singletonCallbackManager;

/// IOCallbackManager singleton.
final IOCallbackManager _singletonCallbackManager = IOCallbackManager();

/// Manages communication between `integration_tests` and the `driver_tests`.
///
/// This is the dart:io implementation.
class IOCallbackManager implements CallbackManager {
  @override
  Future<Map<String, dynamic>> callback(
      Map<String, String> params, IntegrationTestResults testRunner) async {
    final String command = params['command']!;
    Map<String, String> response;
    switch (command) {
      case 'request_data':
        final bool allTestsPassed = await testRunner.allTestsPassed.future;
        response = <String, String>{
          'message': allTestsPassed
              ? Response.allTestsPassed(data: testRunner.reportData).toJson()
              : Response.someTestsFailed(
                  testRunner.failureMethodsDetails,
                  data: testRunner.reportData,
                ).toJson(),
        };
        break;
      case 'get_health':
        response = <String, String>{'status': 'ok'};
        break;
      default:
        throw UnimplementedError('$command is not implemented');
    }
    return <String, dynamic>{
      'isError': false,
      'response': response,
    };
  }

  @override
  void cleanup() {
    // no-op.
    // Add any IO platform specific Completer/Future cleanups to here if any
    // comes up in the future. For example: `WebCallbackManager.cleanup`.
  }

  @override
  Future<Map<String, dynamic>> takeScreenshot(String screenshot) async {
    integrationTestChannel.setMethodCallHandler(_onMethodChannelCall);

    final List<int>? rawBytes = await integrationTestChannel.invokeMethod<List<int>>(
      'captureScreenshot',
      null,
    );
    if (rawBytes == null) {
      throw 'Expected a list of bytes, but instead captureScreenshot returned null';
    }
    return <String, dynamic>{
      'screenshotName': screenshot,
      'bytes': rawBytes,
    };
  }

  Future<dynamic> _onMethodChannelCall(MethodCall call) {
    switch (call.method) {
      case 'scheduleFrame':
        window.scheduleFrame();
        break;
    }
    return Future<dynamic>.value(null);
  }
}
