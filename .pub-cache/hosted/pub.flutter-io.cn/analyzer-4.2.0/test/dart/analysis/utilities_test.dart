// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../util/feature_sets.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UtilitiesTest);
  });
}

@reflectiveTest
class UtilitiesTest with ResourceProviderMixin {
  test_parseFile_default_resource_provider() {
    String content = '''
void main() => print('Hello, world!');
    ''';
    ParseStringResult result = _withTemporaryFile(
        content,
        (path) => parseFile(
            path: path, featureSet: FeatureSet.latestLanguageVersion()));
    expect(result.content, content);
    expect(result.errors, isEmpty);
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(),
        equals("void main() => print('Hello, world!');"));
  }

  test_parseFile_errors_noThrow() {
    String content = '''
void main() => print('Hello, world!')
''';
    ParseStringResult result = _withMemoryFile(
        content,
        (resourceProvider, path) => parseFile(
            path: path,
            featureSet: FeatureSet.latestLanguageVersion(),
            resourceProvider: resourceProvider,
            throwIfDiagnostics: false));
    expect(result.content, content);
    expect(result.errors, hasLength(1));
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(),
        equals("void main() => print('Hello, world!');"));
  }

  test_parseFile_errors_path() {
    String content = '''
void main() => print('Hello, world!')
''';
    late String expectedPath;
    ParseStringResult result =
        _withMemoryFile(content, (resourceProvider, path) {
      expectedPath = path;
      return parseFile(
          path: path,
          featureSet: FeatureSet.latestLanguageVersion(),
          resourceProvider: resourceProvider,
          throwIfDiagnostics: false);
    });
    expect(result.errors, hasLength(1));
    expect(result.errors[0].source.fullName, expectedPath);
  }

  test_parseFile_errors_throw() {
    String content = '''
void main() => print('Hello, world!')
''';
    expect(
        () => _withMemoryFile(
            content,
            (resourceProvider, path) => parseFile(
                path: path,
                featureSet: FeatureSet.latestLanguageVersion(),
                resourceProvider: resourceProvider)),
        throwsA(const TypeMatcher<ArgumentError>()));
  }

  test_parseFile_featureSet_language_2_9() {
    String content = '''
int? f() => 1;
''';
    var featureSet = FeatureSets.language_2_9;
    expect(featureSet.isEnabled(Feature.non_nullable), isFalse);
    ParseStringResult result = _withMemoryFile(
        content,
        (resourceProvider, path) => parseFile(
            path: path,
            resourceProvider: resourceProvider,
            throwIfDiagnostics: false,
            featureSet: featureSet));
    expect(result.content, content);
    expect(result.errors, hasLength(1));
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(), equals('int? f() => 1;'));
  }

  test_parseFile_featureSet_language_latest() {
    String content = '''
int? f() => 1;
''';
    ParseStringResult result = _withMemoryFile(
        content,
        (resourceProvider, path) => parseFile(
            path: path,
            resourceProvider: resourceProvider,
            throwIfDiagnostics: false,
            featureSet: FeatureSet.latestLanguageVersion()));
    expect(result.content, content);
    expect(result.errors, isEmpty);
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(), equals('int? f() => 1;'));
  }

  test_parseFile_noErrors() {
    String content = '''
void main() => print('Hello, world!');
''';
    ParseStringResult result = _withMemoryFile(
        content,
        (resourceProvider, path) => parseFile(
            path: path,
            featureSet: FeatureSet.latestLanguageVersion(),
            resourceProvider: resourceProvider));
    expect(result.content, content);
    expect(result.errors, isEmpty);
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(),
        equals("void main() => print('Hello, world!');"));
  }

  test_parseString_errors_noThrow() {
    String content = '''
void main() => print('Hello, world!')
''';
    ParseStringResult result =
        parseString(content: content, throwIfDiagnostics: false);
    expect(result.content, content);
    expect(result.errors, hasLength(1));
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(),
        equals("void main() => print('Hello, world!');"));
  }

  test_parseString_errors_path() {
    String content = '''
void main() => print('Hello, world!')
''';
    var path = 'foo/bar';
    ParseStringResult result = parseString(
        content: content, path: 'foo/bar', throwIfDiagnostics: false);
    expect(result.errors, hasLength(1));
    var error = result.errors[0];
    expect(error.source.fullName, path);
  }

  test_parseString_errors_throw() {
    String content = '''
void main() => print('Hello, world!')
''';
    expect(() => parseString(content: content),
        throwsA(const TypeMatcher<ArgumentError>()));
  }

  test_parseString_featureSet_nnbd_off() {
    String content = '''
int? f() => 1;
''';
    var featureSet = FeatureSets.language_2_9;
    expect(featureSet.isEnabled(Feature.non_nullable), isFalse);
    ParseStringResult result = parseString(
        content: content, throwIfDiagnostics: false, featureSet: featureSet);
    expect(result.content, content);
    expect(result.errors, hasLength(1));
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(), equals('int? f() => 1;'));
  }

  test_parseString_featureSet_nnbd_on() {
    String content = '''
int? f() => 1;
''';
    ParseStringResult result = parseString(
      content: content,
      throwIfDiagnostics: false,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    expect(result.content, content);
    expect(result.errors, isEmpty);
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(), equals('int? f() => 1;'));
  }

  test_parseString_languageVersion() {
    var content = '''
// @dart = 2.7
class A {}
''';
    var result = parseString(
      content: content,
      throwIfDiagnostics: false,
      featureSet: FeatureSet.latestLanguageVersion(),
    );

    var languageVersion = result.unit.languageVersionToken!;
    expect(languageVersion.major, 2);
    expect(languageVersion.minor, 7);
  }

  test_parseString_languageVersion_null() {
    var content = '''
class A {}
''';
    var result = parseString(
      content: content,
      throwIfDiagnostics: false,
      featureSet: FeatureSet.latestLanguageVersion(),
    );

    expect(result.unit.languageVersionToken, isNull);
  }

  test_parseString_lineInfo() {
    String content = '''
main() {
  print('Hello, world!');
}
''';
    ParseStringResult result = parseString(content: content);
    expect(result.lineInfo, same(result.unit.lineInfo));
    expect(result.lineInfo.lineStarts, [0, 9, 35, 37]);
  }

  test_parseString_noErrors() {
    String content = '''
void main() => print('Hello, world!');
''';
    ParseStringResult result = parseString(content: content);
    expect(result.content, content);
    expect(result.errors, isEmpty);
    expect(result.lineInfo, isNotNull);
    expect(result.unit.toString(),
        equals("void main() => print('Hello, world!');"));
  }

  T _withMemoryFile<T>(
      String content,
      T Function(MemoryResourceProvider resourceProvider, String path)
          callback) {
    var resourceProvider = MemoryResourceProvider();
    var path =
        resourceProvider.pathContext.fromUri(Uri.parse('file:///test.dart'));
    resourceProvider.newFile(path, content);
    return callback(resourceProvider, path);
  }

  T _withTemporaryFile<T>(String content, T Function(String path) callback) {
    var tempDir = Directory.systemTemp.createTempSync();
    try {
      var file = File(p.join(tempDir.path, 'test.dart'));
      file.writeAsStringSync(content);
      return callback(file.path);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  }
}
