// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:test/test.dart';

class CommandRunnerWithFooter extends CommandRunner {
  @override
  String get usageFooter => 'Also, footer!';

  CommandRunnerWithFooter(String executableName, String description)
      : super(executableName, description);
}

class CommandRunnerWithFooterAndWrapping extends CommandRunner {
  @override
  String get usageFooter => 'LONG footer! '
      'This is a long footer, so we can check wrapping on long footer messages.'
      '\n\n'
      'And make sure that they preserve newlines properly.';

  @override
  ArgParser get argParser => _argParser;
  final _argParser = ArgParser(usageLineLength: 40);

  CommandRunnerWithFooterAndWrapping(String executableName, String description)
      : super(executableName, description);
}

class FooCommand extends Command {
  var hasRun = false;

  @override
  final name = 'foo';

  @override
  final description = 'Set a value.';

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class ValueCommand extends Command<int> {
  @override
  final name = 'foo';

  @override
  final description = 'Return a value.';

  @override
  final takesArguments = false;

  @override
  int run() => 12;
}

class AsyncValueCommand extends Command<String> {
  @override
  final name = 'foo';

  @override
  final description = 'Return a future.';

  @override
  final takesArguments = false;

  @override
  Future<String> run() async => 'hi';
}

class Category1Command extends Command {
  var hasRun = false;

  @override
  final name = 'bar';

  @override
  final description = 'Print a value.';

  @override
  final category = 'Printers';

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class Category2Command extends Command {
  var hasRun = false;

  @override
  final name = 'baz';

  @override
  final description = 'Display a value.';

  @override
  final category = 'Displayers';

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class Category2Command2 extends Command {
  var hasRun = false;

  @override
  final name = 'baz2';

  @override
  final description = 'Display another value.';

  @override
  final category = 'Displayers';

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class MultilineCommand extends Command {
  var hasRun = false;

  @override
  final name = 'multiline';

  @override
  final description = 'Multi\nline.';

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class WrappingCommand extends Command {
  var hasRun = false;

  @override
  ArgParser get argParser => _argParser;
  final _argParser = ArgParser(usageLineLength: 40);

  @override
  final name = 'wrapping';

  @override
  final description =
      'This command overrides the argParser so that it will wrap long lines.';

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class LongCommand extends Command {
  var hasRun = false;

  @override
  ArgParser get argParser => _argParser;
  final _argParser = ArgParser(usageLineLength: 40);

  @override
  final name = 'long';

  @override
  final description = 'This command has a long description that needs to be '
          'wrapped sometimes.\nIt has embedded newlines,\n'
          '     and indented lines that also need to be wrapped and have their '
          'indentation preserved.\n' +
      ('0123456789' * 10);

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class MultilineSummaryCommand extends MultilineCommand {
  @override
  String get summary => description;
}

class HiddenCommand extends Command {
  var hasRun = false;

  @override
  final name = 'hidden';

  @override
  final description = 'Set a value.';

  @override
  final hidden = true;

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class HiddenCategorizedCommand extends Command {
  var hasRun = false;

  @override
  final name = 'hiddencategorized';

  @override
  final description = 'Set a value.';

  @override
  final category = 'Some category';

  @override
  final hidden = true;

  @override
  final takesArguments = false;

  @override
  void run() {
    hasRun = true;
  }
}

class AliasedCommand extends Command {
  var hasRun = false;

  @override
  final name = 'aliased';

  @override
  final description = 'Set a value.';

  @override
  final takesArguments = false;

  @override
  final aliases = const ['alias', 'als'];

  @override
  void run() {
    hasRun = true;
  }
}

class AsyncCommand extends Command {
  var hasRun = false;

  @override
  final name = 'async';

  @override
  final description = 'Set a value asynchronously.';

  @override
  final takesArguments = false;

  @override
  Future run() => Future.value().then((_) => hasRun = true);
}

class AllowAnythingCommand extends Command {
  var hasRun = false;

  @override
  final name = 'allowAnything';

  @override
  final description = 'A command using allowAnything.';

  @override
  final argParser = ArgParser.allowAnything();

  @override
  void run() {
    hasRun = true;
  }
}

class CustomNameCommand extends Command {
  @override
  final String name;

  CustomNameCommand(this.name);

  @override
  String get description => 'A command with a custom name';
}

void throwsIllegalArg(function, {String? reason}) {
  expect(function, throwsArgumentError, reason: reason);
}

void throwsFormat(ArgParser parser, List<String> args) {
  expect(() => parser.parse(args), throwsFormatException);
}

Matcher throwsUsageException(Object? message, Object? usage) =>
    throwsA(isA<UsageException>()
        .having((e) => e.message, 'message', message)
        .having((e) => e.usage, 'usage', usage));
