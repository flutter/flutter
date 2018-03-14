// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'src/basic_messaging.dart';
import 'src/method_calls.dart';
import 'src/test_step.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(new TestApp());
}

class TestApp extends StatefulWidget {
  @override
  _TestAppState createState() => new _TestAppState();
}

class _TestAppState extends State<TestApp> {
  static final List<dynamic> aList = <dynamic>[
    false,
    0,
    0.0,
    'hello',
    <dynamic>[
      <String, dynamic>{'key': 42}
    ],
  ];
  static final Map<String, dynamic> aMap = <String, dynamic>{
    'a': false,
    'b': 0,
    'c': 0.0,
    'd': 'hello',
    'e': <dynamic>[
      <String, dynamic>{'key': 42}
    ]
  };
  static final Uint8List someUint8s = new Uint8List.fromList(<int>[
    0xBA,
    0x5E,
    0xBA,
    0x11,
  ]);
  static final Int32List someInt32s = new Int32List.fromList(<int>[
    -0x7fffffff - 1,
    0,
    0x7fffffff,
  ]);
  static final Int64List someInt64s = new Int64List.fromList(<int>[
    -0x7fffffffffffffff - 1,
    0,
    0x7fffffffffffffff,
  ]);
  static final Float64List someFloat64s =
      new Float64List.fromList(<double>[
    double.nan,
    double.negativeInfinity,
    -double.maxFinite,
    -double.minPositive,
    -0.0,
    0.0,
    double.minPositive,
    double.maxFinite,
    double.infinity,
  ]);
  static final List<TestStep> steps = <TestStep>[
    () => methodCallJsonSuccessHandshake(null),
    () => methodCallJsonSuccessHandshake(true),
    () => methodCallJsonSuccessHandshake(7),
    () => methodCallJsonSuccessHandshake('world'),
    () => methodCallJsonSuccessHandshake(aList),
    () => methodCallJsonSuccessHandshake(aMap),
    () => methodCallJsonNotImplementedHandshake(),
    () => methodCallStandardSuccessHandshake(null),
    () => methodCallStandardSuccessHandshake(true),
    () => methodCallStandardSuccessHandshake(7),
    () => methodCallStandardSuccessHandshake('world'),
    () => methodCallStandardSuccessHandshake(aList),
    () => methodCallStandardSuccessHandshake(aMap),
    () => methodCallJsonErrorHandshake(null),
    () => methodCallJsonErrorHandshake('world'),
    () => methodCallStandardErrorHandshake(null),
    () => methodCallStandardErrorHandshake('world'),
    () => methodCallStandardNotImplementedHandshake(),
    () => basicBinaryHandshake(null),
    () => basicBinaryHandshake(new ByteData(0)),
    () => basicBinaryHandshake(new ByteData(4)..setUint32(0, 0x12345678)),
    () => basicStringHandshake('hello, world'),
    () => basicStringHandshake('hello \u263A \u{1f602} unicode'),
    () => basicStringHandshake(''),
    () => basicStringHandshake(null),
    () => basicJsonHandshake(null),
    () => basicJsonHandshake(true),
    () => basicJsonHandshake(false),
    () => basicJsonHandshake(0),
    () => basicJsonHandshake(-7),
    () => basicJsonHandshake(7),
    () => basicJsonHandshake(1 << 32),
    () => basicJsonHandshake(1 << 56),
    () => basicJsonHandshake(0.0),
    () => basicJsonHandshake(-7.0),
    () => basicJsonHandshake(7.0),
    () => basicJsonHandshake(''),
    () => basicJsonHandshake('hello, world'),
    () => basicJsonHandshake('hello, "world"'),
    () => basicJsonHandshake('hello \u263A \u{1f602} unicode'),
    () => basicJsonHandshake(<dynamic>[]),
    () => basicJsonHandshake(aList),
    () => basicJsonHandshake(<String, dynamic>{}),
    () => basicJsonHandshake(aMap),
    () => basicStandardHandshake(null),
    () => basicStandardHandshake(true),
    () => basicStandardHandshake(false),
    () => basicStandardHandshake(0),
    () => basicStandardHandshake(-7),
    () => basicStandardHandshake(7),
    () => basicStandardHandshake(1 << 32),
    () => basicStandardHandshake(1 << 64),
    () => basicStandardHandshake(1 << 128),
    () => basicStandardHandshake(0.0),
    () => basicStandardHandshake(-7.0),
    () => basicStandardHandshake(7.0),
    () => basicStandardHandshake(''),
    () => basicStandardHandshake('hello, world'),
    () => basicStandardHandshake('hello \u263A \u{1f602} unicode'),
    () => basicStandardHandshake(someUint8s),
    () => basicStandardHandshake(someInt32s),
    () => basicStandardHandshake(someInt64s),
    () => basicStandardHandshake(someFloat64s),
    () => basicStandardHandshake(<dynamic>[]),
    () => basicStandardHandshake(aList),
    () => basicStandardHandshake(<String, dynamic>{}),
    () => basicStandardHandshake(<dynamic, dynamic>{7: true, false: -7}),
    () => basicStandardHandshake(aMap),
    () => basicBinaryMessageToUnknownChannel(),
    () => basicStringMessageToUnknownChannel(),
    () => basicJsonMessageToUnknownChannel(),
    () => basicStandardMessageToUnknownChannel(),
  ];
  Future<TestStepResult> _result;
  int _step = 0;

  @override
  void initState() {
    super.initState();
  }

  void _executeNextStep() {
    setState(() {
      if (_step < steps.length)
        _result = steps[_step++]();
      else
        _result = new Future<TestStepResult>.value(TestStepResult.complete);
    });
  }

  Widget _buildTestResultWidget(
    BuildContext context,
    AsyncSnapshot<TestStepResult> snapshot,
  ) {
    return new TestStepResult.fromSnapshot(snapshot).asWidget(context);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Channels Test',
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Channels Test'),
        ),
        body: new Padding(
          padding: const EdgeInsets.all(20.0),
          child: new FutureBuilder<TestStepResult>(
            future: _result,
            builder: _buildTestResultWidget,
          ),
        ),
        floatingActionButton: new FloatingActionButton(
          key: const ValueKey<String>('step'),
          onPressed: _executeNextStep,
          child: const Icon(Icons.navigate_next),
        ),
      ),
    );
  }
}
