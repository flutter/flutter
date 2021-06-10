// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:microbenchmarks/common.dart';

List<Object?> _makeTestBuffer(int size) {
  final List<Object?> answer = <Object?>[];
  for (int i = 0; i < size; ++i) {
    switch (i % 9) {
      case 0:
        answer.add(1);
        break;
      case 1:
        answer.add(math.pow(2, 65));
        break;
      case 2:
        answer.add(1234.0);
        break;
      case 3:
        answer.add(null);
        break;
      case 4:
        answer.add(<int>[1234]);
        break;
      case 5:
        answer.add(<String, int>{'hello': 1234});
        break;
      case 6:
        answer.add('this is a test');
        break;
      case 7:
        answer.add(true);
        break;
      case 8:
        answer.add(Uint8List(64));
        break;
    }
  }
  return answer;
}

Future<double> _runBasicStandardSmall(
    BasicMessageChannel<Object?> basicStandard, int count) async {
  final Stopwatch watch = Stopwatch();
  watch.start();
  for (int i = 0; i < count; ++i) {
    await basicStandard.send(1234);
  }
  watch.stop();
  return watch.elapsedMicroseconds / count;
}

Future<double> _runBasicStandardLarge(BasicMessageChannel<Object?> basicStandard,
    List<Object?> largeBuffer, int count) async {
  int size = 0;
  final Stopwatch watch = Stopwatch();
  watch.start();
  for (int i = 0; i < count; ++i) {
    final List<Object?>? result =
        await basicStandard.send(largeBuffer) as List<Object?>?;
    // This check should be tiny compared to the actual channel send/receive.
    size += (result == null) ? 0 : result.length;
  }
  watch.stop();

  if (size != largeBuffer.length * count) {
    throw Exception(
      "There is an error with the echo channel, the results don't add up: $size",
    );
  }

  return watch.elapsedMicroseconds / count;
}

Future<double> _runBasicBinary(BasicMessageChannel<ByteData> basicBinary,
    ByteData buffer, int count) async {
  int size = 0;
  final Stopwatch watch = Stopwatch();
  watch.start();
  for (int i = 0; i < count; ++i) {
    final ByteData? result = await basicBinary.send(buffer);
    // This check should be tiny compared to the actual channel send/receive.
    size += (result == null) ? 0 : result.lengthInBytes;
  }
  watch.stop();
  if (size != buffer.lengthInBytes * count) {
    throw Exception(
      "There is an error with the echo channel, the results don't add up: $size",
    );
  }

  return watch.elapsedMicroseconds / count;
}

Future<void> _runTests() async {
  if (kDebugMode) {
    throw Exception(
      "Must be run in profile mode! Use 'flutter run --profile'.",
    );
  }

  const BasicMessageChannel<Object?> resetChannel = BasicMessageChannel<Object?>(
    'dev.flutter.echo.reset',
    StandardMessageCodec(),
  );
  const BasicMessageChannel<Object?> basicStandard = BasicMessageChannel<Object?>(
    'dev.flutter.echo.basic.standard',
    StandardMessageCodec(),
  );
  const BasicMessageChannel<ByteData> basicBinary =
      BasicMessageChannel<ByteData>(
    'dev.flutter.echo.basic.binary',
    BinaryCodec(),
  );

  /// WARNING: Don't change the following line of code, it will invalidate
  /// `Large` tests.  Instead make a different test.  The size of largeBuffer
  /// serialized is 14214 bytes.
  final List<Object?> largeBuffer = _makeTestBuffer(1000);
  final ByteData largeBufferBytes =
      const StandardMessageCodec().encodeMessage(largeBuffer)!;
  final ByteData oneMB = ByteData(1024 * 1024);

  const int numMessages = 2500;

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  resetChannel.send(true);
  await _runBasicStandardSmall(basicStandard, 1); // Warmup.
  printer.addResult(
    description: 'BasicMessageChannel/StandardMessageCodec/Flutter->Host/Small',
    value: await _runBasicStandardSmall(basicStandard, numMessages),
    unit: 'µs',
    name: 'platform_channel_basic_standard_2host_small',
  );
  resetChannel.send(true);
  await _runBasicStandardLarge(basicStandard, largeBuffer, 1); // Warmup.
  printer.addResult(
    description: 'BasicMessageChannel/StandardMessageCodec/Flutter->Host/Large',
    value:
        await _runBasicStandardLarge(basicStandard, largeBuffer, numMessages),
    unit: 'µs',
    name: 'platform_channel_basic_standard_2host_large',
  );
  resetChannel.send(true);
  await _runBasicBinary(basicBinary, largeBufferBytes, 1); // Warmup.
  printer.addResult(
    description: 'BasicMessageChannel/BinaryCodec/Flutter->Host/Large',
    value: await _runBasicBinary(basicBinary, largeBufferBytes, numMessages),
    unit: 'µs',
    name: 'platform_channel_basic_binary_2host_large',
  );
  resetChannel.send(true);
  await _runBasicBinary(basicBinary, oneMB, 1); // Warmup.
  printer.addResult(
    description: 'BasicMessageChannel/BinaryCodec/Flutter->Host/1MB',
    value: await _runBasicBinary(basicBinary, oneMB, numMessages),
    unit: 'µs',
    name: 'platform_channel_basic_binary_2host_1MB',
  );
  printer.printToStdout();
}

class _BenchmarkWidget extends StatefulWidget {
  const _BenchmarkWidget(this.tests, {Key? key}) : super(key: key);

  final Future<void> Function() tests;

  @override
  _BenchmarkWidgetState createState() => _BenchmarkWidgetState();
}

class _BenchmarkWidgetState extends State<_BenchmarkWidget> {
  @override
  void initState() {
    widget.tests();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  runApp(const _BenchmarkWidget(_runTests));
}
