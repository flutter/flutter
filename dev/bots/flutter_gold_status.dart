// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import 'utils.dart';

final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(io.Platform.script))));
final String cirrusPR = io.Platform.environment['CIRRUS_PR'];

/// Used to check for any tryjob results from Flutter Gold associated with a PR.
Future<void> main() async {
  // Allow time for the results to have finished processing on Gold's end
  print('$clock WAITING TO START STATUS CHECK');
  await Future<void>.delayed(const Duration(seconds: 30));
  try {
    print('Running task: Flutter Gold Tryjob Status Check');
    print('═' * 80);
    await _queryTryjobStatus();
  } on ExitException catch (error) {
    error.apply();
  }
  print('$clock ${bold}Tryjob status check complete, no untriaged results.$reset');
}

Future<void> _queryTryjobStatus() async {
  print('${green}Running query...$reset');

  final String currentCommit = await _getCurrentCommit();
  final Uri requestForTryjobStatus = Uri.parse(
    'http://flutter-gold.skia.org/json/changelist/github/$cirrusPR/$currentCommit/untriaged'
  );
  String rawResponse;
  bool needsTriage = true;

  // Continue checking until there are no untriaged digests
  while (needsTriage) {
    try {
      final io.HttpClient httpClient = io.HttpClient();
      final io.HttpClientRequest request = await httpClient.getUrl(
        requestForTryjobStatus);
      final io.HttpClientResponse response = await request.close();
      rawResponse = await utf8.decodeStream(response);
      final List<String> digests = json.decode(rawResponse)['digests'] as List<
        String>;
      if (digests == null)
        needsTriage = false;
      else {
        print('${red}Tryjob generated new images.$reset\n'
          'Visit https://flutter-gold.skia.org/changelists to view and triage '
          '(e.g. because this is an intentional change).\n'
          '$clock ${bold}Next status check scheduled in 3 minutes.$reset');

        await Future<void>.delayed(const Duration(minutes: 3));
      }
    } on FormatException catch (_) {
      exitWithError(<String>[
        '${red}Formatting error detected requesting tryjob status from Flutter Gold.\n$reset',
        'rawResponse: $rawResponse',
      ]);
    } catch (e) {
      exit(1);
    }
  }
}

/// Returns the current commit hash of the Flutter repository.
///
/// Gold uses the current commit for a given pull request to identify tryjob
/// patch sets.
Future<String> _getCurrentCommit() async {
  const LocalProcessManager process = LocalProcessManager();
  final io.ProcessResult revParse = await process.run(
    <String>['git', 'rev-parse', 'HEAD'],
    workingDirectory: flutterRoot,
  );
  return revParse.exitCode == 0 ? (revParse.stdout as String).trim() : null;
}