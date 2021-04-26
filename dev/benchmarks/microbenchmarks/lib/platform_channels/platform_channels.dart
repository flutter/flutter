// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';

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

Future<void> _runTests() async {
  assert(false,
      "Don't run benchmarks in checked mode! Use 'flutter run --release'.");
  const int numMessages = 10000;

  const BasicMessageChannel<Object> channel = BasicMessageChannel<Object>(
      'dev.flutter.echo.basic.standard', StandardMessageCodec());
  final Stopwatch watch = Stopwatch();

  watch.start();
  for (int i = 0; i < numMessages; ++i) {
    await channel.send(1234);
  }
  watch.stop();
  final double smallPayloadTime = watch.elapsedMicroseconds / numMessages;

  watch.reset();
  final List<Object> largeBuffer = _makeTestBuffer(1000);
  const StandardMessageCodec codec = StandardMessageCodec();
  final ByteData data = codec.encodeMessage(largeBuffer);
  print('Large buffer size: ${data.lengthInBytes}');
  watch.start();
  for (int i = 0; i < numMessages; ++i) {
    final List<Object> result = await channel.send(largeBuffer) as List<Object>;
  }
  watch.stop();
  final double largePayloadTime = watch.elapsedMicroseconds / numMessages;

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
  printer.addResult(
    description:
        '  BasicMessageChannel/StandardMessageCodec/Flutter->Host/Small',
    value: smallPayloadTime,
    unit: 'µs',
    name: 'platform_channel_basic_standard_2host_small',
  );
  printer.addResult(
    description:
        '  BasicMessageChannel/StandardMessageCodec/Flutter->Host/Large',
    value: largePayloadTime,
    unit: 'µs',
    name: 'platform_channel_basic_standard_2host_large',
  );  
  printer.printToStdout();
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    _runTests();
    super.initState();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

