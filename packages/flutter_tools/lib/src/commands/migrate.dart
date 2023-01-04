// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io show Process;

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
// import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
// import '../globals.dart' as globals;
// import '../ios/xcodeproj.dart';
// import '../project.dart';
import '../runner/flutter_command.dart';

class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    bool verbose = false,
    required Logger logger,
    required FileSystem fileSystem,
    required Stdio stdio,
    required ProcessManager processManager,
  }) : _verbose = verbose,
       _logger = logger,
       _fileSystem = fileSystem,
       _processManager = processManager,
       _stdio = stdio {
    requiresPubspecYaml();
  }

  final bool _verbose;

  final Logger _logger;

  final FileSystem _fileSystem;

  final ProcessManager _processManager;

  final Stdio _stdio;

  @override
  final String name = 'migrate';

  @override
  final String description = 'Migrate legacy flutter projects to modern versions.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  StreamSubscription<String> recordLines(List<_OutputLine> output, Stream<List<int>> stream, _OutputStream streamName) {
    return stream
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        switch (streamName) {
          case _OutputStream.stderr:
            _logger.printError(line);
            break;
          case _OutputStream.stdout:
            _logger.printStatus(line);
            break;
        }
        output!.add(_OutputLine(line, streamName));
      });
  }

  /// The command used for running pub.
  List<String> _migrateCommand(List<String> arguments) {
    // TODO(zanderso): refactor to use artifacts.
    final String sdkPath = _fileSystem.path.joinAll(<String>[
      Cache.flutterRoot!,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      'dart',
    ]);
    // if (!_processManager.canRun(sdkPath)) {
    //   throwToolExit(
    //     'Your Flutter SDK download may be corrupt or missing permissions to run. '
    //     'Try re-downloading the Flutter SDK into a directory that has read/write '
    //     'permissions for the current user.'
    //   );
    // }
    String dillPath = '';
    return <String>[sdkPath, '--disable-dart-dev', 'run', dillPath, ...arguments];
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    List<_OutputLine> output = <_OutputLine>[];
    final List<String> cmd = _migrateCommand(argResults!.arguments);
    // <String>[
    //   dart.path,
    //   '--disable-dart-dev',
    //   constFinder.path,
    //   '--kernel-file', appDill.path
    // ];
    final io.Process process = await _processManager.start(
      cmd,
      workingDirectory: _fileSystem.path.current,
      // environment: pubEnvironment,
    );
    final StreamSubscription<String> stdoutSubscription =
      recordLines(output, process.stdout, _OutputStream.stdout);
    final StreamSubscription<String> stderrSubscription =
      recordLines(output, process.stderr, _OutputStream.stderr);

    final StreamSubscription<String> stdinSubscription = _stdio.stdin
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) => process.stdin.writeln(line));

    exitCode = await process.exitCode;
    unawaited(stdoutSubscription.cancel());
    unawaited(stderrSubscription.cancel());
    unawaited(stdinSubscription.cancel());

    // _logger.printTrace('Running command: ${cmd.join(' ')}');
    // final ProcessResult constFinderProcessResult = await _processManager.run(cmd);

    // if (constFinderProcessResult.exitCode != 0) {
    //   throw IconTreeShakerException._('ConstFinder failure: ${constFinderProcessResult.stderr}');
    // }
    // final Object? constFinderMap = json.decode(constFinderProcessResult.stdout as String);

    return FlutterCommandResult.success();

  }
}

class _OutputLine {
  _OutputLine(this.line, this.stream);
  final String line;
  final _OutputStream stream;
}

enum _OutputStream {
  stdout,
  stderr,
}
