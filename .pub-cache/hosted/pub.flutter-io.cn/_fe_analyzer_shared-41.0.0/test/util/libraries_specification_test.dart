// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart';
import 'package:test/test.dart';

bool Function(dynamic) checkException(String expectedMessage) {
  return (exception) {
    print(exception);
    if (exception is LibrariesSpecificationException) {
      expect(exception.error, expectedMessage);
      return true;
    }
    return false;
  };
}

void main() {
  String notFoundMessage = 'File not found';

  Uri specUri = Uri.parse('org-dartlang-test:///f.json');

  Future<String> Function(Uri) read(Map<Uri, String> map) {
    return (Uri uri) async {
      String? jsonString = map[uri];
      if (jsonString == null) {
        throw notFoundMessage;
      }
      return jsonString;
    };
  }

  group('parse', () {
    test('top-level must be a map', () async {
      var jsonString = '[]';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messageTopLevelIsNotAMap(specUri))));
      jsonString = '""';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messageTopLevelIsNotAMap(specUri))));
    });

    test('target entry must be a map', () async {
      var jsonString = '{"vm" : []}';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messageTargetIsNotAMap('vm', specUri))));
      jsonString = '{"vm" : ""}';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messageTargetIsNotAMap('vm', specUri))));
    });

    test('library entry must exist', () async {
      var jsonString = '{"vm" : {}}';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(
              checkException(messageTargetLibrariesMissing('vm', specUri))));
    });

    test('library entry must be a map', () async {
      var jsonString = '{"vm" : {"libraries": []}}';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(
              checkException(messageLibrariesEntryIsNotAMap('vm', specUri))));
    });

    test('library data must be a map', () async {
      var jsonString = '{"vm" : {"libraries": { "foo": [] }}}';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(
              messageLibraryDataIsNotAMap('foo', 'vm', specUri))));
    });

    test('library uri must be supplied', () async {
      var jsonString = '{"vm" : {"libraries": {"core": {}}}}';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(
              checkException(messageLibraryUriMissing('core', 'vm', specUri))));
    });

    test('uri must be a string', () async {
      var jsonString = '{"vm" : {"libraries": {"core": {"uri": 3}}}}';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(
              messageLibraryUriIsNotAString(3, 'core', 'vm', specUri))));
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
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messagePatchesMustBeListOrString('c'))));

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
      var spec = await LibrariesSpecification.load(
          specUri, read({specUri: jsonString}));
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
      spec = await LibrariesSpecification.load(
          specUri, read({specUri: jsonString}));
      expect(spec.specificationFor("none").libraryInfoFor("c")!.patches.first,
          Uri.parse('org-dartlang-test:///a.dart'));
    });

    test('patches are optional in the format', () async {
      var jsonString = '''
      { "none": { "libraries": {"c" : { "uri": "c/main.dart" }}}}
      ''';
      var uri = Uri.parse('org-dartlang-test:///one/two/f.json');
      var spec =
          await LibrariesSpecification.load(uri, read({uri: jsonString}));
      expect(spec, isNotNull);
      expect(
          spec.specificationFor('none').libraryInfoFor('c')!.patches, isEmpty);
    });

    test('library paths are resolved from spec uri', () async {
      var jsonString = '''
      { "none": { "libraries": {"c" : { "uri": "c/main.dart" }}}}
      ''';
      var uri = Uri.parse('org-dartlang-test:///one/two/f.json');
      var spec =
          await LibrariesSpecification.load(uri, read({uri: jsonString}));
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
      var uri = Uri.parse('org-dartlang-test:///one/two/f.json');
      var spec =
          await LibrariesSpecification.load(uri, read({uri: jsonString}));
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
      var uri = Uri.parse('org-dartlang-test:///one/two/f.json');
      var spec =
          await LibrariesSpecification.load(uri, read({uri: jsonString}));

      expect(spec.specificationFor('vm').libraryInfoFor('foo')!.uri,
          Uri.parse('org-dartlang-test:///one/two/a/main.dart'));
      expect(spec.specificationFor('vm').libraryInfoFor('bar')!.uri,
          Uri.parse('org-dartlang-test:///one/two/b/main.dart'));
      expect(spec.specificationFor('none').libraryInfoFor('c')!.uri,
          Uri.parse('org-dartlang-test:///one/two/c/main.dart'));
    });

    test('supported entry must be bool', () async {
      var jsonString = '''
      {
        "vm": 
        {
          "libraries": 
          {
            "core": {
              "uri": "main.dart", 
              "supported": 3
            }
          }
        }
      }''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messageSupportedIsNotABool(3))));
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
      var uri = Uri.parse('org-dartlang-test:///one/two/f.json');
      var spec =
          await LibrariesSpecification.load(uri, read({uri: jsonString}));
      expect(spec.specificationFor('vm').libraryInfoFor('foo')!.isSupported,
          false);
      expect(
          spec.specificationFor('vm').libraryInfoFor('bar')!.isSupported, true);
      expect(
          spec.specificationFor('vm').libraryInfoFor('baz')!.isSupported, true);
    });
  });

  group('nested', () {
    test('include must be a list', () async {
      var jsonString = '''
      {
        "target": {
          "include": "", 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messageIncludeIsNotAList('target', specUri))));
    });

    test('include entry must be a map', () async {
      var jsonString = '''
      {
        "target": {
          "include": [""], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(
              checkException(messageIncludeEntryIsNotAMap('target', specUri))));
    });

    test('include entry must have a target string', () async {
      var jsonString = '''
      {
        "target": {
          "include": [{}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(
              checkException(messageIncludeTargetMissing('target', specUri))));

      jsonString = '''
      {
        "target": {
          "include": [{"path": "dummy"}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(
              checkException(messageIncludeTargetMissing('target', specUri))));

      jsonString = '''
      {
        "target": {
          "include": [{"path": 0, "target": 0}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(
              messageIncludeTargetIsNotAString('target', specUri))));
    });

    test('include entry path must be a string', () async {
      var jsonString = '''
      {
        "target": {
          "include": [{"path": 0, "target": "dummy"}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(
              messageIncludePathIsNotAString('target', specUri))));

      jsonString = '''
      {
        "target": {
          "include": [{"path": "dummy", "target": 0}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(
              messageIncludeTargetIsNotAString('target', specUri))));
    });

    test('include entry path scheme can only be file', () async {
      var jsonString = '''
      {
        "target": {
          "include": [{"path": "http://foo.dart", "target": "none"}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(
              messageUnsupportedUriScheme("http://foo.dart", specUri))));
    });

    test('include entry must be a existing path and target', () async {
      var otherFile = 'g.json';
      var otherUri = specUri.resolve(otherFile);
      var jsonString = '''
      {
        "target": {
          "include": [{"path": "$otherFile", "target": "none"}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(
              messageIncludePathCouldNotBeRead(otherUri, notFoundMessage))));

      var otherJsonString = '''
      {
        "target": {
          "libraries": {}
        }
      }''';
      expect(
          () => LibrariesSpecification.load(
              specUri, read({specUri: jsonString, otherUri: otherJsonString})),
          throwsA(checkException(messageMissingTarget('none', otherUri))));
    });

    test('internal include target must exist', () async {
      var jsonString = '''
      {
        "target": {
          "include": [{"target": "none"}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messageMissingTarget('none', specUri))));
    });

    test('include entry cannot be cyclic', () async {
      var thisFile = 'f.json';
      var thisUri = specUri.resolve(thisFile);
      var otherFile = 'g.json';
      var otherUri = thisUri.resolve(otherFile);
      var thisJsonString = '''
      {
        "target": {
          "include": [{"path": "$thisFile", "target": "target"}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () => LibrariesSpecification.load(
              thisUri, read({thisUri: thisJsonString})),
          throwsA(checkException(messageCyclicSpec(thisUri))));

      thisJsonString = '''
      {
        "target": {
          "include": [{"path": "$otherFile", "target": "none"}], 
          "libraries": {}
        }
      }
      ''';
      var otherJsonString = '''
      {
        "none": {
          "include": [{"path": "$thisFile", "target": "target"}],
          "libraries": {}
        }
      }''';
      expect(
          () => LibrariesSpecification.load(thisUri,
              read({thisUri: thisJsonString, otherUri: otherJsonString})),
          throwsA(checkException(messageCyclicSpec(thisUri))));
    });

    test('include entry cannot be cyclic internally', () async {
      var jsonString = '''
      {
        "target": {
          "include": [{"target": "target"}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(
              checkException(messageCyclicInternalInclude('target', specUri))));

      jsonString = '''
      {
        "a": {
          "include": [{"target": "b"}], 
          "libraries": {}
        },
        "b": {
          "include": [{"target": "a"}], 
          "libraries": {}
        }
      }
      ''';
      expect(
          () =>
              LibrariesSpecification.load(specUri, read({specUri: jsonString})),
          throwsA(checkException(messageCyclicInternalInclude('a', specUri))));
    });

    test('include works transitively', () async {
      var thisFile = 'f.json';
      var thisUri = specUri.resolve(thisFile);
      var otherFile1 = 'g.json';
      var otherUri1 = thisUri.resolve(otherFile1);
      var otherFile2 = 'subfolder/h.json';
      var otherUri2 = thisUri.resolve(otherFile2);
      var otherFile3 = '../i.json';
      var otherUri3 = otherUri2.resolve(otherFile3);
      var thisJsonString = '''
      {
        "foo": {
          "include": [
            {
              "path": "$otherFile1", 
              "target": "foo"
            },
            {
              "path": "$otherFile2", 
              "target": "foo"
            }
          ], 
          "libraries": {}
        },
        "bar": {
          "include": [{"path": "$otherFile2", "target": "bar"}], 
          "libraries": {}
        }
      }
      ''';
      var otherJsonString1 = '''
      {
        "foo": {
          "libraries": {
            "foo": {
              "uri": "foo.dart"
            }
          }
        }
      }''';
      var otherJsonString2 = '''
      {
        "foo": {
          "libraries": {
            "foo_extra": {
              "uri": "foo_extra.dart"
            }
          }
        },
        "bar": {
          "include": [{"path": "$otherFile3", "target": "baz"}],
          "libraries": {
            "bar": {
              "uri": "bar/baz.dart"
            }
          }
        }
      }''';
      var otherJsonString3 = '''
      {
        "baz": {
          "libraries": {
            "baz": {
              "uri": "bar/baz.dart"
            }
          }
        }
      }''';
      var spec = await LibrariesSpecification.load(
          thisUri,
          read({
            thisUri: thisJsonString,
            otherUri1: otherJsonString1,
            otherUri2: otherJsonString2,
            otherUri3: otherJsonString3,
          }));

      expect(spec.specificationFor('foo').libraryInfoFor('foo')!.uri,
          otherUri1.resolve('foo.dart'));
      expect(spec.specificationFor('foo').libraryInfoFor('foo_extra')!.uri,
          otherUri2.resolve('foo_extra.dart'));
      expect(spec.specificationFor('bar').libraryInfoFor('bar')!.uri,
          otherUri2.resolve('bar/baz.dart'));
      expect(spec.specificationFor('bar').libraryInfoFor('baz')!.uri,
          otherUri3.resolve('bar/baz.dart'));
    });

    test('internal include works transitively', () async {
      var jsonString = '''
      {
        "foo": {
          "include": [{"target": "common"}], 
          "libraries": {
            "foo": {
              "uri": "foo.dart"
            }
          }
        },
        "bar": {
          "include": [
            {
               "target": "common"
            }, 
            {
               "target": "baz"
            }
          ], 
          "libraries": {
            "bar": {
              "uri": "bar.dart"
            }
          }
        },
        "common": {
          "libraries": {
            "common": {
              "uri": "common.dart"
            }
          }
        },
        "baz": {
          "include": [{"target": "boz"}],
          "libraries": {
            "baz": {
              "uri": "bar/baz.dart"
            }
          }
        },
        "boz": {
          "libraries": {
            "boz": {
              "uri": "bar/boz.dart"
            }
          }
        }        
      }
      ''';
      var spec = await LibrariesSpecification.load(
          specUri, read({specUri: jsonString}));

      expect(spec.specificationFor('foo').libraryInfoFor('foo')!.uri,
          specUri.resolve('foo.dart'));
      expect(spec.specificationFor('foo').libraryInfoFor('common')!.uri,
          specUri.resolve('common.dart'));
      expect(spec.specificationFor('bar').libraryInfoFor('bar')!.uri,
          specUri.resolve('bar.dart'));
      expect(spec.specificationFor('bar').libraryInfoFor('common')!.uri,
          specUri.resolve('common.dart'));
      expect(spec.specificationFor('bar').libraryInfoFor('baz')!.uri,
          specUri.resolve('bar/baz.dart'));
      expect(spec.specificationFor('bar').libraryInfoFor('boz')!.uri,
          specUri.resolve('bar/boz.dart'));
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

      var uri = Uri.parse('org-dartlang-test:///one/two/f.json');
      var spec =
          await LibrariesSpecification.load(uri, read({uri: jsonString}));
      var newJson =
          spec.toJsonString(Uri.parse('org-dartlang-test:///one/two/g.json'));
      expect(newJson, jsonString.replaceAll(new RegExp('\\s'), ''));
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

      var uri = Uri.parse('org-dartlang-test:///one/two/f.json');
      var spec =
          await LibrariesSpecification.load(uri, read({uri: jsonString}));
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

      expect(newJson, expected.replaceAll(new RegExp('\\s'), ''));
    });

    test('serialization of nested specs inlines data', () async {
      var jsonString = '''
      {
        "vm": {
          "include": [
            {
              "path": "g.json",
              "target": "vm"
            }
          ],
          "libraries": {
            "foo" : {
              "uri": "a/main.dart"
            }
          }
        }
      }
      ''';
      var otherJsonString = '''
      {
        "vm": {
          "libraries": {
            "bar" : {
              "uri": "b/main.dart"
            }
          }
        },
        "unused": {
          "libraries": {
            "foo" : {
              "uri": "c/main.dart"
            }
          }
        }
      }
      ''';

      var uri = Uri.parse('org-dartlang-test:///one/two/f.json');
      var otherUri = Uri.parse('org-dartlang-test:///one/two/g.json');
      var spec = await LibrariesSpecification.load(
          uri, read({uri: jsonString, otherUri: otherJsonString}));
      var newJson =
          spec.toJsonString(Uri.parse('org-dartlang-test:///one/two/h.json'));
      expect(
          newJson,
          '''
      {
        "vm": {
          "libraries": {
            "bar" : {
              "uri": "b/main.dart",
              "patches": []
            },
            "foo" : {
              "uri": "a/main.dart",
              "patches": []
            }
          }
        }
      }      
      '''
              .replaceAll(new RegExp('\\s'), ''));
    });
  });
}
