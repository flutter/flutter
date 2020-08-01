/// Runs clang-tidy on files with changes.
///
/// usage:
/// dart lint.dart <path to compile_commands.json> <path to git repository> [clang-tidy checks]
///
/// User environment variable FLUTTER_LINT_ALL to run on all files.

import 'dart:async' show Completer;
import 'dart:convert' show jsonDecode, utf8, LineSplitter;
import 'dart:io' show File, exit, Directory, FileSystemEntity, Platform, stderr;

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:process_runner/process_runner.dart';

String _linterOutputHeader = '''
┌──────────────────────────┐
│ Engine Clang Tidy Linter │
└──────────────────────────┘
The following errors have been reported by the Engine Clang Tidy Linter.  For
more information on addressing these issues please see:
https://github.com/flutter/flutter/wiki/Engine-Clang-Tidy-Linter
''';

class Command {
  Directory directory = Directory('');
  String command = '';
  File file = File('');
}

Command parseCommand(Map<String, dynamic> map) {
  final Directory dir = Directory(map['directory'] as String).absolute;
  return Command()
    ..directory = dir
    ..command = map['command'] as String
    ..file = File(path.normalize(path.join(dir.path, map['file'] as String)));
}

String calcTidyArgs(Command command) {
  String result = command.command;
  result = result.replaceAll(RegExp(r'\S*clang/bin/clang'), '');
  result = result.replaceAll(RegExp(r'-MF \S*'), '');
  return result;
}

String calcTidyPath(Command command) {
  final RegExp regex = RegExp(r'\S*clang/bin/clang');
  return regex
          .stringMatch(command.command)
          ?.replaceAll('clang/bin/clang', 'clang/bin/clang-tidy') ??
      '';
}

bool isNonEmptyString(String str) => str.isNotEmpty;

bool containsAny(File file, Iterable<File> queries) {
  return queries.where((File query) => path.equals(query.path, file.path)).isNotEmpty;
}

/// Returns a list of all non-deleted files which differ from the nearest
/// merge-base with `master`. If it can't find a fork point, uses the default
/// merge-base.
Future<List<File>> getListOfChangedFiles(Directory repoPath) async {
  final ProcessRunner processRunner = ProcessRunner(defaultWorkingDirectory: repoPath);
  final ProcessRunnerResult fetchResult = await processRunner.runProcess(
    <String>['git', 'fetch', 'upstream', 'master'],
    failOk: true,
  );
  if (fetchResult.exitCode != 0) {
    await processRunner.runProcess(<String>['git', 'fetch', 'origin', 'master']);
  }
  final Set<String> result = <String>{};
  ProcessRunnerResult mergeBaseResult = await processRunner.runProcess(
      <String>['git', 'merge-base', '--fork-point', 'FETCH_HEAD', 'HEAD'],
      failOk: true);
  if (mergeBaseResult.exitCode != 0) {
    if (verbose) {
      stderr.writeln("Didn't find a fork point, falling back to default merge base.");
    }
    mergeBaseResult = await processRunner
        .runProcess(<String>['git', 'merge-base', 'FETCH_HEAD', 'HEAD'], failOk: false);
  }
  final String mergeBase = mergeBaseResult.stdout.trim();
  final ProcessRunnerResult masterResult = await processRunner
      .runProcess(<String>['git', 'diff', '--name-only', '--diff-filter=ACMRT', mergeBase]);
  result.addAll(masterResult.stdout.split('\n').where(isNonEmptyString));
  return result.map<File>((String filePath) => File(path.join(repoPath.path, filePath))).toList();
}

Future<List<File>> dirContents(Directory dir) {
  final List<File> files = <File>[];
  final Completer<List<File>> completer = Completer<List<File>>();
  final Stream<FileSystemEntity> lister = dir.list(recursive: true);
  lister.listen((FileSystemEntity file) => file is File ? files.add(file) : null,
      onError: (Object e) => completer.completeError(e), onDone: () => completer.complete(files));
  return completer.future;
}

File buildFileAsRepoFile(String buildFile, Directory repoPath) {
  // Removes the "../../flutter" from the build files to make it relative to the flutter
  // dir.
  final String relativeBuildFile = path.joinAll(path.split(buildFile).sublist(3));
  final File result = File(path.join(repoPath.absolute.path, relativeBuildFile));
  print('Build file: $buildFile => ${result.path}');
  return result;
}

Future<String> shouldIgnoreFile(File file) async {
  if (path.split(file.path).contains('third_party')) {
    return 'third_party';
  } else {
    final RegExp exp = RegExp(r'//\s*FLUTTER_NOLINT');
    await for (String line
        in file.openRead().transform(utf8.decoder).transform(const LineSplitter())) {
      if (exp.hasMatch(line)) {
        return 'FLUTTER_NOLINT';
      } else if (line.isNotEmpty && line[0] != '\n' && line[0] != '/') {
        // Quick out once we find a line that isn't empty or a comment.  The
        // FLUTTER_NOLINT must show up before the first real code.
        return '';
      }
    }
    return '';
  }
}

void _usage(ArgParser parser, {int exitCode = 1}) {
  stderr.writeln('lint.dart [--help] [--lint-all] [--verbose] [--diff-branch]');
  stderr.writeln(parser.usage);
  exit(exitCode);
}

bool verbose = false;

void main(List<String> arguments) async {
  final ArgParser parser = ArgParser();
  parser.addFlag('help', help: 'Print help.');
  parser.addFlag('lint-all',
      help: 'lint all of the sources, regardless of FLUTTER_NOLINT.', defaultsTo: false);
  parser.addFlag('verbose', help: 'Print verbose output.', defaultsTo: verbose);
  parser.addOption('repo', help: 'Use the given path as the repo path');
  parser.addOption('compile-commands',
      help: 'Use the given path as the source of compile_commands.json. This '
          'file is created by running tools/gn');
  parser.addOption('checks',
      help: 'Perform the given checks on the code. Defaults to the empty '
          'string, indicating all checks should be performed.',
      defaultsTo: '');
  final ArgResults options = parser.parse(arguments);

  verbose = options['verbose'] as bool;

  if (options['help'] as bool) {
    _usage(parser, exitCode: 0);
  }

  if (!options.wasParsed('compile-commands')) {
    stderr.writeln('ERROR: The --compile-commands argument is requried.');
    _usage(parser);
  }

  if (!options.wasParsed('repo')) {
    stderr.writeln('ERROR: The --repo argument is requried.');
    _usage(parser);
  }

  final File buildCommandsPath = File(options['compile-commands'] as String);
  if (!buildCommandsPath.existsSync()) {
    stderr.writeln("ERROR: Build commands path ${buildCommandsPath.absolute.path} doesn't exist.");
    _usage(parser);
  }

  final Directory repoPath = Directory(options['repo'] as String);
  if (!repoPath.existsSync()) {
    stderr.writeln("ERROR: Repo path ${repoPath.absolute.path} doesn't exist.");
    _usage(parser);
  }

  print(_linterOutputHeader);

  final String checksArg = options.wasParsed('checks') ? options['checks'] as String : '';
  final String checks = checksArg.isNotEmpty ? '--checks=$checksArg' : '--config=';
  final bool lintAll =
      Platform.environment['FLUTTER_LINT_ALL'] != null || options['lint-all'] as bool;
  final List<File> changedFiles =
      lintAll ? await dirContents(repoPath) : await getListOfChangedFiles(repoPath);

  if (verbose) {
    print('Checking lint in repo at $repoPath.');
    if (checksArg.isNotEmpty) {
      print('Checking for specific checks: $checks.');
    }
    if (lintAll) {
      print('Checking all ${changedFiles.length} files the repo dir.');
    } else {
      print('Dectected ${changedFiles.length} files that have changed');
    }
  }

  final List<dynamic> buildCommandMaps =
      jsonDecode(await buildCommandsPath.readAsString()) as List<dynamic>;
  final List<Command> buildCommands = buildCommandMaps
      .map<Command>((dynamic x) => parseCommand(x as Map<String, dynamic>))
      .toList();
  final Command firstCommand = buildCommands[0];
  final String tidyPath = calcTidyPath(firstCommand);
  assert(tidyPath.isNotEmpty);
  final List<Command> changedFileBuildCommands =
      buildCommands.where((Command x) => containsAny(x.file, changedFiles)).toList();

  if (changedFileBuildCommands.isEmpty) {
    print('No changed files that have build commands associated with them '
        'were found.');
    exit(0);
  }

  if (verbose) {
    print('Found ${changedFileBuildCommands.length} files that have build '
        'commands associated with them and can be lint checked.');
  }

  int exitCode = 0;
  final List<WorkerJob> jobs = <WorkerJob>[];
  for (Command command in changedFileBuildCommands) {
    final String relativePath = path.relative(command.file.path, from: repoPath.parent.path);
    final String ignoreReason = await shouldIgnoreFile(command.file);
    if (ignoreReason.isEmpty) {
      final String tidyArgs = calcTidyArgs(command);
      final List<String> args = <String>[command.file.path, checks, '--'];
      args.addAll(tidyArgs?.split(' ') ?? <String>[]);
      print('🔶 linting $relativePath');
      jobs.add(WorkerJob(
        <String>[tidyPath, ...args],
        workingDirectory: command.directory,
        name: 'clang-tidy on ${command.file.path}',
      ));
    } else {
      print('🔷 ignoring $relativePath ($ignoreReason)');
    }
  }
  final ProcessPool pool = ProcessPool();

  await for (final WorkerJob job in pool.startWorkers(jobs)) {
    if (job.result?.stdout.isEmpty ?? true) {
      continue;
    }
    print('❌ Failures for ${job.name}:');
    print(job.result.stdout);
    exitCode = 1;
  }
  print('\n');
  if (exitCode == 0) {
    print('No lint problems found.');
  }
  exit(exitCode);
}
