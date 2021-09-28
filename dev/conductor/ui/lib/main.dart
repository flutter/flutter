// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:desktop_window/desktop_window.dart';
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
  final File _stateFile = _fs.file(_stateFilePath);
  final pb.ConductorState? state =
      _stateFile.existsSync() ? readStateFromFile(_stateFile) : null;

  WidgetsFlutterBinding.ensureInitialized();
  // app currently only supports macOS and Linux, and a minimum app size is added to prevent overflow
  if (!kIsWeb && (io.Platform.isMacOS || io.Platform.isLinux)) {
    await DesktopWindow.setMinWindowSize(const Size(600, 600));
    runApp(MyApp(state));
  }
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
        scaffoldBackgroundColor: Colors.grey[800],
        backgroundColor: Colors.black,
        primaryColor: Colors.black,
        iconTheme: const IconThemeData().copyWith(color: Colors.white),
        fontFamily: 'Montserrat',
        textTheme: TextTheme(
          headline1: const TextStyle(
            color: Colors.white,
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
          ),
          headline2: TextStyle(
            fontSize: 20.0,
            color: Colors.grey[300],
            fontWeight: FontWeight.bold,
          ),
          bodyText1: TextStyle(
            color: Colors.grey[300],
            fontSize: 14.0,
          ),
          bodyText2: TextStyle(
            color: Colors.grey[300],
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SelectableText(
                'Desktop app for managing a release of the Flutter SDK, currently in development',
              ),
              const SizedBox(height: 20.0),
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
