// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import 'migrate.dart';

/// Flutter migrate subcommand that guides the developer through conflicts,
/// allowing them to accept the original, the new lines, or skip and resolve manually.
class MigrateResolveConflictsCommand extends FlutterCommand {
  MigrateResolveConflictsCommand({
    required this.logger,
    required this.fileSystem,
    required this.terminal,
  }) {
    requiresPubspecYaml();
    argParser.addOption(
      'staging-directory',
      help: 'Specifies the custom migration staging directory used to stage and edit proposed changes. '
            'This path can be absolute or relative to the flutter project root. This defaults to `$kDefaultMigrateStagingDirectoryName`',
      valueHelp: 'path',
    );
    argParser.addOption(
      'project-directory',
      help: 'The root directory of the flutter project.',
      valueHelp: 'path',
    );
    argParser.addOption(
      'context-lines',
      defaultsTo: '5',
      help: 'The number of lines of context to show around the each conflict. Defaults to 5.',
    );
    argParser.addFlag(
      'confirm-commit',
      defaultsTo: true,
      help: 'Indicates if proposed changes require user verification before writing to disk.',
    );
  }

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

  static const String _conflictStartMarker = '<<<<<<<';
  static const String _conflictDividerMarker = '=======';
  static const String _conflictEndMarker = '>>>>>>>';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String? projectDirectory = stringArg('project-directory');
    final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(logger: logger, fileSystem: fileSystem);
    final FlutterProject project = projectDirectory == null
      ? FlutterProject.current()
      : flutterProjectFactory.fromDirectory(fileSystem.directory(projectDirectory));

    Directory stagingDirectory = project.directory.childDirectory(kDefaultMigrateStagingDirectoryName);
    final String? customStagingDirectoryPath = stringArg('staging-directory');
    if (customStagingDirectoryPath != null) {
      if (fileSystem.path.isAbsolute(customStagingDirectoryPath)) {
        stagingDirectory = fileSystem.directory(customStagingDirectoryPath);
      } else {
        stagingDirectory = project.directory.childDirectory(customStagingDirectoryPath);
      }
    }
    if (!stagingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Start a new migration with:');
      printCommandText('flutter migrate start', logger);
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(stagingDirectory);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);

    checkAndPrintMigrateStatus(manifest, stagingDirectory, logger: logger);

    final List<String> conflictFiles = manifest.remainingConflictFiles(stagingDirectory);

    terminal.usesTerminalUi = true;

    for (int i = 0; i < conflictFiles.length; i++) {
      final String localPath = conflictFiles[i];
      final File file = stagingDirectory.childFile(localPath);
      final List<String> lines = file.readAsStringSync().split('\n');
      // We write a newline in the output, this counteracts it.
      if (lines.last == '') {
        lines.removeLast();
      }

      // Find all conflicts
      final List<Conflict> conflicts = findConflicts(lines);

      // Prompt developer
      await promptDeveloperSelectAction(conflicts, lines, localPath);

      final bool result = await verifyAndCommit(conflicts, lines, file, localPath);
      if (!result) {
        i--;
      }
    }
    return const FlutterCommandResult(ExitStatus.success);
  }

  /// Parses the lines of a file and extracts a list of Conflicts.
  List<Conflict> findConflicts(List<String> lines) {
    // Find all conflicts
    final List<Conflict> conflicts = <Conflict>[];
    Conflict currentConflict = Conflict.empty();
    for (int lineNumber = 0; lineNumber < lines.length; lineNumber++) {
      final String line = lines[lineNumber];
      if (line.contains(_conflictStartMarker)) {
        currentConflict.startLine = lineNumber;
      } else if (line.contains(_conflictDividerMarker)) {
        currentConflict.dividerLine = lineNumber;
      } else if (line.contains(_conflictEndMarker)) {
        currentConflict.endLine = lineNumber;
        assert(
          (currentConflict.startLine == null || currentConflict.dividerLine == null || currentConflict.startLine! < currentConflict.dividerLine!) &&
          (currentConflict.dividerLine == null || currentConflict.endLine == null || currentConflict.dividerLine! < currentConflict.endLine!)
        );
        conflicts.add(currentConflict);
        currentConflict = Conflict.empty();
      }
    }
    return conflicts;
  }

  /// Display a detected conflict and prompt the developer on whether to accept the original lines, new lines,
  /// or skip handling the conflict.
  Future<void> promptDeveloperSelectAction(List<Conflict> conflicts, List<String> lines, String localPath) async {
    final int contextLineCount = int.parse(stringArg('context-lines')!);
    for (final Conflict conflict in conflicts) {
      if (!conflict.isValid) {
        conflict.keepOriginal = null;
        continue;
      }
      // Print the conflict for reference
      logger.printStatus(terminal.clearScreen(), newline: false);
      logger.printStatus('Cyan', color: TerminalColor.cyan, newline: false);
      logger.printStatus(' = Original lines.  ', newline: false);
      logger.printStatus('Green', color: TerminalColor.green, newline: false);
      logger.printStatus(' = New lines.\n', newline: true);

      // Print the conflict for reference
      for (int lineNumber = (conflict.startLine! - contextLineCount).abs(); lineNumber < conflict.startLine!; lineNumber++) {
        printConflictLine(lines[lineNumber], lineNumber, color: TerminalColor.grey);
      }
      printConflictLine(lines[conflict.startLine!], conflict.startLine!);
      for (int lineNumber = conflict.startLine! + 1; lineNumber < conflict.dividerLine!; lineNumber++) {
        printConflictLine(lines[lineNumber], lineNumber, color: TerminalColor.cyan);
      }
      printConflictLine(lines[conflict.dividerLine!], conflict.dividerLine!);
      for (int lineNumber = conflict.dividerLine! + 1; lineNumber < conflict.endLine!; lineNumber++) {
        printConflictLine(lines[lineNumber], lineNumber, color: TerminalColor.green);
      }
      printConflictLine(lines[conflict.endLine!], conflict.endLine!);
      for (int lineNumber = conflict.endLine! + 1; lineNumber <= (conflict.endLine! + contextLineCount).clamp(0, lines.length - 1); lineNumber++) {
        printConflictLine(lines[lineNumber], lineNumber, color: TerminalColor.grey);
      }

      logger.printStatus('\nConflict in $localPath.');
      // Select action
      String selection = 's';
      selection = await terminal.promptForCharInput(
        <String>['o', 'n', 's'],
        logger: logger,
        prompt: 'Accept the (o)riginal lines, (n)ew lines, or (s)kip and resolve the conflict manually?',
        defaultChoiceIndex: 2,
      );

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
  }

  /// Prints a summary of the changes selected and prompts the developer to commit, abandon, or retry
  /// the changes.
  ///
  /// Returns true if changes were accepted or rejected. Returns false if user indicated to retry.
  Future<bool> verifyAndCommit(List<Conflict> conflicts, List<String> lines, File file, String localPath) async {
    int originalCount = 0;
    int newCount = 0;
    int skipCount = 0;

    String result = '';
    int lastPrintedLine = 0;
    bool hasChanges = false;
    for (final Conflict conflict in conflicts) {
      if (!conflict.isValid) {
        continue;
      }
      if (conflict.keepOriginal != null) {
        hasChanges = true; // don't unecessarily write file if no changes were made.
      }
      for (int lineNumber = lastPrintedLine; lineNumber < conflict.startLine!; lineNumber++) {
        result += '${lines[lineNumber]}\n';
      }
      if (conflict.keepOriginal == null) {
        // Skipped this conflict. Add all lines.
        for (int lineNumber = conflict.startLine!; lineNumber <= conflict.endLine!; lineNumber++) {
          result += '${lines[lineNumber]}\n';
        }
        skipCount++;
      } else if (conflict.keepOriginal!) {
        // Keeping original lines
        for (int lineNumber = conflict.startLine! + 1; lineNumber < conflict.dividerLine!; lineNumber++) {
          result += '${lines[lineNumber]}\n';
        }
        originalCount++;
      } else {
        // Keeping new lines
        for (int lineNumber = conflict.dividerLine! + 1; lineNumber < conflict.endLine!; lineNumber++) {
          result += '${lines[lineNumber]}\n';
        }
        newCount++;
      }
      lastPrintedLine = (conflict.endLine! + 1).clamp(0, lines.length);
    }
    for (int lineNumber = lastPrintedLine; lineNumber < lines.length; lineNumber++) {
      result += '${lines[lineNumber]}\n';
    }
    result.trim();

    // Display conflict summary for this file and confirm with user if the changes should be commited.
    final bool confirm = boolArg('confirm-commit') ?? true;
    if (confirm && skipCount != conflicts.length) {
      logger.printStatus(terminal.clearScreen(), newline: false);
      logger.printStatus('Conflicts in $localPath complete.\n');
      logger.printStatus('You chose to:\n  Skip $skipCount conflicts\n  Acccept the original lines for $originalCount conflicts\n  Accept the new lines for $newCount conflicts\n');
      String selection = 'n';
      selection = await terminal.promptForCharInput(
        <String>['y', 'n', 'r'],
        logger: logger,
        prompt: 'Commit the changes to the working directory? (y)es, (n)o, (r)etry this file',
        defaultChoiceIndex: 1,
      );
      switch(selection) {
        case 'y': {
          if (hasChanges) {
            file.writeAsStringSync(result, flush: true);
          }
          break;
        }
        case 'n': {
          break;
        }
        case 'r': {
          return false;
        }
      }
    } else {
      file.writeAsStringSync(result, flush: true);
    }
    return true;
  }

  /// Prints the line of a file with a prefix that indicates the line count.
  void printConflictLine(String text, int lineNumber, {TerminalColor? color, int paddingLength = 5}) {
    // Default padding of 5 pads line numbers up to 99,999
    final String padding = ' ' * (paddingLength - lineNumber.toString().length);
    logger.printStatus('$lineNumber$padding', color: TerminalColor.grey, newline: false, indent: 2);
    logger.printStatus(text, color: color);
  }
}

/// Simple data class that represents a conflict in a file and tracks what the developer chose to do with it.
class Conflict {
  Conflict(this.startLine, this.dividerLine, this.endLine);

  Conflict.empty();

  int? startLine;
  int? dividerLine;
  int? endLine;

  bool? keepOriginal;

  bool get isValid => startLine != null && dividerLine != null && endLine != null;

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
