// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '_extension_io.dart' if (dart.library.html) '_extension_web.dart';

/// A subclass of [LiveTestWidgetsFlutterBinding] that reports tests results
/// on a channel to adapt them to native instrumentation test format.
class E2EWidgetsFlutterBinding extends LiveTestWidgetsFlutterBinding {
  /// Sets up a listener to report that the tests are finished when everything is
  /// torn down.
  E2EWidgetsFlutterBinding() {
    // TODO(jackson): Report test results as they arrive
    tearDownAll(() async {
      try {
        await _channel.invokeMethod<void>(
            'allTestsFinished', <String, dynamic>{'results': _results});
      } on MissingPluginException {
        print('Warning: E2E test plugin was not detected.');
      }
      if (!allTestsPassed.isCompleted) {
        allTestsPassed.complete(true);
      }
    });
  }

  final Completer<bool> allTestsPassed = Completer<bool>();

  /// Similar to [WidgetsFlutterBinding.ensureInitialized].
  ///
  /// Returns an instance of the [E2EWidgetsFlutterBinding], creating and
  /// initializing it if necessary.
  static WidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null) {
      E2EWidgetsFlutterBinding();
    }
    assert(WidgetsBinding.instance is E2EWidgetsFlutterBinding);
    return WidgetsBinding.instance;
  }

  static const MethodChannel _channel = MethodChannel('plugins.flutter.io/e2e');

  static Map<String, String> _results = <String, String>{};

  // Emulates the Flutter driver extension, returning 'pass' or 'fail'.
  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    Future<Map<String, dynamic>> callback(Map<String, String> params) async {
      final String command = params['command'];
      Map<String, String> response;
      switch (command) {
        case 'request_data':
          final bool allTestsPassedFlag = await allTestsPassed.future;
          response = <String, String>{
            'message': allTestsPassedFlag ? 'pass' : 'fail',
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

    if (kIsWeb) {
      print('****************** kisweb');
      registerWebServiceExtension(callback);
      print('***************** web service extention registered');
    }

    registerServiceExtension(name: 'driver', callback: callback);
  }

  @override
  Future<void> runTest(Future<void> testBody(), VoidCallback invariantTester,
      {String description = '', Duration timeout}) async {
    // TODO(jackson): Report the results individually instead of all at once
    // See https://github.com/flutter/flutter/issues/38985
    final TestExceptionReporter valueBeforeTest = reportTestException;
    reportTestException =
        (FlutterErrorDetails details, String testDescription) {
      _results[description] = 'failed';
      allTestsPassed.complete(false);
      valueBeforeTest(details, testDescription);
    };
    await super.runTest(testBody, invariantTester,
        description: description, timeout: timeout);
    _results[description] ??= 'success';
  }

  @override
  void reportExceptionNoticed(FlutterErrorDetails exception) {
    print('exception $exception');
  }

  /// For flutter web tests we want to use the real messages instead of
  /// test messages.
  /// See [TestDefaultBinaryMessenger].
  /// See [BinaryMessenger].
  @override
  BinaryMessenger createBinaryMessenger() {
    if (kIsWeb) {
      print('****************** kisweb return real binary messenger');
      return super.createOriginalBinaryMessenger();
    } else {
      return super.createBinaryMessenger();
    }
  }
}
