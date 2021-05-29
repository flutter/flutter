// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'customer_test.dart';

Future<bool> runTests({
  int repeat = 1,
  bool skipOnFetchFailure = false,
  bool verbose = false,
  int numberShards = 1,
  int shardIndex = 0,
  List<File> files,
}) async {
  if (verbose)
    print('Starting run_tests.dart...');

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
    CustomerTest instructions;
    try {
      instructions = CustomerTest(file);
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
