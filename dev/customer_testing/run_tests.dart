// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  exit(await run(arguments) ? 0 : 1);
}

Future<bool> run(List<String> arguments) async {
  final ArgParser argParser = ArgParser(
    allowTrailingOptions: false,
    usageLineLength: 72,
  )
    ..addOption(
      'repeat',
      defaultsTo: '1',
      help: 'How many times to run each test. Set to a high value to look for flakes.',
      valueHelp: 'count',
    )
    ..addOption(
      'shards',
      defaultsTo: '1',
      help: 'How many shards to split the tests into. Used in continuous integration.',
      valueHelp: 'count',
    )
    ..addOption(
      'shard-index',
      defaultsTo: '0',
      help: 'The current shard to run the tests with the range [0 .. shards - 1]. Used in continuous integration.',
      valueHelp: 'count',
    )
    ..addFlag(
      'skip-on-fetch-failure',
      defaultsTo: false,
      help: 'Whether to skip tests that we fail to download.',
    )
    ..addFlag(
      'skip-template',
      defaultsTo: false,
      help: 'Whether to skip tests named "template.test".',
    )
    ..addFlag(
      'verbose',
      defaultsTo: false,
      help: 'Describe what is happening in detail.',
    )
    ..addFlag(
      'help',
      defaultsTo: false,
      negatable: false,
      help: 'Print this help message.',
    );

  void printHelp() {
    print('run_tests.dart [options...] path/to/file1.test path/to/file2.test...');
    print('For details on the test registry format, see:');
    print('  https://github.com/flutter/tests/blob/master/registry/template.test');
    print('');
    print(argParser.usage);
    print('');
  }

  ArgResults parsedArguments;
  try {
    parsedArguments = argParser.parse(arguments);
  } on ArgParserException catch (error) {
    printHelp();
    print('Error: ${error.message} Use --help for usage information.');
    exit(1);
  }

  final int repeat = int.tryParse(parsedArguments['repeat'] as String);
  final bool skipOnFetchFailure = parsedArguments['skip-on-fetch-failure'] as bool;
  final bool skipTemplate = parsedArguments['skip-template'] as bool;
  final bool verbose = parsedArguments['verbose'] as bool;
  final bool help = parsedArguments['help'] as bool;
  final int numberShards = int.tryParse(parsedArguments['shards'] as String);
  final int shardIndex = int.tryParse(parsedArguments['shard-index'] as String);
  final List<File> files = parsedArguments
    .rest
    .expand((String path) => Glob(path).listSync())
    .whereType<File>()
    .where((File file) => !skipTemplate || path.basename(file.path) != 'template.test')
    .toList();

  if (help || repeat == null || files.isEmpty) {
    printHelp();
    if (verbose) {
      if (repeat == null)
        print('Error: Could not parse repeat count ("${parsedArguments['repeat']}")');
      if (parsedArguments.rest.isEmpty) {
        print('Error: No file arguments specified.');
      } else if (files.isEmpty) {
        print('Error: File arguments ("${parsedArguments.rest.join('", "')}") did not identify any real files.');
      }
    }
    return help;
  }

  if (verbose)
    print('Starting run_tests.dart...');

  if (files.length < shardIndex)
    print('Warning: There are more shards than tests. Some shards will not run any tests.');

  if (numberShards <= shardIndex) {
    print('Error: There are more shard indexes than shards.');
    return help;
  }

  // Best attempt at evenly splitting tests among the shards
  final List<File> shardedFiles = <File>[];
  for (int i = shardIndex; i < files.length; i += numberShards) {
    shardedFiles.add(files[i]);
  }

  int testCount = 0;
  int failures = 0;

  if (verbose) {
    final String s = files.length == 1 ? '' : 's';
    final String ss = shardedFiles.length == 1 ? '' : 's';
    print('${files.length} file$s specified. ${shardedFiles.length} test$ss in shard #$shardIndex.');
    print('');
  }

  if (verbose) {
    print('Tests in this shard:');
    for (final File file in shardedFiles)
      print(file.path);
  }
  print('');

  for (final File file in shardedFiles) {
    if (verbose)
      print('Processing ${file.path}...');
    TestFile instructions;
    try {
      instructions = TestFile(file);
    } on FormatException catch (error) {
      print('ERROR: ${error.message}');
      print('');
      failures += 1;
      continue;
    } on FileSystemException catch (error) {
      print('ERROR: ${error.message}');
      print('  ${file.path}');
      print('');
      failures += 1;
      continue;
    }

    final Directory checkout = Directory.systemTemp.createTempSync('flutter_customer_testing.${path.basenameWithoutExtension(file.path)}.');
    if (verbose)
      print('Created temporary directory: ${checkout.path}');
    try {
      bool success;
      bool showContacts = false;
      for (final String fetchCommand in instructions.fetch) {
        success = await shell(fetchCommand, checkout, verbose: verbose, silentFailure: skipOnFetchFailure);
        if (!success) {
          if (skipOnFetchFailure) {
            if (verbose) {
              print('Skipping (fetch failed).');
            } else {
              print('Skipping ${file.path} (fetch failed).');
            }
          } else {
            print('ERROR: Failed to fetch repository.');
            failures += 1;
            showContacts = true;
          }
          break;
        }
      }
      assert(success != null);
      if (success) {
        if (verbose)
          print('Running tests...');
        final Directory tests = Directory(path.join(checkout.path, 'tests'));
        // TODO(ianh): Once we have a way to update source code, run that command in each directory of instructions.update
        for (int iteration = 0; iteration < repeat; iteration += 1) {
          if (verbose && repeat > 1)
            print('Round ${iteration + 1} of $repeat.');
          for (final String testCommand in instructions.tests) {
            testCount += 1;
            success = await shell(testCommand, tests, verbose: verbose);
            if (!success) {
              print('ERROR: One or more tests from ${path.basenameWithoutExtension(file.path)} failed.');
              failures += 1;
              showContacts = true;
              break;
            }
          }
        }
        if (verbose && success)
          print('Tests finished.');
      }
      if (showContacts) {
        final String s = instructions.contacts.length == 1 ? '' : 's';
        print('Contact$s: ${instructions.contacts.join(", ")}');
      }
    } finally {
      if (verbose)
        print('Deleting temporary directory...');
      try {
        checkout.deleteSync(recursive: true);
      } on FileSystemException {
        print('Failed to delete "${checkout.path}".');
      }
    }
    if (verbose)
      print('');
  }
  if (failures > 0) {
    final String s = failures == 1 ? '' : 's';
    print('$failures failure$s.');
    return false;
  }
  print('$testCount tests all passed!');
  return true;
}

@immutable
class TestFile {
  factory TestFile(File file) {
    final String errorPrefix = 'Could not parse: ${file.path}\n';
    final List<String> contacts = <String>[];
    final List<String> fetch = <String>[];
    final List<Directory> update = <Directory>[];
    final List<String> test = <String>[];
    bool hasTests = false;
    for (final String line in file.readAsLinesSync().map((String line) => line.trim())) {
      if (line.isEmpty) {
        // blank line
      } else if (line.startsWith('#')) {
        // comment
      } else if (line.startsWith('contact=')) {
        contacts.add(line.substring(8));
      } else if (line.startsWith('fetch=')) {
        fetch.add(line.substring(6));
      } else if (line.startsWith('update=')) {
        update.add(Directory(line.substring(7)));
      } else if (line.startsWith('test=')) {
        hasTests = true;
        test.add(line.substring(5));
      } else if (line.startsWith('test.windows=')) {
        hasTests = true;
        if (Platform.isWindows)
          test.add(line.substring(13));
      } else if (line.startsWith('test.macos=')) {
        hasTests = true;
        if (Platform.isMacOS)
          test.add(line.substring(11));
      } else if (line.startsWith('test.linux=')) {
        hasTests = true;
        if (Platform.isLinux)
          test.add(line.substring(11));
      } else if (line.startsWith('test.posix=')) {
        hasTests = true;
        if (Platform.isLinux || Platform.isMacOS)
          test.add(line.substring(11));
      } else {
        throw FormatException('${errorPrefix}Unexpected directive:\n$line');
      }
    }
    if (contacts.isEmpty)
      throw FormatException('${errorPrefix}No contacts specified. At least one contact e-mail address must be specified.');
    for (final String email in contacts) {
      if (!email.contains(_email) || email.endsWith('@example.com'))
        throw FormatException('${errorPrefix}The following e-mail address appears to be an invalid e-mail address: $email');
    }
    if (fetch.isEmpty)
      throw FormatException('${errorPrefix}No "fetch" directives specified. Two lines are expected: "git clone https://github.com/USERNAME/REPOSITORY.git tests" and "git -C tests checkout HASH".');
    if (fetch.length < 2)
      throw FormatException('${errorPrefix}Only one "fetch" directive specified. Two lines are expected: "git clone https://github.com/USERNAME/REPOSITORY.git tests" and "git -C tests checkout HASH".');
    if (!fetch[0].contains(_fetch1))
      throw FormatException('${errorPrefix}First "fetch" directive does not match expected pattern (expected "git clone https://github.com/USERNAME/REPOSITORY.git tests").');
    if (!fetch[1].contains(_fetch2))
      throw FormatException('${errorPrefix}Second "fetch" directive does not match expected pattern (expected "git -C tests checkout HASH").');
    if (update.isEmpty)
      throw FormatException('${errorPrefix}No "update" directives specified. At least one directory must be specified. (It can be "." to just upgrade the root of the repository.)');
    if (!hasTests)
      throw FormatException('${errorPrefix}No "test" directives specified. At least one command must be specified to run tests.');
    return TestFile._(
      List<String>.unmodifiable(contacts),
      List<String>.unmodifiable(fetch),
      List<Directory>.unmodifiable(update),
      List<String>.unmodifiable(test),
    );
  }

  const TestFile._(this.contacts, this.fetch, this.update, this.tests);

  // (e-mail regexp from HTML standard)
  static final RegExp _email = RegExp(r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
  static final RegExp _fetch1 = RegExp(r'^git(?: -c core.longPaths=true)? clone https://github.com/[-a-zA-Z0-9]+/[-_a-zA-Z0-9]+.git tests$');
  static final RegExp _fetch2 = RegExp(r'^git(?: -c core.longPaths=true)? -C tests checkout [0-9a-f]+$');

  final List<String> contacts;
  final List<String> fetch;
  final List<Directory> update;
  final List<String> tests;
}

final RegExp _spaces = RegExp(r' +');

Future<bool> shell(String command, Directory directory, { bool verbose = false, bool silentFailure = false }) async {
  if (verbose)
    print('>> $command');
  Process process;
  if (Platform.isWindows) {
    process = await Process.start('CMD.EXE', <String>['/S', '/C', command], workingDirectory: directory.path);
  } else {
    final List<String> segments = command.trim().split(_spaces);
    process = await Process.start(segments.first, segments.skip(1).toList(), workingDirectory: directory.path);
  }
  final List<String> output = <String>[];
  utf8.decoder.bind(process.stdout).transform(const LineSplitter()).listen(verbose ? printLog : output.add);
  utf8.decoder.bind(process.stderr).transform(const LineSplitter()).listen(verbose ? printLog : output.add);
  final bool success = await process.exitCode == 0;
  if (success || silentFailure)
    return success;
  if (!verbose) {
    print('>> $command');
    output.forEach(printLog);
  }
  return success;
}

void printLog(String line) {
  print('| $line'.trimRight());
}
