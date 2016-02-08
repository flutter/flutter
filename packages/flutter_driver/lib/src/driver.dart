// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:vm_service_client/vm_service_client.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;

import 'error.dart';
import 'find.dart';
import 'gesture.dart';
import 'health.dart';
import 'message.dart';

/// A function that connects to a Dart VM service given the [url].
typedef Future<VMServiceClient> VMServiceConnectFunction(String url);

/// Connects to a real Dart VM service using the [VMServiceClient].
final VMServiceConnectFunction vmServiceClientConnectFunction =
    VMServiceClient.connect;

/// The connection function used by [FlutterDriver.connect].
///
/// Overwrite this function if you require a different method for connecting to
/// the VM service.
VMServiceConnectFunction vmServiceConnectFunction =
    vmServiceClientConnectFunction;

/// Drives a Flutter Application running in another process.
class FlutterDriver {

  static const String _flutterExtensionMethod = 'ext.flutter_driver';
  static final Logger _log = new Logger('FlutterDriver');

  /// Connects to a Flutter application.
  ///
  /// Resumes the application if it is currently paused (e.g. at a breakpoint).
  ///
  /// [dartVmServiceUrl] is the URL to Dart observatory (a.k.a. VM service). By
  /// default it connects to `http://localhost:8181`.
  static Future<FlutterDriver> connect({String dartVmServiceUrl: 'http://localhost:8181'}) async {
    // Connect to Dart VM servcies
    _log.info('Connecting to Flutter application at $dartVmServiceUrl');
    VMServiceClient client = await vmServiceConnectFunction(dartVmServiceUrl);
    VM vm = await client.getVM();
    _log.trace('Looking for the isolate');
    VMIsolate isolate = await vm.isolates.first.load();
    FlutterDriver driver = new FlutterDriver.connectedTo(client, isolate);

    // Attempts to resume the isolate, but does not crash if it fails because
    // the isolate is already resumed. There could be a race with other tools,
    // such as a debugger, any of which could have resumed the isolate.
    Future resumeLeniently() {
      _log.trace('Attempting to resume isolate');
      return isolate.resume().catchError((e) {
        const vmMustBePausedCode = 101;
        if (e is rpc.RpcException && e.code == vmMustBePausedCode) {
          // No biggie; something else must have resumed the isolate
          _log.warning(
            'Attempted to resume an already resumed isolate. This may happen '
            'when we lose a race with another tool (usually a debugger) that '
            'is connected to the same isolate.'
          );
        } else {
          // Failed to resume due to another reason. Fail hard.
          throw e;
        }
      });
    }

    // Attempt to resume isolate if it was paused
    if (isolate.pauseEvent is VMPauseStartEvent) {
      _log.trace('Isolate is paused at start.');

      // Waits for a signal from the VM service that the extension is registered
      Future waitForServiceExtension() {
        return isolate.onServiceExtensionAdded.firstWhere((VMServiceExtension ext) {
          return ext.method == _flutterExtensionMethod;
        });
      }

      // If the isolate is paused at the start, e.g. via the --start-paused
      // option, then the VM service extension is not registered yet. Wait for
      // it to be registered.
      Future whenResumed = resumeLeniently();
      Future whenServiceExtensionReady = Future.any(<Future>[
        waitForServiceExtension(),
        // We will never receive the extension event if the user does not
        // register it. If that happens time out.
        new Future<String>.delayed(const Duration(seconds: 10), () => 'timeout')
      ]);
      await whenResumed;
      _log.trace('Waiting for service extension');
      dynamic signal = await whenServiceExtensionReady;
      if (signal == 'timeout') {
        throw new DriverError(
          'Timed out waiting for Flutter Driver extension to become available. '
          'To enable the driver extension call registerFlutterDriverExtension '
          'first thing in the main method of your application.'
        );
      }
    } else if (isolate.pauseEvent is VMPauseExitEvent ||
               isolate.pauseEvent is VMPauseBreakpointEvent ||
               isolate.pauseEvent is VMPauseExceptionEvent ||
               isolate.pauseEvent is VMPauseInterruptedEvent) {
      // If the isolate is paused for any other reason, assume the extension is
      // already there.
      _log.trace('Isolate is paused mid-flight.');
      await resumeLeniently();
    } else if (isolate.pauseEvent is VMResumeEvent) {
      _log.trace('Isolate is not paused. Assuming application is ready.');
    } else {
      _log.warning(
        'Unknown pause event type ${isolate.pauseEvent.runtimeType}. '
        'Assuming application is ready.'
      );
    }

    // At this point the service extension must be installed. Verify it.
    Health health = await driver.checkHealth();
    if (health.status != HealthStatus.ok) {
      client.close();
      throw new DriverError('Flutter application health check failed.');
    }

    _log.info('Connected to Flutter application.');
    return driver;
  }

  FlutterDriver.connectedTo(this._serviceClient, this._appIsolate);

  /// Client connected to the Dart VM running the Flutter application
  final VMServiceClient _serviceClient;
  /// The main isolate hosting the Flutter application
  final VMIsolateRef _appIsolate;

  Future<Map<String, dynamic>> _sendCommand(Command command) async {
    Map<String, dynamic> json = <String, dynamic>{'kind': command.kind}
      ..addAll(command.toJson());
    return _appIsolate.invokeExtension(_flutterExtensionMethod, json)
      .then((Map<String, dynamic> result) => result, onError: (error, stackTrace) {
        throw new DriverError(
          'Failed to fulfill ${command.runtimeType} due to remote error',
          error,
          stackTrace
        );
      });
  }

  /// Checks the status of the Flutter Driver extension.
  Future<Health> checkHealth() async {
    return Health.fromJson(await _sendCommand(new GetHealth()));
  }

  Future<ObjectRef> findByValueKey(dynamic key) async {
    return ObjectRef.fromJson(await _sendCommand(new FindByValueKey(key)));
  }

  Future<Null> tap(ObjectRef ref) async {
    return await _sendCommand(new Tap(ref)).then((_) => null);
  }

  Future<String> getText(ObjectRef ref) async {
    GetTextResult result = GetTextResult.fromJson(await _sendCommand(new GetText(ref)));
    return result.text;
  }

  /// Closes the underlying connection to the VM service.
  ///
  /// Returns a [Future] that fires once the connection has been closed.
  // TODO(yjbanov): cleanup object references
  Future close() => _serviceClient.close().then((_) {
    // Don't leak vm_service_client-specific objects, if any
    return null;
  });
}
