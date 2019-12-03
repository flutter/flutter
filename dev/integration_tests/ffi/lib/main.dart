// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'src/ffi_calls.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(TestApp());
}

class TestApp extends StatefulWidget {
  @override
  _TestAppState createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  static final DateTime anUnknownValue = DateTime.fromMillisecondsSinceEpoch(1520777802314);

  Future<TestStatusResult> _result;

  void _executeNextStatus() {
    _result = Future<TestStatusResult>.value(TestStatusResult.start);
    setState(() {
      _result = testFfiCall();
    });
  }

  Widget _buildTestResultWidget(
    BuildContext context,
    AsyncSnapshot<TestStatusResult> snapshot,
  ) {
    return TestStatusResult.fromSnapshot(snapshot).asWidget(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFI Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FFI Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FutureBuilder<TestStatusResult>(
            future: _result,
            builder: _buildTestResultWidget,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: const ValueKey<String>('run'),
          onPressed: _executeNextStatus,
          child: const Icon(Icons.navigate_next),
        ),
      ),
    );
  }
}
