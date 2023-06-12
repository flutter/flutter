// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('ArgParser.addFlag()', () {
    test('throws ArgumentError if the flag already exists', () {
      var parser = ArgParser();
      parser.addFlag('foo');
      throwsIllegalArg(() => parser.addFlag('foo'));
    });

    test('throws ArgumentError if the option already exists', () {
      var parser = ArgParser();
      parser.addOption('foo');
      throwsIllegalArg(() => parser.addFlag('foo'));
    });

    test('throws ArgumentError if the abbreviation exists', () {
      var parser = ArgParser();
      parser.addFlag('foo', abbr: 'f');
      throwsIllegalArg(() => parser.addFlag('flummox', abbr: 'f'));
    });

    test(
        'throws ArgumentError if the abbreviation is longer '
        'than one character', () {
      var parser = ArgParser();
      throwsIllegalArg(() => parser.addFlag('flummox', abbr: 'flu'));
    });

    test('throws ArgumentError if a flag name is invalid', () {
      var parser = ArgParser();

      for (var name in _invalidOptions) {
        var reason = '${Error.safeToString(name)} is not valid';
        throwsIllegalArg(() => parser.addFlag(name), reason: reason);
      }
    });

    test('accepts valid flag names', () {
      var parser = ArgParser();

      for (var name in _validOptions) {
        var reason = '${Error.safeToString(name)} is valid';
        expect(() => parser.addFlag(name), returnsNormally, reason: reason);
      }
    });
  });

  group('ArgParser.addOption()', () {
    test('throws ArgumentError if the flag already exists', () {
      var parser = ArgParser();
      parser.addFlag('foo');
      throwsIllegalArg(() => parser.addOption('foo'));
    });

    test('throws ArgumentError if the option already exists', () {
      var parser = ArgParser();
      parser.addOption('foo');
      throwsIllegalArg(() => parser.addOption('foo'));
    });

    test('throws ArgumentError if the abbreviation exists', () {
      var parser = ArgParser();
      parser.addFlag('foo', abbr: 'f');
      throwsIllegalArg(() => parser.addOption('flummox', abbr: 'f'));
    });

    test(
        'throws ArgumentError if the abbreviation is longer '
        'than one character', () {
      var parser = ArgParser();
      throwsIllegalArg(() => parser.addOption('flummox', abbr: 'flu'));
    });

    test('throws ArgumentError if the abbreviation is empty', () {
      var parser = ArgParser();
      throwsIllegalArg(() => parser.addOption('flummox', abbr: ''));
    });

    test('throws ArgumentError if the abbreviation is an invalid value', () {
      var parser = ArgParser();
      for (var name in _invalidOptions) {
        throwsIllegalArg(() => parser.addOption('flummox', abbr: name));
      }
    });

    test('throws ArgumentError if the abbreviation is a dash', () {
      var parser = ArgParser();
      throwsIllegalArg(() => parser.addOption('flummox', abbr: '-'));
    });

    test('allows explict null value for "abbr"', () {
      var parser = ArgParser();
      expect(() => parser.addOption('flummox', abbr: null), returnsNormally);
    });

    test('throws ArgumentError if an option name is invalid', () {
      var parser = ArgParser();

      for (var name in _invalidOptions) {
        var reason = '${Error.safeToString(name)} is not valid';
        throwsIllegalArg(() => parser.addOption(name), reason: reason);
      }
    });

    test('accepts valid option names', () {
      var parser = ArgParser();

      for (var name in _validOptions) {
        var reason = '${Error.safeToString(name)} is valid';
        expect(() => parser.addOption(name), returnsNormally, reason: reason);
      }
    });
  });

  group('ArgParser.getDefault()', () {
    test('returns the default value for an option', () {
      var parser = ArgParser();
      parser.addOption('mode', defaultsTo: 'debug');
      expect(parser.defaultFor('mode'), 'debug');
    });

    test('throws if the option is unknown', () {
      var parser = ArgParser();
      parser.addOption('mode', defaultsTo: 'debug');
      throwsIllegalArg(() => parser.defaultFor('undefined'));
    });
  });

  group('ArgParser.commands', () {
    test('returns an empty map if there are no commands', () {
      var parser = ArgParser();
      expect(parser.commands, isEmpty);
    });

    test('returns the commands that were added', () {
      var parser = ArgParser();
      parser.addCommand('hide');
      parser.addCommand('seek');
      expect(parser.commands, hasLength(2));
      expect(parser.commands['hide'], isNotNull);
      expect(parser.commands['seek'], isNotNull);
    });

    test('iterates over the commands in the order they were added', () {
      var parser = ArgParser();
      parser.addCommand('a');
      parser.addCommand('d');
      parser.addCommand('b');
      parser.addCommand('c');
      expect(parser.commands.keys, equals(['a', 'd', 'b', 'c']));
    });
  });

  group('ArgParser.options', () {
    test('returns an empty map if there are no options', () {
      var parser = ArgParser();
      expect(parser.options, isEmpty);
    });

    test('returns the options that were added', () {
      var parser = ArgParser();
      parser.addFlag('hide');
      parser.addOption('seek');
      expect(parser.options, hasLength(2));
      expect(parser.options['hide'], isNotNull);
      expect(parser.options['seek'], isNotNull);
    });

    test('iterates over the options in the order they were added', () {
      var parser = ArgParser();
      parser.addFlag('a');
      parser.addOption('d');
      parser.addFlag('b');
      parser.addOption('c');
      expect(parser.options.keys, equals(['a', 'd', 'b', 'c']));
    });
  });

  group('ArgParser.findByNameOrAlias', () {
    test('returns null if there is no match', () {
      var parser = ArgParser();
      expect(parser.findByNameOrAlias('a'), isNull);
    });

    test('can find options by alias', () {
      var parser = ArgParser()..addOption('a', aliases: ['b']);
      expect(parser.findByNameOrAlias('b'),
          isA<Option>().having((o) => o.name, 'name', 'a'));
    });

    test('can find flags by alias', () {
      var parser = ArgParser()..addFlag('a', aliases: ['b']);
      expect(parser.findByNameOrAlias('b'),
          isA<Option>().having((o) => o.name, 'name', 'a'));
    });

    test('does not allow duplicate aliases', () {
      var parser = ArgParser()..addOption('a', aliases: ['b']);
      throwsIllegalArg(() => parser.addOption('c', aliases: ['b']));
    });

    test('does not allow aliases that conflict with existing names', () {
      var parser = ArgParser()..addOption('a', aliases: ['b']);
      throwsIllegalArg(() => parser.addOption('c', aliases: ['a']));
    });

    test('does not allow names that conflict with existing aliases', () {
      var parser = ArgParser()..addOption('a', aliases: ['b']);
      throwsIllegalArg(() => parser.addOption('b'));
    });
  });

  group('ArgResults', () {
    group('options', () {
      test('returns the provided options', () {
        var parser = ArgParser();
        parser.addFlag('woof');
        parser.addOption('meow');

        parser.addOption('missing-option');
        parser.addFlag('missing-flag', defaultsTo: null);

        var args = parser.parse(['--woof', '--meow', 'kitty']);
        expect(args.options, hasLength(2));
        expect(args.options, contains('woof'));
        expect(args.options, contains('meow'));
      });

      test('includes defaulted options', () {
        var parser = ArgParser();
        parser.addFlag('woof', defaultsTo: false);
        parser.addOption('meow', defaultsTo: 'kitty');

        // Flags normally have a default value.
        parser.addFlag('moo');

        parser.addOption('missing-option');
        parser.addFlag('missing-flag', defaultsTo: null);

        var args = parser.parse([]);
        expect(args.options, hasLength(3));
        expect(args.options, contains('woof'));
        expect(args.options, contains('meow'));
        expect(args.options, contains('moo'));
      });
    });

    test('[] throws if the name is not an option', () {
      var results = ArgParser().parse([]);
      throwsIllegalArg(() => results['unknown']);
    });

    test('rest cannot be modified', () {
      var results = ArgParser().parse([]);
      expect(() => results.rest.add('oops'), throwsUnsupportedError);
    });

    test('.arguments returns the original argument list', () {
      var parser = ArgParser();
      parser.addFlag('foo');

      var results = parser.parse(['--foo']);
      expect(results.arguments, equals(['--foo']));
    });

    group('.wasParsed()', () {
      test('throws if the name is not an option', () {
        var results = ArgParser().parse([]);
        throwsIllegalArg(() => results.wasParsed('unknown'));
      });

      test('returns true for parsed options', () {
        var parser = ArgParser();
        parser.addFlag('fast');
        parser.addFlag('verbose');
        parser.addOption('mode');
        parser.addOption('output');

        var results = parser.parse(['--fast', '--mode=debug']);

        expect(results.wasParsed('fast'), isTrue);
        expect(results.wasParsed('verbose'), isFalse);
        expect(results.wasParsed('mode'), isTrue);
        expect(results.wasParsed('output'), isFalse);
      });
    });
  });

  group('Option', () {
    test('.valueOrDefault() returns a type-specific default value', () {
      var parser = ArgParser();
      parser.addFlag('flag-no', defaultsTo: null);
      parser.addFlag('flag-def', defaultsTo: true);
      parser.addOption('single-no');
      parser.addOption('single-def', defaultsTo: 'def');
      parser.addMultiOption('multi-no');
      parser.addMultiOption('multi-def', defaultsTo: ['def']);

      expect(parser.options['flag-no']!.valueOrDefault(null), equals(null));
      expect(parser.options['flag-no']!.valueOrDefault(false), equals(false));
      expect(parser.options['flag-def']!.valueOrDefault(null), equals(true));
      expect(parser.options['flag-def']!.valueOrDefault(false), equals(false));
      expect(parser.options['single-no']!.valueOrDefault(null), equals(null));
      expect(parser.options['single-no']!.valueOrDefault('v'), equals('v'));
      expect(parser.options['single-def']!.valueOrDefault(null), equals('def'));
      expect(parser.options['single-def']!.valueOrDefault('v'), equals('v'));
      expect(parser.options['multi-no']!.valueOrDefault(null), equals([]));
      expect(parser.options['multi-no']!.valueOrDefault(['v']), equals(['v']));
      expect(
          parser.options['multi-def']!.valueOrDefault(null), equals(['def']));
      expect(parser.options['multi-def']!.valueOrDefault(['v']), equals(['v']));
    });
  });
}

const _invalidOptions = [
  ' ',
  '',
  '-',
  '--',
  '--foo',
  ' with space',
  'with\ttab',
  'with\rcarriage\rreturn',
  'with\nline\nfeed',
  "'singlequotes'",
  '"doublequotes"',
  'back\\slash',
  'forward/slash'
];

const _validOptions = [
  'a', // One character.
  'contains-dash',
  'contains_underscore',
  'ends-with-dash-',
  'contains--doubledash--',
  '1starts-with-number',
  'contains-a-1number',
  'ends-with-a-number8'
];
