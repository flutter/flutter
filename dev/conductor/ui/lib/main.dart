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
  // final pb.ConductorState? state = _stateFile.existsSync() ? readStateFromFile(_stateFile) : null;

  const String conductorVersion = 'v1.0';
  const String releaseChannel = 'beta';
  const String releaseVersion = '1.2.0-3.4.pre';
  const String engineCandidateBranch = 'flutter-1.2-candidate.3';
  const String frameworkCandidateBranch = 'flutter-1.2-candidate.4';
  const String workingBranch = 'cherrypicks-$engineCandidateBranch';
  const String dartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
  const String engineCherrypick1 = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
  const String engineCherrypick2 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
  const String frameworkCherrypick = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
  const String engineStartingGitHead = '083049e6cae311910c6a6619a6681b7eba4035b4';
  const String engineCurrentGitHead = '083049e6cae311910c6a6619a6681b7eba4035b4';
  const String engineCheckoutPath = '/Users/alexchen/Desktop/flutter_conductor_checkouts/engine';
  const String frameworkStartingGitHead = 'df6981e98rh49er8h149er8h19er8h1';
  const String frameworkCurrentGitHead = 'df6981e98rh49er8h149er8h19er8h1';
  const String frameworkCheckoutPath = '/Users/alexchen/Desktop/flutter_conductor_checkouts/framework';

  final pb.ConductorState state = pb.ConductorState(
    engine: pb.Repository(
      candidateBranch: engineCandidateBranch,
      cherrypicks: <pb.Cherrypick>[
        pb.Cherrypick(trunkRevision: engineCherrypick1),
        pb.Cherrypick(trunkRevision: engineCherrypick2),
      ],
      dartRevision: dartRevision,
      workingBranch: workingBranch,
      startingGitHead: engineStartingGitHead,
      currentGitHead: engineCurrentGitHead,
      checkoutPath: engineCheckoutPath,
    ),
    framework: pb.Repository(
      candidateBranch: frameworkCandidateBranch,
      cherrypicks: <pb.Cherrypick>[
        pb.Cherrypick(trunkRevision: frameworkCherrypick),
      ],
      workingBranch: workingBranch,
      startingGitHead: frameworkStartingGitHead,
      currentGitHead: frameworkCurrentGitHead,
      checkoutPath: frameworkCheckoutPath,
    ),
    conductorVersion: conductorVersion,
    releaseChannel: releaseChannel,
    releaseVersion: releaseVersion,
  );

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
