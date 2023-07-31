// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:test/test.dart';

void main() {
  group('ArgParser.usage', () {
    test('negatable flags show "no-" in title', () {
      var parser = ArgParser();
      parser.addFlag('mode', help: 'The mode');

      validateUsage(parser, '''
          --[no-]mode    The mode
          ''');
    });

    test('non-negatable flags don\'t show "no-" in title', () {
      var parser = ArgParser();
      parser.addFlag('mode', negatable: false, help: 'The mode');

      validateUsage(parser, '''
          --mode    The mode
          ''');
    });

    test('if there are no abbreviations, there is no column for them', () {
      var parser = ArgParser();
      parser.addFlag('mode', help: 'The mode');

      validateUsage(parser, '''
          --[no-]mode    The mode
          ''');
    });

    test('options are lined up past abbreviations', () {
      var parser = ArgParser();
      parser.addFlag('mode', abbr: 'm', help: 'The mode');
      parser.addOption('long', help: 'Lacks an abbreviation');

      validateUsage(parser, '''
          -m, --[no-]mode    The mode
              --long         Lacks an abbreviation
          ''');
    });

    test('help text is lined up past the longest option', () {
      var parser = ArgParser();
      parser.addFlag('mode', abbr: 'm', help: 'Lined up with below');
      parser.addOption('a-really-long-name', help: 'Its help text');

      validateUsage(parser, '''
          -m, --[no-]mode             Lined up with below
              --a-really-long-name    Its help text
          ''');
    });

    test('leading empty lines are ignored in help text', () {
      var parser = ArgParser();
      parser.addFlag('mode', help: '\n\n\n\nAfter newlines');

      validateUsage(parser, '''
          --[no-]mode    After newlines
          ''');
    });

    test('trailing empty lines are ignored in help text', () {
      var parser = ArgParser();
      parser.addFlag('mode', help: 'Before newlines\n\n\n\n');

      validateUsage(parser, '''
          --[no-]mode    Before newlines
          ''');
    });

    test('options are documented in the order they were added', () {
      var parser = ArgParser();
      parser.addFlag('zebra', help: 'First');
      parser.addFlag('monkey', help: 'Second');
      parser.addFlag('wombat', help: 'Third');

      validateUsage(parser, '''
          --[no-]zebra     First
          --[no-]monkey    Second
          --[no-]wombat    Third
          ''');
    });

    test('the default value for a flag is shown if on', () {
      var parser = ArgParser();
      parser.addFlag('affirm', help: 'Should be on', defaultsTo: true);
      parser.addFlag('negate', help: 'Should be off', defaultsTo: false);
      parser.addFlag('null', help: 'Should be null', defaultsTo: null);

      validateUsage(parser, '''
          --[no-]affirm    Should be on
                           (defaults to on)
          --[no-]negate    Should be off
          --[no-]null      Should be null
          ''');
    });

    test('the default value for an option with no allowed list is shown', () {
      var parser = ArgParser();
      parser.addOption('single',
          help: 'Can be anything', defaultsTo: 'whatevs');
      parser.addMultiOption('multiple',
          help: 'Can be anything', defaultsTo: ['whatevs']);

      validateUsage(parser, '''
          --single      Can be anything
                        (defaults to "whatevs")
          --multiple    Can be anything
                        (defaults to "whatevs")
          ''');
    });

    test('multiple default values for an option with no allowed list are shown',
        () {
      var parser = ArgParser();
      parser.addMultiOption('any',
          help: 'Can be anything', defaultsTo: ['some', 'stuff']);

      validateUsage(parser, '''
          --any    Can be anything
                   (defaults to "some", "stuff")
          ''');
    });

    test('no default values are shown for a multi option with an empty default',
        () {
      var parser = ArgParser();
      parser.addMultiOption('implicit', help: 'Implicit default');
      parser
          .addMultiOption('explicit', help: 'Explicit default', defaultsTo: []);

      validateUsage(parser, '''
          --implicit    Implicit default
          --explicit    Explicit default
          ''');
    });

    test('the value help is shown', () {
      var parser = ArgParser();
      parser.addOption('out',
          abbr: 'o', help: 'Where to write file', valueHelp: 'path');

      validateUsage(parser, '''
          -o, --out=<path>    Where to write file
          ''');
    });

    test('the allowed list is shown', () {
      var parser = ArgParser();
      parser.addOption('suit',
          help: 'Like in cards',
          allowed: ['spades', 'clubs', 'hearts', 'diamonds']);

      validateUsage(parser, '''
          --suit    Like in cards
                    [spades, clubs, hearts, diamonds]
          ''');
    });

    test('the default is highlighted in the allowed list', () {
      var parser = ArgParser();
      parser.addOption('suit',
          help: 'Like in cards',
          defaultsTo: 'clubs',
          allowed: ['spades', 'clubs', 'hearts', 'diamonds']);

      validateUsage(parser, '''
          --suit    Like in cards
                    [spades, clubs (default), hearts, diamonds]
          ''');
    });

    test('multiple defaults are highlighted in the allowed list', () {
      var parser = ArgParser();
      parser.addMultiOption('suit',
          help: 'Like in cards',
          defaultsTo: ['clubs', 'diamonds'],
          allowed: ['spades', 'clubs', 'hearts', 'diamonds']);

      validateUsage(parser, '''
          --suit    Like in cards
                    [spades, clubs (default), hearts, diamonds (default)]
          ''');
    });

    test('the allowed help is shown', () {
      var parser = ArgParser();
      parser.addOption('suit', help: 'Like in cards', allowed: [
        'spades',
        'clubs',
        'diamonds',
        'hearts'
      ], allowedHelp: {
        'spades': 'Swords of a soldier',
        'clubs': 'Weapons of war',
        'diamonds': 'Money for this art',
        'hearts': 'The shape of my heart'
      });

      validateUsage(parser, '''
          --suit              Like in cards

                [clubs]       Weapons of war
                [diamonds]    Money for this art
                [hearts]      The shape of my heart
                [spades]      Swords of a soldier
          ''');
    });

    test('the default is highlighted in the allowed help', () {
      var parser = ArgParser();
      parser.addOption('suit',
          help: 'Like in cards',
          defaultsTo: 'clubs',
          allowed: [
            'spades',
            'clubs',
            'diamonds',
            'hearts'
          ],
          allowedHelp: {
            'spades': 'Swords of a soldier',
            'clubs': 'Weapons of war',
            'diamonds': 'Money for this art',
            'hearts': 'The shape of my heart'
          });

      validateUsage(parser, '''
          --suit                     Like in cards

                [clubs] (default)    Weapons of war
                [diamonds]           Money for this art
                [hearts]             The shape of my heart
                [spades]             Swords of a soldier
          ''');
    });

    test('multiple defaults are highlighted in the allowed help', () {
      var parser = ArgParser();
      parser.addMultiOption('suit', help: 'Like in cards', defaultsTo: [
        'clubs',
        'hearts'
      ], allowed: [
        'spades',
        'clubs',
        'diamonds',
        'hearts'
      ], allowedHelp: {
        'spades': 'Swords of a soldier',
        'clubs': 'Weapons of war',
        'diamonds': 'Money for this art',
        'hearts': 'The shape of my heart'
      });

      validateUsage(parser, '''
          --suit                      Like in cards

                [clubs] (default)     Weapons of war
                [diamonds]            Money for this art
                [hearts] (default)    The shape of my heart
                [spades]              Swords of a soldier
          ''');
    });

    test("hidden options don't appear in the help", () {
      var parser = ArgParser();
      parser.addOption('first', help: 'The first option');
      parser.addOption('second', hide: true);
      parser.addOption('third', help: 'The third option');

      validateUsage(parser, '''
          --first    The first option
          --third    The third option
          ''');
    });

    test("hidden flags don't appear in the help", () {
      var parser = ArgParser();
      parser.addFlag('first', help: 'The first flag');
      parser.addFlag('second', hide: true);
      parser.addFlag('third', help: 'The third flag');

      validateUsage(parser, '''
          --[no-]first    The first flag
          --[no-]third    The third flag
          ''');
    });

    test("hidden options don't affect spacing", () {
      var parser = ArgParser();
      parser.addFlag('first', help: 'The first flag');
      parser.addFlag('second-very-long-option', hide: true);
      parser.addFlag('third', help: 'The third flag');

      validateUsage(parser, '''
          --[no-]first    The first flag
          --[no-]third    The third flag
          ''');
    });

    test('help strings are not wrapped if usageLineLength is null', () {
      var parser = ArgParser(usageLineLength: null);
      parser.addFlag('long',
          help: 'The flag with a really long help text that will not '
              'be wrapped.');
      validateUsage(parser, '''
          --[no-]long    The flag with a really long help text that will not be wrapped.
          ''');
    });

    test('help strings are wrapped properly when usageLineLength is specified',
        () {
      var parser = ArgParser(usageLineLength: 60);
      parser.addFlag('long',
          help: 'The flag with a really long help text that will be wrapped.');
      parser.addFlag('longNewline',
          help: 'The flag with a really long help text and newlines\n\nthat '
              'will still be wrapped because it is really long.');
      parser.addFlag('solid',
          help:
              'The-flag-with-no-whitespace-that-will-be-wrapped-by-splitting-a-word.');
      parser.addFlag('longWhitespace',
          help:
              '           The flag with a really long help text and whitespace at the start.');
      parser.addFlag('longTrailspace',
          help:
              'The flag with a really long help text and whitespace at the end.             ');
      parser.addFlag('small1', help: ' a ');
      parser.addFlag('small2', help: ' a');
      parser.addFlag('small3', help: 'a ');
      validateUsage(parser, '''
          --[no-]long              The flag with a really long help
                                   text that will be wrapped.
          --[no-]longNewline       The flag with a really long help
                                   text and newlines
                                   
                                   that will still be wrapped because
                                   it is really long.
          --[no-]solid             The-flag-with-no-whitespace-that-wi
                                   ll-be-wrapped-by-splitting-a-word.
          --[no-]longWhitespace    The flag with a really long help
                                   text and whitespace at the start.
          --[no-]longTrailspace    The flag with a really long help
                                   text and whitespace at the end.
          --[no-]small1            a
          --[no-]small2            a
          --[no-]small3            a
          ''');
    });

    test(
        'help strings are wrapped with at 10 chars when usageLineLength is '
        'smaller than available space', () {
      var parser = ArgParser(usageLineLength: 1);
      parser.addFlag('long',
          help: 'The flag with a really long help text that will be wrapped.');
      parser.addFlag('longNewline',
          help:
              'The flag with a really long help text and newlines\n\nthat will '
              'still be wrapped because it is really long.');
      parser.addFlag('solid',
          help:
              'The-flag-with-no-whitespace-that-will-be-wrapped-by-splitting-a-word.');
      parser.addFlag('small1', help: ' a ');
      parser.addFlag('small2', help: ' a');
      parser.addFlag('small3', help: 'a ');
      validateUsage(parser, '''
          --[no-]long           The flag
                                with a
                                really
                                long help
                                text that
                                will be
                                wrapped.
          --[no-]longNewline    The flag
                                with a
                                really
                                long help
                                text and
                                newlines
                                
                                that will
                                still be
                                wrapped
                                because it
                                is really
                                long.
          --[no-]solid          The-flag-w
                                ith-no-whi
                                tespace-th
                                at-will-be
                                -wrapped-b
                                y-splittin
                                g-a-word.
          --[no-]small1         a
          --[no-]small2         a
          --[no-]small3         a
          ''');
    });

    test('display "mandatory" after a mandatory option', () {
      var parser = ArgParser();
      parser.addOption('test', mandatory: true);
      validateUsage(parser, '''
        --test (mandatory)    
        ''');
    });

    test('throw argument error if option is mandatory with a default value',
        () {
      var parser = ArgParser();
      expect(
          () => parser.addOption('test', mandatory: true, defaultsTo: 'test'),
          throwsArgumentError);
    });

    group('separators', () {
      test("separates options where it's placed", () {
        var parser = ArgParser();
        parser.addFlag('zebra', help: 'First');
        parser.addSeparator('Primate:');
        parser.addFlag('monkey', help: 'Second');
        parser.addSeparator('Marsupial:');
        parser.addFlag('wombat', help: 'Third');

        validateUsage(parser, '''
            --[no-]zebra     First

            Primate:
            --[no-]monkey    Second

            Marsupial:
            --[no-]wombat    Third
            ''');
      });

      test("doesn't add extra newlines after a multiline option", () {
        var parser = ArgParser();
        parser.addFlag('zebra', help: 'Multi\nline');
        parser.addSeparator('Primate:');
        parser.addFlag('monkey', help: 'Second');

        validateUsage(parser, '''
            --[no-]zebra     Multi
                             line

            Primate:
            --[no-]monkey    Second
            ''');
      });

      test("doesn't add newlines if it's the first component", () {
        var parser = ArgParser();
        parser.addSeparator('Equine:');
        parser.addFlag('zebra', help: 'First');

        validateUsage(parser, '''
            Equine:
            --[no-]zebra    First
            ''');
      });

      test("doesn't add trailing newlines if it's the last component", () {
        var parser = ArgParser();
        parser.addFlag('zebra', help: 'First');
        parser.addSeparator('Primate:');

        validateUsage(parser, '''
            --[no-]zebra    First

            Primate:
            ''');
      });

      test('adds a newline after another separator', () {
        var parser = ArgParser();
        parser.addSeparator('First');
        parser.addSeparator('Second');

        validateUsage(parser, '''
            First

            Second
            ''');
      });
    });
  });
}

void validateUsage(ArgParser parser, String expected) {
  expected = unindentString(expected);
  expect(parser.usage, equals(expected));
}

// TODO(rnystrom): Replace one in test_utils.
String unindentString(String text) {
  var lines = text.split('\n');

  // Count the indentation of the last line.
  var whitespace = RegExp('^ *');
  var indent = whitespace.firstMatch(lines[lines.length - 1])![0]!.length;

  // Drop the last line. It only exists for specifying indentation.
  lines.removeLast();

  // Strip indentation from the remaining lines.
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.length <= indent) {
      // It's short, so it must be nothing but whitespace.
      if (line.trim() != '') {
        throw ArgumentError('Line "$line" does not have enough indentation.');
      }

      lines[i] = '';
    } else {
      if (line.substring(0, indent).trim() != '') {
        throw ArgumentError('Line "$line" does not have enough indentation.');
      }

      lines[i] = line.substring(indent);
    }
  }

  return lines.join('\n');
}
