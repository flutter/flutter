// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import 'environment.dart';
import 'utils.dart';
import 'watcher.dart';

class BuildCommand extends Command<bool> with ArgUtils {
  BuildCommand() {
    argParser
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Run the build in watch mode so it rebuilds whenever a change'
            'is made.',
      );
  }

  @override
  String get name => 'build';

  @override
  String get description => 'Build the Flutter web engine.';

  bool get isWatchMode => boolArg('watch');

  @override
  FutureOr<bool> run() async {
    final FilePath libPath = FilePath.fromWebUi('lib');
    final Pipeline buildPipeline = Pipeline(steps: <PipelineStep>[
      gn,
      ninja,
    ]);
    await buildPipeline.start();

    if (isWatchMode) {
      print('Initial build done!');
      print('Watching directory: ${libPath.relativeToCwd}/');
      PipelineWatcher(
        dir: libPath.absolute,
        pipeline: buildPipeline,
        // Ignore font files that are copied whenever tests run.
        ignore: (event) => event.path.endsWith('.ttf'),
      ).start();
      // Return a never-ending future.
      return Completer<bool>().future;
    } else {
      return true;
    }
  }
}

Future<void> gn() {
  print('Running gn...');
  return runProcess(
    path.join(environment.flutterDirectory.path, 'tools', 'gn'),
    <String>[
      '--unopt',
      '--full-dart-sdk',
    ],
  );
}

// TODO(mdebbar): Make the ninja step interruptable in the pipeline.
Future<void> ninja() {
  print('Running autoninja...');
  return runProcess('autoninja', <String>[
    '-C',
    environment.hostDebugUnoptDir.path,
  ]);
}
