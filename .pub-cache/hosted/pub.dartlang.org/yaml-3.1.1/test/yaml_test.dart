// Copyright (c) 2012, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:test/test.dart';
import 'package:yaml/src/error_listener.dart';
import 'package:yaml/yaml.dart';

import 'utils.dart';

void main() {
  var infinity = double.parse('Infinity');
  var nan = double.parse('NaN');

  group('has a friendly error message for', () {
    var tabError = predicate((e) =>
        e.toString().contains('Tab characters are not allowed as indentation'));

    test('using a tab as indentation', () {
      expect(() => loadYaml('foo:\n\tbar'), throwsA(tabError));
    });

    test('using a tab not as indentation', () {
      expect(() => loadYaml('''
          "foo
          \tbar"
          error'''), throwsA(isNot(tabError)));
    });
  });

  group('refuses', () {
    // Regression test for #19.
    test('invalid contents', () {
      expectYamlFails('{');
    });

    test('duplicate mapping keys', () {
      expectYamlFails('{a: 1, a: 2}');
    });

    group('documents that declare version', () {
      test('1.0', () {
        expectYamlFails('''
         %YAML 1.0
         --- text
         ''');
      });

      test('1.3', () {
        expectYamlFails('''
           %YAML 1.3
           --- text
           ''');
      });

      test('2.0', () {
        expectYamlFails('''
           %YAML 2.0
           --- text
           ''');
      });
    });
  });

  group('recovers', () {
    var collector = ErrorCollector();
    setUp(() {
      collector = ErrorCollector();
    });

    test('from incomplete leading keys', () {
      final yaml = cleanUpLiteral(r'''
        dependencies:
          zero
          one: any
          ''');
      var result = loadYaml(yaml, recover: true, errorListener: collector);
      expect(
          result,
          deepEquals({
            'dependencies': {
              'zero': null,
              'one': 'any',
            }
          }));
      expect(collector.errors.length, equals(1));
      // These errors are reported at the start of the next token (after the
      // whitespace/newlines).
      expectErrorAtLineCol(collector.errors[0], "Expected ':'.", 2, 2);
      // Skipped because this case is not currently handled. If it's the first
      // package without the colon, because the value is indented from the line
      // above, the whole `zero\n     one` is treated as a scalar value.
    }, skip: true);
    test('from incomplete keys', () {
      final yaml = cleanUpLiteral(r'''
        dependencies:
          one: any
          two
          three:
          four
          five:
            1.2.3
          six: 5.4.3
          ''');
      var result = loadYaml(yaml, recover: true, errorListener: collector);
      expect(
          result,
          deepEquals({
            'dependencies': {
              'one': 'any',
              'two': null,
              'three': null,
              'four': null,
              'five': '1.2.3',
              'six': '5.4.3',
            }
          }));

      expect(collector.errors.length, equals(2));
      // These errors are reported at the start of the next token (after the
      // whitespace/newlines).
      expectErrorAtLineCol(collector.errors[0], "Expected ':'.", 3, 2);
      expectErrorAtLineCol(collector.errors[1], "Expected ':'.", 5, 2);
    });
    test('from incomplete trailing keys', () {
      final yaml = cleanUpLiteral(r'''
        dependencies:
          six: 5.4.3
          seven
          ''');
      var result = loadYaml(yaml, recover: true);
      expect(
          result,
          deepEquals({
            'dependencies': {
              'six': '5.4.3',
              'seven': null,
            }
          }));
    });
  });

  test('includes source span information', () {
    var yaml = loadYamlNode(r'''
- foo:
    bar
- 123
''') as YamlList;

    expect(yaml.span.start.line, equals(0));
    expect(yaml.span.start.column, equals(0));
    expect(yaml.span.end.line, equals(3));
    expect(yaml.span.end.column, equals(0));

    var map = yaml.nodes.first as YamlMap;
    expect(map.span.start.line, equals(0));
    expect(map.span.start.column, equals(2));
    expect(map.span.end.line, equals(2));
    expect(map.span.end.column, equals(0));

    var key = map.nodes.keys.first;
    expect(key.span.start.line, equals(0));
    expect(key.span.start.column, equals(2));
    expect(key.span.end.line, equals(0));
    expect(key.span.end.column, equals(5));

    var value = map.nodes.values.first;
    expect(value.span.start.line, equals(1));
    expect(value.span.start.column, equals(4));
    expect(value.span.end.line, equals(1));
    expect(value.span.end.column, equals(7));

    var scalar = yaml.nodes.last;
    expect(scalar.span.start.line, equals(2));
    expect(scalar.span.start.column, equals(2));
    expect(scalar.span.end.line, equals(2));
    expect(scalar.span.end.column, equals(5));
  });

  // The following tests are all taken directly from the YAML spec
  // (http://www.yaml.org/spec/1.2/spec.html). Most of them are code examples
  // that are directly included in the spec, but additional tests are derived
  // from the prose.

  // A few examples from the spec are deliberately excluded, because they test
  // features that this implementation doesn't intend to support (character
  // encoding detection and user-defined tags). More tests are commented out,
  // because they're intended to be supported but not yet implemented.

  // Chapter 2 is just a preview of various Yaml documents. It's probably not
  // necessary to test its examples, but it would be nice to test everything in
  // the spec.
  group('2.1: Collections', () {
    test('[Example 2.1]', () {
      expectYamlLoads(['Mark McGwire', 'Sammy Sosa', 'Ken Griffey'], '''
        - Mark McGwire
        - Sammy Sosa
        - Ken Griffey''');
    });

    test('[Example 2.2]', () {
      expectYamlLoads({'hr': 65, 'avg': 0.278, 'rbi': 147}, '''
        hr:  65    # Home runs
        avg: 0.278 # Batting average
        rbi: 147   # Runs Batted In''');
    });

    test('[Example 2.3]', () {
      expectYamlLoads({
        'american': ['Boston Red Sox', 'Detroit Tigers', 'New York Yankees'],
        'national': ['New York Mets', 'Chicago Cubs', 'Atlanta Braves'],
      }, '''
        american:
          - Boston Red Sox
          - Detroit Tigers
          - New York Yankees
        national:
          - New York Mets
          - Chicago Cubs
          - Atlanta Braves''');
    });

    test('[Example 2.4]', () {
      expectYamlLoads([
        {'name': 'Mark McGwire', 'hr': 65, 'avg': 0.278},
        {'name': 'Sammy Sosa', 'hr': 63, 'avg': 0.288},
      ], '''
        -
          name: Mark McGwire
          hr:   65
          avg:  0.278
        -
          name: Sammy Sosa
          hr:   63
          avg:  0.288''');
    });

    test('[Example 2.5]', () {
      expectYamlLoads([
        ['name', 'hr', 'avg'],
        ['Mark McGwire', 65, 0.278],
        ['Sammy Sosa', 63, 0.288]
      ], '''
        - [name        , hr, avg  ]
        - [Mark McGwire, 65, 0.278]
        - [Sammy Sosa  , 63, 0.288]''');
    });

    test('[Example 2.6]', () {
      expectYamlLoads({
        'Mark McGwire': {'hr': 65, 'avg': 0.278},
        'Sammy Sosa': {'hr': 63, 'avg': 0.288}
      }, '''
        Mark McGwire: {hr: 65, avg: 0.278}
        Sammy Sosa: {
            hr: 63,
            avg: 0.288
          }''');
    });
  });

  group('2.2: Structures', () {
    test('[Example 2.7]', () {
      expectYamlStreamLoads([
        ['Mark McGwire', 'Sammy Sosa', 'Ken Griffey'],
        ['Chicago Cubs', 'St Louis Cardinals']
      ], '''
        # Ranking of 1998 home runs
        ---
        - Mark McGwire
        - Sammy Sosa
        - Ken Griffey

        # Team ranking
        ---
        - Chicago Cubs
        - St Louis Cardinals''');
    });

    test('[Example 2.8]', () {
      expectYamlStreamLoads([
        {'time': '20:03:20', 'player': 'Sammy Sosa', 'action': 'strike (miss)'},
        {'time': '20:03:47', 'player': 'Sammy Sosa', 'action': 'grand slam'},
      ], '''
        ---
        time: 20:03:20
        player: Sammy Sosa
        action: strike (miss)
        ...
        ---
        time: 20:03:47
        player: Sammy Sosa
        action: grand slam
        ...''');
    });

    test('[Example 2.9]', () {
      expectYamlLoads({
        'hr': ['Mark McGwire', 'Sammy Sosa'],
        'rbi': ['Sammy Sosa', 'Ken Griffey']
      }, '''
        ---
        hr: # 1998 hr ranking
          - Mark McGwire
          - Sammy Sosa
        rbi:
          # 1998 rbi ranking
          - Sammy Sosa
          - Ken Griffey''');
    });

    test('[Example 2.10]', () {
      expectYamlLoads({
        'hr': ['Mark McGwire', 'Sammy Sosa'],
        'rbi': ['Sammy Sosa', 'Ken Griffey']
      }, '''
        ---
        hr:
          - Mark McGwire
          # Following node labeled SS
          - &SS Sammy Sosa
        rbi:
          - *SS # Subsequent occurrence
          - Ken Griffey''');
    });

    test('[Example 2.11]', () {
      var doc = deepEqualsMap();
      doc[['Detroit Tigers', 'Chicago cubs']] = ['2001-07-23'];
      doc[['New York Yankees', 'Atlanta Braves']] = [
        '2001-07-02',
        '2001-08-12',
        '2001-08-14'
      ];
      expectYamlLoads(doc, '''
        ? - Detroit Tigers
          - Chicago cubs
        :
          - 2001-07-23

        ? [ New York Yankees,
            Atlanta Braves ]
        : [ 2001-07-02, 2001-08-12,
            2001-08-14 ]''');
    });

    test('[Example 2.12]', () {
      expectYamlLoads([
        {'item': 'Super Hoop', 'quantity': 1},
        {'item': 'Basketball', 'quantity': 4},
        {'item': 'Big Shoes', 'quantity': 1},
      ], '''
        ---
        # Products purchased
        - item    : Super Hoop
          quantity: 1
        - item    : Basketball
          quantity: 4
        - item    : Big Shoes
          quantity: 1''');
    });
  });

  group('2.3: Scalars', () {
    test('[Example 2.13]', () {
      expectYamlLoads(cleanUpLiteral('''
        \\//||\\/||
        // ||  ||__'''), '''
        # ASCII Art
        --- |
          \\//||\\/||
          // ||  ||__''');
    });

    test('[Example 2.14]', () {
      expectYamlLoads("Mark McGwire's year was crippled by a knee injury.", '''
        --- >
          Mark McGwire's
          year was crippled
          by a knee injury.''');
    });

    test('[Example 2.15]', () {
      expectYamlLoads(cleanUpLiteral('''
        Sammy Sosa completed another fine season with great stats.

          63 Home Runs
          0.288 Batting Average

        What a year!'''), '''
        >
         Sammy Sosa completed another
         fine season with great stats.

           63 Home Runs
           0.288 Batting Average

         What a year!''');
    });

    test('[Example 2.16]', () {
      expectYamlLoads({
        'name': 'Mark McGwire',
        'accomplishment': 'Mark set a major league home run record in 1998.\n',
        'stats': '65 Home Runs\n0.278 Batting Average'
      }, '''
        name: Mark McGwire
        accomplishment: >
          Mark set a major league
          home run record in 1998.
        stats: |
          65 Home Runs
          0.278 Batting Average''');
    });

    test('[Example 2.17]', () {
      expectYamlLoads({
        'unicode': 'Sosa did fine.\u263A',
        'control': '\b1998\t1999\t2000\n',
        'hex esc': '\r\n is \r\n',
        'single': '"Howdy!" he cried.',
        'quoted': " # Not a 'comment'.",
        'tie-fighter': '|\\-*-/|'
      }, """
        unicode: "Sosa did fine.\\u263A"
        control: "\\b1998\\t1999\\t2000\\n"
        hex esc: "\\x0d\\x0a is \\r\\n"

        single: '"Howdy!" he cried.'
        quoted: ' # Not a ''comment''.'
        tie-fighter: '|\\-*-/|'""");
    });

    test('[Example 2.18]', () {
      expectYamlLoads({
        'plain': 'This unquoted scalar spans many lines.',
        'quoted': 'So does this quoted scalar.\n'
      }, '''
        plain:
          This unquoted scalar
          spans many lines.

        quoted: "So does this
          quoted scalar.\\n"''');
    });
  });

  group('2.4: Tags', () {
    test('[Example 2.19]', () {
      expectYamlLoads({
        'canonical': 12345,
        'decimal': 12345,
        'octal': 12,
        'hexadecimal': 12
      }, '''
        canonical: 12345
        decimal: +12345
        octal: 0o14
        hexadecimal: 0xC''');
    });

    test('[Example 2.20]', () {
      expectYamlLoads({
        'canonical': 1230.15,
        'exponential': 1230.15,
        'fixed': 1230.15,
        'negative infinity': -infinity,
        'not a number': nan
      }, '''
        canonical: 1.23015e+3
        exponential: 12.3015e+02
        fixed: 1230.15
        negative infinity: -.inf
        not a number: .NaN''');
    });

    test('[Example 2.21]', () {
      var doc = deepEqualsMap({
        'booleans': [true, false],
        'string': '012345'
      });
      doc[null] = null;
      expectYamlLoads(doc, """
        null:
        booleans: [ true, false ]
        string: '012345'""");
    });

    // Examples 2.22 through 2.26 test custom tag URIs, which this
    // implementation currently doesn't plan to support.
  });

  group('2.5 Full Length Example', () {
    // Example 2.27 tests custom tag URIs, which this implementation currently
    // doesn't plan to support.

    test('[Example 2.28]', () {
      expectYamlStreamLoads([
        {
          'Time': '2001-11-23 15:01:42 -5',
          'User': 'ed',
          'Warning': 'This is an error message for the log file'
        },
        {
          'Time': '2001-11-23 15:02:31 -5',
          'User': 'ed',
          'Warning': 'A slightly different error message.'
        },
        {
          'DateTime': '2001-11-23 15:03:17 -5',
          'User': 'ed',
          'Fatal': 'Unknown variable "bar"',
          'Stack': [
            {
              'file': 'TopClass.py',
              'line': 23,
              'code': 'x = MoreObject("345\\n")\n'
            },
            {'file': 'MoreClass.py', 'line': 58, 'code': 'foo = bar'}
          ]
        }
      ], '''
        ---
        Time: 2001-11-23 15:01:42 -5
        User: ed
        Warning:
          This is an error message
          for the log file
        ---
        Time: 2001-11-23 15:02:31 -5
        User: ed
        Warning:
          A slightly different error
          message.
        ---
        DateTime: 2001-11-23 15:03:17 -5
        User: ed
        Fatal:
          Unknown variable "bar"
        Stack:
          - file: TopClass.py
            line: 23
            code: |
              x = MoreObject("345\\n")
          - file: MoreClass.py
            line: 58
            code: |-
              foo = bar''');
    });
  });

  // Chapter 3 just talks about the structure of loading and dumping Yaml.
  // Chapter 4 explains conventions used in the spec.

  // Chapter 5: Characters
  group('5.1: Character Set', () {
    void expectAllowsCharacter(int charCode) {
      var char = String.fromCharCodes([charCode]);
      expectYamlLoads('The character "$char" is allowed',
          'The character "$char" is allowed');
    }

    void expectAllowsQuotedCharacter(int charCode) {
      var char = String.fromCharCodes([charCode]);
      expectYamlLoads("The character '$char' is allowed",
          '"The character \'$char\' is allowed"');
    }

    void expectDisallowsCharacter(int charCode) {
      var char = String.fromCharCodes([charCode]);
      expectYamlFails('The character "$char" is disallowed');
    }

    test("doesn't include C0 control characters", () {
      expectDisallowsCharacter(0x0);
      expectDisallowsCharacter(0x8);
      expectDisallowsCharacter(0x1F);
    });

    test('includes TAB', () => expectAllowsCharacter(0x9));
    test("doesn't include DEL", () => expectDisallowsCharacter(0x7F));

    test("doesn't include C1 control characters", () {
      expectDisallowsCharacter(0x80);
      expectDisallowsCharacter(0x8A);
      expectDisallowsCharacter(0x9F);
    });

    test('includes NEL', () => expectAllowsCharacter(0x85));

    group('within quoted strings', () {
      test('includes DEL', () => expectAllowsQuotedCharacter(0x7F));
      test('includes C1 control characters', () {
        expectAllowsQuotedCharacter(0x80);
        expectAllowsQuotedCharacter(0x8A);
        expectAllowsQuotedCharacter(0x9F);
      });
    });
  });

  // Skipping section 5.2 (Character Encodings), since at the moment the module
  // assumes that the client code is providing it with a string of the proper
  // encoding.

  group('5.3: Indicator Characters', () {
    test('[Example 5.3]', () {
      expectYamlLoads({
        'sequence': ['one', 'two'],
        'mapping': {'sky': 'blue', 'sea': 'green'}
      }, '''
        sequence:
        - one
        - two
        mapping:
          ? sky
          : blue
          sea : green''');
    });

    test('[Example 5.4]', () {
      expectYamlLoads({
        'sequence': ['one', 'two'],
        'mapping': {'sky': 'blue', 'sea': 'green'}
      }, '''
        sequence: [ one, two, ]
        mapping: { sky: blue, sea: green }''');
    });

    test('[Example 5.5]', () => expectYamlLoads(null, '# Comment only.'));

    // Skipping 5.6 because it uses an undefined tag.

    test('[Example 5.7]', () {
      expectYamlLoads({'literal': 'some\ntext\n', 'folded': 'some text\n'}, '''
        literal: |
          some
          text
        folded: >
          some
          text
        ''');
    });

    test('[Example 5.8]', () {
      expectYamlLoads({'single': 'text', 'double': 'text'}, '''
        single: 'text'
        double: "text"
        ''');
    });

    test('[Example 5.9]', () {
      expectYamlLoads('text', '''
        %YAML 1.2
        --- text''');
    });

    test('[Example 5.10]', () {
      expectYamlFails('commercial-at: @text');
      expectYamlFails('commercial-at: `text');
    });
  });

  group('5.4: Line Break Characters', () {
    group('include', () {
      test('\\n', () => expectYamlLoads([1, 2], indentLiteral('- 1\n- 2')));
      test('\\r', () => expectYamlLoads([1, 2], '- 1\r- 2'));
    });

    group('do not include', () {
      test('form feed', () => expectYamlFails('- 1\x0C- 2'));
      test('NEL', () => expectYamlLoads(['1\x85- 2'], '- 1\x85- 2'));
      test('0x2028', () => expectYamlLoads(['1\u2028- 2'], '- 1\u2028- 2'));
      test('0x2029', () => expectYamlLoads(['1\u2029- 2'], '- 1\u2029- 2'));
    });

    group('in a scalar context must be normalized', () {
      test(
          'from \\r to \\n',
          () => expectYamlLoads(
              ['foo\nbar'], indentLiteral('- |\n  foo\r  bar')));
      test(
          'from \\r\\n to \\n',
          () => expectYamlLoads(
              ['foo\nbar'], indentLiteral('- |\n  foo\r\n  bar')));
    });

    test('[Example 5.11]', () {
      expectYamlLoads(cleanUpLiteral('''
        Line break (no glyph)
        Line break (glyphed)'''), '''
        |
          Line break (no glyph)
          Line break (glyphed)''');
    });
  });

  group('5.5: White Space Characters', () {
    test('[Example 5.12]', () {
      expectYamlLoads({
        'quoted': 'Quoted \t',
        'block': 'void main() {\n\tprintf("Hello, world!\\n");\n}\n'
      }, '''
        # Tabs and spaces
        quoted: "Quoted \t"
        block:\t|
          void main() {
          \tprintf("Hello, world!\\n");
          }
        ''');
    });
  });

  group('5.7: Escaped Characters', () {
    test('[Example 5.13]', () {
      expectYamlLoads(
          'Fun with \x5C '
              '\x22 \x07 \x08 \x1B \x0C '
              '\x0A \x0D \x09 \x0B \x00 '
              '\x20 \xA0 \x85 \u2028 \u2029 '
              'A A A',
          '''
        "Fun with \\\\
        \\" \\a \\b \\e \\f \\
        \\n \\r \\t \\v \\0 \\
        \\  \\_ \\N \\L \\P \\
        \\x41 \\u0041 \\U00000041"''');
    });

    test('[Example 5.14]', () {
      expectYamlFails('Bad escape: "\\c"');
      expectYamlFails('Bad escape: "\\xq-"');
    });
  });

  // Chapter 6: Basic Structures
  group('6.1: Indentation Spaces', () {
    test('may not include TAB characters', () {
      expectYamlFails('''
        -
        \t- foo
        \t- bar''');
    });

    test('must be the same for all sibling nodes', () {
      expectYamlFails('''
        -
          - foo
         - bar''');
    });

    test('may be different for the children of sibling nodes', () {
      expectYamlLoads([
        ['foo'],
        ['bar']
      ], '''
        -
          - foo
        -
         - bar''');
    });

    test('[Example 6.1]', () {
      expectYamlLoads({
        'Not indented': {
          'By one space': 'By four\n  spaces\n',
          'Flow style': ['By two', 'Also by two', 'Still by two']
        }
      }, '''
          # Leading comment line spaces are
           # neither content nor indentation.
            
        Not indented:
         By one space: |
            By four
              spaces
         Flow style: [    # Leading spaces
           By two,        # in flow style
          Also by two,    # are neither
          \tStill by two   # content nor
            ]             # indentation.''');
    });

    test('[Example 6.2]', () {
      expectYamlLoads({
        'a': [
          'b',
          ['c', 'd']
        ]
      }, '''
        ? a
        : -\tb
          -  -\tc
             - d''');
    });
  });

  group('6.2: Separation Spaces', () {
    test('[Example 6.3]', () {
      expectYamlLoads([
        {'foo': 'bar'},
        ['baz', 'baz']
      ], '''
        - foo:\t bar
        - - baz
          -\tbaz''');
    });
  });

  group('6.3: Line Prefixes', () {
    test('[Example 6.4]', () {
      expectYamlLoads({
        'plain': 'text lines',
        'quoted': 'text lines',
        'block': 'text\n \tlines\n'
      }, '''
        plain: text
          lines
        quoted: "text
          \tlines"
        block: |
          text
           \tlines
        ''');
    });
  });

  group('6.4: Empty Lines', () {
    test('[Example 6.5]', () {
      expectYamlLoads({
        'Folding': 'Empty line\nas a line feed',
        'Chomping': 'Clipped empty lines\n',
      }, '''
        Folding:
          "Empty line
           \t
          as a line feed"
        Chomping: |
          Clipped empty lines
         ''');
    });
  });

  group('6.5: Line Folding', () {
    test('[Example 6.6]', () {
      expectYamlLoads('trimmed\n\n\nas space', '''
        >-
          trimmed
          
         

          as
          space
        ''');
    });

    test('[Example 6.7]', () {
      expectYamlLoads('foo \n\n\t bar\n\nbaz\n', '''
        >
          foo 
         
          \t bar

          baz
        ''');
    });

    test('[Example 6.8]', () {
      expectYamlLoads(' foo\nbar\nbaz ', '''
        "
          foo 
         
          \t bar

          baz
        "''');
    });
  });

  group('6.6: Comments', () {
    test('must be separated from other tokens by white space characters', () {
      expectYamlLoads('foo#bar', 'foo#bar');
      expectYamlLoads('foo:#bar', 'foo:#bar');
      expectYamlLoads('-#bar', '-#bar');
    });

    test('[Example 6.9]', () {
      expectYamlLoads({'key': 'value'}, '''
        key:    # Comment
          value''');
    });

    group('outside of scalar content', () {
      test('may appear on a line of their own', () {
        expectYamlLoads([1, 2], '''
        - 1
        # Comment
        - 2''');
      });

      test('are independent of indentation level', () {
        expectYamlLoads([
          [1, 2]
        ], '''
        -
          - 1
         # Comment
          - 2''');
      });

      test('include lines containing only white space characters', () {
        expectYamlLoads([1, 2], '''
        - 1
          \t  
        - 2''');
      });
    });

    group('within scalar content', () {
      test('may not appear on a line of their own', () {
        expectYamlLoads(['foo\n# not comment\nbar\n'], '''
        - |
          foo
          # not comment
          bar
        ''');
      });

      test("don't include lines containing only white space characters", () {
        expectYamlLoads(['foo\n  \t   \nbar\n'], '''
        - |
          foo
            \t   
          bar
        ''');
      });
    });

    test('[Example 6.10]', () {
      expectYamlLoads(null, '''
          # Comment
           
        ''');
    });

    test('[Example 6.11]', () {
      expectYamlLoads({'key': 'value'}, '''
        key:    # Comment
                # lines
          value
        ''');
    });

    group('ending a block scalar header', () {
      test('may not be followed by additional comment lines', () {
        expectYamlLoads(['# not comment\nfoo\n'], '''
        - | # comment
            # not comment
            foo
        ''');
      });
    });
  });

  group('6.7: Separation Lines', () {
    test('may not be used within implicit keys', () {
      expectYamlFails('''
        [1,
         2]: 3''');
    });

    test('[Example 6.12]', () {
      var doc = deepEqualsMap();
      doc[{'first': 'Sammy', 'last': 'Sosa'}] = {'hr': 65, 'avg': 0.278};
      expectYamlLoads(doc, '''
        { first: Sammy, last: Sosa }:
        # Statistics:
          hr:  # Home runs
             65
          avg: # Average
           0.278''');
    });
  });

  group('6.8: Directives', () {
    // TODO(nweiz): assert that this produces a warning
    test('[Example 6.13]', () {
      expectYamlLoads('foo', '''
        %FOO  bar baz # Should be ignored
                      # with a warning.
        --- "foo"''');
    });

    // TODO(nweiz): assert that this produces a warning.
    test('[Example 6.14]', () {
      expectYamlLoads('foo', '''
        %YAML 1.3 # Attempt parsing
                   # with a warning
        ---
        "foo"''');
    });

    test('[Example 6.15]', () {
      expectYamlFails('''
        %YAML 1.2
        %YAML 1.1
        foo''');
    });

    test('[Example 6.16]', () {
      expectYamlLoads('foo', '''
        %TAG !yaml! tag:yaml.org,2002:
        ---
        !yaml!str "foo"''');
    });

    test('[Example 6.17]', () {
      expectYamlFails('''
        %TAG ! !foo
        %TAG ! !foo
        bar''');
    });

    // Examples 6.18 through 6.22 test custom tag URIs, which this
    // implementation currently doesn't plan to support.
  });

  group('6.9: Node Properties', () {
    test('may be specified in any order', () {
      expectYamlLoads(['foo', 'bar'], '''
        - !!str &a1 foo
        - &a2 !!str bar''');
    });

    test('[Example 6.23]', () {
      expectYamlLoads({'foo': 'bar', 'baz': 'foo'}, '''
        !!str &a1 "foo":
          !!str bar
        &a2 baz : *a1''');
    });

    // Example 6.24 tests custom tag URIs, which this implementation currently
    // doesn't plan to support.

    test('[Example 6.25]', () {
      expectYamlFails('- !<!> foo');
      expectYamlFails('- !<\$:?> foo');
    });

    // Examples 6.26 and 6.27 test custom tag URIs, which this implementation
    // currently doesn't plan to support.

    test('[Example 6.28]', () {
      expectYamlLoads(['12', 12, '12'], '''
        # Assuming conventional resolution:
        - "12"
        - 12
        - ! 12''');
    });

    test('[Example 6.29]', () {
      expectYamlLoads(
          {'First occurrence': 'Value', 'Second occurrence': 'Value'}, '''
        First occurrence: &anchor Value
        Second occurrence: *anchor''');
    });
  });

  // Chapter 7: Flow Styles
  group('7.1: Alias Nodes', () {
    test("must not use an anchor that doesn't previously occur", () {
      expectYamlFails('''
        - *anchor
        - &anchor foo''');
    });

    test("don't have to exist for a given anchor node", () {
      expectYamlLoads(['foo'], '- &anchor foo');
    });

    group('must not specify', () {
      test('tag properties', () => expectYamlFails('''
        - &anchor foo
        - !str *anchor'''));

      test('anchor properties', () => expectYamlFails('''
        - &anchor foo
        - &anchor2 *anchor'''));

      test('content', () => expectYamlFails('''
        - &anchor foo
        - *anchor bar'''));
    });

    test('must preserve structural equality', () {
      var doc = loadYaml(cleanUpLiteral('''
        anchor: &anchor [a, b, c]
        alias: *anchor'''));
      var anchorList = doc['anchor'];
      var aliasList = doc['alias'];
      expect(anchorList, same(aliasList));

      doc = loadYaml(cleanUpLiteral('''
        ? &anchor [a, b, c]
        : ? *anchor
          : bar'''));
      anchorList = doc.keys.first;
      aliasList = doc[['a', 'b', 'c']].keys.first;
      expect(anchorList, same(aliasList));
    });

    test('[Example 7.1]', () {
      expectYamlLoads({
        'First occurrence': 'Foo',
        'Second occurrence': 'Foo',
        'Override anchor': 'Bar',
        'Reuse anchor': 'Bar',
      }, '''
        First occurrence: &anchor Foo
        Second occurrence: *anchor
        Override anchor: &anchor Bar
        Reuse anchor: *anchor''');
    });
  });

  group('7.2: Empty Nodes', () {
    test('[Example 7.2]', () {
      expectYamlLoads({'foo': '', '': 'bar'}, '''
        {
          foo : !!str,
          !!str : bar,
        }''');
    });

    test('[Example 7.3]', () {
      var doc = deepEqualsMap({'foo': null});
      doc[null] = 'bar';
      expectYamlLoads(doc, '''
        {
          ? foo :,
          : bar,
        }''');
    });
  });

  group('7.3: Flow Scalar Styles', () {
    test('[Example 7.4]', () {
      expectYamlLoads({
        'implicit block key': [
          {'implicit flow key': 'value'}
        ]
      }, '''
        "implicit block key" : [
          "implicit flow key" : value,
         ]''');
    });

    test('[Example 7.5]', () {
      expectYamlLoads(
          'folded to a space,\nto a line feed, or \t \tnon-content', '''
        "folded 
        to a space,\t
         
        to a line feed, or \t\\
         \\ \tnon-content"''');
    });

    test('[Example 7.6]', () {
      expectYamlLoads(' 1st non-empty\n2nd non-empty 3rd non-empty ', '''
        " 1st non-empty

         2nd non-empty 
        \t3rd non-empty "''');
    });

    test('[Example 7.7]', () {
      expectYamlLoads("here's to \"quotes\"", "'here''s to \"quotes\"'");
    });

    test('[Example 7.8]', () {
      expectYamlLoads({
        'implicit block key': [
          {'implicit flow key': 'value'}
        ]
      }, """
        'implicit block key' : [
          'implicit flow key' : value,
         ]""");
    });

    test('[Example 7.9]', () {
      expectYamlLoads(' 1st non-empty\n2nd non-empty 3rd non-empty ', """
        ' 1st non-empty

         2nd non-empty 
        \t3rd non-empty '""");
    });

    test('[Example 7.10]', () {
      expectYamlLoads([
        '::vector',
        ': - ()',
        'Up, up, and away!',
        -123,
        'http://example.com/foo#bar',
        [
          '::vector',
          ': - ()',
          'Up, up, and away!',
          -123,
          'http://example.com/foo#bar'
        ]
      ], '''
        # Outside flow collection:
        - ::vector
        - ": - ()"
        - Up, up, and away!
        - -123
        - http://example.com/foo#bar
        # Inside flow collection:
        - [ ::vector,
          ": - ()",
          "Up, up, and away!",
          -123,
          http://example.com/foo#bar ]''');
    });

    test('[Example 7.11]', () {
      expectYamlLoads({
        'implicit block key': [
          {'implicit flow key': 'value'}
        ]
      }, '''
        implicit block key : [
          implicit flow key : value,
         ]''');
    });

    test('[Example 7.12]', () {
      expectYamlLoads('1st non-empty\n2nd non-empty 3rd non-empty', '''
        1st non-empty

         2nd non-empty 
        \t3rd non-empty''');
    });
  });

  group('7.4: Flow Collection Styles', () {
    test('[Example 7.13]', () {
      expectYamlLoads([
        ['one', 'two'],
        ['three', 'four']
      ], '''
        - [ one, two, ]
        - [three ,four]''');
    });

    test('[Example 7.14]', () {
      expectYamlLoads([
        'double quoted',
        'single quoted',
        'plain text',
        ['nested'],
        {'single': 'pair'}
      ], """
        [
        "double
         quoted", 'single
                   quoted',
        plain
         text, [ nested ],
        single: pair,
        ]""");
    });

    test('[Example 7.15]', () {
      expectYamlLoads([
        {'one': 'two', 'three': 'four'},
        {'five': 'six', 'seven': 'eight'},
      ], '''
        - { one : two , three: four , }
        - {five: six,seven : eight}''');
    });

    test('[Example 7.16]', () {
      var doc = deepEqualsMap({'explicit': 'entry', 'implicit': 'entry'});
      doc[null] = null;
      expectYamlLoads(doc, '''
        {
        ? explicit: entry,
        implicit: entry,
        ?
        }''');
    });

    test('[Example 7.17]', () {
      var doc = deepEqualsMap({
        'unquoted': 'separate',
        'http://foo.com': null,
        'omitted value': null
      });
      doc[null] = 'omitted key';
      expectYamlLoads(doc, '''
        {
        unquoted : "separate",
        http://foo.com,
        omitted value:,
        : omitted key,
        }''');
    });

    test('[Example 7.18]', () {
      expectYamlLoads(
          {'adjacent': 'value', 'readable': 'value', 'empty': null}, '''
        {
        "adjacent":value,
        "readable": value,
        "empty":
        }''');
    });

    test('[Example 7.19]', () {
      expectYamlLoads([
        {'foo': 'bar'}
      ], '''
        [
        foo: bar
        ]''');
    });

    test('[Example 7.20]', () {
      expectYamlLoads([
        {'foo bar': 'baz'}
      ], '''
        [
        ? foo
         bar : baz
        ]''');
    });

    test('[Example 7.21]', () {
      var el1 = deepEqualsMap();
      el1[null] = 'empty key entry';

      var el2 = deepEqualsMap();
      el2[{'JSON': 'like'}] = 'adjacent';

      expectYamlLoads([
        [
          {'YAML': 'separate'}
        ],
        [el1],
        [el2]
      ], '''
        - [ YAML : separate ]
        - [ : empty key entry ]
        - [ {JSON: like}:adjacent ]''');
    });

    // TODO(nweiz): enable this when we throw an error for long or multiline
    // keys.
    // test('[Example 7.22]', () {
    //   expectYamlFails(
    //     """
    //     [ foo
    //      bar: invalid ]""");
    //
    //   var dotList = new List.filled(1024, ' ');
    //   var dots = dotList.join();
    //   expectYamlFails('[ "foo...$dots...bar": invalid ]');
    // });
  });

  group('7.5: Flow Nodes', () {
    test('[Example 7.23]', () {
      expectYamlLoads([
        ['a', 'b'],
        {'a': 'b'},
        'a',
        'b',
        'c'
      ], '''
        - [ a, b ]
        - { a: b }
        - 'a'
        - 'b'
        - c''');
    });

    test('[Example 7.24]', () {
      expectYamlLoads(['a', 'b', 'c', 'c', ''], '''
        - !!str "a"
        - 'b'
        - &anchor "c"
        - *anchor
        - !!str''');
    });
  });

  // Chapter 8: Block Styles
  group('8.1: Block Scalar Styles', () {
    test('[Example 8.1]', () {
      expectYamlLoads(['literal\n', ' folded\n', 'keep\n\n', ' strip'], '''
        - | # Empty header
         literal
        - >1 # Indentation indicator
          folded
        - |+ # Chomping indicator
         keep

        - >1- # Both indicators
          strip''');
    });

    test('[Example 8.2]', () {
      // Note: in the spec, the fourth element in this array is listed as
      // "\t detected\n", not "\t\ndetected\n". However, I'm reasonably
      // confident that "\t\ndetected\n" is correct when parsed according to the
      // rest of the spec.
      expectYamlLoads(
          ['detected\n', '\n\n# detected\n', ' explicit\n', '\t\ndetected\n'],
          '''
        - |
         detected
        - >


          # detected
        - |1
          explicit
        - >
         \t
         detected
        ''');
    });

    test('[Example 8.3]', () {
      expectYamlFails('''
        - |
          
         text''');

      expectYamlFails('''
        - >
          text
         text''');

      expectYamlFails('''
        - |2
         text''');
    });

    test('[Example 8.4]', () {
      expectYamlLoads({'strip': 'text', 'clip': 'text\n', 'keep': 'text\n'}, '''
        strip: |-
          text
        clip: |
          text
        keep: |+
          text
        ''');
    });

    test('[Example 8.5]', () {
      // This example in the spec only includes a single newline in the "keep"
      // value, but as far as I can tell that's not how it's supposed to be
      // parsed according to the rest of the spec.
      expectYamlLoads(
          {'strip': '# text', 'clip': '# text\n', 'keep': '# text\n\n'}, '''
         # Strip
          # Comments:
        strip: |-
          # text
          
         # Clip
          # comments:

        clip: |
          # text
         
         # Keep
          # comments:

        keep: |+
          # text

         # Trail
          # comments.
        ''');
    });

    test('[Example 8.6]', () {
      expectYamlLoads({'strip': '', 'clip': '', 'keep': '\n'}, '''
        strip: >-

        clip: >

        keep: |+

        ''');
    });

    test('[Example 8.7]', () {
      expectYamlLoads('literal\n\ttext\n', '''
        |
         literal
         \ttext
        ''');
    });

    test('[Example 8.8]', () {
      expectYamlLoads('\n\nliteral\n \n\ntext\n', '''
        |
         
          
          literal
           
          
          text

         # Comment''');
    });

    test('[Example 8.9]', () {
      expectYamlLoads('folded text\n', '''
        >
         folded
         text
        ''');
    });

    test('[Example 8.10]', () {
      expectYamlLoads(cleanUpLiteral('''

        folded line
        next line
          * bullet

          * list
          * lines

        last line
        '''), '''
        >

         folded
         line

         next
         line
           * bullet

           * list
           * lines

         last
         line

        # Comment''');
    });

    // Examples 8.11 through 8.13 are duplicates of 8.10.
  });

  group('8.2: Block Collection Styles', () {
    test('[Example 8.14]', () {
      expectYamlLoads({
        'block sequence': [
          'one',
          {'two': 'three'}
        ]
      }, '''
        block sequence:
          - one
          - two : three''');
    });

    test('[Example 8.15]', () {
      expectYamlLoads([
        null,
        'block node\n',
        ['one', 'two'],
        {'one': 'two'}
      ], '''
        - # Empty
        - |
         block node
        - - one # Compact
          - two # sequence
        - one: two # Compact mapping''');
    });

    test('[Example 8.16]', () {
      expectYamlLoads({
        'block mapping': {'key': 'value'}
      }, '''
        block mapping:
         key: value''');
    });

    test('[Example 8.17]', () {
      expectYamlLoads({
        'explicit key': null,
        'block key\n': ['one', 'two']
      }, '''
        ? explicit key # Empty value
        ? |
          block key
        : - one # Explicit compact
          - two # block value''');
    });

    test('[Example 8.18]', () {
      var doc = deepEqualsMap({
        'plain key': 'in-line value',
        'quoted key': ['entry']
      });
      doc[null] = null;
      expectYamlLoads(doc, '''
        plain key: in-line value
        : # Both empty
        "quoted key":
        - entry''');
    });

    test('[Example 8.19]', () {
      var el = deepEqualsMap();
      el[{'earth': 'blue'}] = {'moon': 'white'};
      expectYamlLoads([
        {'sun': 'yellow'},
        el
      ], '''
        - sun: yellow
        - ? earth: blue
          : moon: white''');
    });

    test('[Example 8.20]', () {
      expectYamlLoads([
        'flow in block',
        'Block scalar\n',
        {'foo': 'bar'}
      ], '''
        -
          "flow in block"
        - >
         Block scalar
        - !!map # Block collection
          foo : bar''');
    });

    test('[Example 8.21]', () {
      // The spec doesn't include a newline after "value" in the parsed map, but
      // the block scalar is clipped so it should be retained.
      expectYamlLoads({'literal': 'value\n', 'folded': 'value'}, '''
        literal: |2
          value
        folded:
           !!str
          >1
         value''');
    });

    test('[Example 8.22]', () {
      expectYamlLoads({
        'sequence': [
          'entry',
          ['nested']
        ],
        'mapping': {'foo': 'bar'}
      }, '''
        sequence: !!seq
        - entry
        - !!seq
         - nested
        mapping: !!map
         foo: bar''');
    });
  });

  // Chapter 9: YAML Character Stream
  group('9.1: Documents', () {
    // Example 9.1 tests the use of a BOM, which this implementation currently
    // doesn't plan to support.

    test('[Example 9.2]', () {
      expectYamlLoads('Document', '''
        %YAML 1.2
        ---
        Document
        ... # Suffix''');
    });

    test('[Example 9.3]', () {
      // The spec example indicates that the comment after "%!PS-Adobe-2.0"
      // should be stripped, which would imply that that line is not part of the
      // literal defined by the "|". The rest of the spec is ambiguous on this
      // point; the allowable indentation for non-indented literal content is
      // not clearly explained. However, if both the "|" and the text were
      // indented the same amount, the text would be part of the literal, which
      // implies that the spec's parse of this document is incorrect.
      expectYamlStreamLoads(
          ['Bare document', '%!PS-Adobe-2.0 # Not the first line\n'], '''
        Bare
        document
        ...
        # No document
        ...
        |
        %!PS-Adobe-2.0 # Not the first line
        ''');
    });

    test('[Example 9.4]', () {
      expectYamlStreamLoads([
        {'matches %': 20},
        null
      ], '''
        ---
        { matches
        % : 20 }
        ...
        ---
        # Empty
        ...''');
    });

    test('[Example 9.5]', () {
      // The spec doesn't have a space between the second
      // "YAML" and "1.2", but this seems to be a typo.
      expectYamlStreamLoads(['%!PS-Adobe-2.0\n', null], '''
        %YAML 1.2
        --- |
        %!PS-Adobe-2.0
        ...
        %YAML 1.2
        ---
        # Empty
        ...''');
    });

    test('[Example 9.6]', () {
      expectYamlStreamLoads([
        'Document',
        null,
        {'matches %': 20}
      ], '''
        Document
        ---
        # Empty
        ...
        %YAML 1.2
        ---
        matches %: 20''');
    });
  });

  // Chapter 10: Recommended Schemas
  group('10.1: Failsafe Schema', () {
    test('[Example 10.1]', () {
      expectYamlLoads({
        'Block style': {
          'Clark': 'Evans',
          'Ingy': 'döt Net',
          'Oren': 'Ben-Kiki'
        },
        'Flow style': {'Clark': 'Evans', 'Ingy': 'döt Net', 'Oren': 'Ben-Kiki'}
      }, '''
        Block style: !!map
          Clark : Evans
          Ingy  : döt Net
          Oren  : Ben-Kiki

        Flow style: !!map { Clark: Evans, Ingy: döt Net, Oren: Ben-Kiki }''');
    });

    test('[Example 10.2]', () {
      expectYamlLoads({
        'Block style': ['Clark Evans', 'Ingy döt Net', 'Oren Ben-Kiki'],
        'Flow style': ['Clark Evans', 'Ingy döt Net', 'Oren Ben-Kiki']
      }, '''
        Block style: !!seq
        - Clark Evans
        - Ingy döt Net
        - Oren Ben-Kiki

        Flow style: !!seq [ Clark Evans, Ingy döt Net, Oren Ben-Kiki ]''');
    });

    test('[Example 10.3]', () {
      expectYamlLoads({
        'Block style': 'String: just a theory.',
        'Flow style': 'String: just a theory.'
      }, '''
        Block style: !!str |-
          String: just a theory.

        Flow style: !!str "String: just a theory."''');
    });
  });

  group('10.2: JSON Schema', () {
    // test('[Example 10.4]', () {
    //   var doc = deepEqualsMap({"key with null value": null});
    //   doc[null] = "value for null key";
    //   expectYamlStreamLoads(doc,
    //     """
    //     !!null null: value for null key
    //     key with null value: !!null null""");
    // });

    // test('[Example 10.5]', () {
    //   expectYamlStreamLoads({
    //     "YAML is a superset of JSON": true,
    //     "Pluto is a planet": false
    //   },
    //     """
    //     YAML is a superset of JSON: !!bool true
    //     Pluto is a planet: !!bool false""");
    // });

    // test('[Example 10.6]', () {
    //   expectYamlStreamLoads({
    //     "negative": -12,
    //     "zero": 0,
    //     "positive": 34
    //   },
    //     """
    //     negative: !!int -12
    //     zero: !!int 0
    //     positive: !!int 34""");
    // });

    // test('[Example 10.7]', () {
    //   expectYamlStreamLoads({
    //     "negative": -1,
    //     "zero": 0,
    //     "positive": 23000,
    //     "infinity": infinity,
    //     "not a number": nan
    //   },
    //     """
    //     negative: !!float -1
    //     zero: !!float 0
    //     positive: !!float 2.3e4
    //     infinity: !!float .inf
    //     not a number: !!float .nan""");
    // });

    // test('[Example 10.8]', () {
    //   expectYamlStreamLoads({
    //     "A null": null,
    //     "Booleans": [true, false],
    //     "Integers": [0, -0, 3, -19],
    //     "Floats": [0, 0, 12000, -200000],
    //     // Despite being invalid in the JSON schema, these values are valid in
    //     // the core schema which this implementation supports.
    //     "Invalid": [ true, null, 7, 0x3A, 12.3]
    //   },
    //     """
    //     A null: null
    //     Booleans: [ true, false ]
    //     Integers: [ 0, -0, 3, -19 ]
    //     Floats: [ 0., -0.0, 12e03, -2E+05 ]
    //     Invalid: [ True, Null, 0o7, 0x3A, +12.3 ]""");
    // });
  });

  group('10.3: Core Schema', () {
    test('[Example 10.9]', () {
      expectYamlLoads({
        'A null': null,
        'Also a null': null,
        'Not a null': '',
        'Booleans': [true, true, false, false],
        'Integers': [0, 7, 0x3A, -19],
        'Floats': [0, 0, 0.5, 12000, -200000],
        'Also floats': [infinity, -infinity, infinity, nan]
      }, '''
        A null: null
        Also a null: # Empty
        Not a null: ""
        Booleans: [ true, True, false, FALSE ]
        Integers: [ 0, 0o7, 0x3A, -19 ]
        Floats: [ 0., -0.0, .5, +12e03, -2E+05 ]
        Also floats: [ .inf, -.Inf, +.INF, .NAN ]''');
    });
  });

  test('preserves key order', () {
    const keys = ['a', 'b', 'c', 'd', 'e', 'f'];
    var sanityCheckCount = 0;
    for (var permutation in _generatePermutations(keys)) {
      final yaml = permutation.map((key) => '$key: value').join('\n');
      expect(loadYaml(yaml).keys.toList(), permutation);
      sanityCheckCount++;
    }
    final expectedPermutationCount =
        List.generate(keys.length, (i) => i + 1).reduce((n, i) => n * i);
    expect(sanityCheckCount, expectedPermutationCount);
  });
}

Iterable<List<String>> _generatePermutations(List<String> keys) sync* {
  if (keys.length <= 1) {
    yield keys;
    return;
  }
  for (var i = 0; i < keys.length; i++) {
    final first = keys[i];
    final rest = <String>[...keys.sublist(0, i), ...keys.sublist(i + 1)];
    for (var subPermutation in _generatePermutations(rest)) {
      yield <String>[first, ...subPermutation];
    }
  }
}
