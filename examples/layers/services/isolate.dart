// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void OnProgressListener(double completed, double total);
typedef void OnResultListener(String result);

// An encapsulation of a large amount of synchronous processing.
//
// The choice of JSON parsing here is meant as an example that might surface
// in real-world applications.
class Calculator {
  Calculator({ @required this.onProgressListener, @required this.onResultListener, String data })
    : assert(onProgressListener != null),
      assert(onResultListener != null),
      // In order to keep the example files smaller, we "cheat" a little and
      // replicate our small json string into a 10,000-element array.
      _data = _replicateJson(data, 10000);

  final OnProgressListener onProgressListener;
  final OnResultListener onResultListener;
  final String _data;
  // This example assumes that the number of objects to parse is known in
  // advance. In a real-world situation, this might not be true; in that case,
  // the app might choose to display an indeterminate progress indicator.
  static const int _NUM_ITEMS = 110000;
  static const int _NOTIFY_INTERVAL = 1000;

  // Run the computation associated with this Calculator.
  void run() {
    int i = 0;
    final JsonDecoder decoder = new JsonDecoder(
      (dynamic key, dynamic value) {
        if (key is int && i++ % _NOTIFY_INTERVAL == 0)
          onProgressListener(i.toDouble(), _NUM_ITEMS.toDouble());
        return value;
      }
    );
    try {
      final List<dynamic> result = decoder.convert(_data);
      final int n = result.length;
      onResultListener('Decoded $n results');
    } catch (e, stack) {
      print('Invalid JSON file: $e');
      print(stack);
    }
  }

  static String _replicateJson(String data, int count) {
    final StringBuffer buffer = new StringBuffer()..write('[');
    for (int i = 0; i < count; i++) {
      buffer.write(data);
      if (i < count - 1)
        buffer.write(',');
    }
    buffer.write(']');
    return buffer.toString();
  }
}

// The current state of the calculation.
enum CalculationState {
  idle,
  loading,
  calculating
}

// Structured message to initialize the spawned isolate.
class CalculationMessage {
  CalculationMessage(this.data, this.sendPort);
  String data;
  SendPort sendPort;
}

// A manager for the connection to a spawned isolate.
//
// Isolates communicate with each other via ReceivePorts and SendPorts.
// This class manages these ports and maintains state related to the
// progress of the background computation.
class CalculationManager {
  CalculationManager({ @required this.onProgressListener, @required this.onResultListener })
    : assert(onProgressListener != null),
      assert(onResultListener != null),
      _receivePort = new ReceivePort() {
    _receivePort.listen(_handleMessage);
  }

  CalculationState _state = CalculationState.idle;
  CalculationState get state => _state;
  bool get isRunning => _state != CalculationState.idle;

  double _completed = 0.0;
  double _total = 1.0;

  final OnProgressListener onProgressListener;
  final OnResultListener onResultListener;

  // Start the background computation.
  //
  // Does nothing if the computation is already running.
  void start() {
    if (!isRunning) {
      _state = CalculationState.loading;
      _runCalculation();
    }
  }

  // Stop the background computation.
  //
  // Kills the isolate immediately, if spawned. Does nothing if the
  // computation is not running.
  void stop() {
    if (isRunning) {
      _state = CalculationState.idle;
      if (_isolate != null) {
        _isolate.kill(priority: Isolate.immediate);
        _isolate = null;
        _completed = 0.0;
        _total = 1.0;
      }
    }
  }

  final ReceivePort _receivePort;
  Isolate _isolate;

  void _runCalculation() {
    // Load the JSON string. Note that this is done in the main isolate; at the
    // moment, spawned isolates do not have access to Mojo services, including
    // the root bundle (see https://github.com/flutter/flutter/issues/3294).
    // However, the loading process is asynchronous, so the UI will not block
    // while the file is loaded.
    rootBundle.loadString('services/data.json').then<Null>((String data) {
      if (isRunning) {
        final CalculationMessage message = new CalculationMessage(data, _receivePort.sendPort);
        // Spawn an isolate to JSON-parse the file contents. The JSON parsing
        // is synchronous, so if done in the main isolate, the UI would block.
        Isolate.spawn(_calculate, message).then<Null>((Isolate isolate) {
          if (!isRunning) {
            isolate.kill(priority: Isolate.immediate);
          } else {
            _state = CalculationState.calculating;
            _isolate = isolate;
          }
        });
      }
    });
  }

  void _handleMessage(dynamic message) {
    if (message is List<double>) {
      _completed = message[0];
      _total = message[1];
      onProgressListener(_completed, _total);
    } else if (message is String) {
      _completed = 0.0;
      _total = 1.0;
      _isolate = null;
      _state = CalculationState.idle;
      onResultListener(message);
    }
  }

  // Main entry point for the spawned isolate.
  //
  // This entry point must be static, and its (single) argument must match
  // the message passed in Isolate.spawn above. Typically, some part of the
  // message will contain a SendPort so that the spawned isolate can
  // communicate back to the main isolate.
  //
  // Static and global variables are initialized anew in the spawned isolate,
  // in a separate memory space.
  static void _calculate(CalculationMessage message) {
    final SendPort sender = message.sendPort;
    final Calculator calculator = new Calculator(
      onProgressListener: (double completed, double total) {
        sender.send(<double>[ completed, total ]);
      },
      onResultListener: sender.send,
      data: message.data
    );
    calculator.run();
  }
}

// Main app widget.
//
// The app shows a simple UI that allows control of the background computation,
// as well as an animation to illustrate that the UI does not block while this
// computation is performed.
//
// This is a StatefulWidget in order to hold the CalculationManager and
// the AnimationController for the running animation.
class IsolateExampleWidget extends StatefulWidget {
  @override
  IsolateExampleState createState() => new IsolateExampleState();
}

// Main application state.
class IsolateExampleState extends State<StatefulWidget> with SingleTickerProviderStateMixin {

  String _status = 'Idle';
  String _label = 'Start';
  String _result = ' ';
  double _progress = 0.0;
  AnimationController _animation;
  CalculationManager _calculationManager;

  @override
  void initState() {
    super.initState();
    _animation = new AnimationController(
      duration: const Duration(milliseconds: 3600),
      vsync: this,
    )..repeat();
    _calculationManager = new CalculationManager(
      onProgressListener: _handleProgressUpdate,
      onResultListener: _handleResult
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          new RotationTransition(
            turns: _animation,
            child: new Container(
              width: 120.0,
              height: 120.0,
              color: const Color(0xFF882222),
            )
          ),
          new Opacity(
            opacity: _calculationManager.isRunning ? 1.0 : 0.0,
            child: new CircularProgressIndicator(
              value: _progress
            )
          ),
          new Text(_status),
          new Center(
            child: new RaisedButton(
              child: new Text(_label),
              onPressed: _handleButtonPressed
            )
          ),
          new Text(_result)
        ]
      )
    );
  }

  void _handleProgressUpdate(double completed, double total) {
    _updateState(' ', completed / total);
  }

  void _handleResult(String result) {
    _updateState(result, 0.0);
  }

  void _handleButtonPressed() {
    if (_calculationManager.isRunning)
      _calculationManager.stop();
    else
      _calculationManager.start();
    _updateState(' ', 0.0);
  }

  String _getStatus(CalculationState state) {
      switch (state) {
        case CalculationState.loading:
          return 'Loading...';
        case CalculationState.calculating:
          return 'In Progress';
        case CalculationState.idle:
        default:
          return 'Idle';
      }
  }

  void _updateState(String result, double progress) {
    setState(() {
      _result = result;
      _progress = progress;
      _label = _calculationManager.isRunning ? 'Stop' : 'Start';
      _status = _getStatus(_calculationManager.state);
    });
  }
}

void main() {
  runApp(new MaterialApp(home: new IsolateExampleWidget()));
}
