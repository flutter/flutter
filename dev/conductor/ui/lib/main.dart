// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';

const String _title = 'Flutter Conductor';

const LocalFileSystem _fs = LocalFileSystem();
const LocalPlatform _platform = LocalPlatform();
final String _stateFilePath = defaultStateFilePath(_platform);

void main() {
  final File _stateFile = _fs.file(_stateFilePath);
  final pb.ConductorState? state = _stateFile.existsSync() ? readStateFromFile(_stateFile) : null;
  runApp(MyApp(state));
}

class MyApp extends StatelessWidget {
  const MyApp(
    this.state, {
    Key? key,
  }) : super(key: key);

  final pb.ConductorState? state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: SelectableText(
                  state != null ? presentState(state!) : 'No persistent state file found at $_stateFilePath',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
