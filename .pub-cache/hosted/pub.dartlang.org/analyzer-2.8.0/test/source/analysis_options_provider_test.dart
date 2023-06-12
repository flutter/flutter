// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../src/util/yaml_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsProviderTest);
  });
  group('AnalysisOptionsProvider', () {
    void expectMergesTo(String defaults, String overrides, String expected) {
      var optionsProvider = AnalysisOptionsProvider();
      var defaultOptions = optionsProvider.getOptionsFromString(defaults);
      var overrideOptions = optionsProvider.getOptionsFromString(overrides);
      var merged = optionsProvider.merge(defaultOptions, overrideOptions);
      expectEquals(merged, optionsProvider.getOptionsFromString(expected));
    }

    group('merging', () {
      test('integration', () {
        expectMergesTo('''
analyzer:
  plugins:
    - p1
    - p2
  errors:
    unused_local_variable : error
linter:
  rules:
    - camel_case_types
    - one_member_abstracts
''', '''
analyzer:
  plugins:
    - p3
  errors:
    unused_local_variable : ignore # overrides error
linter:
  rules:
    one_member_abstracts: false # promotes and disables
    always_specify_return_types: true
''', '''
analyzer:
  plugins:
    - p1
    - p2
    - p3
  errors:
    unused_local_variable : ignore
linter:
  rules:
    camel_case_types: true
    one_member_abstracts: false
    always_specify_return_types: true
''');
      });
    });
  });

  group('AnalysisOptionsProvider', () {
    test('test_bad_yaml (1)', () {
      var src = '''
    analyzer: # <= bang
strong-mode: true
''';

      var optionsProvider = AnalysisOptionsProvider();
      expect(() => optionsProvider.getOptionsFromString(src),
          throwsA(TypeMatcher<OptionsFormatException>()));
    });

    test('test_bad_yaml (2)', () {
      var src = '''
analyzer:
  strong-mode:true # missing space (sdk/issues/24885)
''';

      var optionsProvider = AnalysisOptionsProvider();
      // Should not throw an exception.
      var options = optionsProvider.getOptionsFromString(src);
      // Should return a non-null options list.
      expect(options, isNotNull);
    });
  });
}

@reflectiveTest
class AnalysisOptionsProviderTest with ResourceProviderMixin {
  String get analysisOptionsYaml => file_paths.analysisOptionsYaml;

  void test_getOptions_crawlUp_hasInFolder() {
    newFolder('/foo/bar');
    newFile('/foo/$analysisOptionsYaml', content: r'''
analyzer:
  ignore:
    - foo
''');
    newFile('/foo/bar/$analysisOptionsYaml', content: r'''
analyzer:
  ignore:
    - bar
''');
    YamlMap options = _getOptions('/foo/bar');
    expect(options, hasLength(1));
    {
      var analyzer = options.valueAt('analyzer') as YamlMap;
      expect(analyzer, isNotNull);
      expect(analyzer.valueAt('ignore'), unorderedEquals(['bar']));
    }
  }

  void test_getOptions_crawlUp_hasInParent() {
    newFolder('/foo/bar/baz');
    newFile('/foo/$analysisOptionsYaml', content: r'''
analyzer:
  ignore:
    - foo
''');
    newFile('/foo/bar/$analysisOptionsYaml', content: r'''
analyzer:
  ignore:
    - bar
''');
    YamlMap options = _getOptions('/foo/bar/baz');
    expect(options, hasLength(1));
    {
      var analyzer = options.valueAt('analyzer') as YamlMap;
      expect(analyzer, isNotNull);
      expect(analyzer.valueAt('ignore'), unorderedEquals(['bar']));
    }
  }

  void test_getOptions_doesNotExist() {
    newFolder('/notFile');
    YamlMap options = _getOptions('/notFile');
    expect(options, isEmpty);
  }

  void test_getOptions_empty() {
    newFile('/$analysisOptionsYaml', content: r'''#empty''');
    YamlMap options = _getOptions('/');
    expect(options, isNotNull);
    expect(options, isEmpty);
  }

  void test_getOptions_include() {
    newFile('/foo.include', content: r'''
analyzer:
  ignore:
    - ignoreme.dart
    - 'sdk_ext/**'
''');
    newFile('/$analysisOptionsYaml', content: r'''
include: foo.include
''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(2));
    {
      var analyzer = options.valueAt('analyzer') as YamlMap;
      expect(analyzer, hasLength(1));
      {
        var ignore = analyzer.valueAt('ignore') as YamlList;
        expect(ignore, hasLength(2));
        expect(ignore[0], 'ignoreme.dart');
        expect(ignore[1], 'sdk_ext/**');
      }
    }
  }

  void test_getOptions_include_emptyLints() {
    newFile('/foo.include', content: r'''
linter:
  rules:
    - prefer_single_quotes
''');
    newFile('/$analysisOptionsYaml', content: r'''
include: foo.include
linter:
  rules:
    # avoid_print: false
''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(2));
    {
      var linter = options.valueAt('linter') as YamlMap;
      expect(linter, hasLength(1));
      {
        var rules = linter.valueAt('rules') as YamlList;
        expect(rules, hasLength(1));
        expect(rules[0], 'prefer_single_quotes');
      }
    }
  }

  void test_getOptions_include_missing() {
    newFile('/$analysisOptionsYaml', content: r'''
include: /foo.include
''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(1));
  }

  void test_getOptions_invalid() {
    newFile('/$analysisOptionsYaml', content: r''':''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(1));
  }

  void test_getOptions_simple() {
    newFile('/$analysisOptionsYaml', content: r'''
analyzer:
  ignore:
    - ignoreme.dart
    - 'sdk_ext/**'
''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(1));
    {
      var analyzer = options.valueAt('analyzer') as YamlMap;
      expect(analyzer, hasLength(1));
      {
        var ignore = analyzer.valueAt('ignore') as YamlList;
        expect(ignore, hasLength(2));
        expect(ignore[0], 'ignoreme.dart');
        expect(ignore[1], 'sdk_ext/**');
      }
    }
  }

  YamlMap _getOptions(String posixPath) {
    var folder = getFolder(posixPath);
    var provider = AnalysisOptionsProvider(SourceFactory([
      ResourceUriResolver(resourceProvider),
    ]));
    return provider.getOptions(folder);
  }
}
