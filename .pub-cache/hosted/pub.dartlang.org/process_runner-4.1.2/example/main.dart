// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to send a bunch of jobs to ProcessPool for processing.
//
// This example program is actually pretty useful even if you don't use
// process_runner for your Dart project. It can speed up processing of a bunch
// of single-threaded CPU-intensive commands by a multiple of the number of
// processor cores you have (modulo being disk/network bound, of course).

import 'dart:io';

import 'package:args/args.dart';
import 'package:process_runner/process_runner.dart';

const String _kHelpFlag = 'help';
const String _kQuietFlag = 'quiet';
const String _kReportFlag = 'report';
const String _kPrintStdoutFlag = 'stdout';
const String _kPrintStderrFlag = 'stderr';
const String _kRunInShellFlag = 'run-in-shell';
const String _kAllowFailureFlag = 'fail-ok';
const List<String> _kFlags = <String>[
  _kHelpFlag,
  _kQuietFlag,
  _kReportFlag,
  _kPrintStdoutFlag,
  _kPrintStderrFlag,
  _kRunInShellFlag,
];
const String _kJobsOption = 'jobs';
const String _kWorkingDirectoryOption = 'working-directory';
const String _kCommandOption = 'command';
const String _kSourceOption = 'source';
const String _kAppName = 'process_runner';

// This only works for escaped spaces and things in double or single quotes.
// This is just an example, modify to meet your own requirements.
List<String> splitIntoArgs(String args) {
  bool inQuote = false;
  bool inEscape = false;
  String quoteMatch = '';
  final List<String> result = <String>[];
  final List<String> currentArg = <String>[];
  for (int i = 0; i < args.length; ++i) {
    final String char = args[i];
    if (inEscape) {
      switch (char) {
        case 'n':
          currentArg.add('\n');
          break;
        case 't':
          currentArg.add('\t');
          break;
        case 'r':
          currentArg.add('\r');
          break;
        case 'b':
          currentArg.add('\b');
          break;
        default:
          currentArg.add(char);
          break;
      }
      inEscape = false;
      continue;
    }
    if (char == ' ' && !inQuote) {
      result.add(currentArg.join(''));
      currentArg.clear();
      continue;
    }
    if (char == r'\') {
      inEscape = true;
      continue;
    }
    if (inQuote) {
      if (char == quoteMatch) {
        inQuote = false;
        quoteMatch = '';
      } else {
        currentArg.add(char);
      }
      continue;
    }
    if (char == '"' || char == '"') {
      inQuote = !inQuote;
      quoteMatch = args[i];
      continue;
    }
    currentArg.add(char);
  }
  if (currentArg.isNotEmpty) {
    result.add(currentArg.join(''));
  }
  return result;
}

String? findOption(String option, List<String> args) {
  for (int i = 0; i < args.length - 1; ++i) {
    if (args[i] == option) {
      return args[i + 1];
    }
  }
  return null;
}

Iterable<String> findAllOptions(String option, List<String> args) sync* {
  for (int i = 0; i < args.length - 1; ++i) {
    if (args[i] == option) {
      yield args[i + 1];
    }
  }
}

// Print reports to stderr, to avoid polluting any stdout from the jobs.
void stderrPrintReport(
  int total,
  int completed,
  int inProgress,
  int pending,
  int failed,
) {
  stderr.write(ProcessPool.defaultReportToString(total, completed, inProgress, pending, failed));
}

Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser(usageLineLength: 80);
  parser.addFlag(
    _kHelpFlag,
    abbr: 'h',
    defaultsTo: false,
    negatable: false,
    help: 'Print help for $_kAppName.',
  );
  parser.addFlag(
    _kQuietFlag,
    abbr: 'q',
    defaultsTo: false,
    negatable: false,
    help: 'Silences the stderr and stdout output of the commands. This '
        'is a shorthand for "--no-$_kPrintStdoutFlag --no-$_kPrintStderrFlag".',
  );
  parser.addFlag(
    _kReportFlag,
    abbr: 'r',
    defaultsTo: false,
    negatable: false,
    help: 'Print progress on the jobs to stderr while running.',
  );
  parser.addFlag(
    _kPrintStdoutFlag,
    defaultsTo: true,
    help: 'Prints the stdout output of the commands to stdout in the order '
        'they complete. Will not interleave lines from separate processes. Has no '
        'effect if --$_kQuietFlag is specified.',
  );
  parser.addFlag(
    _kPrintStderrFlag,
    defaultsTo: true,
    help: 'Prints the stderr output of the commands to stderr in the order '
        'they complete. Will not interleave lines from separate processes. Has no '
        'effect if --$_kQuietFlag is specified',
  );
  parser.addFlag(
    _kRunInShellFlag,
    defaultsTo: false,
    negatable: false,
    help: 'Run the commands in a subshell.',
  );
  parser.addFlag(
    _kAllowFailureFlag,
    defaultsTo: false,
    help: 'If set, allows continuing execution of the remaining commands even if '
        'one fails to execute. If not set, ("--no-$_kAllowFailureFlag") then '
        'process will just exit with a non-zero code at completion if there were '
        'any jobs that failed.',
  );
  parser.addOption(
    _kJobsOption,
    abbr: 'j',
    help: 'Specify the number of worker jobs to run simultaneously. Defaults '
        'to the number of processor cores on the machine (which is '
        '${Platform.numberOfProcessors} on this machine).',
  );
  parser.addOption(
    _kWorkingDirectoryOption,
    defaultsTo: '.',
    help: 'Specify the working directory to run in.',
  );
  parser.addMultiOption(
    _kCommandOption,
    abbr: 'c',
    help: 'Specify a command to add to the commands to be run. Commands '
        'specified with this option run before those specified with '
        '--$_kSourceOption. Be sure to quote arguments to --$_kCommandOption '
        'properly on the command line.',
  );
  parser.addMultiOption(
    _kSourceOption,
    abbr: 's',
    defaultsTo: <String>[],
    help: 'Specify the name of a file to read commands from, one per line, as '
        'they would appear on the command line, with spaces escaped or '
        'quoted. Specify "--$_kSourceOption -" to read from stdin. More than '
        'one --$_kSourceOption argument may be specified, and they will be '
        'concatenated in the order specified. The stdin ("--$_kSourceOption -") '
        'argument may only be specified once.',
  );

  late ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Argument Error: ${e.message}');
    stderr.writeln(parser.usage);
    exitCode = 1;
    return;
  }

  if (options[_kHelpFlag] as bool) {
    print(
      '$_kAppName [--${_kFlags.join('] [--')}] '
      '[--$_kWorkingDirectoryOption=<working directory>] '
      '[--$_kJobsOption=<num_worker_jobs>] '
      '[--$_kCommandOption="command" ...] '
      '[--$_kSourceOption=<file|"-"> ...]:',
    );

    print(parser.usage);
    exitCode = 0;
    return;
  }

  final bool quiet = options[_kQuietFlag]! as bool;
  final bool printStderr = !quiet && options[_kPrintStderrFlag]! as bool;
  final bool printStdout = !quiet && options[_kPrintStdoutFlag]! as bool;
  final bool printReport = options[_kReportFlag]! as bool;
  final bool runInShell = options[_kRunInShellFlag]! as bool;
  final bool failOk = options[_kAllowFailureFlag]! as bool;

  // Collect the commands to be run from the command file(s).
  final List<String>? commandFiles = options[_kSourceOption] as List<String>?;
  final List<String> fileCommands = <String>[];
  if (commandFiles != null) {
    bool sawStdinAlready = false;
    for (final String commandFile in commandFiles) {
      // Read from stdin if the --file option is set to '-'.
      if (commandFile == '-') {
        if (sawStdinAlready) {
          stderr.writeln('ERROR: The stdin can only be specified once with "--$_kSourceOption -"');
          exitCode = 1;
          return;
        }
        sawStdinAlready = true;
        String? line = stdin.readLineSync();
        while (line != null) {
          fileCommands.add(line);
          line = stdin.readLineSync();
        }
      } else {
        // Read the commands from a file.
        final File cmdFile = File(commandFile);
        if (!cmdFile.existsSync()) {
          print('''Command file "$commandFile" doesn't exist.''');
          exit(1);
        }
        fileCommands.addAll(cmdFile.readAsLinesSync());
      }
    }
  }

  // Collect all the commands, both from the input file, and from the command
  // line. The command line commands come first (although they could all
  // potentially be executed simultaneously, depending on the number of workers,
  // and number of commands).
  final List<String> commands = <String>[
    if (options[_kCommandOption] != null) ...options[_kCommandOption]! as List<String>,
    ...fileCommands,
  ];

  // Split each command entry into a list of strings, taking into account some
  // simple quoting and escaping.
  final List<List<String>> splitCommands = commands.map<List<String>>(splitIntoArgs).toList();

  // If the numWorkers is set to null, then the ProcessPool will automatically
  // select the number of processes based on how many CPU cores the machine has.
  final int? numWorkers = int.tryParse(options[_kJobsOption] as String? ?? '');
  final Directory workingDirectory =
      Directory((options[_kWorkingDirectoryOption] as String?) ?? '.');

  final ProcessPool pool = ProcessPool(
    numWorkers: numWorkers,
    printReport: printReport ? stderrPrintReport : null,
  );
  final List<WorkerJob> jobs = splitCommands.map<WorkerJob>((List<String> command) {
    return WorkerJob(
      command,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
      failOk: failOk,
    );
  }).toList();
  try {
    await for (final WorkerJob done in pool.startWorkers(jobs)) {
      if (printStdout) {
        stdout.write(done.result.stdout);
      }
      if (printStderr) {
        stderr.write(done.result.stderr);
      }
    }
  } on ProcessRunnerException catch (e) {
    if (!failOk) {
      stderr.writeln('$_kAppName execution failed: $e');
      exitCode = e.exitCode;
      return;
    }
  }

  // Return non-zero exit code if there were jobs that failed.
  exitCode = pool.failedJobs != 0 ? 1 : 0;
}
