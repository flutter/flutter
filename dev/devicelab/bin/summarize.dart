// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:open_url/open_url.dart';

import 'package:args/args.dart';

import 'package:flutter_devicelab/framework/ab.dart';
import 'package:flutter_devicelab/framework/utils.dart';

String kRawSummaryOpt = 'raw-summary';
String kTabTableOpt = 'tsv-table';
String kAsciiTableOpt = 'ascii-table';
String kWebGraphOpt = 'web-graph';

void _usage(String error) {
  stderr.writeln(error);
  stderr.writeln('Usage:\n');
  stderr.writeln(_argParser.usage);
  exitCode = 1;
}

Future<void> main(List<String> rawArgs) async {
  ArgResults args;
  try {
    args = _argParser.parse(rawArgs);
  } on FormatException catch (error) {
    _usage('${error.message}\n');
    return;
  }

  final List<String> jsonFiles = args.rest.isNotEmpty ? args.rest : <String>[ 'ABresults.json' ];

  for (final String filename in jsonFiles) {
    final File file = File(filename);
    if (!file.existsSync()) {
      _usage('File "$filename" does not exist');
      return;
    }

    String json;
    ABTest test;
    try {
      json = file.readAsStringSync();
      test = ABTest.fromJsonMap(
          const JsonDecoder().convert(json) as Map<String, dynamic>
      );
    } catch(error) {
      _usage('Could not parse json file "$filename"');
      return;
    }

    bool didWork = false;
    if (args[kRawSummaryOpt] as bool) {
      section('Raw results for "$filename"');
      print(test.rawResults());
      didWork = true;
    }
    if (args[kTabTableOpt] as bool) {
      section('A/B comparison for "$filename"');
      print(test.printSummary());
      didWork = true;
    }
    if (args[kAsciiTableOpt] as bool) {
      section('Formatted summary for "$filename"');
      print(test.asciiSummary());
      didWork = true;
    }
    if (args[kWebGraphOpt] as bool) {
      final String template = File('graphAB.html').readAsStringSync();
      final String html = template.replaceAll('null;  // %initial_results_placeholder%', json);
      final Directory tempDir = Directory.systemTemp.createTempSync('graph_AB');
      final File tempFile = File('${tempDir.path}/graphABout.html');
      tempFile.writeAsStringSync(html);
      final dynamic result = await openUrl(tempFile.uri.toString());
      if (result.exitCode != 0) {
        print('Error opening graph web page: ${result.stderr}');
      }
      didWork = true;
    }
    if (!didWork) {
      _usage('Must specify at least one output option');
    }
  }
}

/// Command-line options for the `summarize.dart` command.
final ArgParser _argParser = ArgParser()
  ..addFlag(
    kAsciiTableOpt,
    defaultsTo: false,
    help: 'Prints the summary in a table formatted nicely for terminal output.',
  )
  ..addFlag(
    kTabTableOpt,
    defaultsTo: false,
    help: 'Prints the summary in a table with tabs for easy spreadsheet entry.',
  )
  ..addFlag(
    kRawSummaryOpt,
    defaultsTo: false,
    help: 'Prints all per-run data collected by the A/B test formatted with\n'
        'tabs for easy spreadsheet entry.',
  )
  ..addFlag(
    kWebGraphOpt,
    defaultsTo: false,
    help: 'Opens up a web page with column graphs of the run results.',
  );
