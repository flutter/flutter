// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('ArgParser.addCommand()', () {
    test('creates a new ArgParser if none is given', () {
      var parser = ArgParser();
      var command = parser.addCommand('install');
      expect(parser.commands['install'], equals(command));
      expect(command, const TypeMatcher<ArgParser>());
    });

    test('uses the command parser if given one', () {
      var parser = ArgParser();
      var command = ArgParser();
      var result = parser.addCommand('install', command);
      expect(parser.commands['install'], equals(command));
      expect(result, equals(command));
    });

    test('throws on a duplicate command name', () {
      var parser = ArgParser();
      parser.addCommand('install');
      throwsIllegalArg(() => parser.addCommand('install'));
    });
  });

  group('ArgParser.parse()', () {
    test('parses a command', () {
      var parser = ArgParser()..addCommand('install');

      var args = parser.parse(['install']);

      expect(args.command!.name, equals('install'));
      expect(args.rest, isEmpty);
    });

    test('parses a command option', () {
      var parser = ArgParser();
      var command = parser.addCommand('install');
      command.addOption('path');

      var args = parser.parse(['install', '--path', 'some/path']);
      expect(args.command!['path'], equals('some/path'));
    });

    test('parses a parent solo option before the command', () {
      var parser = ArgParser()
        ..addOption('mode', abbr: 'm')
        ..addCommand('install');

      var args = parser.parse(['-m', 'debug', 'install']);
      expect(args['mode'], equals('debug'));
      expect(args.command!.name, equals('install'));
    });

    test('parses a parent solo option after the command', () {
      var parser = ArgParser()
        ..addOption('mode', abbr: 'm')
        ..addCommand('install');

      var args = parser.parse(['install', '-m', 'debug']);
      expect(args['mode'], equals('debug'));
      expect(args.command!.name, equals('install'));
    });

    test('parses a parent option before the command', () {
      var parser = ArgParser()
        ..addFlag('verbose')
        ..addCommand('install');

      var args = parser.parse(['--verbose', 'install']);
      expect(args['verbose'], isTrue);
      expect(args.command!.name, equals('install'));
    });

    test('parses a parent option after the command', () {
      var parser = ArgParser()
        ..addFlag('verbose')
        ..addCommand('install');

      var args = parser.parse(['install', '--verbose']);
      expect(args['verbose'], isTrue);
      expect(args.command!.name, equals('install'));
    });

    test('parses a parent negated option before the command', () {
      var parser = ArgParser()
        ..addFlag('verbose', defaultsTo: true)
        ..addCommand('install');

      var args = parser.parse(['--no-verbose', 'install']);
      expect(args['verbose'], isFalse);
      expect(args.command!.name, equals('install'));
    });

    test('parses a parent negated option after the command', () {
      var parser = ArgParser()
        ..addFlag('verbose', defaultsTo: true)
        ..addCommand('install');

      var args = parser.parse(['install', '--no-verbose']);
      expect(args['verbose'], isFalse);
      expect(args.command!.name, equals('install'));
    });

    test('parses a parent abbreviation before the command', () {
      var parser = ArgParser()
        ..addFlag('debug', abbr: 'd')
        ..addFlag('verbose', abbr: 'v')
        ..addCommand('install');

      var args = parser.parse(['-dv', 'install']);
      expect(args['debug'], isTrue);
      expect(args['verbose'], isTrue);
      expect(args.command!.name, equals('install'));
    });

    test('parses a parent abbreviation after the command', () {
      var parser = ArgParser()
        ..addFlag('debug', abbr: 'd')
        ..addFlag('verbose', abbr: 'v')
        ..addCommand('install');

      var args = parser.parse(['install', '-dv']);
      expect(args['debug'], isTrue);
      expect(args['verbose'], isTrue);
      expect(args.command!.name, equals('install'));
    });

    test('does not parse a solo command option before the command', () {
      var parser = ArgParser();
      var command = parser.addCommand('install');
      command.addOption('path', abbr: 'p');

      throwsFormat(parser, ['-p', 'foo', 'install']);
    });

    test('does not parse a command option before the command', () {
      var parser = ArgParser();
      var command = parser.addCommand('install');
      command.addOption('path');

      throwsFormat(parser, ['--path', 'foo', 'install']);
    });

    test('does not parse a command abbreviation before the command', () {
      var parser = ArgParser();
      var command = parser.addCommand('install');
      command.addFlag('debug', abbr: 'd');
      command.addFlag('verbose', abbr: 'v');

      throwsFormat(parser, ['-dv', 'install']);
    });

    test('assigns collapsed options to the proper command', () {
      var parser = ArgParser();
      parser.addFlag('apple', abbr: 'a');
      var command = parser.addCommand('cmd');
      command.addFlag('banana', abbr: 'b');
      var subcommand = command.addCommand('subcmd');
      subcommand.addFlag('cherry', abbr: 'c');

      var args = parser.parse(['cmd', 'subcmd', '-abc']);
      expect(args['apple'], isTrue);
      expect(args.command!.name, equals('cmd'));
      expect(args.command!['banana'], isTrue);
      expect(args.command!.command!.name, equals('subcmd'));
      expect(args.command!.command!['cherry'], isTrue);
    });

    test('option is given to innermost command that can take it', () {
      var parser = ArgParser();
      parser.addFlag('verbose');
      parser.addCommand('cmd')
        ..addFlag('verbose')
        ..addCommand('subcmd');

      var args = parser.parse(['cmd', 'subcmd', '--verbose']);
      expect(args['verbose'], isFalse);
      expect(args.command!.name, equals('cmd'));
      expect(args.command!['verbose'], isTrue);
      expect(args.command!.command!.name, equals('subcmd'));
    });

    test('remaining arguments are given to the innermost command', () {
      var parser = ArgParser();
      parser.addCommand('cmd').addCommand('subcmd');

      var args = parser.parse(['cmd', 'subcmd', 'other', 'stuff']);
      expect(args.command!.name, equals('cmd'));
      expect(args.rest, isEmpty);
      expect(args.command!.command!.name, equals('subcmd'));
      expect(args.command!.rest, isEmpty);
      expect(args.command!.command!.rest, equals(['other', 'stuff']));
    });
  });
}
