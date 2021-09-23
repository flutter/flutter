// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';

import 'src/core/proto/conductor_state.pb.dart' as pb;
import 'src/core/state.dart';

const String _title = 'Flutter Conductor';

void main() {
  const LocalFileSystem _fs = LocalFileSystem();
  const LocalPlatform _platform = LocalPlatform();
  final File _stateFile = _fs.file(defaultStateFilePath(_platform));

  runApp(
      MyApp(
          readStateFromFile(_stateFile),
      ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp(
    this.state, {
    Key? key,
  }) : super(key: key);

  final pb.ConductorState state;

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
                  child: SelectableText(presentState(state)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
