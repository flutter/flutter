// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsRuleValidatorTest);
  });
}

class DeprecatedLint extends LintRule {
  DeprecatedLint()
      : super(
          name: 'deprecated_lint',
          group: Group.style,
          maturity: Maturity.deprecated,
          description: '',
          details: '',
        );
}

@reflectiveTest
class OptionsRuleValidatorTest extends Object with ResourceProviderMixin {
  LinterRuleOptionsValidator validator = LinterRuleOptionsValidator(
      provider: () => [DeprecatedLint(), StableLint(), RuleNeg(), RulePos()]);

  /// Assert that when the validator is used on the given [content] the
  /// [expectedErrorCodes] are produced.
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes) {
    GatheringErrorListener listener = GatheringErrorListener();
    ErrorReporter reporter = ErrorReporter(
      listener,
      StringSource(content, 'analysis_options.yaml'),
      isNonNullableByDefault: false,
    );
    validator.validate(reporter, loadYamlNode(content) as YamlMap);
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  test_deprecated_rule() {
    assertErrors('''
linter:
  rules:
    - deprecated_lint
      ''', [DEPRECATED_LINT_HINT]);
  }

  test_duplicated_rule() {
    assertErrors('''
linter:
  rules:
    - stable_lint
    - stable_lint
      ''', [DUPLICATE_RULE_HINT]);
  }

  test_incompatible_rule() {
    assertErrors('''
linter:
  rules:
    - rule_pos
    - rule_neg
      ''', [INCOMPATIBLE_LINT_WARNING]);
  }

  test_stable_rule() {
    assertErrors('''
linter:
  rules:
    - stable_lint
      ''', []);
  }

  test_undefined_rule() {
    assertErrors('''
linter:
  rules:
    - this_rule_does_not_exist
      ''', [UNDEFINED_LINT_WARNING]);
  }
}

class RuleNeg extends LintRule {
  RuleNeg()
      : super(
          name: 'rule_neg',
          group: Group.style,
          description: '',
          details: '',
        );
  @override
  List<String> get incompatibleRules => ['rule_pos'];
}

class RulePos extends LintRule {
  RulePos()
      : super(
          name: 'rule_pos',
          group: Group.style,
          description: '',
          details: '',
        );
  @override
  List<String> get incompatibleRules => ['rule_neg'];
}

class StableLint extends LintRule {
  StableLint()
      : super(
          name: 'stable_lint',
          group: Group.style,
          maturity: Maturity.stable,
          description: '',
          details: '',
        );
}
