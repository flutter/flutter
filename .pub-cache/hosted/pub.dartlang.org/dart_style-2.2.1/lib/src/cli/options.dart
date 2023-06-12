// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:args/args.dart';

import '../style_fix.dart';

void defineOptions(ArgParser parser,
    {bool oldCli = false, bool verbose = false}) {
  if (oldCli) {
    // The Command class implicitly adds "--help", so we only need to manually
    // add it for the old CLI.
    parser.addFlag('help',
        abbr: 'h',
        negatable: false,
        help: 'Show this usage information.\n'
            '(pass "--verbose" or "-v" to see all options)');
    // Always make verbose hidden since the help text for --help explains it.
    parser.addFlag('verbose', abbr: 'v', negatable: false, hide: true);
  } else {
    parser.addFlag('verbose',
        abbr: 'v',
        negatable: false,
        help: 'Show all options and flags with --help.');
  }

  if (verbose) parser.addSeparator('Output options:');

  if (oldCli) {
    parser.addFlag('overwrite',
        abbr: 'w',
        negatable: false,
        help: 'Overwrite input files with formatted output.');
    parser.addFlag('dry-run',
        abbr: 'n',
        negatable: false,
        help: 'Show which files would be modified but make no changes.');
  } else {
    parser.addOption('output',
        abbr: 'o',
        help: 'Set where to write formatted output.',
        allowed: ['write', 'show', 'json', 'none'],
        allowedHelp: {
          'write': 'Overwrite formatted files on disk.',
          'show': 'Print code to terminal.',
          'json': 'Print code and selection as JSON.',
          'none': 'Discard output.'
        },
        defaultsTo: 'write');
    parser.addOption('show',
        help: 'Set which filenames to print.',
        allowed: ['all', 'changed', 'none'],
        allowedHelp: {
          'all': 'All visited files and directories.',
          'changed': 'Only the names of files whose formatting is changed.',
          'none': 'No file names or directories.',
        },
        defaultsTo: 'changed',
        hide: !verbose);
    parser.addOption('summary',
        help: 'Show the specified summary after formatting.',
        allowed: ['line', 'profile', 'none'],
        allowedHelp: {
          'line': 'Single-line summary.',
          'profile': 'How long it took for format each file.',
          'none': 'No summary.'
        },
        defaultsTo: 'line',
        hide: !verbose);
  }

  parser.addFlag('set-exit-if-changed',
      negatable: false,
      help: 'Return exit code 1 if there are any formatting changes.');

  if (verbose) parser.addSeparator('Non-whitespace fixes (off by default):');
  parser.addFlag('fix', negatable: false, help: 'Apply all style fixes.');

  for (var fix in StyleFix.all) {
    // TODO(rnystrom): Allow negating this if used in concert with "--fix"?
    parser.addFlag('fix-${fix.name}',
        negatable: false, help: fix.description, hide: !verbose);
  }

  if (verbose) parser.addSeparator('Other options:');

  parser.addOption('line-length',
      abbr: 'l', help: 'Wrap lines longer than this.', defaultsTo: '80');
  parser.addOption('indent',
      abbr: 'i',
      help: 'Add this many spaces of leading indentation.',
      defaultsTo: '0',
      hide: !verbose);
  if (oldCli) {
    parser.addFlag('machine',
        abbr: 'm',
        negatable: false,
        help: 'Produce machine-readable JSON output.',
        hide: !verbose);
  }
  parser.addFlag('follow-links',
      negatable: false,
      help: 'Follow links to files and directories.\n'
          'If unset, links will be ignored.',
      hide: !verbose);
  parser.addFlag('version',
      negatable: false, help: 'Show dart_style version.', hide: !verbose);

  if (verbose) parser.addSeparator('Options when formatting from stdin:');

  parser.addOption(oldCli ? 'preserve' : 'selection',
      help: 'Track selection (given as "start:length") through formatting.',
      hide: !verbose);
  parser.addOption('stdin-name',
      help: 'Use this path in error messages when input is read from stdin.',
      defaultsTo: 'stdin',
      hide: !verbose);

  if (oldCli) {
    parser.addFlag('profile', negatable: false, hide: true);

    // Ancient no longer used flag.
    parser.addFlag('transform', abbr: 't', negatable: false, hide: true);
  }
}

List<int>? parseSelection(ArgResults argResults, String optionName) {
  var option = argResults[optionName] as String?;
  if (option == null) return null;

  // Can only preserve a selection when parsing from stdin.
  if (argResults.rest.isNotEmpty) {
    throw FormatException(
        'Can only use --$optionName when reading from stdin.');
  }

  try {
    var coordinates = option.split(':');
    if (coordinates.length != 2) {
      throw FormatException(
          'Selection should be a colon-separated pair of integers, "123:45".');
    }

    return coordinates.map<int>((coord) => int.parse(coord.trim())).toList();
  } on FormatException catch (_) {
    throw FormatException(
        '--$optionName must be a colon-separated pair of integers, was '
        '"${argResults[optionName]}".');
  }
}
