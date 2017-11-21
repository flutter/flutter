// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State createState() => new MyAppState();
}

const MethodChannel channel = const MethodChannel('texture');

enum FrameState { initial, slow, afterSlow, fast, afterFast }

class MyAppState extends State<MyApp> {
  int _widgetBuilds = 0;
  FrameState _state = FrameState.initial;
  String _summary = 'Press play to start producing frames';
  IconData _icon = Icons.play_arrow;

  Future<Null> _summarizeStats() async {
    final double framesProduced = await channel.invokeMethod('getProducedFrameRate');
    final double framesConsumed = await channel.invokeMethod('getConsumedFrameRate');
    _summary = '''
Produced: ${framesProduced.toStringAsFixed(1)}fps
Consumed: ${framesConsumed.toStringAsFixed(1)}fps
Widget builds: $_widgetBuilds''';
  }

  Future<Null> _nextState() async {
    switch (_state) {
    case FrameState.initial:
      _widgetBuilds = 0;
      _summary = 'Producing frames slowly, collecting stats...';
      _state = FrameState.slow;
      _icon = Icons.stop;
      channel.invokeMethod('start', 10);
      break;
    case FrameState.slow:
      await channel.invokeMethod('stop');
      await _summarizeStats();
      _icon = Icons.fast_forward;
      _state = FrameState.afterSlow;
      break;
    case FrameState.afterSlow:
      _widgetBuilds = 0;
      _summary = 'Producing frames quickly, collecting stats...';
      _state = FrameState.fast;
      _icon = Icons.stop;
      channel.invokeMethod('start', 100);
      break;
    case FrameState.fast:
      await channel.invokeMethod('stop');
      await _summarizeStats();
      _state = FrameState.afterFast;
      _icon = Icons.replay;
      break;
    case FrameState.afterFast:
      _summary = 'Press play to start producing frames';
      _state = FrameState.initial;
      _icon = Icons.play_arrow;
      break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _widgetBuilds++;
    return new MaterialApp(
      home: new Scaffold(
        body: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Container(
                width: 300.0,
                height: 200.0,
                child: const Texture(textureId: 0),
              ),
              new Container(
                width: 300.0,
                height: 60.0,
                color: Colors.grey,
                child: new Center(
                  child: new Text(
                    _summary,
                    key: const ValueKey<String>('summary'),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: new FloatingActionButton(
          key: const ValueKey<String>('fab'),
          child: new Icon(_icon),
          onPressed: _nextState,
        ),
      ),
    );
  }
}
