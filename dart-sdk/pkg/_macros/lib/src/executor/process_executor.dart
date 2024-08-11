// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../executor.dart';
import 'exception_impls.dart';
import 'executor_base.dart';
import 'message_grouper.dart';
import 'serialization.dart';

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
      {required super.messageStream,
      required this.onClose,
      required this.outSink,
      required super.serializationMode});

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
    Process process;
    try {
      process = await Process.start(programPath, [
        ...arguments,
        serverSocket.address.address,
        serverSocket.port.toString(),
      ]);
    } catch (e) {
      await serverSocket.close();
      rethrow;
    }
    process.stderr.transform(const Utf8Decoder()).listen((content) =>
        throw UnexpectedMacroExceptionImpl(
            'stderr output by macro process: $content'));
    process.stdout.transform(const Utf8Decoder()).listen(
        (event) => print('Stdout from MacroExecutor at $programPath:\n$event'));

    Completer<Socket> clientCompleter = Completer();
    serverSocket.listen((client) {
      clientCompleter.complete(client);
    });
    Socket client = await clientCompleter.future;
    // Nagle's algorithm slows us down >100x, disable it.
    client.setOption(SocketOption.tcpNoDelay, true);

    Stream<Object> messageStream;

    if (serializationMode == SerializationMode.byteData) {
      messageStream = MessageGrouper(client).messageStream;
    } else if (serializationMode == SerializationMode.json) {
      messageStream = const Utf8Decoder()
          .bind(client)
          .transform(const LineSplitter())
          .map((line) => jsonDecode(line) as Object);
    } else {
      throw UnsupportedError(
          'Unsupported serialization mode \$serializationMode for '
          'ProcessExecutor');
    }

    return _SingleProcessMacroExecutor(
        onClose: () {
          try {
            client.close();
          } catch (_) {
            // The `process.kill` two lines down can trigger an exception here
            // because the remote side closes the socket first. Ignore it.
          }
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
    process.stderr.transform(const Utf8Decoder()).listen((content) =>
        throw UnexpectedMacroExceptionImpl(
            'stderr output by macro process: $content'));

    Stream<Object> messageStream;

    if (serializationMode == SerializationMode.byteData) {
      messageStream = MessageGrouper(process.stdout).messageStream;
    } else if (serializationMode == SerializationMode.json) {
      messageStream = process.stdout
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .map((line) => jsonDecode(line) as Object);
    } else {
      throw UnsupportedError(
          'Unsupported serialization mode \$serializationMode for '
          'ProcessExecutor');
    }

    return _SingleProcessMacroExecutor(
        onClose: () {
          process.kill();
        },
        messageStream: messageStream,
        outSink: process.stdin,
        serializationMode: serializationMode);
  }

  @override
  Future<void> close() {
    if (isClosed) return Future.value();
    isClosed = true;
    return Future.sync(onClose);
  }

  /// Sends the [Serializer.result] to [stdin].
  ///
  /// Json results are serialized to a `String`, and separated by newlines.
  @override
  void sendResult(Serializer serializer) {
    if (serializationMode == SerializationMode.json) {
      outSink.writeln(jsonEncode(serializer.result));
    } else if (serializationMode == SerializationMode.byteData) {
      Uint8List result = (serializer as ByteDataSerializer).result;
      int length = result.lengthInBytes;
      if (length > 0xffffffff) {
        throw StateError('Message was larger than the allowed size!');
      }
      BytesBuilder bytesBuilder = BytesBuilder(copy: false);
      bytesBuilder.add([
        length >> 24 & 0xff,
        length >> 16 & 0xff,
        length >> 8 & 0xff,
        length & 0xff
      ]);
      bytesBuilder.add(result);
      outSink.add(bytesBuilder.takeBytes());
    } else {
      throw UnsupportedError(
          'Unsupported serialization mode $serializationMode for '
          'ProcessExecutor');
    }
  }
}

enum CommunicationChannel {
  socket,
  stdio,
}
