// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_macros/src/executor/message_grouper.dart';
import 'package:_macros/src/executor/serialization.dart';

void main() async {
  for (var serializationMode in [
    SerializationMode.json,
    SerializationMode.byteData
  ]) {
    await withSerializationMode(serializationMode, () async {
      await _isolateSpawnBenchmarks();
      await _isolateSpawnUriBenchmarks();
      await _separateProcessStdioBenchmarks();
      await _separateProcessSocketBenchmarks();
    });
  }
}

Future<void> _isolateSpawnBenchmarks() async {
  void Function(SendPort) childIsolateFn(SerializationMode mode) =>
      (SendPort sendPort) => withSerializationMode(mode, () {
            var isolateReceivePort = ReceivePort();
            isolateReceivePort.listen((data) {
              deserialize(data);
              var result = serialize();
              result = result is Uint8List
                  ? TransferableTypedData.fromList([result])
                  : result;
              sendPort.send(result);
            });
            sendPort.send(isolateReceivePort.sendPort);
          });

  Completer? responseCompleter;
  late SendPort sendPort;

  var receivePort = ReceivePort();

  var isolate = await Isolate.spawn(
      childIsolateFn(serializationMode), receivePort.sendPort);

  final sendPortCompleter = Completer<SendPort>();
  receivePort.listen((data) {
    if (!sendPortCompleter.isCompleted) {
      sendPortCompleter.complete(data as SendPort);
    } else {
      responseCompleter!.complete(data);
    }
  });
  sendPort = await sendPortCompleter.future;

  // warmup
  for (var i = 0; i < 100; i++) {
    responseCompleter = Completer();
    var result = serialize();
    result =
        result is Uint8List ? TransferableTypedData.fromList([result]) : result;
    sendPort.send(result);
    deserialize(await responseCompleter.future);
  }
  // measure
  var watch = Stopwatch()..start();
  for (var i = 0; i < 100; i++) {
    responseCompleter = Completer();
    var result = serialize();
    result =
        result is Uint8List ? TransferableTypedData.fromList([result]) : result;
    sendPort.send(result);
    deserialize(await responseCompleter.future);
  }
  print('Isolate.spawn + $serializationMode: ${watch.elapsed}');

  receivePort.close();
  isolate.kill();
}

Future<void> _isolateSpawnUriBenchmarks() async {
  Completer? responseCompleter;
  late SendPort sendPort;

  var receivePort = ReceivePort();

  var isolate = await Isolate.spawnUri(
      Uri.dataFromString(childProgram(serializationMode)),
      [],
      receivePort.sendPort);

  final sendPortCompleter = Completer<SendPort>();
  receivePort.listen((data) {
    if (!sendPortCompleter.isCompleted) {
      sendPortCompleter.complete(data as SendPort);
    } else {
      responseCompleter!.complete(data);
    }
  });
  sendPort = await sendPortCompleter.future;

  // warmup
  for (var i = 0; i < 100; i++) {
    responseCompleter = Completer();
    var result = serialize();
    result =
        result is Uint8List ? TransferableTypedData.fromList([result]) : result;
    sendPort.send(result);
    deserialize(await responseCompleter.future);
  }
  // measure
  var watch = Stopwatch()..start();
  for (var i = 0; i < 100; i++) {
    responseCompleter = Completer();
    var result = serialize();
    result =
        result is Uint8List ? TransferableTypedData.fromList([result]) : result;
    sendPort.send(result);
    deserialize(await responseCompleter.future);
  }
  print('Isolate.spawnUri + $serializationMode: ${watch.elapsed}');

  receivePort.close();
  isolate.kill();
}

Future<void> _separateProcessStdioBenchmarks() async {
  Completer? responseCompleter;

  var tmpDir = Directory.systemTemp.createTempSync('serialize_bench');
  try {
    var file = File(tmpDir.uri.resolve('main.dart').toFilePath());
    file.writeAsStringSync(childProgram(serializationMode));
    var process = await Process.start(Platform.resolvedExecutable, [
      '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
      file.path,
    ]);

    var listeners = <StreamSubscription>[
      process.stderr.listen((event) {
        print('stderr: ${utf8.decode(event)}');
      }),
      (serializationMode == SerializationMode.json
              ? process.stdout
              : MessageGrouper(process.stdout).messageStream)
          .listen((data) {
        responseCompleter!.complete(data);
      }),
    ];

    // warmup
    for (var i = 0; i < 100; i++) {
      responseCompleter = Completer();
      var result = serialize();
      if (result is List<int>) {
        final bytesBuilder = BytesBuilder(copy: false);
        _writeLength(result, bytesBuilder);
        bytesBuilder.add(result);
        process.stdin.add(bytesBuilder.takeBytes());
      } else {
        process.stdin.writeln(jsonEncode(result));
      }
      deserialize(await responseCompleter.future);
    }
    // measure
    var watch = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      responseCompleter = Completer();
      var result = serialize();
      if (result is List<int>) {
        final bytesBuilder = BytesBuilder(copy: false);
        _writeLength(result, bytesBuilder);
        bytesBuilder.add(result);
        process.stdin.add(bytesBuilder.takeBytes());
      } else {
        process.stdin.writeln(jsonEncode(result));
      }
      deserialize(await responseCompleter.future);
    }
    print('Separate process + Stdio + $serializationMode: ${watch.elapsed}');

    for (var listener in listeners) {
      listener.cancel();
    }
    process.kill();
  } catch (e, s) {
    print('Error running benchmark \n$e\n\n$s');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

Future<void> _separateProcessSocketBenchmarks() async {
  Completer? responseCompleter;

  var tmpDir = Directory.systemTemp.createTempSync('serialize_bench');
  try {
    var file = File(tmpDir.uri.resolve('main.dart').toFilePath());
    file.writeAsStringSync(childProgram(serializationMode));

    ServerSocket serverSocket;
    // Try an ipv6 address loopback first, and fall back on ipv4.
    try {
      serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
    } on SocketException catch (_) {
      serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    }

    Completer<Socket> clientCompleter = Completer();
    serverSocket.listen((client) {
      clientCompleter.complete(client);
    });

    var process = await Process.start(Platform.resolvedExecutable, [
      '--packages=${(await Isolate.packageConfig)!.toFilePath()}',
      file.path,
      serverSocket.address.address,
      serverSocket.port.toString(),
    ]);
    var client = await clientCompleter.future;
    // Nagle's algorithm slows us down >100x, disable it.
    client.setOption(SocketOption.tcpNoDelay, true);

    var listeners = <StreamSubscription>[
      (serializationMode == SerializationMode.json
              ? client
              : MessageGrouper(client).messageStream)
          .listen((event) {
        responseCompleter!.complete(event);
      }),
      process.stderr.listen((event) {
        print('stderr: ${utf8.decode(event)}');
      }),
      process.stdout.listen((event) {
        print('stdout: ${utf8.decode(event)}');
      }),
    ];

    // warmup
    for (var i = 0; i < 100; i++) {
      responseCompleter = Completer();
      var result = serialize();
      if (result is List<int>) {
        final bytesBuilder = BytesBuilder(copy: false);
        _writeLength(result, bytesBuilder);
        bytesBuilder.add(result);
        client.add(bytesBuilder.takeBytes());
      } else {
        client.write(jsonEncode(result));
      }
      deserialize(await responseCompleter.future);
    }
    // measure
    var watch = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      responseCompleter = Completer();
      var result = serialize();
      if (result is List<int>) {
        final bytesBuilder = BytesBuilder(copy: false);
        _writeLength(result, bytesBuilder);
        bytesBuilder.add(result);
        client.add(bytesBuilder.takeBytes());
      } else {
        client.write(jsonEncode(result));
      }
      deserialize(await responseCompleter.future);
    }
    print('Separate process + Socket + $serializationMode: ${watch.elapsed}');

    for (var listener in listeners) {
      listener.cancel();
    }
    process.kill();
    await serverSocket.close();
    client.destroy();
  } catch (e, s) {
    print('Error running benchmark \n$e\n\n$s');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

void _writeLength(List<int> result, BytesBuilder bytesBuilder) {
  int length = (result as Uint8List).lengthInBytes;
  if (length > 0xffffffff) {
    throw StateError('Message was larger than the allowed size!');
  }
  bytesBuilder.add([
    length >> 24 & 0xff,
    length >> 16 & 0xff,
    length >> 8 & 0xff,
    length & 0xff
  ]);
}

String childProgram(SerializationMode mode) => '''
      import 'dart:convert';
      import 'dart:io';
      import 'dart:isolate';
      import 'dart:typed_data';

      import 'package:_fe_analyzer_shared/src/macros/executor/message_grouper.dart';
      import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';

      void main(List<String> args, [SendPort? sendPort]) async {
        var mode = $mode;
        await withSerializationMode(mode, () async {
          if (sendPort != null) {
              var isolateReceivePort = ReceivePort();
              isolateReceivePort.listen((data) {
                deserialize(data);
                var result = serialize();
                result = result is Uint8List
                    ? TransferableTypedData.fromList([result])
                    : result;
                sendPort.send(result);
              });
              sendPort.send(isolateReceivePort.sendPort);
          } else if (args.isNotEmpty) {
            var address = args[0];
            var port = int.parse(args[1]);
            var socket = await Socket.connect(address, port);
            if (mode == SerializationMode.json) {
              socket.listen((data) {
                var json = utf8.decode(data).trimRight();
                deserialize(jsonDecode(json));
                socket.write(jsonEncode(serialize()));
              });
            } else {
              MessageGrouper(socket).messageStream.listen((data) {
                deserialize(data);
                var result = serialize() as Uint8List;
                final bytesBuilder = BytesBuilder(copy: false);
                _writeLength(result, bytesBuilder);
                bytesBuilder.add(result);
                socket.add(bytesBuilder.takeBytes());
              });
            }
          } else {
            // We allow one empty line to work around some weird data.
            var allowEmpty = true;
            if (mode == SerializationMode.json) {
              stdin.listen((data) {
                var json = utf8.decode(data).trimRight();
                // On exit we tend to get extra empty lines sometimes?
                if (json.isEmpty && allowEmpty) {
                  allowEmpty = false;
                  return;
                }
                deserialize(jsonDecode(json));
                stdout.write(jsonEncode(serialize()));
              });
            } else {
              MessageGrouper(stdin).messageStream.listen((data) {
                deserialize(data);
                var result = serialize() as Uint8List;
                final bytesBuilder = BytesBuilder(copy: false);
                _writeLength(result, bytesBuilder);
                bytesBuilder.add(result);
                stdout.add(bytesBuilder.takeBytes());
              });
            }
          }
        });
      }

      Object? serialize() {
        var serializer = serializerFactory();
        for (var i = 0; i < 100; i++) {
          serializer.addInt(i * 100);
          serializer.addString('foo' * i);
          serializer.addBool(i % 2 == 0);
          serializer.startList();
          for (var j = 0; j < 10; j++) {
            serializer.addDouble(i * 5);
          }
          serializer.endList();
          serializer.addNull();
        }
        return serializer.result;
      }

      void deserialize(Object? result) {
        result = result is TransferableTypedData
            ? result.materialize().asUint8List()
            : result;
        var deserializer = deserializerFactory(result);
        while (deserializer.moveNext()) {
          deserializer
            ..expectInt()
            ..moveNext()
            ..expectString()
            ..moveNext()
            ..expectBool()
            ..moveNext()
            ..expectList();
          while (deserializer.moveNext()) {
            deserializer.expectDouble();
          }
          deserializer
            ..moveNext()
            ..checkNull();
        }
      }

      void _writeLength(Uint8List result, BytesBuilder bytesBuilder) {
        int length = result.lengthInBytes;
        if (length > 0xffffffff) {
          throw new StateError('Message was larger than the allowed size!');
        }
        bytesBuilder.add([
          length >> 24 & 0xff,
          length >> 16 & 0xff,
          length >> 8 & 0xff,
          length & 0xff
        ]);
      }''';

Object? serialize() {
  var serializer = serializerFactory();
  for (var i = -50; i < 50; i++) {
    serializer.addInt(i % 2 * 100);
    serializer.addString('foo' * i);
    serializer.addBool(i < 0);
    serializer.startList();
    for (var j = 0.0; j < 10; j++) {
      serializer.addDouble(i * j);
    }
    serializer.endList();
    serializer.addNull();
  }
  return serializer.result;
}

void deserialize(Object? result) {
  result = result is TransferableTypedData
      ? result.materialize().asUint8List()
      : result;
  if (serializationMode == SerializationMode.json) {
    if (result is List<int>) {
      result = jsonDecode(utf8.decode(result));
    }
  }
  var deserializer = deserializerFactory(result);
  while (deserializer.moveNext()) {
    deserializer
      ..expectInt()
      ..moveNext()
      ..expectString()
      ..moveNext()
      ..expectBool()
      ..moveNext()
      ..expectList();
    while (deserializer.moveNext()) {
      deserializer.expectDouble();
    }
    deserializer
      ..moveNext()
      ..checkNull();
  }
}
