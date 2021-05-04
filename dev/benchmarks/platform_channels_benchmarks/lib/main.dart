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

const int _numMessages = 2500;

List<Object> _makeTestBuffer(int size) {
  final List<Object> answer = <Object>[];
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
    BasicMessageChannel<Object> basicStandard) async {
  final Stopwatch watch = Stopwatch();
  watch.start();
  for (int i = 0; i < _numMessages; ++i) {
    await basicStandard.send(1234);
  }
  watch.stop();
  return watch.elapsedMicroseconds / _numMessages;
}

Future<double> _runBasicStandardLarge(
    BasicMessageChannel<Object> basicStandard, List<Object> largeBuffer) async {
  int size = 0;
  final Stopwatch watch = Stopwatch();
  watch.start();
  for (int i = 0; i < _numMessages; ++i) {
    final List<Object> result =
        await basicStandard.send(largeBuffer) as List<Object>;
    // This check should be tiny compared to the actual channel send/receive.
    size += (result == null) ? 0 : result.length;
  }
  watch.stop();

  if (size != largeBuffer.length * _numMessages) {
    throw Exception(
        'There is an error with the echo channel, the results don\'t add up: $size');
  }

  return watch.elapsedMicroseconds / _numMessages;
}

Future<double> _runBasicBinaryLarge(
    BasicMessageChannel<ByteData> basicBinary, List<Object> largeBuffer) async {
  int size = 0;
  final Stopwatch watch = Stopwatch();
  const StandardMessageCodec standardCodec = StandardMessageCodec();
  final ByteData encodedLargeBuffer = standardCodec.encodeMessage(largeBuffer);
  watch.start();
  for (int i = 0; i < _numMessages; ++i) {
    final ByteData result = await basicBinary.send(encodedLargeBuffer);
    // This check should be tiny compared to the actual channel send/receive.
    size += (result == null) ? 0 : result.lengthInBytes;
  }
  watch.stop();
  if (size != encodedLargeBuffer.lengthInBytes * _numMessages) {
    throw Exception(
        'There is an error with the echo channel, the results don\'t add up: $size');
  }

  return watch.elapsedMicroseconds / _numMessages;
}

Future<void> _runTests() async {
  if (kDebugMode) {
    throw Exception(
        "Must be run in profile mode! Use 'flutter run --profile'.");
  }

  const BasicMessageChannel<Object> basicStandard = BasicMessageChannel<Object>(
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
  final List<Object> largeBuffer = _makeTestBuffer(1000);

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description: 'BasicMessageChannel/StandardMessageCodec/Flutter->Host/Small',
    value: await _runBasicStandardSmall(basicStandard),
    unit: 'µs',
    name: 'platform_channel_basic_standard_2host_small',
  );
  printer.addResult(
    description: 'BasicMessageChannel/StandardMessageCodec/Flutter->Host/Large',
    value: await _runBasicStandardLarge(basicStandard, largeBuffer),
    unit: 'µs',
    name: 'platform_channel_basic_standard_2host_large',
  );
  printer.addResult(
    description: 'BasicMessageChannel/BinaryCodec/Flutter->Host/Large',
    value: await _runBasicBinaryLarge(basicBinary, largeBuffer),
    unit: 'µs',
    name: 'platform_channel_basic_binary_2host_large',
  );
  printer.printToStdout();
}

class _BenchmarkWidget extends StatefulWidget {
  const _BenchmarkWidget(this.tests, {Key key}) : super(key: key);

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
