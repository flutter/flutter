// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

import 'dart:_js_helper' show NoReifyGeneric;
import 'dart:_internal' show patch;
import 'dart:async';
import "dart:typed_data" show TypedData;

@patch
class Isolate {
  // `current` must be a getter, not just a final field,
  // to match the external declaration.
  @patch
  static Isolate get current => _unsupported();

  @patch
  String? get debugName => _unsupported();

  @patch
  static Future<Uri?> get packageConfig => _unsupported();

  @patch
  static Uri? get packageConfigSync => _unsupported();

  @patch
  static Future<Uri?> resolvePackageUri(Uri packageUri) => _unsupported();

  @patch
  static Uri? resolvePackageUriSync(Uri packageUri) => _unsupported();

  @patch
  static Future<Isolate> spawn<T>(void entryPoint(T message), T message,
          {bool paused = false,
          bool errorsAreFatal = true,
          SendPort? onExit,
          SendPort? onError,
          String? debugName}) =>
      _unsupported();

  @patch
  static Future<Isolate> spawnUri(Uri uri, List<String> args, var message,
          {bool paused = false,
          SendPort? onExit,
          SendPort? onError,
          bool errorsAreFatal = true,
          bool? checked,
          Map<String, String>? environment,
          Uri? packageRoot,
          Uri? packageConfig,
          bool automaticPackageResolution = false,
          String? debugName}) =>
      _unsupported();

  @patch
  void _pause(Capability resumeCapability) => _unsupported();

  @patch
  void resume(Capability resumeCapability) => _unsupported();

  @patch
  void addOnExitListener(SendPort responsePort, {Object? response}) =>
      _unsupported();

  @patch
  void removeOnExitListener(SendPort responsePort) => _unsupported();

  @patch
  void setErrorsFatal(bool errorsAreFatal) => _unsupported();

  @patch
  void kill({int priority = beforeNextEvent}) => _unsupported();
  @patch
  void ping(SendPort responsePort,
          {Object? response, int priority = immediate}) =>
      _unsupported();

  @patch
  void addErrorListener(SendPort port) => _unsupported();

  @patch
  void removeErrorListener(SendPort port) => _unsupported();

  @patch
  static Never exit([SendPort? finalMessagePort, Object? message]) =>
      _unsupported();
}

/// Default factory for receive ports.
@patch
class ReceivePort {
  @patch
  factory ReceivePort([String debugName]) = _ReceivePort;

  @patch
  factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) =>
      _unsupported();
}

/// ReceivePort is supported by dev_compiler because async test packages
/// (async_helper, unittest) create a dummy receive port to keep the Dart VM
/// alive.
class _ReceivePort extends Stream implements ReceivePort {
  _ReceivePort([String debugName = '']);

  close() {}

  get sendPort => _unsupported();

  StreamSubscription listen(void Function(dynamic)? onData,
          {Function? onError,
          void Function()? onDone,
          bool? cancelOnError = true}) =>
      _unsupported();
}

@patch
class RawReceivePort {
  @patch
  factory RawReceivePort([Function? handler, String debugName = '']) =>
      _unsupported();
}

@patch
class Capability {
  @patch
  factory Capability() => _unsupported();
}

@patch
abstract class TransferableTypedData {
  @patch
  factory TransferableTypedData.fromList(List<TypedData> list) =>
      _unsupported();
}

@NoReifyGeneric()
T _unsupported<T>() {
  throw UnsupportedError('dart:isolate is not supported on dart4web');
}
