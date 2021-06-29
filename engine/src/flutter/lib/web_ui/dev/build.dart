// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;
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
        defaultsTo: false,
        abbr: 'w',
        help: 'Run the build in watch mode so it rebuilds whenever a change'
            'is made. Disabled by default.',
      );
  }

  @override
  String get name => 'build';

  @override
  String get description => 'Build the Flutter web engine.';

  bool get isWatchMode => boolArg('watch')!;

  @override
  FutureOr<bool> run() async {
    final FilePath libPath = FilePath.fromWebUi('lib');
    final Pipeline buildPipeline = Pipeline(steps: <PipelineStep>[
      GnPipelineStep(),
      NinjaPipelineStep(),
    ]);
    await buildPipeline.start();

    if (isWatchMode) {
      print('Initial build done!');
      print('Watching directory: ${libPath.relativeToCwd}/');
      await PipelineWatcher(
        dir: libPath.absolute,
        pipeline: buildPipeline,
        // Ignore font files that are copied whenever tests run.
        ignore: (event) => event.path.endsWith('.ttf'),
      ).start();
    }
    return true;
  }
}

/// Runs `gn`.
///
/// Not safe to interrupt as it may leave the `out/` directory in a corrupted
/// state. GN is pretty quick though, so it's OK to not support interruption.
class GnPipelineStep extends ProcessStep {
  @override
  String get name => 'gn';

  @override
  bool get isSafeToInterrupt => false;

  @override
  Future<ProcessManager> createProcess() {
    print('Running gn...');
    return startProcess(
      path.join(environment.flutterDirectory.path, 'tools', 'gn'),
      <String>[
        '--unopt',
        if (Platform.isMacOS) '--xcode-symlinks',
        '--full-dart-sdk',
      ],
    );
  }
}

/// Runs `autoninja`.
///
/// Can be safely interrupted.
class NinjaPipelineStep extends ProcessStep {
  @override
  String get name => 'ninja';

  @override
  bool get isSafeToInterrupt => true;

  @override
  Future<ProcessManager> createProcess() {
    print('Running autoninja...');
    return startProcess(
      'autoninja',
      <String>[
        '-C',
        environment.hostDebugUnoptDir.path,
      ],
    );
  }
}
