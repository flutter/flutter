// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../globals.dart' as globals;
import '../cache.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import 'migrate.dart';

/// Flutter migrate subcommand to check the migration status of the project.
class MigrateResolveConflictsCommand extends FlutterCommand {
  MigrateResolveConflictsCommand({
    bool verbose = false,
    required this.logger,
    required this.fileSystem,
    required this.terminal,
  }) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
      help: 'Specifies the custom migration working directory used to stage and edit proposed changes.',
      valueHelp: 'path',
    );
    argParser.addFlag(
      'diff',
      defaultsTo: true,
      help: 'Shows the diff output when enabled. Enabled by default.',
    );
  }

  final bool _verbose;

  final Logger logger;

  final FileSystem fileSystem;

  final Terminal terminal;

  @override
  final String name = 'resolve-conflicts';

  @override
  final String description = 'Prints the current status of the in progress migration.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  /// Manually marks the lines in a diff that should be printed unformatted for visbility.
  final Set<int> _initialDiffLines = <int>{0, 1};

  static const String _conflictStartMarker = '<<<<<<<';
  static const String _conflictDividerMarker = '=======';
  static const String _conflictEndMarker = '>>>>>>>';
  static const int _contextLineCount = 5;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject project = FlutterProject.current();
    Directory workingDirectory = project.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    if (stringArg('working-directory') != null) {
      workingDirectory = fileSystem.directory(stringArg('working-directory'));
    }
    if (!workingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Start a new migration with:');
      MigrateUtils.printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(workingDirectory);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);

    logger.printBox('Working directory at `${workingDirectory.path}`');

    checkAndPrintMigrateStatus(manifest, workingDirectory, logger: logger);

    final List<String> conflictFiles = manifest.remainingConflictFiles(workingDirectory);

    terminal.usesTerminalUi = true;

    for (final String localPath in conflictFiles) {
      final File file = workingDirectory.childFile(localPath);
      List<String> lines = file.readAsStringSync().split('\n');

      // Find all conflicts
      List<Conflict> conflicts = <Conflict>[];
      Conflict currentConflict = Conflict.empty();
      for (int lineNumber = 0; lineNumber < lines.length; lineNumber++) {
        final String line = lines[lineNumber];
        if (line.contains(_conflictStartMarker)) {
          currentConflict.startLine = lineNumber;
        } else if (line.contains(_conflictDividerMarker)) {
          currentConflict.dividerLine = lineNumber;
        } else if (line.contains(_conflictEndMarker)) {
          currentConflict.endLine = lineNumber;
          assert(currentConflict.startLine! < currentConflict.dividerLine! && currentConflict.dividerLine! < currentConflict.endLine!);
          conflicts.add(currentConflict);
          currentConflict = Conflict.empty();
        }
      }

      // Prompt developer
      for (final Conflict conflict in conflicts) {
        assert(conflict.startLine != null && conflict.dividerLine != null && conflict.endLine != null);
        // Print the conflict for reference
        logger.printStatus('\n\n\n\n\n\n\n\n'); // Space out diffs
        for (int lineNumber = (conflict.startLine! - _contextLineCount).abs(); lineNumber < conflict.startLine!; lineNumber++) {
          logger.printStatus(lines[lineNumber], color: TerminalColor.grey);
        }
        logger.printStatus(lines[conflict.startLine!]);
        for (int lineNumber = conflict.startLine! + 1; lineNumber < conflict.dividerLine!; lineNumber++) {
          logger.printStatus(lines[lineNumber], color: TerminalColor.cyan);
        }
        logger.printStatus(lines[conflict.dividerLine!]);
        for (int lineNumber = conflict.dividerLine! + 1; lineNumber < conflict.endLine!; lineNumber++) {
          logger.printStatus(lines[lineNumber], color: TerminalColor.green);
        }
        logger.printStatus(lines[conflict.endLine!]);
        for (int lineNumber = conflict.endLine! + 1; lineNumber <= (conflict.endLine! + _contextLineCount).clamp(0, lines.length - 1); lineNumber++) {
          logger.printStatus(lines[lineNumber], color: TerminalColor.grey);
        }

        // Select action
        String selection = 's';
        try {
          selection = await terminal.promptForCharInput(
            <String>['o', 'n', 's'],
            logger: logger,
            prompt: 'Keep the (O)riginal lines, (N)ew lines, or (S)kip resolving this conflict?',
            defaultChoiceIndex: 2,
          );
        } on StateError catch(e) {
          logger.printError(
            e.message,
            indent: 0,
          );
        }

        switch(selection) {
          case 'o': {
            conflict.chooseOriginal();
            break;
          }
          case 'n': {
            conflict.chooseNew();
            break;
          }
          case 's': {
            conflict.skip();
            break;
          }
        }
      }

      int lastPrintedLine = 0;
      String result = '';
      for (final Conflict conflict in conflicts) {
        for (int lineNumber = lastPrintedLine; lineNumber < conflict.startLine!; lineNumber++) {
          result += '${lines[lineNumber]}\n';
        }
        if (conflict.keepOriginal == null) {
          // Skipped this conflict. Add all lines.
          for (int lineNumber = conflict.startLine!; lineNumber <= conflict.endLine!; lineNumber++) {
            result += '${lines[lineNumber]}\n';
          }
        } else if (conflict.keepOriginal!) {
          // Keeping original lines
          for (int lineNumber = conflict.startLine! + 1; lineNumber < conflict.dividerLine!; lineNumber++) {
            result += '${lines[lineNumber]}\n';
          }
        } else {
          // Keeping new lines
          for (int lineNumber = conflict.dividerLine! + 1; lineNumber < conflict.endLine!; lineNumber++) {
            result += '${lines[lineNumber]}\n';
          }
        }
        lastPrintedLine = (conflict.endLine! + 1).clamp(0, lines.length);
      }
      for (int lineNumber = lastPrintedLine; lineNumber < lines.length; lineNumber++) {
        result += '${lines[lineNumber]}\n';
      }

      file.writeAsStringSync(result, flush: true);
    }

    // logger.printStatus('Resolve conflicts and accept changes with:');
    // MigrateUtils.printCommandText('flutter migrate apply', logger);

    return const FlutterCommandResult(ExitStatus.success);
  }
}

class Conflict {
  Conflict.empty();
  Conflict(this.startLine, this.dividerLine, this.endLine);

  int? startLine;
  int? dividerLine;
  int? endLine;

  bool? keepOriginal;

  void chooseOriginal() {
    keepOriginal = true;
  }

  void skip() {
    keepOriginal = null;
  }

  void chooseNew() {
    keepOriginal = false;
  }
}
