// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../project_validator.dart';
import '../runner/flutter_command.dart';
import 'analyze_base.dart';
import 'analyze_continuously.dart';
import 'analyze_once.dart';
import 'validate_project.dart';

class AnalyzeCommand extends FlutterCommand {
  AnalyzeCommand({
    bool verboseHelp = false,
    this.workingDirectory,
    required FileSystem fileSystem,
    required Platform platform,
    required Terminal terminal,
    required Logger logger,
    required ProcessManager processManager,
    required Artifacts artifacts,
    required List<ProjectValidator> allProjectValidators,
  }) : _artifacts = artifacts,
       _fileSystem = fileSystem,
       _processManager = processManager,
       _logger = logger,
       _terminal = terminal,
       _allProjectValidators = allProjectValidators,
       _platform = platform {
    argParser.addFlag('flutter-repo',
        negatable: false,
        help: 'Include all the examples and tests from the Flutter repository.',
        hide: !verboseHelp);
    argParser.addFlag('current-package',
        help: 'Analyze the current project, if applicable.', defaultsTo: true);
    argParser.addFlag('dartdocs',
        negatable: false,
        help: '(deprecated) List every public member that is lacking documentation. '
              'This command will be removed in a future version of Flutter.',
        hide: !verboseHelp);
    argParser.addFlag('watch',
        help: 'Run analysis continuously, watching the filesystem for changes.',
        negatable: false);
    argParser.addOption('write',
        valueHelp: 'file',
        help: 'Also output the results to a file. This is useful with "--watch" '
              'if you want a file to always contain the latest results.');
    argParser.addOption('dart-sdk',
        valueHelp: 'path-to-sdk',
        help: 'The path to the Dart SDK.',
        hide: !verboseHelp);
    argParser.addOption('protocol-traffic-log',
        valueHelp: 'path-to-protocol-traffic-log',
        help: 'The path to write the request and response protocol. This is '
              'only intended to be used for debugging the tooling.',
        hide: !verboseHelp);
    argParser.addFlag('suggestions',
        help: 'Show suggestions about the current flutter project.'
    );

    // Hidden option to enable a benchmarking mode.
    argParser.addFlag('benchmark',
        negatable: false,
        hide: !verboseHelp,
        help: 'Also output the analysis time.');

    usesPubOption();

    // Not used by analyze --watch
    argParser.addFlag('congratulate',
        help: 'Show output even when there are no errors, warnings, hints, or lints. '
              'Ignored if "--watch" is specified.',
        defaultsTo: true);
    argParser.addFlag('preamble',
        defaultsTo: true,
        help: 'When analyzing the flutter repository, display the number of '
              'files that will be analyzed.\n'
              'Ignored if "--watch" is specified.');
    argParser.addFlag('fatal-infos',
        help: 'Treat info level issues as fatal.',
        defaultsTo: true);
    argParser.addFlag('fatal-warnings',
        help: 'Treat warning level issues as fatal.',
        defaultsTo: true);
  }

  /// The working directory for testing analysis using dartanalyzer.
  final Directory? workingDirectory;

  final Artifacts _artifacts;
  final FileSystem _fileSystem;
  final Logger _logger;
  final Terminal _terminal;
  final ProcessManager _processManager;
  final Platform _platform;
  final List<ProjectValidator> _allProjectValidators;

  @override
  String get name => 'analyze';

  @override
  String get description => "Analyze the project's Dart code.";

  @override
  String get category => FlutterCommandCategory.project;

  @override
  bool get shouldRunPub {
    // If they're not analyzing the current project.
    if (!boolArgDeprecated('current-package')) {
      return false;
    }

    // Or we're not in a project directory.
    if (!_fileSystem.file('pubspec.yaml').existsSync()) {
      return false;
    }

    return super.shouldRunPub;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool? suggestionFlag = boolArg('suggestions');
    if (suggestionFlag != null && suggestionFlag == true) {
      final String directoryPath;
      final bool? watchFlag = boolArg('watch');
      if (watchFlag != null && watchFlag) {
        throwToolExit('flag --watch is not compatible with --suggestions');
      }
      if (workingDirectory == null) {
        final Set<String> items = findDirectories(argResults!, _fileSystem);
        if (items.isEmpty || items.length > 1) {
          throwToolExit('The suggestions flags needs one directory path');
        }
        directoryPath = items.first;
      } else {
        directoryPath = workingDirectory!.path;
      }
      return ValidateProject(
        fileSystem: _fileSystem,
        logger: _logger,
        allProjectValidators: _allProjectValidators,
        userPath: directoryPath,
      ).run();
    } else if (boolArgDeprecated('watch')) {
      await AnalyzeContinuously(
        argResults!,
        runner!.getRepoRoots(),
        runner!.getRepoPackages(),
        fileSystem: _fileSystem,
        logger: _logger,
        platform: _platform,
        processManager: _processManager,
        terminal: _terminal,
        artifacts: _artifacts,
      ).analyze();
    } else {
      await AnalyzeOnce(
        argResults!,
        runner!.getRepoRoots(),
        runner!.getRepoPackages(),
        workingDirectory: workingDirectory,
        fileSystem: _fileSystem,
        logger: _logger,
        platform: _platform,
        processManager: _processManager,
        terminal: _terminal,
        artifacts: _artifacts,
      ).analyze();
    }
    return FlutterCommandResult.success();
  }
}
