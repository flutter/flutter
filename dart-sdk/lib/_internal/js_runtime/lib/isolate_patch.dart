// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.

import "dart:async";
import 'dart:_foreign_helper' show JS;
import 'dart:_internal' show patch;
import "dart:typed_data" show TypedData;

@patch
class Isolate {
  @patch
  static Isolate get current {
    throw UnsupportedError("Isolate.current");
  }

  @patch
  String? get debugName {
    throw UnsupportedError("Isolate.debugName");
  }

  @patch
  static Future<Uri?> get packageConfig {
    throw UnsupportedError("Isolate.packageConfig");
  }

  @patch
  static Uri? get packageConfigSync {
    throw UnsupportedError("Isolate.packageConfigSync");
  }

  @patch
  static Future<Uri?> resolvePackageUri(Uri packageUri) {
    throw UnsupportedError("Isolate.resolvePackageUri");
  }

  @patch
  static Uri? resolvePackageUriSync(Uri packageUri) {
    throw UnsupportedError("Isolate.resolvePackageUriSync");
  }

  @patch
  static Future<Isolate> spawn<T>(void entryPoint(T message), T message,
      {bool paused = false,
      bool errorsAreFatal = true,
      SendPort? onExit,
      SendPort? onError,
      String? debugName}) {
    throw UnsupportedError("Isolate.spawn");
  }

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
      String? debugName}) {
    throw UnsupportedError("Isolate.spawnUri");
  }

  @patch
  void _pause(Capability resumeCapability) {
    throw UnsupportedError("Isolate._pause");
  }

  @patch
  void resume(Capability resumeCapability) {
    throw UnsupportedError("Isolate.resume");
  }

  @patch
  void addOnExitListener(SendPort responsePort, {Object? response}) {
    throw UnsupportedError("Isolate.addOnExitListener");
  }

  @patch
  void removeOnExitListener(SendPort responsePort) {
    throw UnsupportedError("Isolate.removeOnExitListener");
  }

  @patch
  void setErrorsFatal(bool errorsAreFatal) {
    throw UnsupportedError("Isolate.setErrorsFatal");
  }

  @patch
  void kill({int priority = beforeNextEvent}) {
    throw UnsupportedError("Isolate.kill");
  }

  @patch
  void ping(SendPort responsePort,
      {Object? response, int priority = immediate}) {
    throw UnsupportedError("Isolate.ping");
  }

  @patch
  void addErrorListener(SendPort port) {
    throw UnsupportedError("Isolate.addErrorListener");
  }

  @patch
  void removeErrorListener(SendPort port) {
    throw UnsupportedError("Isolate.removeErrorListener");
  }

  @patch
  static Never exit([SendPort? finalMessagePort, Object? message]) {
    throw UnsupportedError("Isolate.exit");
  }
}

@patch
class ReceivePort {
  @patch
  factory ReceivePort([String debugName]) = _ReceivePortImpl;

  @patch
  factory ReceivePort.fromRawReceivePort(RawReceivePort rawPort) {
    throw UnsupportedError('new ReceivePort.fromRawReceivePort');
  }
}

class _ReceivePortImpl extends Stream implements ReceivePort {
  _ReceivePortImpl([String debugName = '']);

  StreamSubscription listen(void Function(dynamic)? onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError = true}) {
    throw UnsupportedError("ReceivePort.listen");
  }

  void close() {}

  SendPort get sendPort => throw UnsupportedError("ReceivePort.sendPort");
}

@patch
class RawReceivePort {
  @patch
  factory RawReceivePort([Function? handler, String debugName = '']) {
    throw UnsupportedError('new RawReceivePort');
  }
}

@patch
class Capability {
  @patch
  factory Capability() {
    throw UnsupportedError('new Capability');
  }
}

@patch
abstract class TransferableTypedData {
  @patch
  factory TransferableTypedData.fromList(List<TypedData> list) {
    throw UnsupportedError('TransferableTypedData.fromList');
  }
}
