// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/executable.dart' as executable;
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  test('Help for command line arguments is consistently styled and complete', () => Testbed().run(() {
    final FlutterCommandRunner runner = FlutterCommandRunner(verboseHelp: true);
    executable.generateCommands(
      verboseHelp: true,
      verbose: true,
    ).forEach(runner.addCommand);
    verifyCommandRunner(runner);
  }));
}

void verifyCommandRunner(CommandRunner<Object> runner) {
  expect(runner.argParser, isNotNull, reason: '${runner.runtimeType} has no argParser');
  expect(runner.argParser.allowsAnything, isFalse, reason: '${runner.runtimeType} allows anything');
  expect(runner.argParser.allowTrailingOptions, isFalse, reason: '${runner.runtimeType} allows trailing options');
  verifyOptions('the global argument "', runner.argParser.options.values);
  runner.commands.values.forEach(verifyCommand);
}

void verifyCommand(Command<Object> runner) {
  expect(runner.argParser, isNotNull, reason: 'command ${runner.name} has no argParser');
  verifyOptions('"flutter ${runner.name} ', runner.argParser.options.values);
  runner.subcommands.values.forEach(verifyCommand);
}

// Patterns for arguments names.
// The "ExtraFrontEndOptions", "ExtraGenSnapshotOptions", and "DartDefines" cases are special cases
// that we should remove; search for "useLegacyNames" in commands/assemble.dart and other files.
// TODO(ianh): consider changing all underscores to hyphens in argument names when we can do aliases.
// That depends on being able to have argument aliases: https://github.com/dart-lang/args/issues/181
final RegExp _allowedArgumentNamePattern = RegExp(r'^([-a-z0-9_]+|ExtraFrontEndOptions|ExtraGenSnapshotOptions|DartDefines)$');

// Patterns for help messages.
final RegExp _bannedLeadingPatterns = RegExp(r'^[-a-z]', multiLine: true);
final RegExp _allowedTrailingPatterns = RegExp(r'([^ ][.!:]\)?|: https?://[^ ]+[^.]|^)$');
final RegExp _bannedQuotePatterns = RegExp(r" '|' |'\.|\('|'\)|`");
final RegExp _bannedArgumentReferencePatterns = RegExp(r'[^"=]--[^ ]');
final RegExp _questionablePatterns = RegExp(r'[a-z]\.[A-Z]');
const String _needHelp = 'Every option must have help explaining what it does, even if it\'s '
                         'for testing purposes, because this is the bare minimum of '
                         'documentation we can add just for ourselves. If it is not intended '
                         'for developers, then use "hide: !verboseHelp" to only show the '
                         'help when people run with "--help --verbose".';

const String _header = ' Comment: ';

void verifyOptions(String command, Iterable<Option> options) {
  assert(command.contains('"'));
  for (final Option option in options) {
    // If you think you need to add an exception here, please ask Hixie (but he'll say no).
    expect(option.name, matches(_allowedArgumentNamePattern), reason: '$_header$command--${option.name}" is not a valid name for a command line argument. (Is it all lowercase?)');
    expect(option.hide, isFalse, reason: '${_header}Help for $command--${option.name}" is always hidden. $_needHelp');
    expect(option.help, isNotNull, reason: '${_header}Help for $command--${option.name}" has null help. $_needHelp');
    expect(option.help, isNotEmpty, reason: '${_header}Help for $command--${option.name}" has empty help. $_needHelp');
    expect(option.help, isNot(matches(_bannedLeadingPatterns)), reason: '${_header}A line in the help for $command--${option.name}" starts with a lowercase letter. For stylistic consistency, all help messages must start with a capital letter.');
    expect(option.help, isNot(startsWith('(Deprecated')), reason: '${_header}Help for $command--${option.name}" should start with lowercase "(deprecated)" for consistency with other deprecated commands.');
    expect(option.help, isNot(startsWith('(Required')), reason: '${_header}Help for $command--${option.name}" should start with lowercase "(required)" for consistency with other deprecated commands.');
    expect(option.help, isNot(contains('?')), reason: '${_header}Help for $command--${option.name}" has a question mark. Generally we prefer the passive voice for help messages.');
    expect(option.help, isNot(contains('Note:')), reason: '${_header}Help for $command--${option.name}" uses "Note:". See our style guide entry about "empty prose".');
    expect(option.help, isNot(contains('Note that')), reason: '${_header}Help for $command--${option.name}" uses "Note that". See our style guide entry about "empty prose".');
    expect(option.help, isNot(matches(_bannedQuotePatterns)), reason: '${_header}Help for $command--${option.name}" uses single quotes or backticks instead of double quotes in the help message. For consistency we use double quotes throughout.');
    expect(option.help, isNot(matches(_questionablePatterns)), reason: '${_header}Help for $command--${option.name}" may have a typo. (If it does not you may have to update args_test.dart, sorry. Search for "_questionablePatterns")');
    if (option.defaultsTo != null) {
      expect(option.help, isNot(contains('Default')), reason: '${_header}Help for $command--${option.name}" mentions the default value but that is redundant with the defaultsTo option which is also specified (and preferred).');
    }
    expect(option.help, isNot(matches(_bannedArgumentReferencePatterns)), reason: '${_header}Help for $command--${option.name}" contains the string "--" in an unexpected way. If it\'s trying to mention another argument, it should be quoted, as in "--foo".');
    for (final String line in option.help.split('\n')) {
      if (!line.startsWith('    ')) {
        expect(line, isNot(contains('  ')), reason: '${_header}Help for $command--${option.name}" has excessive whitespace (check e.g. for double spaces after periods or round line breaks in the source).');
        expect(line, matches(_allowedTrailingPatterns), reason: '${_header}A line in the help for $command--${option.name}" does not end with the expected period that a full sentence should end with. (If the help ends with a URL, place it after a colon, don\'t leave a trailing period; if it\'s sample code, prefix the line with four spaces.)');
      }
    }
    expect(option.help, isNot(endsWith(':')), reason: '${_header}Help for $command--${option.name}" ends with a colon, which seems unlikely to be correct.');
    // TODO(ianh): add some checking for embedded URLs to make sure we're consistent on how we format those.
    // TODO(ianh): arguably we should ban help text that starts with "Whether to..." since by definition a flag is to enable a feature, so the "whether to" is redundant.
    // TODO(ianh): consider looking for strings that use the term "URI" instead of "URL".
  }
}
