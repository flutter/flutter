// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../executor/executor_base.dart';
import '../executor/serialization.dart';
import '../executor.dart';

/// Spawns a [MacroExecutor] as an isolate by passing [uriToSpawn] to
/// [Isolate.spawnUri], and communicating using [serializationMode].
///
/// The [uriToSpawn] can be any valid Uri for [Isolate.spawnUri].
///
/// Both [arguments] and [packageConfigUri] will be forwarded to
/// [Isolate.spawnUri] if provided.
///
/// The [serializationMode] must be a `server` variant, and [uriToSpawn] must
/// use the corresponding `client` variant.
///
/// This is the only public api exposed by this library.
Future<MacroExecutor> start(SerializationMode serializationMode, Uri uriToSpawn,
        {List<String> arguments = const [], Uri? packageConfigUri}) async =>
    _SingleIsolatedMacroExecutor.start(
        uriToSpawn, serializationMode, arguments, packageConfigUri);

/// Actual implementation of the isolate based macro executor.
class _SingleIsolatedMacroExecutor extends ExternalMacroExecutorBase {
  /// The send port where we should send requests.
  final SendPort sendPort;

  /// A function that should be invoked when shutting down this executor
  /// to perform any necessary cleanup.
  final void Function() onClose;

  _SingleIsolatedMacroExecutor(
      {required Stream<Object> messageStream,
      required this.onClose,
      required this.sendPort,
      required SerializationMode serializationMode})
      : super(
            messageStream: messageStream, serializationMode: serializationMode);

  static Future<_SingleIsolatedMacroExecutor> start(
      Uri uriToSpawn,
      SerializationMode serializationMode,
      List<String> arguments,
      Uri? packageConfig) async {
    ReceivePort receivePort = new ReceivePort();
    Isolate isolate = await Isolate.spawnUri(
        uriToSpawn, arguments, receivePort.sendPort,
        packageConfig: packageConfig);
    Completer<SendPort> sendPortCompleter = new Completer();
    StreamController<Object> messageStreamController =
        new StreamController(sync: true);
    receivePort.listen((message) {
      if (!sendPortCompleter.isCompleted) {
        sendPortCompleter.complete(message as SendPort);
      } else {
        if (serializationMode == SerializationMode.byteDataServer) {
          message =
              (message as TransferableTypedData).materialize().asUint8List();
        }
        messageStreamController.add(message);
      }
    }).onDone(messageStreamController.close);

    return new _SingleIsolatedMacroExecutor(
        onClose: () {
          receivePort.close();
          isolate.kill();
        },
        messageStream: messageStreamController.stream,
        sendPort: await sendPortCompleter.future,
        serializationMode: serializationMode);
  }

  @override
  Future<void> close() => new Future.sync(onClose);

  /// Sends the [Serializer.result] to [sendPort], possibly wrapping it in a
  /// [TransferableTypedData] object.
  void sendResult(Serializer serializer) {
    if (serializationMode == SerializationMode.byteDataServer) {
      sendPort.send(
          new TransferableTypedData.fromList([serializer.result as Uint8List]));
    } else {
      sendPort.send(serializer.result);
    }
  }
}
