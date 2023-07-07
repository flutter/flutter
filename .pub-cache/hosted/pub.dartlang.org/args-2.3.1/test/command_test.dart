// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  late FooCommand foo;
  setUp(() {
    foo = FooCommand();

    // Make sure [Command.runner] is set up.
    CommandRunner('test', 'A test command runner.').addCommand(foo);
  });

  group('.invocation has a sane default', () {
    test('without subcommands', () {
      expect(foo.invocation, equals('test foo [arguments]'));
    });

    test('with subcommands', () {
      foo.addSubcommand(AsyncCommand());
      expect(foo.invocation, equals('test foo <subcommand> [arguments]'));
    });

    test('for a subcommand', () {
      var async = AsyncCommand();
      foo.addSubcommand(async);

      expect(async.invocation, equals('test foo async [arguments]'));
    });
  });

  group('.usage', () {
    test('returns the usage string', () {
      expect(foo.usage, equals('''
Set a value.

Usage: test foo [arguments]
-h, --help    Print this usage information.

Run "test help" to see global options.'''));
    });

    test('contains custom options', () {
      foo.argParser.addFlag('flag', help: 'Do something.');

      expect(foo.usage, equals('''
Set a value.

Usage: test foo [arguments]
-h, --help         Print this usage information.
    --[no-]flag    Do something.

Run "test help" to see global options.'''));
    });

    test("doesn't print hidden subcommands", () {
      foo.addSubcommand(AsyncCommand());
      foo.addSubcommand(HiddenCommand());

      expect(foo.usage, equals('''
Set a value.

Usage: test foo <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  async   Set a value asynchronously.

Run "test help" to see global options.'''));
    });

    test("doesn't print subcommand aliases", () {
      foo.addSubcommand(AliasedCommand());

      expect(foo.usage, equals('''
Set a value.

Usage: test foo <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  aliased   Set a value.

Run "test help" to see global options.'''));
    });

    test('wraps long command descriptions with subcommands', () {
      var wrapping = WrappingCommand();

      // Make sure [Command.runner] is set up.
      CommandRunner('longtest', 'A long-lined test command runner.')
          .addCommand(wrapping);

      wrapping.addSubcommand(LongCommand());
      expect(wrapping.usage, equals('''
This command overrides the argParser so
that it will wrap long lines.

Usage: longtest wrapping <subcommand>
       [arguments]
-h, --help    Print this usage
              information.

Available subcommands:
  long   This command has a long
         description that needs to be
         wrapped sometimes.

Run "longtest help" to see global
options.'''));
    });

    test('wraps long command descriptions', () {
      var longCommand = LongCommand();

      // Make sure [Command.runner] is set up.
      CommandRunner('longtest', 'A long-lined test command runner.')
          .addCommand(longCommand);

      expect(longCommand.usage, equals('''
This command has a long description that
needs to be wrapped sometimes.
It has embedded newlines,
     and indented lines that also need
     to be wrapped and have their
     indentation preserved.
0123456789012345678901234567890123456789
0123456789012345678901234567890123456789
01234567890123456789

Usage: longtest long [arguments]
-h, --help    Print this usage
              information.

Run "longtest help" to see global
options.'''));
    });
  });

  test('usageException splits up the message and usage', () {
    expect(
        () => foo.usageException('message'), throwsUsageException('message', '''
Usage: test foo [arguments]
-h, --help    Print this usage information.

Run "test help" to see global options.'''));
  });

  test('considers a command hidden if all its subcommands are hidden', () {
    foo.addSubcommand(HiddenCommand());
    expect(foo.hidden, isTrue);
  });
}
