// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';

void main() async {
  for (var serializationMode in [
    SerializationMode.jsonClient,
    SerializationMode.byteDataClient
  ]) {
    await withSerializationMode(serializationMode, () async {
      await _isolateSpawnBenchmarks();
      await _isolateSpawnUriBenchmarks();
      await _separateProcessBenchmarks();
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
      sendPortCompleter.complete(data);
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
      sendPortCompleter.complete(data);
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

Future<void> _separateProcessBenchmarks() async {
  Completer? responseCompleter;

  var tmpDir = Directory.systemTemp.createTempSync('serialize_bench');
  try {
    var file = File(tmpDir.uri.resolve('main.dart').toFilePath());
    file.writeAsStringSync(childProgram(serializationMode));
    var process = await Process.start(Platform.resolvedExecutable, [
      '--packages=' + (await Isolate.packageConfig)!.toFilePath(),
      file.path,
    ]);

    var listeners = <StreamSubscription>[
      process.stderr.listen((event) {
        print('stderr: ${utf8.decode(event)}');
      }),
      process.stdout.listen((data) {
        responseCompleter!.complete(data);
      }),
    ];

    // warmup
    for (var i = 0; i < 100; i++) {
      responseCompleter = Completer();
      var result = serialize();
      if (result is List<int>) {
        process.stdin.add(result);
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
        process.stdin.add(result);
      } else {
        process.stdin.writeln(jsonEncode(result));
      }
      deserialize(await responseCompleter.future);
    }
    print('Separate process + $serializationMode: ${watch.elapsed}');

    listeners.forEach((l) => l.cancel());
    process.kill();
  } catch (e, s) {
    print('Error running benchmark \n$e\n\n$s');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

String childProgram(SerializationMode mode) => '''
      import 'dart:convert';
      import 'dart:io';
      import 'dart:isolate';
      import 'dart:typed_data';

      import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';

      void main(_, [SendPort? sendPort]) {
        var mode = $mode;
        withSerializationMode(mode, () {
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
          } else {
            // We allow one empty line to work around some weird data.
            var allowEmpty = true;
            stdin.listen((data) {
              if (mode == SerializationMode.jsonClient || mode == SerializationMode.jsonServer) {
                var json = utf8.decode(data).trimRight();
                // On exit we tend to get extra empty lines sometimes?
                if (json.isEmpty && allowEmpty) {
                  allowEmpty = false;
                  return;
                }
                deserialize(jsonDecode(json));
                stdout.write(jsonEncode(serialize()));
              } else {
                deserialize(data);
                stdout.add(serialize() as List<int>);
              }
            });
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
  if (serializationMode == SerializationMode.jsonClient ||
      serializationMode == SerializationMode.jsonServer) {
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
