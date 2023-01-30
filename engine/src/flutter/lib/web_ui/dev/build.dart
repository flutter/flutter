// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Directory;

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
      abbr: 'w',
      help: 'Run the build in watch mode so it rebuilds whenever a change is '
          'made. Disabled by default.',
    );
    argParser.addFlag(
      'build-canvaskit',
      help: 'Build CanvasKit locally instead of getting it from CIPD. Enabled '
          'by default.',
      defaultsTo: true
    );
    argParser.addFlag(
      'build-canvaskit-chromium',
      help: 'Build the Chromium variant of CanvasKit. Disabled by default.',
    );
    argParser.addFlag(
      'host',
      help: 'Build the host build instead of the wasm build, which is '
          'currently needed for `flutter run --local-engine` to work.'
    );
  }

  @override
  String get name => 'build';

  @override
  String get description => 'Build the Flutter web engine.';

  bool get isWatchMode => boolArg('watch');

  bool get buildCanvasKit => boolArg('build-canvaskit');

  bool get buildCanvasKitChromium => boolArg('build-canvaskit-chromium');

  bool get host => boolArg('host');

  @override
  FutureOr<bool> run() async {
    final FilePath libPath = FilePath.fromWebUi('lib');
    final List<PipelineStep> steps = <PipelineStep>[
      GnPipelineStep(
        buildCanvasKit: buildCanvasKit,
        buildCanvasKitChromium: buildCanvasKitChromium,
        host: host,
      ),
      NinjaPipelineStep(target: host ? environment.hostDebugUnoptDir : environment.wasmReleaseOutDir),
    ];
    final Pipeline buildPipeline = Pipeline(steps: steps);
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
  GnPipelineStep({
    required this.buildCanvasKit,
    required this.buildCanvasKitChromium,
    required this.host,
  });

  final bool buildCanvasKit;
  final bool buildCanvasKitChromium;
  final bool host;

  @override
  String get description => 'gn';

  @override
  bool get isSafeToInterrupt => false;

  List<String> get _gnArgs {
    if (host) {
      return <String>[
        '--unoptimized',
        '--full-dart-sdk',
      ];
    } else {
      return <String>[
        '--web',
        '--runtime-mode=release',
        if (buildCanvasKit) '--build-canvaskit',
        if (buildCanvasKitChromium) '--build-canvaskit-chromium',
      ];
    }
  }

  @override
  Future<ProcessManager> createProcess() {
    print('Running gn...');
    return startProcess(
      path.join(environment.flutterDirectory.path, 'tools', 'gn'),
      _gnArgs,
    );
  }
}

/// Runs `autoninja`.
///
/// Can be safely interrupted.
class NinjaPipelineStep extends ProcessStep {
  NinjaPipelineStep({required this.target});

  @override
  String get description => 'ninja';

  @override
  bool get isSafeToInterrupt => true;

  /// The target directory to build.
  final Directory target;

  @override
  Future<ProcessManager> createProcess() {
    print('Running autoninja...');
    return startProcess(
      'autoninja',
      <String>[
        '-C',
        target.path,
      ],
    );
  }
}
