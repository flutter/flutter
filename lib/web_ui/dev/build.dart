// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/src/watch_event.dart';

import 'environment.dart';
import 'pipeline.dart';
import 'utils.dart';

class BuildCommand extends Command<bool> with ArgUtils<bool> {
  BuildCommand() {
    argParser.addFlag(
      'watch',
      defaultsTo: false,
      abbr: 'w',
      help: 'Run the build in watch mode so it rebuilds whenever a change is '
          'made. Disabled by default.',
    );
    argParser.addFlag(
      'build-canvaskit',
      defaultsTo: false,
      help: 'Build CanvasKit locally instead of getting it from CIPD. Disabled '
          'by default.',
    );
  }

  @override
  String get name => 'build';

  @override
  String get description => 'Build the Flutter web engine.';

  bool get isWatchMode => boolArg('watch');

  bool get buildCanvasKit => boolArg('build-canvaskit');

  @override
  FutureOr<bool> run() async {
    final FilePath libPath = FilePath.fromWebUi('lib');
    final Pipeline buildPipeline = Pipeline(steps: <PipelineStep>[
      GnPipelineStep(buildCanvasKit),
      NinjaPipelineStep(buildCanvasKit),
    ]);
    await buildPipeline.run();

    if (isWatchMode) {
      print('Initial build done!');
      print('Watching directory: ${libPath.relativeToCwd}/');
      await PipelineWatcher(
        dir: libPath.absolute,
        pipeline: buildPipeline,
        // Ignore font files that are copied whenever tests run.
        ignore: (WatchEvent event) => event.path.endsWith('.ttf'),
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
  GnPipelineStep(this.buildCanvasKit);

  @override
  String get description => 'gn';

  @override
  bool get isSafeToInterrupt => false;

  /// Whether or not to build CanvasKit.
  final bool buildCanvasKit;

  @override
  Future<ProcessManager> createProcess() {
    print('Running gn...');
    Future<ProcessManager> gnProcess = startProcess(
      path.join(environment.flutterDirectory.path, 'tools', 'gn'),
      <String>[
        '--unopt',
        if (Platform.isMacOS) '--xcode-symlinks',
        '--full-dart-sdk',
      ],
    );
    if (buildCanvasKit) {
      gnProcess = gnProcess.then((_) {
        return startProcess(
          path.join(environment.flutterDirectory.path, 'tools', 'gn'),
          <String>[
            '--wasm',
          ],
        );
      });
    }
    return gnProcess;
  }
}

/// Runs `autoninja`.
///
/// Can be safely interrupted.
class NinjaPipelineStep extends ProcessStep {
  NinjaPipelineStep(this.buildCanvasKit);

  @override
  String get description => 'ninja';

  @override
  bool get isSafeToInterrupt => true;

  /// Whether or not to build CanvasKit.
  final bool buildCanvasKit;

  @override
  Future<ProcessManager> createProcess() {
    print('Running autoninja...');
    Future<ProcessManager> ninjaProcess = startProcess(
      'autoninja',
      <String>[
        '-C',
        environment.hostDebugUnoptDir.path,
      ],
    );
    if (buildCanvasKit) {
      ninjaProcess = ninjaProcess.then((_) {
        return startProcess(
          'autoninja',
          <String>[
            '-C',
            environment.canvasKitOutDir.path,
          ],
        );
      });
    }
    return ninjaProcess;
  }
}
