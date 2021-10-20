// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';

import 'widgets/progression.dart';

const String _title = 'Flutter Desktop Conductor (Not ready, do not use)';

const LocalFileSystem _fs = LocalFileSystem();
const LocalPlatform _platform = LocalPlatform();
final String _stateFilePath = defaultStateFilePath(_platform);

Future<void> main() async {
  // The app currently only supports macOS and Linux.
  if (kIsWeb || io.Platform.isWindows) {
    throw Exception('The conductor only supports MacOS and Linux desktop');
  }
  final File _stateFile = _fs.file(_stateFilePath);
  final pb.ConductorState? state = _stateFile.existsSync() ? readStateFromFile(_stateFile) : null;

  WidgetsFlutterBinding.ensureInitialized();
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
      home: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SelectableText(
                'Desktop app for managing a release of the Flutter SDK, currently in development',
              ),
              const SizedBox(height: 10.0),
              MainProgression(
                releaseState: state,
                stateFilePath: _stateFilePath,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
