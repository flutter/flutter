// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

/// Flutter code sample for [StreamBuilder] that switches between two streams.
///
/// Uses an [ObjectKey] keyed on the current stream so that the [StreamBuilder]'s
/// state is recreated when the stream changes, resetting its data immediately
/// rather than retaining the previous stream's snapshot.

void main() => runApp(StreamBuilderExampleApp());

class StreamBuilderExampleApp extends StatelessWidget {
  const StreamBuilderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('StreamBuilder Switch Sample')),
        body: const Center(child: StreamBuilderExample()),
      ),
    );
  }
}

class StreamBuilderExample extends StatefulWidget {
  const StreamBuilderExample({super.key});

  @override
  State<StreamBuilderExample> createState() => _StreamBuilderExampleState();
}

class _StreamBuilderExampleState extends State<StreamBuilderExample> {
  late final _fastController = StreamController<String>.broadcast();
  late final _slowController = StreamController<String>.broadcast();

  late final Stream<String> _fastStream = _fastController.stream;
  late final Stream<String> _slowStream = _slowController.stream;

  late Stream<String> _currentStream = _fastStream;

  late final Timer _fastTimer;
  late final Timer _slowTimer;
  int _fastCount = 0;
  int _slowCount = 0;

  @override
  void initState() {
    super.initState();
    _fastTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fastController.add('${_fastCount++}');
    });
    _slowTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _slowController.add('${_slowCount++}');
    });
  }

  @override
  void dispose() {
    _fastTimer.cancel();
    _slowTimer.cancel();
    _fastController.close();
    _slowController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    final streamBuilder = StreamBuilder<String>(
      // This key makes it so the StreamBuilder's state restarts
      // each time the stream switches, so that 'waiting...' is displayed
      // instead of the old stream's value.
      key: ObjectKey(_currentStream),
      stream: _currentStream,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return Text(
          snapshot.data ?? 'waiting...',
          style: textTheme.displayMedium,
        );
      },
    );

    return Column(
      mainAxisAlignment: .center,
      spacing: 24,
      children: <Widget>[
        Text(
          _currentStream == _fastStream ? 'Fast stream' : 'Slow stream',
          style: textTheme.titleLarge,
        ),
        streamBuilder,
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (_currentStream == _fastStream) {
                _currentStream = _slowStream;
              } else {
                _currentStream = _fastStream;
              }
            });
          },
          child: const Text('Switch stream'),
        ),
      ],
    );
  }
}
