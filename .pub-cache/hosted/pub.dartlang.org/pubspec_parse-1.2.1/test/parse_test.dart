// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package
library parse_test;

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('minimal set values', () {
    final value = parse(defaultPubspec);
    expect(value.name, 'sample');
    expect(value.version, isNull);
    expect(value.publishTo, isNull);
    expect(value.description, isNull);
    expect(value.homepage, isNull);
    expect(value.author, isNull);
    expect(value.authors, isEmpty);
    expect(
      value.environment,
      {'sdk': VersionConstraint.parse('>=2.7.0 <3.0.0')},
    );
    expect(value.documentation, isNull);
    expect(value.dependencies, isEmpty);
    expect(value.devDependencies, isEmpty);
    expect(value.dependencyOverrides, isEmpty);
    expect(value.flutter, isNull);
    expect(value.repository, isNull);
    expect(value.issueTracker, isNull);
    expect(value.screenshots, isEmpty);
  });

  test('all fields set', () {
    final version = Version.parse('1.2.3');
    final sdkConstraint = VersionConstraint.parse('>=2.0.0-dev.54 <3.0.0');
    final value = parse({
      'name': 'sample',
      'version': version.toString(),
      'publish_to': 'none',
      'author': 'name@example.com',
      'environment': {'sdk': sdkConstraint.toString()},
      'description': 'description',
      'homepage': 'homepage',
      'documentation': 'documentation',
      'repository': 'https://github.com/example/repo',
      'issue_tracker': 'https://github.com/example/repo/issues',
      'funding': [
        'https://patreon.com/example',
      ],
      'screenshots': [
        {'description': 'my screenshot', 'path': 'path/to/screenshot'}
      ],
    });
    expect(value.name, 'sample');
    expect(value.version, version);
    expect(value.publishTo, 'none');
    expect(value.description, 'description');
    expect(value.homepage, 'homepage');
    expect(value.author, 'name@example.com');
    expect(value.authors, ['name@example.com']);
    expect(value.environment, hasLength(1));
    expect(value.environment, containsPair('sdk', sdkConstraint));
    expect(value.documentation, 'documentation');
    expect(value.dependencies, isEmpty);
    expect(value.devDependencies, isEmpty);
    expect(value.dependencyOverrides, isEmpty);
    expect(value.repository, Uri.parse('https://github.com/example/repo'));
    expect(
      value.issueTracker,
      Uri.parse('https://github.com/example/repo/issues'),
    );
    expect(value.funding, hasLength(1));
    expect(value.funding!.single.toString(), 'https://patreon.com/example');
    expect(value.screenshots, hasLength(1));
    expect(value.screenshots!.first.description, 'my screenshot');
    expect(value.screenshots!.first.path, 'path/to/screenshot');
  });

  test('environment values can be null', () {
    final value = parse(
      {
        'name': 'sample',
        'environment': {
          'sdk': '>=2.7.0 <3.0.0',
          'bob': null,
        }
      },
      skipTryPub: true,
    );
    expect(value.name, 'sample');
    expect(value.environment, hasLength(2));
    expect(value.environment, containsPair('bob', isNull));
  });

  group('publish_to', () {
    for (var entry in {
      42: r'''
line 3, column 16: Unsupported value for "publish_to". type 'int' is not a subtype of type 'String?' in type cast
  ╷
3 │  "publish_to": 42
  │                ^^
  ╵''',
      '##not a uri!': r'''
line 3, column 16: Unsupported value for "publish_to". Must be an http or https URL.
  ╷
3 │  "publish_to": "##not a uri!"
  │                ^^^^^^^^^^^^^^
  ╵''',
      '/cool/beans': r'''
line 3, column 16: Unsupported value for "publish_to". Must be an http or https URL.
  ╷
3 │  "publish_to": "/cool/beans"
  │                ^^^^^^^^^^^^^
  ╵''',
      'file:///Users/kevmoo/': r'''
line 3, column 16: Unsupported value for "publish_to". Must be an http or https URL.
  ╷
3 │  "publish_to": "file:///Users/kevmoo/"
  │                ^^^^^^^^^^^^^^^^^^^^^^^
  ╵''',
    }.entries) {
      test('cannot be `${entry.key}`', () {
        expectParseThrows(
          {'name': 'sample', 'publish_to': entry.key},
          entry.value,
          skipTryPub: true,
        );
      });
    }

    for (var entry in {
      null: null,
      'http': 'http://example.com',
      'https': 'https://example.com',
      'none': 'none'
    }.entries) {
      test('can be ${entry.key}', () {
        final value = parse({
          ...defaultPubspec,
          'publish_to': entry.value,
        });
        expect(value.publishTo, entry.value);
      });
    }
  });

  group('author, authors', () {
    test('one author', () {
      final value = parse({
        ...defaultPubspec,
        'author': 'name@example.com',
      });
      expect(value.author, 'name@example.com');
      expect(value.authors, ['name@example.com']);
    });

    test('one author, via authors', () {
      final value = parse({
        ...defaultPubspec,
        'authors': ['name@example.com']
      });
      expect(value.author, 'name@example.com');
      expect(value.authors, ['name@example.com']);
    });

    test('many authors', () {
      final value = parse({
        ...defaultPubspec,
        'authors': ['name@example.com', 'name2@example.com']
      });
      expect(value.author, isNull);
      expect(value.authors, ['name@example.com', 'name2@example.com']);
    });

    test('author and authors', () {
      final value = parse({
        ...defaultPubspec,
        'author': 'name@example.com',
        'authors': ['name2@example.com']
      });
      expect(value.author, isNull);
      expect(value.authors, ['name@example.com', 'name2@example.com']);
    });

    test('duplicate author values', () {
      final value = parse({
        ...defaultPubspec,
        'author': 'name@example.com',
        'authors': ['name@example.com', 'name@example.com']
      });
      expect(value.author, 'name@example.com');
      expect(value.authors, ['name@example.com']);
    });

    test('flutter', () {
      final value = parse({
        ...defaultPubspec,
        'flutter': {'key': 'value'},
      });
      expect(value.flutter, {'key': 'value'});
    });
  });

  group('invalid', () {
    test('null', () {
      expectParseThrows(
        null,
        r'''
line 1, column 1: Not a map
  ╷
1 │ null
  │ ^^^^
  ╵''',
      );
    });
    test('empty string', () {
      expectParseThrows(
        '',
        r'''
line 1, column 1: Not a map
  ╷
1 │ ""
  │ ^^
  ╵''',
      );
    });
    test('array', () {
      expectParseThrows(
        [],
        r'''
line 1, column 1: Not a map
  ╷
1 │ []
  │ ^^
  ╵''',
      );
    });

    test('missing name', () {
      expectParseThrows(
        {},
        r'''
line 1, column 1: Missing key "name". type 'Null' is not a subtype of type 'String' in type cast
  ╷
1 │ {}
  │ ^^
  ╵''',
      );
    });

    test('null name value', () {
      expectParseThrows(
        {'name': null},
        r'''
line 2, column 10: Unsupported value for "name". type 'Null' is not a subtype of type 'String' in type cast
  ╷
2 │  "name": null
  │          ^^^^
  ╵''',
      );
    });

    test('empty name value', () {
      expectParseThrows(
        {'name': ''},
        r'''
line 2, column 10: Unsupported value for "name". "name" cannot be empty.
  ╷
2 │  "name": ""
  │          ^^
  ╵''',
      );
    });

    test('"dart" is an invalid environment key', () {
      expectParseThrows(
        {
          'name': 'sample',
          'environment': {'dart': 'cool'}
        },
        r'''
line 4, column 3: Use "sdk" to for Dart SDK constraints.
  ╷
4 │   "dart": "cool"
  │   ^^^^^^
  ╵''',
      );
    });

    test('environment values cannot be int', () {
      expectParseThrows(
        {
          'name': 'sample',
          'environment': {'sdk': 42}
        },
        r'''
line 4, column 10: Unsupported value for "sdk". `42` is not a String.
  ╷
4 │     "sdk": 42
  │ ┌──────────^
5 │ │  }
  │ └─^
  ╵''',
      );
    });

    test('version', () {
      expectParseThrows(
        {'name': 'sample', 'version': 'invalid'},
        r'''
line 3, column 13: Unsupported value for "version". Could not parse "invalid".
  ╷
3 │  "version": "invalid"
  │             ^^^^^^^^^
  ╵''',
      );
    });

    test('invalid environment value', () {
      expectParseThrows(
        {
          'name': 'sample',
          'environment': {'sdk': 'silly'}
        },
        r'''
line 4, column 10: Unsupported value for "sdk". Could not parse version "silly". Unknown text at "silly".
  ╷
4 │   "sdk": "silly"
  │          ^^^^^^^
  ╵''',
      );
    });

    test('bad repository url', () {
      expectParseThrows(
        {
          ...defaultPubspec,
          'repository': {'x': 'y'},
        },
        r'''
line 6, column 16: Unsupported value for "repository". type 'YamlMap' is not a subtype of type 'String' in type cast
  ╷
6 │    "repository": {
  │ ┌────────────────^
7 │ │   "x": "y"
8 │ └  }
  ╵''',
        skipTryPub: true,
      );
    });

    test('bad issue_tracker url', () {
      expectParseThrows(
        {
          'name': 'sample',
          'issue_tracker': {'x': 'y'},
        },
        r'''
line 3, column 19: Unsupported value for "issue_tracker". type 'YamlMap' is not a subtype of type 'String' in type cast
  ╷
3 │    "issue_tracker": {
  │ ┌───────────────────^
4 │ │   "x": "y"
5 │ └  }
  ╵''',
        skipTryPub: true,
      );
    });
  });

  group('funding', () {
    test('not a list', () {
      expectParseThrows(
        {
          ...defaultPubspec,
          'funding': 1,
        },
        r'''
line 6, column 13: Unsupported value for "funding". type 'int' is not a subtype of type 'List<dynamic>?' in type cast
  ╷
6 │  "funding": 1
  │             ^
  ╵''',
        skipTryPub: true,
      );
    });

    test('not an uri', () {
      expectParseThrows(
        {
          ...defaultPubspec,
          'funding': [1],
        },
        r'''
line 6, column 13: Unsupported value for "funding". type 'int' is not a subtype of type 'String' in type cast
  ╷
6 │    "funding": [
  │ ┌─────────────^
7 │ │   1
8 │ └  ]
  ╵''',
        skipTryPub: true,
      );
    });

    test('not an uri', () {
      expectParseThrows(
        {
          ...defaultPubspec,
          'funding': ['ht tps://example.com/'],
        },
        r'''
line 6, column 13: Unsupported value for "funding". Illegal scheme character at offset 2.
  ╷
6 │    "funding": [
  │ ┌─────────────^
7 │ │   "ht tps://example.com/"
8 │ └  ]
  ╵''',
        skipTryPub: true,
      );
    });
  });

  group('screenshots', () {
    test('one screenshot', () {
      final value = parse({
        ...defaultPubspec,
        'screenshots': [
          {'description': 'my screenshot', 'path': 'path/to/screenshot'}
        ],
      });
      expect(value.screenshots, hasLength(1));
      expect(value.screenshots!.first.description, 'my screenshot');
      expect(value.screenshots!.first.path, 'path/to/screenshot');
    });

    test('many screenshots', () {
      final value = parse({
        ...defaultPubspec,
        'screenshots': [
          {'description': 'my screenshot', 'path': 'path/to/screenshot'},
          {
            'description': 'my second screenshot',
            'path': 'path/to/screenshot2'
          },
        ],
      });
      expect(value.screenshots, hasLength(2));
      expect(value.screenshots!.first.description, 'my screenshot');
      expect(value.screenshots!.first.path, 'path/to/screenshot');
      expect(value.screenshots!.last.description, 'my second screenshot');
      expect(value.screenshots!.last.path, 'path/to/screenshot2');
    });

    test('one screenshot plus invalid entries', () {
      final value = parse({
        ...defaultPubspec,
        'screenshots': [
          42,
          {
            'description': 'my screenshot',
            'path': 'path/to/screenshot',
            'extraKey': 'not important'
          },
          'not a screenshot',
        ],
      });
      expect(value.screenshots, hasLength(1));
      expect(value.screenshots!.first.description, 'my screenshot');
      expect(value.screenshots!.first.path, 'path/to/screenshot');
    });

    test('invalid entries', () {
      final value = parse({
        ...defaultPubspec,
        'screenshots': [
          42,
          'not a screenshot',
        ],
      });
      expect(value.screenshots, isEmpty);
    });

    test('missing key `dessription', () {
      expectParseThrows(
        {
          ...defaultPubspec,
          'screenshots': [
            {'path': 'my/path'},
          ],
        },
        r'''
line 7, column 3: Missing key "description". Missing required key `description`
  ╷
7 │ ┌   {
8 │ │    "path": "my/path"
9 │ └   }
  ╵''',
        skipTryPub: true,
      );
    });

    test('missing key `path`', () {
      expectParseThrows(
        {
          ...defaultPubspec,
          'screenshots': [
            {'description': 'my screenshot'},
          ],
        },
        r'''
line 7, column 3: Missing key "path". Missing required key `path`
  ╷
7 │ ┌   {
8 │ │    "description": "my screenshot"
9 │ └   }
  ╵''',
        skipTryPub: true,
      );
    });

    test('Value of description not a String`', () {
      expectParseThrows(
        {
          ...defaultPubspec,
          'screenshots': [
            {'description': 42},
          ],
        },
        r'''
line 8, column 19: Unsupported value for "description". `42` is not a String
  ╷
8 │      "description": 42
  │ ┌───────────────────^
9 │ │   }
  │ └──^
  ╵''',
        skipTryPub: true,
      );
    });

    test('Value of path not a String`', () {
      expectParseThrows(
        {
          ...defaultPubspec,
          'screenshots': [
            {
              'description': '',
              'path': 42,
            },
          ],
        },
        r'''
line 9, column 12: Unsupported value for "path". `42` is not a String
   ╷
9  │      "path": 42
   │ ┌────────────^
10 │ │   }
   │ └──^
   ╵''',
        skipTryPub: true,
      );
    });

    test('invalid screenshot - lenient', () {
      final value = parse(
        {
          ...defaultPubspec,
          'screenshots': 'Invalid value',
        },
        lenient: true,
      );
      expect(value.name, 'sample');
      expect(value.screenshots, isEmpty);
    });
  });

  group('lenient', () {
    test('null', () {
      expectParseThrows(
        null,
        r'''
line 1, column 1: Not a map
  ╷
1 │ null
  │ ^^^^
  ╵''',
        lenient: true,
      );
    });

    test('empty string', () {
      expectParseThrows(
        '',
        r'''
line 1, column 1: Not a map
  ╷
1 │ ""
  │ ^^
  ╵''',
        lenient: true,
      );
    });

    test('name cannot be empty', () {
      expectParseThrows(
        {},
        r'''
line 1, column 1: Missing key "name". type 'Null' is not a subtype of type 'String' in type cast
  ╷
1 │ {}
  │ ^^
  ╵''',
        lenient: true,
      );
    });

    test('bad repository url', () {
      final value = parse(
        {
          ...defaultPubspec,
          'repository': {'x': 'y'},
        },
        lenient: true,
      );
      expect(value.name, 'sample');
      expect(value.repository, isNull);
    });

    test('bad issue_tracker url', () {
      final value = parse(
        {
          ...defaultPubspec,
          'issue_tracker': {'x': 'y'},
        },
        lenient: true,
      );
      expect(value.name, 'sample');
      expect(value.issueTracker, isNull);
    });

    test('multiple bad values', () {
      final value = parse(
        {
          ...defaultPubspec,
          'repository': {'x': 'y'},
          'issue_tracker': {'x': 'y'},
        },
        lenient: true,
      );
      expect(value.name, 'sample');
      expect(value.repository, isNull);
      expect(value.issueTracker, isNull);
    });

    test('deep error throws with lenient', () {
      expect(
        () => parse(
          {
            'name': 'sample',
            'dependencies': {
              'foo': {
                'git': {'url': 1}
              },
            },
            'issue_tracker': {'x': 'y'},
          },
          skipTryPub: true,
          lenient: true,
        ),
        throwsException,
      );
    });
  });
}
