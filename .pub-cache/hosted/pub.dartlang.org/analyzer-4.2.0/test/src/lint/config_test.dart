// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/config.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../util/yaml_test.dart';

main() {
  defineTests();
}

defineTests() {
  const src = """
files:
  include: foo # un-quoted
  exclude:
    - 'test/**'       # file globs can be scalars or lists
    - '**/_data.dart' # unquoted stars treated by YAML as aliases
rules:
  style_guide:
    unnecessary_getters: false #disable
    camel_case_types: true #enable
  pub:
    package_names: false
""";

// In the future, options might be marshaled in maps and passed to rules.
//  acme:
//    some_rule:
//      some_option: # Note this nesting might be arbitrarily complex?
//        - param1
//        - param2

  var config = LintConfig.parse(src);

  group('lint config', () {
    group('file', () {
      test('includes', () {
        expect(config.fileIncludes, unorderedEquals(['foo']));
      });
      test('excludes', () {
        expect(
            config.fileExcludes, unorderedEquals(['test/**', '**/_data.dart']));
      });
    });
    group('rule', () {
      test('configs', () {
        expect(config.ruleConfigs, hasLength(3));
      });

      test('config', () {
        config = LintConfig.parse('''
rules:
  style_guide:
    unnecessary_getters: false''');
        expect(config.ruleConfigs, hasLength(1));
        var ruleConfig = config.ruleConfigs[0];
        expect(ruleConfig.group, 'style_guide');
        expect(ruleConfig.name, 'unnecessary_getters');
        expect(ruleConfig.args, {'enabled': false});
        expect(ruleConfig.disables('unnecessary_getters'), isTrue);
      });
    });
  });

  group('analysis options', () {
    group('parsing', () {
      group('groups', () {
        test('basic', () {
          var src = '''
plugin_a:
  option_a: false
plugin_b:
  option_b: true
linter:
  rules:
    style_guide:
      unnecessary_getters: false #disable
      camel_case_types: true #enable
''';
          var config = processAnalysisOptionsFile(src)!;
          var ruleNames = config.ruleConfigs.map((rc) => rc.name);
          expect(ruleNames, hasLength(2));
          expect(ruleNames, contains('unnecessary_getters'));
          expect(ruleNames, contains('camel_case_types'));
        });
      });

      group('w/o groups', () {
        test('rule list', () {
          var src = '''
plugin_a:
  option_a: false
plugin_b:
  option_b: true
linter:
  rules:
    - camel_case_types
''';
          var config = processAnalysisOptionsFile(src)!;
          expect(config.ruleConfigs.length, 1);
          // Verify that defaults are enabled.
          expect(config.ruleConfigs[0].args['enabled'], isTrue);
        });

        test('rule map (bools)', () {
          var src = '''
plugin_a:
  option_a: false
plugin_b:
  option_b: true
linter:
  rules:
    camel_case_types: true #enable
    unnecessary_getters: false #disable
''';
          var config = processAnalysisOptionsFile(src)!;
          var ruleConfigs = config.ruleConfigs.toList();
          ruleConfigs.sort((RuleConfig rc1, RuleConfig rc2) =>
              rc1.name!.compareTo(rc2.name!));
          expect(ruleConfigs, hasLength(2));
          expect(ruleConfigs[0].name, 'camel_case_types');
          expect(ruleConfigs[0].args['enabled'], isTrue);
          expect(ruleConfigs[1].name, 'unnecessary_getters');
          expect(ruleConfigs[1].args['enabled'], isFalse);
        });
      });
    });

    test('empty file', () {
      expect(processAnalysisOptionsFile(''), isNull);
    });

    test('bad format', () {
      expect(processAnalysisOptionsFile('foo: '), isNull);
    });
  });

  group('options processing', () {
    group('raw maps', () {
      LintConfig parseMap(Map<Object, Object?> map) {
        return parseConfig(wrap(map) as YamlMap)!;
      }

      test('rule list', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': ['camel_case_types']
        };
        options['linter'] = lintOptions;

        var config = parseMap(options);
        expect(config, isNotNull);
        expect(config.ruleConfigs, hasLength(1));
      });

      test('rule map (bool)', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': {'camel_case_types': true}
        };
        options['linter'] = lintOptions;

        var config = parseMap(options);
        expect(config, isNotNull);
        expect(config.ruleConfigs, hasLength(1));
      });

      test('rule map (string)', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': {'camel_case_types': 'true'}
        };
        options['linter'] = lintOptions;

        var config = parseMap(options);
        expect(config, isNotNull);
        expect(config.ruleConfigs, hasLength(1));
      });

      test('nested rule map (bool)', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': {
            'style_guide': {'camel_case_types': true}
          }
        };
        options['linter'] = lintOptions;

        var config = parseMap(options);
        expect(config, isNotNull);
        expect(config.ruleConfigs, hasLength(1));
      });

      test('nested rule map (string)', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': {
            'style_guide': {'camel_case_types': true}
          }
        };
        options['linter'] = lintOptions;

        var config = parseMap(options);
        expect(config, isNotNull);
        expect(config.ruleConfigs, hasLength(1));
      });
    });
  });
}
