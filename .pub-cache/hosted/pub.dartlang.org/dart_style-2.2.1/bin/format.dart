// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_style/src/cli/formatter_options.dart';
import 'package:dart_style/src/cli/options.dart';
import 'package:dart_style/src/cli/output.dart';
import 'package:dart_style/src/cli/show.dart';
import 'package:dart_style/src/cli/summary.dart';
import 'package:dart_style/src/io.dart';
import 'package:dart_style/src/style_fix.dart';

void main(List<String> args) async {
  var parser = ArgParser(allowTrailingOptions: true);

  defineOptions(parser,
      oldCli: true, verbose: args.contains('--verbose') || args.contains('-v'));

  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on FormatException catch (err) {
    usageError(parser, err.message);
  }

  if (argResults['help']) {
    printUsage(parser);
    return;
  }

  if (argResults['version']) {
    print(dartStyleVersion);
    return;
  }

  if (argResults['verbose'] && !(argResults['help'] as bool)) {
    usageError(parser, 'Can only use --verbose with --help.');
  }

  List<int>? selection;
  try {
    selection = parseSelection(argResults, 'preserve');
  } on FormatException catch (exception) {
    usageError(parser, exception.message);
  }

  if (argResults['dry-run'] && argResults['overwrite']) {
    usageError(
        parser, 'Cannot use --dry-run and --overwrite at the same time.');
  }

  void checkForReporterCollision(String chosen, String other) {
    if (!(argResults[other] as bool)) return;

    usageError(parser, 'Cannot use --$chosen and --$other at the same time.');
  }

  var show = Show.legacy;
  var summary = Summary.none;
  var output = Output.show;
  var setExitIfChanged = false;
  if (argResults['dry-run']) {
    checkForReporterCollision('dry-run', 'overwrite');
    checkForReporterCollision('dry-run', 'machine');

    show = Show.dryRun;
    output = Output.none;
  } else if (argResults['overwrite']) {
    checkForReporterCollision('overwrite', 'machine');

    if (argResults.rest.isEmpty) {
      usageError(parser,
          'Cannot use --overwrite without providing any paths to format.');
    }

    show = Show.overwrite;
    output = Output.write;
  } else if (argResults['machine']) {
    output = Output.json;
  }

  if (argResults['profile']) summary = Summary.profile();

  setExitIfChanged = argResults['set-exit-if-changed'];

  int pageWidth;
  try {
    pageWidth = int.parse(argResults['line-length']);
  } on FormatException catch (_) {
    usageError(
        parser,
        '--line-length must be an integer, was '
        '"${argResults['line-length']}".');
  }

  int indent;
  try {
    indent = int.parse(argResults['indent']);
    if (indent < 0 || indent.toInt() != indent) throw FormatException();
  } on FormatException catch (_) {
    usageError(
        parser,
        '--indent must be a non-negative integer, was '
        '"${argResults['indent']}".');
  }

  var followLinks = argResults['follow-links'];

  var fixes = <StyleFix>[];
  if (argResults['fix']) fixes.addAll(StyleFix.all);
  for (var fix in StyleFix.all) {
    if (argResults['fix-${fix.name}']) {
      if (argResults['fix']) {
        usageError(parser, '--fix-${fix.name} is redundant with --fix.');
      }

      fixes.add(fix);
    }
  }

  if (argResults.wasParsed('stdin-name') && argResults.rest.isNotEmpty) {
    usageError(parser, 'Cannot pass --stdin-name when not reading from stdin.');
  }

  var options = FormatterOptions(
      indent: indent,
      pageWidth: pageWidth,
      followLinks: followLinks,
      fixes: fixes,
      show: show,
      output: output,
      summary: summary,
      setExitIfChanged: setExitIfChanged);

  if (argResults.rest.isEmpty) {
    await formatStdin(options, selection, argResults['stdin-name'] as String);
  } else {
    formatPaths(options, argResults.rest);
  }

  options.summary.show();
}

/// Prints [error] and usage help then exits with exit code 64.
Never usageError(ArgParser parser, String error) {
  printUsage(parser, error);
  exit(64);
}

void printUsage(ArgParser parser, [String? error]) {
  var output = stdout;

  var message = 'Idiomatically format Dart source code.';
  if (error != null) {
    message = error;
    output = stdout;
  }

  output.write('''$message

Usage:   dartfmt [options...] [files or directories...]

Example: dartfmt -w .
         Reformats every Dart file in the current directory tree.

${parser.usage}
''');
}
