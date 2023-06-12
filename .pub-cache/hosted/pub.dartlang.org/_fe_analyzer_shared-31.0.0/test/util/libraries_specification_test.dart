// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart';
import 'package:test/test.dart';

void main() {
  group('parse', () {
    test('top-level must be a map', () async {
      var jsonString = '[]';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));
      jsonString = '""';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));
    });

    test('target entry must be a map', () async {
      var jsonString = '{"vm" : []}';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));
      jsonString = '{"vm" : ""}';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));
    });

    test('library entry must exist', () async {
      var jsonString = '{"vm" : {}}';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));
    });

    test('library entry must be a map', () async {
      var jsonString = '{"vm" : {"libraries": []}}';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));
    });

    test('uri must be a string', () async {
      var jsonString = '{"vm" : {"libraries": {"core": {"uri": 3}}}';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));
    });

    test('patches must be a string or list of string', () async {
      var jsonString = '''
      { 
        "none": {
          "libraries": {
              "c" : {
                "uri": "c/main.dart",
                "patches": 3
              }
          }
        }
      }
      ''';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));

      jsonString = '''
      { 
        "none": {
          "libraries": {
              "c" : {
                "uri": "c/main.dart",
                "patches": "a.dart"
              }
          }
        }
      }
      ''';
      var spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///f.json'), jsonString);
      expect(spec.specificationFor("none").libraryInfoFor("c")!.patches.first,
          Uri.parse('org-dartlang-test:///a.dart'));

      jsonString = '''
      { 
        "none": {
          "libraries": {
              "c" : {
                "uri": "c/main.dart",
                "patches": ["a.dart"]
              }
          }
        }
      }
      ''';
      spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///f.json'), jsonString);
      expect(spec.specificationFor("none").libraryInfoFor("c")!.patches.first,
          Uri.parse('org-dartlang-test:///a.dart'));
    });

    test('patches are optional in the format', () async {
      var jsonString = '''
      { "none": { "libraries": {"c" : { "uri": "c/main.dart" }}}}
      ''';
      var spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///one/two/f.json'), jsonString);
      expect(spec, isNotNull);
      expect(
          spec.specificationFor('none').libraryInfoFor('c')!.patches, isEmpty);
    });

    test('library paths are resolved from spec uri', () async {
      var jsonString = '''
      { "none": { "libraries": {"c" : { "uri": "c/main.dart" }}}}
      ''';

      var spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///one/two/f.json'), jsonString);
      expect(spec.specificationFor('none').libraryInfoFor('c')!.uri,
          Uri.parse('org-dartlang-test:///one/two/c/main.dart'));
    });

    test('patches paths are resolved from spec uri', () async {
      var jsonString = '''
      { 
        "none": {
          "libraries": {
              "c" : {
                "uri": "c/main.dart",
                "patches": [
                  "../a/p1.dart",
                  "../a/p2.dart"
                ]
              }
          }
        }
      }
      ''';

      var spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///one/two/f.json'), jsonString);
      expect(spec.specificationFor('none').libraryInfoFor('c')!.patches[0],
          Uri.parse('org-dartlang-test:///one/a/p1.dart'));
      expect(spec.specificationFor('none').libraryInfoFor('c')!.patches[1],
          Uri.parse('org-dartlang-test:///one/a/p2.dart'));
    });

    test('multiple targets are supported', () async {
      var jsonString = '''
      {
        "vm": {
          "libraries": {
              "foo" : {
                "uri": "a/main.dart",
                "patches": [
                  "a/p1.dart",
                  "a/p2.dart"
                ]
              },
              "bar" : {
                "uri": "b/main.dart",
                "patches": [
                  "b/p3.dart"
                ]
              }
          }
        },
        "none": {
          "libraries": {
              "c" : {
                "uri": "c/main.dart"
              }
          }
        }
      }
      ''';

      var spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///one/two/f.json'), jsonString);

      expect(spec.specificationFor('vm').libraryInfoFor('foo')!.uri,
          Uri.parse('org-dartlang-test:///one/two/a/main.dart'));
      expect(spec.specificationFor('vm').libraryInfoFor('bar')!.uri,
          Uri.parse('org-dartlang-test:///one/two/b/main.dart'));
      expect(spec.specificationFor('none').libraryInfoFor('c')!.uri,
          Uri.parse('org-dartlang-test:///one/two/c/main.dart'));
    });

    test('supported entry must be bool', () async {
      var jsonString = '{"vm" : {"libraries": {"core": '
          '{"uri": "main.dart", "supported": 3}},';
      expect(
          () => LibrariesSpecification.parse(
              Uri.parse('org-dartlang-test:///f.json'), jsonString),
          throwsA((e) => e is LibrariesSpecificationException));
    });

    test('supported entry is copied correctly when parsing', () async {
      var jsonString = '''
      {
        "vm": {
          "libraries": {
              "foo" : {
                "uri": "a/main.dart",
                "patches": [
                  "a/p1.dart",
                  "a/p2.dart"
                ],
                "supported": false

              },
              "bar" : {
                "uri": "b/main.dart",
                "patches": [
                  "b/p3.dart"
                ],
                "supported": true
              },
              "baz" : {
                "uri": "b/main.dart",
                "patches": [
                  "b/p3.dart"
                ]
              }
          }
        }
      }
      ''';
      var spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///one/two/f.json'), jsonString);
      expect(spec.specificationFor('vm').libraryInfoFor('foo')!.isSupported,
          false);
      expect(
          spec.specificationFor('vm').libraryInfoFor('bar')!.isSupported, true);
      expect(
          spec.specificationFor('vm').libraryInfoFor('baz')!.isSupported, true);
    });
  });

  group('toJson', () {
    test('serialization produces same data that was parsed', () async {
      var jsonString = '''
      {
        "vm": {
          "libraries": {
              "foo" : {
                "uri": "a/main.dart",
                "patches": [
                  "a/p1.dart",
                  "a/p2.dart"
                ],
                "supported": false
              },
              "bar" : {
                "uri": "b/main.dart",
                "patches": [
                  "b/p3.dart"
                ]
              }
          }
        },
        "none": {
          "libraries": {
              "c" : {
                "uri": "c/main.dart",
                "patches": []
              }
          }
        }
      }
      ''';

      var spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///one/two/f.json'), jsonString);
      var newJson =
          spec.toJsonString(Uri.parse('org-dartlang-test:///one/two/g.json'));
      expect(jsonString.replaceAll(new RegExp('\\s'), ''), newJson);
    });

    test('serialization can adapt to new file location', () async {
      var jsonString = '''
      {
        "vm": {
          "libraries": {
              "foo" : {
                "uri": "a/main.dart",
                "patches": [
                  "a/p1.dart",
                  "a/p2.dart"
                ]
              },
              "bar" : {
                "uri": "b/main.dart",
                "patches": [
                  "b/p3.dart"
                ]
              }
          }
        },
        "none": {
          "libraries": {
              "c" : {
                "uri": "c/main.dart"
              }
          }
        }
      }
      ''';

      var spec = LibrariesSpecification.parse(
          Uri.parse('org-dartlang-test:///one/two/f.json'), jsonString);
      var newJson =
          spec.toJsonString(Uri.parse('org-dartlang-test:///one/g.json'));

      var expected = '''
      {
        "vm": {
          "libraries": {
              "foo" : {
                "uri": "two/a/main.dart",
                "patches": [
                  "two/a/p1.dart",
                  "two/a/p2.dart"
                ]
              },
              "bar" : {
                "uri": "two/b/main.dart",
                "patches": [
                  "two/b/p3.dart"
                ]
              }
          }
        },
        "none": {
          "libraries": {
              "c" : {
                "uri": "two/c/main.dart",
                "patches": []
              }
          }
        }
      }
      ''';

      expect(expected.replaceAll(new RegExp('\\s'), ''), newJson);
    });
  });
}
