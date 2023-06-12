// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart';

import '../executor/message_grouper.dart';
import '../executor/executor_base.dart';
import '../executor/serialization.dart';
import '../executor.dart';

/// Spawns a [MacroExecutor] as a separate process, by running [program] with
/// [arguments], and communicating using [serializationMode].
///
/// The [serializationMode] must be a `server` variant, and [program] must use
/// the corresponding `client` variant.
///
/// This is the only public api exposed by this library.
Future<MacroExecutor> start(SerializationMode serializationMode,
    CommunicationChannel communicationChannel, String program,
    [List<String> arguments = const []]) {
  switch (communicationChannel) {
    case CommunicationChannel.stdio:
      return _SingleProcessMacroExecutor.startWithStdio(
          serializationMode, program, arguments);
    case CommunicationChannel.socket:
      return _SingleProcessMacroExecutor.startWithSocket(
          serializationMode, program, arguments);
  }
}

/// Actual implementation of the separate process based macro executor.
class _SingleProcessMacroExecutor extends ExternalMacroExecutorBase {
  /// The IOSink that writes to stdin of the external process.
  final IOSink outSink;

  /// A function that should be invoked when shutting down this executor
  /// to perform any necessary cleanup.
  final void Function() onClose;

  _SingleProcessMacroExecutor(
      {required Stream<Object> messageStream,
      required this.onClose,
      required this.outSink,
      required SerializationMode serializationMode})
      : super(
            messageStream: messageStream, serializationMode: serializationMode);

  static Future<_SingleProcessMacroExecutor> startWithSocket(
      SerializationMode serializationMode,
      String programPath,
      List<String> arguments) async {
    ServerSocket serverSocket;
    // Try an ipv6 address loopback first, and fall back on ipv4.
    try {
      serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
    } on SocketException catch (_) {
      serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    }
    Process process = await Process.start(programPath, [
      ...arguments,
      serverSocket.address.address,
      serverSocket.port.toString(),
    ]);
    process.stderr
        .transform(const Utf8Decoder())
        .listen((content) => throw new RemoteException(content));
    process.stdout.transform(const Utf8Decoder()).listen(
        (event) => print('Stdout from MacroExecutor at $programPath:\n$event'));

    Completer<Socket> clientCompleter = new Completer();
    serverSocket.listen((client) {
      clientCompleter.complete(client);
    });
    Socket client = await clientCompleter.future;

    Stream<Object> messageStream;

    if (serializationMode == SerializationMode.byteDataServer) {
      messageStream = new MessageGrouper(client).messageStream;
    } else if (serializationMode == SerializationMode.jsonServer) {
      messageStream = const Utf8Decoder()
          .bind(client)
          .transform(const LineSplitter())
          .map((line) => jsonDecode(line)!);
    } else {
      throw new UnsupportedError(
          'Unsupported serialization mode \$serializationMode for '
          'ProcessExecutor');
    }

    return new _SingleProcessMacroExecutor(
        onClose: () {
          client.close();
          serverSocket.close();
          process.kill();
        },
        messageStream: messageStream,
        outSink: client,
        serializationMode: serializationMode);
  }

  static Future<_SingleProcessMacroExecutor> startWithStdio(
      SerializationMode serializationMode,
      String programPath,
      List<String> arguments) async {
    Process process = await Process.start(programPath, arguments);
    process.stderr
        .transform(const Utf8Decoder())
        .listen((content) => throw new RemoteException(content));

    Stream<Object> messageStream;

    if (serializationMode == SerializationMode.byteDataServer) {
      messageStream = new MessageGrouper(process.stdout).messageStream;
    } else if (serializationMode == SerializationMode.jsonServer) {
      messageStream = process.stdout
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .map((line) => jsonDecode(line)!);
    } else {
      throw new UnsupportedError(
          'Unsupported serialization mode \$serializationMode for '
          'ProcessExecutor');
    }

    return new _SingleProcessMacroExecutor(
        onClose: () {
          process.kill();
        },
        messageStream: messageStream,
        outSink: process.stdin,
        serializationMode: serializationMode);
  }

  @override
  Future<void> close() => new Future.sync(onClose);

  /// Sends the [Serializer.result] to [stdin].
  ///
  /// Json results are serialized to a `String`, and separated by newlines.
  void sendResult(Serializer serializer) {
    if (serializationMode == SerializationMode.jsonServer) {
      outSink.writeln(jsonEncode(serializer.result));
    } else if (serializationMode == SerializationMode.byteDataServer) {
      Uint8List result = (serializer as ByteDataSerializer).result;
      int length = result.lengthInBytes;
      if (length > 0xffffffff) {
        throw new StateError('Message was larger than the allowed size!');
      }
      outSink.add([
        length >> 24 & 0xff,
        length >> 16 & 0xff,
        length >> 8 & 0xff,
        length & 0xff
      ]);
      outSink.add(result);
    } else {
      throw new UnsupportedError(
          'Unsupported serialization mode $serializationMode for '
          'ProcessExecutor');
    }
  }
}

enum CommunicationChannel {
  socket,
  stdio,
}
